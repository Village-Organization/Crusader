/// Crusader — Mailbox Entity
///
/// Represents an IMAP mailbox / folder (INBOX, Sent, Drafts, etc.).
library;

/// Well-known mailbox roles.
enum MailboxRole {
  inbox,
  sent,
  drafts,
  trash,
  archive,
  spam,
  flagged,
  all,
  custom,
}

/// Immutable mailbox entity.
class Mailbox {
  const Mailbox({
    required this.path,
    required this.name,
    required this.accountId,
    this.role = MailboxRole.custom,
    this.totalMessages = 0,
    this.unseenMessages = 0,
    this.isSubscribed = true,
    this.highestModSeq,
    this.uidValidity,
    this.uidNext,
  });

  /// Full IMAP path (e.g. "INBOX", "[Gmail]/Sent Mail").
  final String path;

  /// Human-readable name (e.g. "Inbox", "Sent").
  final String name;

  /// Which account this mailbox belongs to.
  final String accountId;

  /// Semantic role of this mailbox.
  final MailboxRole role;

  /// Total message count.
  final int totalMessages;

  /// Unseen (unread) message count.
  final int unseenMessages;

  /// Whether the user is subscribed to this mailbox.
  final bool isSubscribed;

  /// IMAP HIGHESTMODSEQ (for incremental sync).
  final int? highestModSeq;

  /// IMAP UIDVALIDITY (cache invalidation).
  final int? uidValidity;

  /// IMAP UIDNEXT (next expected UID).
  final int? uidNext;

  // ── Convenience ──

  bool get hasUnread => unseenMessages > 0;
  bool get isInbox => role == MailboxRole.inbox;
  bool get isSent => role == MailboxRole.sent;
  bool get isDrafts => role == MailboxRole.drafts;
  bool get isTrash => role == MailboxRole.trash;
  bool get isArchive => role == MailboxRole.archive;
  bool get isJunk => role == MailboxRole.spam;
  bool get isSpam => role == MailboxRole.spam;
  bool get isFlagged => role == MailboxRole.flagged;

  Mailbox copyWith({
    String? path,
    String? name,
    String? accountId,
    MailboxRole? role,
    int? totalMessages,
    int? unseenMessages,
    bool? isSubscribed,
    int? highestModSeq,
    int? uidValidity,
    int? uidNext,
  }) {
    return Mailbox(
      path: path ?? this.path,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      role: role ?? this.role,
      totalMessages: totalMessages ?? this.totalMessages,
      unseenMessages: unseenMessages ?? this.unseenMessages,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      highestModSeq: highestModSeq ?? this.highestModSeq,
      uidValidity: uidValidity ?? this.uidValidity,
      uidNext: uidNext ?? this.uidNext,
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'accountId': accountId,
        'role': role.name,
        'totalMessages': totalMessages,
        'unseenMessages': unseenMessages,
        'isSubscribed': isSubscribed,
        'highestModSeq': highestModSeq,
        'uidValidity': uidValidity,
        'uidNext': uidNext,
      };

  factory Mailbox.fromJson(Map<String, dynamic> json) => Mailbox(
        path: json['path'] as String,
        name: json['name'] as String,
        accountId: json['accountId'] as String,
        role: MailboxRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => MailboxRole.custom,
        ),
        totalMessages: json['totalMessages'] as int? ?? 0,
        unseenMessages: json['unseenMessages'] as int? ?? 0,
        isSubscribed: json['isSubscribed'] as bool? ?? true,
        highestModSeq: json['highestModSeq'] as int?,
        uidValidity: json['uidValidity'] as int?,
        uidNext: json['uidNext'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mailbox &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          accountId == other.accountId;

  @override
  int get hashCode => Object.hash(path, accountId);

  @override
  String toString() => 'Mailbox($name, $path)';
}
