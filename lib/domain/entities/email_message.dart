/// Crusader — Email Message Entity
///
/// Core domain entity representing a single email message.
/// Immutable, serializable, provider-agnostic.
library;

import 'attachment.dart';
import 'email_address.dart';

/// Flags that can be applied to an email.
enum EmailFlag {
  seen,
  flagged,
  answered,
  draft,
  deleted,
}

/// Immutable email message domain entity.
class EmailMessage {
  const EmailMessage({
    required this.id,
    required this.accountId,
    required this.mailboxPath,
    required this.uid,
    required this.from,
    required this.to,
    required this.subject,
    required this.date,
    this.cc = const [],
    this.bcc = const [],
    this.replyTo = const [],
    this.textPlain,
    this.textHtml,
    this.snippet = '',
    this.flags = const {},
    this.messageId,
    this.inReplyTo,
    this.references = const [],
    this.threadId,
    this.size = 0,
    this.hasAttachments = false,
    this.attachmentCount = 0,
    this.attachments = const [],
    this.isSnoozed = false,
    this.snoozedUntil,
  });

  /// Local unique ID (uuid).
  final String id;

  /// Which account this email belongs to.
  final String accountId;

  /// Mailbox / folder path (e.g. "INBOX", "Sent", "[Gmail]/Trash").
  final String mailboxPath;

  /// IMAP UID within the mailbox.
  final int uid;

  /// Sender.
  final EmailAddress from;

  /// Recipients.
  final List<EmailAddress> to;
  final List<EmailAddress> cc;
  final List<EmailAddress> bcc;
  final List<EmailAddress> replyTo;

  /// Subject line.
  final String subject;

  /// Date sent/received.
  final DateTime date;

  /// Plain text body (if available).
  final String? textPlain;

  /// HTML body (if available).
  final String? textHtml;

  /// Short preview snippet (~120 chars of plain text).
  final String snippet;

  /// Email flags (read, flagged, etc.).
  final Set<EmailFlag> flags;

  /// RFC 2822 Message-ID header (for threading).
  final String? messageId;

  /// In-Reply-To header (for threading).
  final String? inReplyTo;

  /// References header values (for threading).
  final List<String> references;

  /// Local thread ID (computed from Message-ID / References).
  final String? threadId;

  /// Message size in bytes.
  final int size;

  /// Whether the email has attachments.
  final bool hasAttachments;
  final int attachmentCount;

  /// Parsed attachment metadata (populated after full body fetch).
  final List<Attachment> attachments;

  /// Whether this email is currently snoozed (hidden from inbox).
  final bool isSnoozed;

  /// When the snooze expires and the email reappears.
  final DateTime? snoozedUntil;

  // ── Convenience getters ──

  bool get isRead => flags.contains(EmailFlag.seen);
  bool get isFlagged => flags.contains(EmailFlag.flagged);
  bool get isAnswered => flags.contains(EmailFlag.answered);
  bool get isDraft => flags.contains(EmailFlag.draft);
  bool get isDeleted => flags.contains(EmailFlag.deleted);

  /// Relative date string for list display.
  String get relativeDate {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (date.year == now.year) {
      return '${_monthAbbr[date.month - 1]} ${date.day}';
    }
    return '${_monthAbbr[date.month - 1]} ${date.day}, ${date.year}';
  }

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  EmailMessage copyWith({
    String? id,
    String? accountId,
    String? mailboxPath,
    int? uid,
    EmailAddress? from,
    List<EmailAddress>? to,
    List<EmailAddress>? cc,
    List<EmailAddress>? bcc,
    List<EmailAddress>? replyTo,
    String? subject,
    DateTime? date,
    String? textPlain,
    String? textHtml,
    String? snippet,
    Set<EmailFlag>? flags,
    String? messageId,
    String? inReplyTo,
    List<String>? references,
    String? threadId,
    int? size,
    bool? hasAttachments,
    int? attachmentCount,
    List<Attachment>? attachments,
    bool? isSnoozed,
    DateTime? snoozedUntil,
  }) {
    return EmailMessage(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      mailboxPath: mailboxPath ?? this.mailboxPath,
      uid: uid ?? this.uid,
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      replyTo: replyTo ?? this.replyTo,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      textPlain: textPlain ?? this.textPlain,
      textHtml: textHtml ?? this.textHtml,
      snippet: snippet ?? this.snippet,
      flags: flags ?? this.flags,
      messageId: messageId ?? this.messageId,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      references: references ?? this.references,
      threadId: threadId ?? this.threadId,
      size: size ?? this.size,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      attachments: attachments ?? this.attachments,
      isSnoozed: isSnoozed ?? this.isSnoozed,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EmailMessage($subject, from: $from)';
}
