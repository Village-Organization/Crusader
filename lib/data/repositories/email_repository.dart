/// Crusader — Email Repository
///
/// Orchestrates IMAP fetching + Drift cache for offline-first email.
/// This is the single source of truth for the presentation layer.
///
/// Flow:
///   1. Return cached emails immediately (fast local read).
///   2. Sync in background (IMAP fetch → cache update).
///   3. Notify listeners when cache updates arrive.
library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/attachment.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/entities/email_address.dart';
import '../../domain/entities/email_message.dart';
import '../../domain/entities/email_thread.dart';
import '../../domain/entities/mailbox.dart';
import '../datasources/database.dart';
import '../datasources/imap_service.dart';
import '../datasources/smtp_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Email Repository
// ─────────────────────────────────────────────────────────────────────────────

class EmailRepository {
  EmailRepository({
    required CrusaderDatabase db,
    required ImapService imapService,
    required SmtpService smtpService,
  }) : _db = db,
       _imap = imapService,
       _smtp = smtpService;

  final CrusaderDatabase _db;
  final ImapService _imap;
  final SmtpService _smtp;

  /// Stream controller for sync events.
  final _syncController = StreamController<SyncEvent>.broadcast();

  /// Listen to sync progress/completion events.
  Stream<SyncEvent> get syncEvents => _syncController.stream;

  // ── Mailbox Operations ────────────────────────────────────────────────

  /// Get cached mailboxes for an account.
  Future<List<Mailbox>> getCachedMailboxes(String accountId) async {
    final rows = await _db.getMailboxes(accountId);
    return rows.map(_rowToMailbox).toList();
  }

  /// Sync mailboxes from IMAP and cache them.
  Future<List<Mailbox>> syncMailboxes({
    required EmailAccount account,
    required String accessToken,
  }) async {
    try {
      await _imap.connect(account: account, accessToken: accessToken);
      final mailboxes = await _imap.listMailboxes(accountId: account.id);

      // Cache to Drift.
      final companions = mailboxes
          .map((mb) => _mailboxToCompanion(mb))
          .toList();
      await _db.upsertMailboxes(companions);

      return mailboxes;
    } catch (e) {
      _syncController.add(
        SyncEvent.error(account.id, 'Mailbox sync failed: $e'),
      );
      // Fall back to cache.
      return getCachedMailboxes(account.id);
    }
  }

  // ── Email Operations ──────────────────────────────────────────────────

  /// Get cached emails for a mailbox, grouped into threads.
  Future<List<EmailThread>> getCachedThreads(
    String accountId,
    String mailboxPath,
  ) async {
    final rows = await _db.getEmails(accountId, mailboxPath);
    final messages = rows.map(_rowToEmail).toList();
    return _groupIntoThreads(messages, accountId);
  }

  /// Get a single thread by thread ID.
  Future<EmailThread?> getCachedThread(
    String accountId,
    String threadId,
  ) async {
    final rows = await _db.getEmailsByThread(accountId, threadId);
    if (rows.isEmpty) return null;
    final messages = rows.map(_rowToEmail).toList();
    return EmailThread(id: threadId, accountId: accountId, messages: messages);
  }

  /// Search emails locally and group into threads.
  Future<List<EmailThread>> searchThreads(
    String accountId,
    String query,
  ) async {
    final rows = await _db.searchEmails(accountId, query);
    final messages = rows.map(_rowToEmail).toList();
    return _groupIntoThreads(messages, accountId);
  }

  /// Get cached inbox threads across ALL accounts, sorted chronologically.
  /// Used for the "Unified Inbox" view.
  Future<List<EmailThread>> getCachedThreadsAllAccounts(
    List<String> accountIds,
  ) async {
    final rows = await _db.getInboxEmailsAllAccounts(accountIds: accountIds);
    final messages = rows.map(_rowToEmail).toList();
    return _groupIntoThreadsMultiAccount(messages);
  }

  /// Full sync: fetch envelopes from IMAP, cache, return threads.
  Future<List<EmailThread>> syncInbox({
    required EmailAccount account,
    required String accessToken,
    String mailboxPath = 'INBOX',
    int limit = 50,
  }) async {
    _syncController.add(SyncEvent.started(account.id));

    try {
      // Connect if needed.
      await _imap.connect(account: account, accessToken: accessToken);

      // Get sync state.
      final syncState = await _db.getSyncState(account.id, mailboxPath);
      final lastUid = syncState?.lastSyncedUid ?? 0;

      // Fetch emails.
      List<EmailMessage> emails;
      if (lastUid > 0) {
        // Incremental sync — fetch only new messages.
        emails = await _imap.fetchNewMessages(
          accountId: account.id,
          mailboxPath: mailboxPath,
          sinceUid: lastUid,
        );
      } else {
        // Initial sync — fetch recent batch.
        emails = await _imap.fetchEnvelopes(
          accountId: account.id,
          mailboxPath: mailboxPath,
          limit: limit,
        );
      }

      if (emails.isNotEmpty) {
        // Cache to Drift.
        final companions = emails.map(_emailToCompanion).toList();
        await _db.upsertEmails(companions);

        // Update sync state.
        final highestUid = emails.fold<int>(
          lastUid,
          (max, e) => e.uid > max ? e.uid : max,
        );
        await _db.upsertSyncState(
          SyncStateCompanion(
            accountId: Value(account.id),
            mailboxPath: Value(mailboxPath),
            lastSyncedUid: Value(highestUid),
            lastSyncTime: Value(DateTime.now()),
          ),
        );
      }

      // Find the newest message for notification info.
      final newest = emails.isNotEmpty
          ? emails.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
          : null;

      _syncController.add(
        SyncEvent.completed(
          account.id,
          newMessageCount: emails.length,
          newestSender: newest?.from.shortLabel,
          newestSubject: newest?.subject,
        ),
      );

      // Return full cached thread list.
      return getCachedThreads(account.id, mailboxPath);
    } catch (e) {
      _syncController.add(SyncEvent.error(account.id, '$e'));
      // Fall back to cache.
      return getCachedThreads(account.id, mailboxPath);
    }
  }

  /// Fetch the full body of a message (for thread detail view).
  Future<EmailMessage?> fetchFullMessage({
    required EmailAccount account,
    required String accessToken,
    required String mailboxPath,
    required int uid,
  }) async {
    try {
      await _imap.connect(account: account, accessToken: accessToken);

      // Look up the existing cached email to preserve its local ID.
      final existingRow = await _db.getEmailByUid(account.id, mailboxPath, uid);

      final email = await _imap.fetchFullMessage(
        accountId: account.id,
        mailboxPath: mailboxPath,
        uid: uid,
        existingId: existingRow?.id,
      );

      // Update cache with full body (matches on primary key = id).
      await _db.upsertEmail(_emailToCompanion(email));

      return email;
    } catch (e) {
      // Try returning cached version.
      final cached = await _db.getEmailByUid(account.id, mailboxPath, uid);
      return cached != null ? _rowToEmail(cached) : null;
    }
  }

  /// Mark a message as read (locally + IMAP).
  Future<void> markAsRead({
    required EmailAccount account,
    required String accessToken,
    required String emailId,
    required int uid,
  }) async {
    // Update local cache immediately.
    final cached = await _db.getEmailById(emailId);
    if (cached != null) {
      final flags = _addFlag(cached.flags, 'seen');
      await _db.updateEmailFlags(emailId, flags);
    }

    // Update on server.
    try {
      await _imap.connect(account: account, accessToken: accessToken);
      await _imap.markAsRead(accountId: account.id, uid: uid);
    } catch (_) {
      // Silently fail — will re-sync later.
    }
  }

  /// Toggle flagged state.
  Future<void> toggleFlag({
    required EmailAccount account,
    required String accessToken,
    required String emailId,
    required int uid,
    required bool flagged,
  }) async {
    // Update local cache.
    final cached = await _db.getEmailById(emailId);
    if (cached != null) {
      final flags = flagged
          ? _addFlag(cached.flags, 'flagged')
          : _removeFlag(cached.flags, 'flagged');
      await _db.updateEmailFlags(emailId, flags);
    }

    // Update on server.
    try {
      await _imap.connect(account: account, accessToken: accessToken);
      await _imap.toggleFlag(accountId: account.id, uid: uid, flagged: flagged);
    } catch (_) {
      // Silently fail.
    }
  }

  // ── Send Operations ────────────────────────────────────────────────

  /// Send a new email via SMTP.
  Future<void> sendEmail({
    required EmailAccount account,
    required String accessToken,
    required List<EmailAddress> to,
    List<EmailAddress> cc = const [],
    List<EmailAddress> bcc = const [],
    required String subject,
    String? textPlain,
    String? textHtml,
  }) async {
    await _smtp.connect(account: account, accessToken: accessToken);

    await _smtp.sendEmail(
      accountId: account.id,
      from: EmailAddress(
        address: account.email,
        displayName: account.displayName,
      ),
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
      textPlain: textPlain,
      textHtml: textHtml,
    );
  }

  /// Move a message to a different mailbox.
  Future<void> moveMessage({
    required EmailAccount account,
    required String accessToken,
    required String emailId,
    required int uid,
    required String targetMailboxPath,
  }) async {
    // Update local cache: remove from current mailbox.
    await _db.deleteEmail(emailId);

    // Move on server.
    try {
      await _imap.connect(account: account, accessToken: accessToken);
      await _imap.moveToTrash(
        accountId: account.id,
        uid: uid,
        trashPath: targetMailboxPath,
      );
    } catch (_) {
      // Silently fail — will re-sync later.
    }
  }

  /// Mark a message as unread.
  Future<void> markAsUnread({
    required EmailAccount account,
    required String accessToken,
    required String emailId,
    required int uid,
  }) async {
    // Update local cache.
    final cached = await _db.getEmailById(emailId);
    if (cached != null) {
      final flags = _removeFlag(cached.flags, 'seen');
      await _db.updateEmailFlags(emailId, flags);
    }

    // Update on server.
    try {
      await _imap.connect(account: account, accessToken: accessToken);
      await _imap.markAsUnread(accountId: account.id, uid: uid);
    } catch (_) {
      // Silently fail.
    }
  }

  /// Archive a message (move to Archive mailbox).
  Future<void> archiveMessage({
    required EmailAccount account,
    required String accessToken,
    required String emailId,
    required int uid,
    required String archivePath,
  }) async {
    await moveMessage(
      account: account,
      accessToken: accessToken,
      emailId: emailId,
      uid: uid,
      targetMailboxPath: archivePath,
    );
  }

  /// Clear all data for an account.
  Future<void> clearAccountData(String accountId) async {
    await _db.clearAccountData(accountId);
    await _imap.disconnect(accountId);
  }

  /// Disconnect everything.
  Future<void> dispose() async {
    await _imap.disconnectAll();
    await _smtp.disconnectAll();
    await _syncController.close();
  }

  // ── Threading ─────────────────────────────────────────────────────────

  /// Group a flat list of emails into conversation threads.
  List<EmailThread> _groupIntoThreads(
    List<EmailMessage> emails,
    String accountId,
  ) {
    final threadMap = <String, List<EmailMessage>>{};

    for (final email in emails) {
      final tid = email.threadId ?? email.id;
      threadMap.putIfAbsent(tid, () => []).add(email);
    }

    final threads = threadMap.entries.map(
      (entry) {
        final messages = entry.value..sort((a, b) => a.date.compareTo(b.date));
        return EmailThread(
          id: entry.key,
          accountId: accountId,
          messages: messages,
        );
      },
    ).toList()..sort((a, b) => b.date.compareTo(a.date)); // newest thread first

    return threads;
  }

  /// Group messages from multiple accounts into threads.
  /// Uses the first message's accountId for the thread.
  List<EmailThread> _groupIntoThreadsMultiAccount(List<EmailMessage> emails) {
    final threadMap = <String, List<EmailMessage>>{};

    for (final email in emails) {
      final tid = email.threadId ?? email.id;
      threadMap.putIfAbsent(tid, () => []).add(email);
    }

    final threads = threadMap.entries.map((entry) {
      final messages = entry.value..sort((a, b) => a.date.compareTo(b.date));
      return EmailThread(
        id: entry.key,
        accountId: messages.first.accountId,
        messages: messages,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return threads;
  }

  // ── Snooze Operations ─────────────────────────────────────────────────

  /// Snooze all messages in a thread until [until].
  Future<void> snoozeThread(EmailThread thread, DateTime until) async {
    for (final msg in thread.messages) {
      await _db.snoozeEmail(msg.id, until);
    }
  }

  /// Un-snooze all messages in a thread.
  Future<void> unsnoozeThread(EmailThread thread) async {
    for (final msg in thread.messages) {
      await _db.unsnoozeEmail(msg.id);
    }
  }

  /// Check for snoozed emails whose snooze time has elapsed, un-snooze
  /// them, and return the number of threads woken up.
  Future<int> checkAndUnsnoozeDueEmails() async {
    final dueRows = await _db.getSnoozedEmailsDue();
    if (dueRows.isEmpty) return 0;

    final threadIds = <String>{};
    for (final row in dueRows) {
      await _db.unsnoozeEmail(row.id);
      if (row.threadId != null) threadIds.add(row.threadId!);
    }
    return threadIds.length;
  }

  // ── Drift ↔ Domain Converters ─────────────────────────────────────────

  EmailMessage _rowToEmail(CachedEmail row) {
    return EmailMessage(
      id: row.id,
      accountId: row.accountId,
      mailboxPath: row.mailboxPath,
      uid: row.uid,
      from: EmailAddress(address: row.fromAddress, displayName: row.fromName),
      to: _decodeAddresses(row.toAddresses),
      cc: _decodeAddresses(row.ccAddresses),
      subject: row.subject,
      date: row.date,
      textPlain: row.textPlain,
      textHtml: row.textHtml,
      snippet: row.snippet,
      flags: _decodeFlags(row.flags),
      messageId: row.messageId,
      inReplyTo: row.inReplyTo,
      references: row.references.isEmpty ? [] : row.references.split(','),
      threadId: row.threadId,
      size: row.size,
      hasAttachments: row.hasAttachments,
      attachmentCount: row.attachmentCount,
      attachments: Attachment.decodeList(row.attachmentsJson),
      isSnoozed: row.isSnoozed,
      snoozedUntil: row.snoozedUntil,
    );
  }

  CachedEmailsCompanion _emailToCompanion(EmailMessage email) {
    return CachedEmailsCompanion(
      id: Value(email.id),
      accountId: Value(email.accountId),
      mailboxPath: Value(email.mailboxPath),
      uid: Value(email.uid),
      fromAddress: Value(email.from.address),
      fromName: Value(email.from.displayName),
      toAddresses: Value(_encodeAddresses(email.to)),
      ccAddresses: Value(_encodeAddresses(email.cc)),
      subject: Value(email.subject),
      date: Value(email.date),
      textPlain: Value(email.textPlain),
      textHtml: Value(email.textHtml),
      snippet: Value(email.snippet),
      flags: Value(_encodeFlags(email.flags)),
      messageId: Value(email.messageId),
      inReplyTo: Value(email.inReplyTo),
      references: Value(email.references.join(',')),
      threadId: Value(email.threadId),
      size: Value(email.size),
      hasAttachments: Value(email.hasAttachments),
      attachmentCount: Value(email.attachmentCount),
      attachmentsJson: Value(Attachment.encodeList(email.attachments)),
      isSnoozed: Value(email.isSnoozed),
      snoozedUntil: Value(email.snoozedUntil),
    );
  }

  Mailbox _rowToMailbox(CachedMailboxe row) {
    return Mailbox(
      path: row.path,
      name: row.name,
      accountId: row.accountId,
      role: MailboxRole.values.firstWhere(
        (r) => r.name == row.role,
        orElse: () => MailboxRole.custom,
      ),
      totalMessages: row.totalMessages,
      unseenMessages: row.unseenMessages,
      isSubscribed: row.isSubscribed,
      highestModSeq: row.highestModSeq,
      uidValidity: row.uidValidity,
      uidNext: row.uidNext,
    );
  }

  CachedMailboxesCompanion _mailboxToCompanion(Mailbox mb) {
    return CachedMailboxesCompanion(
      path: Value(mb.path),
      name: Value(mb.name),
      accountId: Value(mb.accountId),
      role: Value(mb.role.name),
      totalMessages: Value(mb.totalMessages),
      unseenMessages: Value(mb.unseenMessages),
      isSubscribed: Value(mb.isSubscribed),
      highestModSeq: Value(mb.highestModSeq),
      uidValidity: Value(mb.uidValidity),
      uidNext: Value(mb.uidNext),
    );
  }

  // ── Serialization Helpers ─────────────────────────────────────────────

  String _encodeAddresses(List<EmailAddress> addresses) {
    return jsonEncode(addresses.map((a) => a.toJson()).toList());
  }

  List<EmailAddress> _decodeAddresses(String json) {
    if (json.isEmpty || json == '[]') return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((j) => EmailAddress.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _encodeFlags(Set<EmailFlag> flags) {
    return flags.map((f) => f.name).join(',');
  }

  Set<EmailFlag> _decodeFlags(String flags) {
    if (flags.isEmpty) return {};
    return flags.split(',').map((f) {
      return EmailFlag.values.firstWhere(
        (e) => e.name == f,
        orElse: () => EmailFlag.seen,
      );
    }).toSet();
  }

  String _addFlag(String flags, String flag) {
    final set = flags.isEmpty ? <String>{} : flags.split(',').toSet();
    set.add(flag);
    return set.join(',');
  }

  String _removeFlag(String flags, String flag) {
    final set = flags.isEmpty ? <String>{} : flags.split(',').toSet();
    set.remove(flag);
    return set.join(',');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync Events
// ─────────────────────────────────────────────────────────────────────────────

enum SyncStatus { started, completed, error }

class SyncEvent {
  const SyncEvent({
    required this.accountId,
    required this.status,
    this.newMessageCount = 0,
    this.error,
    this.newestSender,
    this.newestSubject,
  });

  factory SyncEvent.started(String accountId) =>
      SyncEvent(accountId: accountId, status: SyncStatus.started);

  factory SyncEvent.completed(
    String accountId, {
    int newMessageCount = 0,
    String? newestSender,
    String? newestSubject,
  }) => SyncEvent(
    accountId: accountId,
    status: SyncStatus.completed,
    newMessageCount: newMessageCount,
    newestSender: newestSender,
    newestSubject: newestSubject,
  );

  factory SyncEvent.error(String accountId, String error) =>
      SyncEvent(accountId: accountId, status: SyncStatus.error, error: error);

  final String accountId;
  final SyncStatus status;
  final int newMessageCount;
  final String? error;

  /// Sender name of the newest message (for notifications).
  final String? newestSender;

  /// Subject of the newest message (for notifications).
  final String? newestSubject;
}
