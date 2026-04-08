/// Crusader — Email Thread Entity
///
/// A conversation thread groups related emails by Message-ID / References.
/// The inbox displays threads, not individual messages.
library;

import 'email_address.dart';
import 'email_message.dart';

/// Immutable email thread (conversation).
class EmailThread {
  const EmailThread({
    required this.id,
    required this.accountId,
    required this.messages,
  });

  /// Unique thread ID (derived from first Message-ID in the chain).
  final String id;

  /// Which account this thread belongs to.
  final String accountId;

  /// All messages in this thread, sorted oldest-first.
  final List<EmailMessage> messages;

  // ── Convenience getters ──

  /// The most recent message.
  EmailMessage get latest => messages.last;

  /// Subject line (from the latest message, strip "Re:" prefix for display).
  String get subject {
    final s = latest.subject;
    final re = RegExp(r'^(?:Re|Fwd|Fw):\s*', caseSensitive: false);
    return s.replaceAll(re, '').trim();
  }

  /// Original subject line (from the latest message, unmodified).
  String get rawSubject => latest.subject;

  /// Snippet preview.
  String get snippet => latest.snippet;

  /// Date of the newest message.
  DateTime get date => latest.date;

  /// Relative date.
  String get relativeDate => latest.relativeDate;

  /// Sender of the newest message.
  EmailAddress get from => latest.from;

  /// All unique participants in the thread.
  List<EmailAddress> get participants {
    final seen = <String>{};
    final result = <EmailAddress>[];
    for (final msg in messages) {
      if (seen.add(msg.from.address.toLowerCase())) {
        result.add(msg.from);
      }
      for (final addr in msg.to) {
        if (seen.add(addr.address.toLowerCase())) {
          result.add(addr);
        }
      }
    }
    return result;
  }

  /// Number of messages in the conversation.
  int get messageCount => messages.length;

  /// Whether the thread has multiple messages.
  bool get isConversation => messages.length > 1;

  /// Whether the latest message is unread.
  bool get isUnread => !latest.isRead;

  /// Whether any message in the thread is unread.
  bool get hasUnread => messages.any((m) => !m.isRead);

  /// Number of unread messages.
  int get unreadCount => messages.where((m) => !m.isRead).length;

  /// Whether any message is flagged.
  bool get isFlagged => messages.any((m) => m.isFlagged);

  /// Whether any message has attachments.
  bool get hasAttachments => messages.any((m) => m.hasAttachments);

  /// Whether this thread is snoozed.
  bool get isSnoozed => messages.any((m) => m.isSnoozed);

  /// When the snooze expires (from latest message).
  DateTime? get snoozedUntil => latest.snoozedUntil;

  /// Mailbox path (from the latest message).
  String get mailboxPath => latest.mailboxPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailThread &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EmailThread($subject, ${messages.length} messages)';
}
