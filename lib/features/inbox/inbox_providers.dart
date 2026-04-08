/// Crusader — Email Providers (Riverpod)
///
/// Provides email state (threads, mailboxes, sync) to the UI layer.
/// Connects to the EmailRepository for data + the AccountNotifier for auth.
library;

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:typed_data';

import '../../data/datasources/avatar_service.dart';
import '../../data/datasources/database.dart';
import '../../data/datasources/imap_service.dart';
import '../../data/datasources/notification_service.dart';
import '../../data/datasources/smtp_service.dart';
import '../../data/repositories/email_repository.dart';
import '../../domain/entities/email_thread.dart';
import '../../domain/entities/mailbox.dart';
import '../auth/auth_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Singleton Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Drift database — single instance for the app lifetime.
final databaseProvider = Provider<CrusaderDatabase>((ref) {
  final db = CrusaderDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// IMAP service — single instance managing all connections.
final imapServiceProvider = Provider<ImapService>((ref) {
  final service = ImapService();
  ref.onDispose(() => service.disconnectAll());
  return service;
});

/// SMTP service — single instance for sending emails.
final smtpServiceProvider = Provider<SmtpService>((ref) {
  final service = SmtpService();
  ref.onDispose(() => service.disconnectAll());
  return service;
});

/// Email repository — combines IMAP + SMTP + Drift.
final emailRepositoryProvider = Provider<EmailRepository>((ref) {
  final repo = EmailRepository(
    db: ref.read(databaseProvider),
    imapService: ref.read(imapServiceProvider),
    smtpService: ref.read(smtpServiceProvider),
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Singleton avatar service.
final avatarServiceProvider = Provider<AvatarService>((ref) {
  return AvatarService.instance;
});

/// Per-email avatar bytes — auto-cached, returns null when no Gravatar exists.
final avatarProvider = FutureProvider.family<Uint8List?, String>((ref, email) {
  return ref.read(avatarServiceProvider).getAvatar(email);
});

// ─────────────────────────────────────────────────────────────────────────────
// Inbox State
// ─────────────────────────────────────────────────────────────────────────────

/// Active quick filters for the thread list.
enum InboxFilter { unread, hasAttachments, starred }

/// Current state of the inbox.
class InboxState {
  InboxState({
    this.threads = const [],
    this.mailboxes = const [],
    this.selectedMailbox,
    this.isSyncing = false,
    this.isInitialLoad = true,
    this.error,
    this.lastSyncTime,
    this.activeFilters = const {},
    this.isUnifiedInbox = false,
    int? unreadCount,
  }) : unreadCount = unreadCount ?? threads.where((t) => t.hasUnread).length;

  final List<EmailThread> threads;
  final List<Mailbox> mailboxes;
  final Mailbox? selectedMailbox;
  final bool isSyncing;
  final bool isInitialLoad;
  final String? error;
  final DateTime? lastSyncTime;
  final Set<InboxFilter> activeFilters;

  /// When true, showing merged threads from all accounts.
  final bool isUnifiedInbox;

  /// Cached unread count — computed once when state is created.
  final int unreadCount;

  bool get hasEmails => threads.isNotEmpty;
  bool get hasMailboxes => mailboxes.isNotEmpty;

  /// Threads filtered by active quick filters.
  List<EmailThread> get filteredThreads {
    if (activeFilters.isEmpty) return threads;
    return threads.where((t) {
      if (activeFilters.contains(InboxFilter.unread) && !t.hasUnread) {
        return false;
      }
      if (activeFilters.contains(InboxFilter.hasAttachments) &&
          !t.hasAttachments) {
        return false;
      }
      if (activeFilters.contains(InboxFilter.starred) && !t.isFlagged) {
        return false;
      }
      return true;
    }).toList();
  }

  InboxState copyWith({
    List<EmailThread>? threads,
    List<Mailbox>? mailboxes,
    Mailbox? selectedMailbox,
    bool? isSyncing,
    bool? isInitialLoad,
    String? error,
    DateTime? lastSyncTime,
    Set<InboxFilter>? activeFilters,
    bool? isUnifiedInbox,
  }) {
    return InboxState(
      threads: threads ?? this.threads,
      mailboxes: mailboxes ?? this.mailboxes,
      selectedMailbox: selectedMailbox ?? this.selectedMailbox,
      isSyncing: isSyncing ?? this.isSyncing,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      error: error,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      activeFilters: activeFilters ?? this.activeFilters,
      isUnifiedInbox: isUnifiedInbox ?? this.isUnifiedInbox,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inbox Notifier
// ─────────────────────────────────────────────────────────────────────────────

final inboxProvider = StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  return InboxNotifier(
    emailRepo: ref.read(emailRepositoryProvider),
    accountNotifier: ref.read(accountProvider.notifier),
    ref: ref,
  );
});

class InboxNotifier extends StateNotifier<InboxState> {
  InboxNotifier({
    required EmailRepository emailRepo,
    required AccountNotifier accountNotifier,
    required Ref ref,
  }) : _emailRepo = emailRepo,
       _accountNotifier = accountNotifier,
       _ref = ref,
       super(InboxState()) {
    _init();
  }

  final EmailRepository _emailRepo;
  final AccountNotifier _accountNotifier;
  final Ref _ref;
  StreamSubscription<SyncEvent>? _syncSub;
  Timer? _pollTimer;

  /// Whether the current sync was triggered by background polling
  /// (for notification gating — don't notify on manual refresh).
  bool _isBackgroundSync = false;

  /// Polling interval for background sync (seconds).
  static const _pollIntervalSec = 90;

  Future<void> _init() async {
    // Listen for sync events.
    _syncSub = _emailRepo.syncEvents.listen(_onSyncEvent);

    // Load cached data first.
    await _loadCachedInbox();

    // Start background polling.
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: _pollIntervalSec),
      (_) => _backgroundSync(),
    );
  }

  /// Silent background sync — only runs if not already syncing and has accounts.
  Future<void> _backgroundSync() async {
    if (state.isSyncing) return;
    final accountState = _ref.read(accountProvider);
    if (accountState.activeAccount == null) return;

    // Check for snoozed emails that should reappear.
    final unsnoozed = await _checkSnoozedEmails();

    // Mark as background sync so _onSyncEvent shows notifications.
    _isBackgroundSync = true;

    // Use syncInbox which already handles errors gracefully.
    if (state.isUnifiedInbox) {
      await syncAllAccounts();
    } else {
      await syncInbox();
    }

    _isBackgroundSync = false;

    // If threads were un-snoozed but sync didn't refresh, force refresh.
    if (unsnoozed > 0) {
      await _refreshThreads();
    }
  }

  /// Switch to the unified inbox (all accounts merged).
  Future<void> selectUnifiedInbox() async {
    final accountState = _ref.read(accountProvider);
    if (accountState.accounts.isEmpty) return;

    state = state.copyWith(
      isUnifiedInbox: true,
      isSyncing: true,
      selectedMailbox: null,
    );

    // Load cached threads from all accounts' inboxes.
    final accountIds = accountState.accounts.map((a) => a.id).toList();
    try {
      final threads = await _emailRepo.getCachedThreadsAllAccounts(accountIds);
      state = state.copyWith(threads: threads, isSyncing: false);
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to load unified inbox: $e',
      );
    }
  }

  /// Sync inbox for ALL accounts and merge threads.
  Future<void> syncAllAccounts() async {
    final accountState = _ref.read(accountProvider);
    if (accountState.accounts.isEmpty) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      // Sync each account sequentially to avoid overwhelming connections.
      for (final account in accountState.accounts) {
        final token = await _accountNotifier.getValidToken(account.id);
        if (token == null) continue;

        try {
          await _emailRepo.syncMailboxes(
            account: account,
            accessToken: token.accessToken,
          );
          await _emailRepo.syncInbox(
            account: account,
            accessToken: token.accessToken,
            mailboxPath: 'INBOX',
          );
        } catch (_) {
          // Continue syncing other accounts even if one fails.
        }
      }

      // Merge cached threads from all accounts.
      final accountIds = accountState.accounts.map((a) => a.id).toList();
      final threads = await _emailRepo.getCachedThreadsAllAccounts(accountIds);

      state = state.copyWith(
        threads: threads,
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: 'Sync failed: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }

  /// Load cached threads from the local database.
  Future<void> _loadCachedInbox() async {
    final accountState = _ref.read(accountProvider);
    final account = accountState.activeAccount;
    if (account == null) {
      state = InboxState(isInitialLoad: false);
      return;
    }

    try {
      // Load cached mailboxes.
      final mailboxes = await _emailRepo.getCachedMailboxes(account.id);
      final inbox = mailboxes.isEmpty
          ? null
          : mailboxes.firstWhere(
              (m) => m.isInbox,
              orElse: () => mailboxes.first,
            );

      // Load cached threads for inbox.
      final threads = inbox != null
          ? await _emailRepo.getCachedThreads(account.id, inbox.path)
          : <EmailThread>[];

      state = InboxState(
        threads: threads,
        mailboxes: mailboxes,
        selectedMailbox: inbox,
        isInitialLoad: false,
      );
    } catch (e) {
      state = InboxState(
        isInitialLoad: false,
        error: 'Failed to load cached data: $e',
      );
    }
  }

  /// Sync inbox from IMAP server.
  Future<void> syncInbox() async {
    final accountState = _ref.read(accountProvider);
    final account = accountState.activeAccount;
    if (account == null) return;

    // Get a valid token.
    final token = await _accountNotifier.getValidToken(account.id);
    if (token == null) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Authentication expired. Please re-sign in.',
      );
      return;
    }

    state = state.copyWith(isSyncing: true, error: null);

    try {
      // Sync mailboxes first.
      final mailboxes = await _emailRepo.syncMailboxes(
        account: account,
        accessToken: token.accessToken,
      );

      final inbox = mailboxes.isEmpty
          ? state.selectedMailbox
          : (state.selectedMailbox ??
                mailboxes.firstWhere(
                  (m) => m.isInbox,
                  orElse: () => mailboxes.first,
                ));

      state = state.copyWith(mailboxes: mailboxes, selectedMailbox: inbox);

      // Sync emails.
      final mailboxPath = inbox?.path ?? 'INBOX';
      final threads = await _emailRepo.syncInbox(
        account: account,
        accessToken: token.accessToken,
        mailboxPath: mailboxPath,
      );

      state = state.copyWith(
        threads: threads,
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: 'Sync failed: $e');
    }
  }

  /// Switch to a different mailbox.
  Future<void> selectMailbox(Mailbox mailbox) async {
    final accountState = _ref.read(accountProvider);
    final account = accountState.activeAccount;
    if (account == null) return;

    state = state.copyWith(
      selectedMailbox: mailbox,
      isSyncing: true,
      isUnifiedInbox: false,
    );

    // Load cached threads for this mailbox.
    final threads = await _emailRepo.getCachedThreads(account.id, mailbox.path);
    state = state.copyWith(threads: threads);

    // Then sync from server.
    final token = await _accountNotifier.getValidToken(account.id);
    if (token == null) {
      state = state.copyWith(isSyncing: false);
      return;
    }

    try {
      final synced = await _emailRepo.syncInbox(
        account: account,
        accessToken: token.accessToken,
        mailboxPath: mailbox.path,
      );
      state = state.copyWith(
        threads: synced,
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false);
    }
  }

  /// Mark a thread as read.
  Future<void> markThreadAsRead(EmailThread thread) async {
    final accountState = _ref.read(accountProvider);
    final account =
        accountState.accounts
            .where((a) => a.id == thread.accountId)
            .firstOrNull ??
        accountState.activeAccount;
    if (account == null) return;

    final token = await _accountNotifier.getValidToken(account.id);
    if (token == null) return;

    // Mark latest unread message.
    for (final msg in thread.messages.where((m) => !m.isRead)) {
      await _emailRepo.markAsRead(
        account: account,
        accessToken: token.accessToken,
        emailId: msg.id,
        uid: msg.uid,
      );
    }

    await _refreshThreads();
  }

  /// Toggle flag on a thread.
  Future<void> toggleThreadFlag(EmailThread thread) async {
    final accountState = _ref.read(accountProvider);
    final account =
        accountState.accounts
            .where((a) => a.id == thread.accountId)
            .firstOrNull ??
        accountState.activeAccount;
    if (account == null) return;

    final token = await _accountNotifier.getValidToken(account.id);
    if (token == null) return;

    final shouldFlag = !thread.isFlagged;

    await _emailRepo.toggleFlag(
      account: account,
      accessToken: token.accessToken,
      emailId: thread.latest.id,
      uid: thread.latest.uid,
      flagged: shouldFlag,
    );

    await _refreshThreads();
  }

  /// Move a thread's messages to Trash.
  Future<void> moveThreadToTrash(EmailThread thread) async {
    final accountState = _ref.read(accountProvider);
    final account =
        accountState.accounts
            .where((a) => a.id == thread.accountId)
            .firstOrNull ??
        accountState.activeAccount;
    if (account == null) return;

    final token = await _accountNotifier.getValidToken(account.id);
    if (token == null) return;

    // Find the Trash mailbox path.
    final trashPath =
        state.mailboxes
            .where((m) => m.isTrash)
            .map((m) => m.path)
            .firstOrNull ??
        '[Gmail]/Trash';

    for (final msg in thread.messages) {
      await _emailRepo.moveMessage(
        account: account,
        accessToken: token.accessToken,
        emailId: msg.id,
        uid: msg.uid,
        targetMailboxPath: trashPath,
      );
    }

    await _refreshThreads();
  }

  /// Archive a thread (move to Archive mailbox).
  Future<void> archiveThread(EmailThread thread) async {
    final accountState = _ref.read(accountProvider);
    final account =
        accountState.accounts
            .where((a) => a.id == thread.accountId)
            .firstOrNull ??
        accountState.activeAccount;
    if (account == null) return;

    final token = await _accountNotifier.getValidToken(account.id);
    if (token == null) return;

    // Find the Archive mailbox path.
    final archivePath =
        state.mailboxes
            .where((m) => m.isArchive)
            .map((m) => m.path)
            .firstOrNull ??
        '[Gmail]/All Mail';

    for (final msg in thread.messages) {
      await _emailRepo.archiveMessage(
        account: account,
        accessToken: token.accessToken,
        emailId: msg.id,
        uid: msg.uid,
        archivePath: archivePath,
      );
    }

    await _refreshThreads();
  }

  /// Mark a thread as unread.
  Future<void> markThreadAsUnread(EmailThread thread) async {
    final accountState = _ref.read(accountProvider);
    final account =
        accountState.accounts
            .where((a) => a.id == thread.accountId)
            .firstOrNull ??
        accountState.activeAccount;
    if (account == null) return;

    final token = await _accountNotifier.getValidToken(account.id);
    if (token == null) return;

    // Mark latest message as unread.
    await _emailRepo.markAsUnread(
      account: account,
      accessToken: token.accessToken,
      emailId: thread.latest.id,
      uid: thread.latest.uid,
    );

    await _refreshThreads();
  }

  /// Snooze a thread until the given time (disappears from inbox).
  Future<void> snoozeThread(EmailThread thread, DateTime until) async {
    await _emailRepo.snoozeThread(thread, until);

    // Refresh cached threads to remove the snoozed thread.
    await _refreshThreads();
  }

  /// Un-snooze a thread manually.
  Future<void> unsnoozeThread(EmailThread thread) async {
    await _emailRepo.unsnoozeThread(thread);

    // Refresh cached threads to re-show the thread.
    await _refreshThreads();
  }

  /// Check for snoozed emails that are due and un-snooze them.
  /// Called during background poll cycle.
  Future<int> _checkSnoozedEmails() async {
    return _emailRepo.checkAndUnsnoozeDueEmails();
  }

  /// Refresh threads from cache based on current view (unified or single).
  Future<void> _refreshThreads() async {
    if (state.isUnifiedInbox) {
      final accountState = _ref.read(accountProvider);
      final accountIds = accountState.accounts.map((a) => a.id).toList();
      final threads = await _emailRepo.getCachedThreadsAllAccounts(accountIds);
      state = state.copyWith(threads: threads);
    } else {
      final accountState = _ref.read(accountProvider);
      final account = accountState.activeAccount;
      if (account == null) return;
      final mailboxPath = state.selectedMailbox?.path ?? 'INBOX';
      final threads = await _emailRepo.getCachedThreads(
        account.id,
        mailboxPath,
      );
      state = state.copyWith(threads: threads);
    }
  }

  void _onSyncEvent(SyncEvent event) {
    // Show a Windows toast notification for new mail during background syncs.
    if (_isBackgroundSync &&
        event.status == SyncStatus.completed &&
        event.newMessageCount > 0) {
      NotificationService.instance.showNewMailNotification(
        count: event.newMessageCount,
        senderName: event.newestSender,
        subject: event.newestSubject,
      );
    }
  }

  /// Toggle a quick filter on/off.
  void toggleFilter(InboxFilter filter) {
    final filters = Set<InboxFilter>.from(state.activeFilters);
    if (filters.contains(filter)) {
      filters.remove(filter);
    } else {
      filters.add(filter);
    }
    state = state.copyWith(activeFilters: filters);
  }

  /// Clear all active filters.
  void clearFilters() {
    state = state.copyWith(activeFilters: const {});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thread Detail Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provides a single thread's full messages for the detail view.
/// Returns cached data immediately, then lazy-loads message bodies
/// from IMAP for any messages missing body content.
final threadDetailProvider = FutureProvider.family<EmailThread?, String>((
  ref,
  threadId,
) async {
  final accountState = ref.read(accountProvider);
  final account = accountState.activeAccount;
  if (account == null) return null;

  final emailRepo = ref.read(emailRepositoryProvider);
  final accountNotifier = ref.read(accountProvider.notifier);
  final thread = await emailRepo.getCachedThread(account.id, threadId);
  if (thread == null) return null;

  // Check if any messages are missing body content.
  final needsBody = thread.messages.where(
    (m) =>
        (m.textPlain == null || m.textPlain!.isEmpty) &&
        (m.textHtml == null || m.textHtml!.isEmpty),
  );

  if (needsBody.isEmpty) return thread;

  // Get a valid token for IMAP fetch.
  final token = await accountNotifier.getValidToken(account.id);
  if (token == null) return thread; // Return what we have.

  // Fetch full bodies for messages that need them.
  for (final msg in needsBody) {
    if (msg.uid <= 0) continue;
    try {
      await emailRepo.fetchFullMessage(
        account: account,
        accessToken: token.accessToken,
        mailboxPath: msg.mailboxPath,
        uid: msg.uid,
      );
    } catch (e, st) {
      dev.log(
        'Failed to fetch body for UID ${msg.uid}: $e',
        name: 'threadDetail',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Re-read from cache with the now-populated bodies.
  return emailRepo.getCachedThread(account.id, threadId);
});
