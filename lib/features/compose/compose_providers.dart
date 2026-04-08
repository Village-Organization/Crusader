/// Crusader — Compose Providers (Riverpod)
///
/// Manages compose state: drafting, sending, reply/forward prefill.
/// Includes undo-send with configurable delay before SMTP dispatch.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/email_repository.dart';
import '../../domain/entities/email_address.dart';
import '../../domain/entities/email_message.dart';
import '../auth/auth_providers.dart';
import '../inbox/inbox_providers.dart';
import 'signature_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Send Delay Setting
// ─────────────────────────────────────────────────────────────────────────────

const _kSendDelayKey = 'crusader_send_delay';

/// Available send delay options (in seconds).
/// 0 means send immediately (no undo).
const sendDelayOptions = [0, 3, 5, 10, 15, 30];

/// Provides the configured send delay in seconds.
final sendDelayProvider = StateNotifierProvider<SendDelayNotifier, int>((ref) {
  return SendDelayNotifier();
});

class SendDelayNotifier extends StateNotifier<int> {
  SendDelayNotifier() : super(5) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_kSendDelayKey);
    if (stored != null && sendDelayOptions.contains(stored)) {
      state = stored;
    }
  }

  Future<void> setDelay(int seconds) async {
    if (!sendDelayOptions.contains(seconds)) return;
    state = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSendDelayKey, seconds);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compose Mode
// ─────────────────────────────────────────────────────────────────────────────

enum ComposeMode { newMessage, reply, replyAll, forward }

// ─────────────────────────────────────────────────────────────────────────────
// Compose State
// ─────────────────────────────────────────────────────────────────────────────

class ComposeState {
  const ComposeState({
    this.mode = ComposeMode.newMessage,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.subject = '',
    this.bodyPlain = '',
    this.bodyHtml,
    this.originalMessage,
    this.isSending = false,
    this.isSent = false,
    this.isSendPending = false,
    this.sendCountdown = 0,
    this.error,
  });

  final ComposeMode mode;
  final List<EmailAddress> to;
  final List<EmailAddress> cc;
  final List<EmailAddress> bcc;
  final String subject;
  final String bodyPlain;
  final String? bodyHtml;
  final EmailMessage? originalMessage;
  final bool isSending;
  final bool isSent;
  final bool isSendPending;
  final int sendCountdown;
  final String? error;

  bool get canSend =>
      to.isNotEmpty &&
      (bodyPlain.isNotEmpty || bodyHtml != null) &&
      !isSending &&
      !isSendPending;

  ComposeState copyWith({
    ComposeMode? mode,
    List<EmailAddress>? to,
    List<EmailAddress>? cc,
    List<EmailAddress>? bcc,
    String? subject,
    String? bodyPlain,
    String? bodyHtml,
    EmailMessage? originalMessage,
    bool? isSending,
    bool? isSent,
    bool? isSendPending,
    int? sendCountdown,
    String? error,
  }) {
    return ComposeState(
      mode: mode ?? this.mode,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      bodyPlain: bodyPlain ?? this.bodyPlain,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      originalMessage: originalMessage ?? this.originalMessage,
      isSending: isSending ?? this.isSending,
      isSent: isSent ?? this.isSent,
      isSendPending: isSendPending ?? this.isSendPending,
      sendCountdown: sendCountdown ?? this.sendCountdown,
      error: error,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compose Notifier
// ─────────────────────────────────────────────────────────────────────────────

final composeProvider =
    StateNotifierProvider.autoDispose<ComposeNotifier, ComposeState>((ref) {
      return ComposeNotifier(
        emailRepo: ref.read(emailRepositoryProvider),
        accountNotifier: ref.read(accountProvider.notifier),
        ref: ref,
      );
    });

class ComposeNotifier extends StateNotifier<ComposeState> {
  ComposeNotifier({
    required EmailRepository emailRepo,
    required AccountNotifier accountNotifier,
    required Ref ref,
  }) : _emailRepo = emailRepo,
       _accountNotifier = accountNotifier,
       _ref = ref,
       super(const ComposeState());

  final EmailRepository _emailRepo;
  final AccountNotifier _accountNotifier;
  final Ref _ref;
  Timer? _sendTimer;
  Timer? _countdownTimer;

  // ── Signature Helper ──────────────────────────────────────────────────

  /// Get the formatted signature for the active account.
  String _getSignature() {
    final accountState = _ref.read(accountProvider);
    final account = accountState.activeAccount;
    if (account == null) return '';
    return _ref
        .read(signatureProvider.notifier)
        .getFormattedSignature(account.id);
  }

  // ── Field Updates ─────────────────────────────────────────────────────

  /// Initialize a new compose with signature pre-filled.
  void prepareNewMessage() {
    final sig = _getSignature();
    state = ComposeState(
      mode: ComposeMode.newMessage,
      bodyPlain: sig.isNotEmpty ? sig : '',
    );
  }

  void addRecipient(EmailAddress address) {
    state = state.copyWith(to: [...state.to, address]);
  }

  void removeRecipient(int index) {
    final updated = [...state.to]..removeAt(index);
    state = state.copyWith(to: updated);
  }

  void addCc(EmailAddress address) {
    state = state.copyWith(cc: [...state.cc, address]);
  }

  void removeCc(int index) {
    final updated = [...state.cc]..removeAt(index);
    state = state.copyWith(cc: updated);
  }

  void addBcc(EmailAddress address) {
    state = state.copyWith(bcc: [...state.bcc, address]);
  }

  void removeBcc(int index) {
    final updated = [...state.bcc]..removeAt(index);
    state = state.copyWith(bcc: updated);
  }

  void updateSubject(String subject) {
    state = state.copyWith(subject: subject);
  }

  void updateBody(String body) {
    state = state.copyWith(bodyPlain: body);
  }

  void updateBodyHtml(String html) {
    state = state.copyWith(bodyHtml: html);
  }

  // ── Reply / Forward Prefill ───────────────────────────────────────────

  /// Prefill for a reply.
  void prepareReply(EmailMessage original, {bool replyAll = false}) {
    final replyTo = original.replyTo.isNotEmpty
        ? original.replyTo
        : [original.from];

    final subject = original.subject.startsWith('Re:')
        ? original.subject
        : 'Re: ${original.subject}';

    // Get current account email to exclude from CC.
    final accountState = _ref.read(accountProvider);
    final myEmail = accountState.activeAccount?.email.toLowerCase();

    List<EmailAddress> cc = [];
    if (replyAll) {
      cc = [...original.to, ...original.cc].where((addr) {
        // Exclude the sender (already in To) and self.
        final email = addr.address.toLowerCase();
        return email != original.from.address.toLowerCase() && email != myEmail;
      }).toList();
    }

    state = ComposeState(
      mode: replyAll ? ComposeMode.replyAll : ComposeMode.reply,
      to: replyTo,
      cc: cc,
      subject: subject,
      originalMessage: original,
      bodyPlain: '${_getSignature()}${_quoteOriginal(original)}',
    );
  }

  /// Prefill for a forward.
  void prepareForward(EmailMessage original) {
    final subject = original.subject.startsWith('Fwd:')
        ? original.subject
        : 'Fwd: ${original.subject}';

    state = ComposeState(
      mode: ComposeMode.forward,
      subject: subject,
      originalMessage: original,
      bodyPlain: '${_getSignature()}${_forwardBody(original)}',
    );
  }

  /// Generate quoted reply text.
  String _quoteOriginal(EmailMessage original) {
    final date = original.date.toString().split('.').first;
    final from = original.from.label;
    final body = original.textPlain ?? '';
    final quoted = body.split('\n').map((line) => '> $line').join('\n');
    return '\n\nOn $date, $from wrote:\n$quoted';
  }

  /// Generate forward body text.
  String _forwardBody(EmailMessage original) {
    final date = original.date.toString().split('.').first;
    return '\n\n---------- Forwarded message ----------\n'
        'From: ${original.from.label}\n'
        'Date: $date\n'
        'Subject: ${original.subject}\n'
        'To: ${original.to.map((a) => a.label).join(', ')}\n\n'
        '${original.textPlain ?? ''}';
  }

  // ── Send ──────────────────────────────────────────────────────────────

  /// Schedule a send with configurable delay.
  /// If delay is 0, sends immediately.
  /// Returns true if the send was scheduled (or sent immediately).
  Future<bool> scheduleSend() async {
    if (!state.canSend) return false;

    final delay = _ref.read(sendDelayProvider);

    if (delay == 0) {
      // No delay — send immediately.
      return send();
    }

    // Start countdown.
    state = state.copyWith(
      isSendPending: true,
      sendCountdown: delay,
      error: null,
    );

    // Tick the countdown every second.
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = state.sendCountdown - 1;
      if (remaining > 0) {
        state = state.copyWith(sendCountdown: remaining);
      }
    });

    // Schedule the actual send after the delay.
    _sendTimer?.cancel();
    final completer = Completer<bool>();
    _sendTimer = Timer(Duration(seconds: delay), () async {
      _countdownTimer?.cancel();
      if (!mounted) {
        completer.complete(false);
        return;
      }
      state = state.copyWith(isSendPending: false, sendCountdown: 0);
      final result = await send();
      completer.complete(result);
    });

    return completer.future;
  }

  /// Cancel a pending send (undo).
  void cancelSend() {
    _sendTimer?.cancel();
    _sendTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;

    if (mounted) {
      state = state.copyWith(isSendPending: false, sendCountdown: 0);
    }
  }

  /// Send the composed email immediately (via SMTP).
  Future<bool> send() async {
    if (state.isSending) return false;
    if (state.to.isEmpty) return false;
    if (state.bodyPlain.isEmpty && state.bodyHtml == null) return false;

    state = state.copyWith(isSending: true, error: null);

    final accountState = _ref.read(accountProvider);
    final account = accountState.activeAccount;
    if (account == null) {
      state = state.copyWith(isSending: false, error: 'No active account');
      return false;
    }

    final token = await _accountNotifier.getValidToken(account.id);
    if (token == null) {
      state = state.copyWith(
        isSending: false,
        error: 'Authentication expired. Please re-sign in.',
      );
      return false;
    }

    try {
      await _emailRepo.sendEmail(
        account: account,
        accessToken: token.accessToken,
        to: state.to,
        cc: state.cc,
        bcc: state.bcc,
        subject: state.subject,
        textPlain: state.bodyPlain,
        textHtml: state.bodyHtml,
      );

      state = state.copyWith(isSending: false, isSent: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false, error: 'Failed to send: $e');
      return false;
    }
  }

  /// Reset the compose state.
  void reset() {
    cancelSend();
    state = const ComposeState();
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
