/// Crusader — IMAP Email Service
///
/// Connects to IMAP servers using enough_mail, authenticates via
/// OAuth2 XOAUTH2, fetches mailboxes, and syncs email messages.
///
/// This is the raw IMAP data source — no caching, no business logic.
library;

import 'dart:async';

import 'package:enough_mail/enough_mail.dart' as imap;
import 'package:uuid/uuid.dart';

import '../../domain/entities/attachment.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/entities/email_address.dart';
import '../../domain/entities/email_message.dart';
import '../../domain/entities/mailbox.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMAP Service
// ─────────────────────────────────────────────────────────────────────────────

class ImapService {
  static const _uuid = Uuid();

  /// Active IMAP client connections keyed by account ID.
  final Map<String, imap.ImapClient> _clients = {};

  // ── Connection ────────────────────────────────────────────────────────

  /// Connect and authenticate to an IMAP server with OAuth2.
  /// Returns the connected ImapClient.
  Future<imap.ImapClient> connect({
    required EmailAccount account,
    required String accessToken,
  }) async {
    // Reuse existing connection if alive.
    final existing = _clients[account.id];
    if (existing != null && existing.isLoggedIn) {
      return existing;
    }

    final client = imap.ImapClient(isLogEnabled: false);

    try {
      await client.connectToServer(
        account.imapHost,
        account.imapPort,
        isSecure: true,
      );

      await client.authenticateWithOAuth2(
        account.email,
        accessToken,
      );

      _clients[account.id] = client;
      return client;
    } catch (e) {
      await _safeDisconnect(client);
      throw ImapException('Connection failed: $e');
    }
  }

  /// Disconnect a specific account.
  Future<void> disconnect(String accountId) async {
    final client = _clients.remove(accountId);
    if (client != null) {
      await _safeDisconnect(client);
    }
  }

  /// Disconnect all accounts.
  Future<void> disconnectAll() async {
    for (final client in _clients.values) {
      await _safeDisconnect(client);
    }
    _clients.clear();
  }

  /// Check if an account is connected.
  bool isConnected(String accountId) {
    final client = _clients[accountId];
    return client != null && client.isLoggedIn;
  }

  // ── Mailbox Operations ────────────────────────────────────────────────

  /// List all mailboxes for a connected account.
  Future<List<Mailbox>> listMailboxes({
    required String accountId,
  }) async {
    final client = _requireClient(accountId);

    try {
      final mailboxes = await client.listMailboxes(recursive: true);
      return mailboxes
          .where((mb) => !mb.isNotSelectable)
          .map((mb) => _convertMailbox(mb, accountId))
          .toList();
    } catch (e) {
      throw ImapException('Failed to list mailboxes: $e');
    }
  }

  /// Select a mailbox and return its updated metadata.
  Future<Mailbox> selectMailbox({
    required String accountId,
    required String mailboxPath,
  }) async {
    final client = _requireClient(accountId);

    try {
      final mb = await client.selectMailboxByPath(mailboxPath);
      return _convertMailbox(mb, accountId);
    } catch (e) {
      throw ImapException('Failed to select mailbox "$mailboxPath": $e');
    }
  }

  // ── Email Fetch ───────────────────────────────────────────────────────

  /// Fetch email envelopes (headers + flags) for a range of UIDs.
  /// Used for initial sync and incremental updates.
  ///
  /// [afterUid]: fetch messages with UID > afterUid (0 = fetch from start).
  /// [limit]: max number of messages (fetches most recent first).
  Future<List<EmailMessage>> fetchEnvelopes({
    required String accountId,
    required String mailboxPath,
    int afterUid = 0,
    int limit = 50,
  }) async {
    final client = _requireClient(accountId);

    try {
      // Select the mailbox first.
      final mb = await client.selectMailboxByPath(mailboxPath);

      if (mb.messagesExists == 0) return [];

      // Calculate sequence range: fetch the last `limit` messages.
      final total = mb.messagesExists;
      final start = (total - limit + 1).clamp(1, total);
      final sequence = imap.MessageSequence.fromRange(start, total);

      final result = await client.fetchMessages(
        sequence,
        '(UID FLAGS ENVELOPE BODYSTRUCTURE)',
      );

      return result.messages
          .where((msg) {
            // Filter by afterUid if specified.
            if (afterUid > 0 && msg.uid != null && msg.uid! <= afterUid) {
              return false;
            }
            return true;
          })
          .map((msg) => _convertMessage(msg, accountId, mailboxPath))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // newest first
    } catch (e) {
      throw ImapException('Failed to fetch envelopes: $e');
    }
  }

  /// Fetch full message body by UID.
  /// Pass [existingId] to preserve the local ID from the cached envelope.
  Future<EmailMessage> fetchFullMessage({
    required String accountId,
    required String mailboxPath,
    required int uid,
    String? existingId,
  }) async {
    final client = _requireClient(accountId);

    try {
      await client.selectMailboxByPath(mailboxPath);

      final result = await client.uidFetchMessage(
        uid,
        '(UID FLAGS ENVELOPE BODY.PEEK[])',
      );

      if (result.messages.isEmpty) {
        throw ImapException('Message not found: UID $uid');
      }

      return _convertMessage(
        result.messages.first,
        accountId,
        mailboxPath,
        includeBody: true,
        existingId: existingId,
      );
    } catch (e) {
      if (e is ImapException) rethrow;
      throw ImapException('Failed to fetch message UID $uid: $e');
    }
  }

  /// Fetch new messages since a given UID.
  Future<List<EmailMessage>> fetchNewMessages({
    required String accountId,
    required String mailboxPath,
    required int sinceUid,
  }) async {
    final client = _requireClient(accountId);

    try {
      await client.selectMailboxByPath(mailboxPath);

      final sequence = imap.MessageSequence.fromRangeToLast(
        sinceUid + 1,
        isUidSequence: true,
      );

      final result = await client.uidFetchMessages(
        sequence,
        '(UID FLAGS ENVELOPE BODYSTRUCTURE)',
      );

      return result.messages
          .map((msg) => _convertMessage(msg, accountId, mailboxPath))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      throw ImapException('Failed to fetch new messages: $e');
    }
  }

  /// Mark a message as read.
  Future<void> markAsRead({
    required String accountId,
    required int uid,
  }) async {
    final client = _requireClient(accountId);

    try {
      await client.uidStore(
        imap.MessageSequence.fromId(uid, isUid: true),
        [imap.MessageFlags.seen],
        action: imap.StoreAction.add,
      );
    } catch (e) {
      throw ImapException('Failed to mark as read: $e');
    }
  }

  /// Mark a message as unread.
  Future<void> markAsUnread({
    required String accountId,
    required int uid,
  }) async {
    final client = _requireClient(accountId);

    try {
      await client.uidStore(
        imap.MessageSequence.fromId(uid, isUid: true),
        [imap.MessageFlags.seen],
        action: imap.StoreAction.remove,
      );
    } catch (e) {
      throw ImapException('Failed to mark as unread: $e');
    }
  }

  /// Mark a message as flagged/unflagged.
  Future<void> toggleFlag({
    required String accountId,
    required int uid,
    required bool flagged,
  }) async {
    final client = _requireClient(accountId);

    try {
      await client.uidStore(
        imap.MessageSequence.fromId(uid, isUid: true),
        [imap.MessageFlags.flagged],
        action: flagged ? imap.StoreAction.add : imap.StoreAction.remove,
      );
    } catch (e) {
      throw ImapException('Failed to toggle flag: $e');
    }
  }

  /// Move a message to trash.
  Future<void> moveToTrash({
    required String accountId,
    required int uid,
    required String trashPath,
  }) async {
    final client = _requireClient(accountId);

    try {
      await client.uidMove(
        imap.MessageSequence.fromId(uid, isUid: true),
        targetMailbox: await client.selectMailboxByPath(trashPath),
      );
    } catch (e) {
      throw ImapException('Failed to move to trash: $e');
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────

  imap.ImapClient _requireClient(String accountId) {
    final client = _clients[accountId];
    if (client == null || !client.isLoggedIn) {
      throw ImapException('Not connected for account $accountId');
    }
    return client;
  }

  Future<void> _safeDisconnect(imap.ImapClient client) async {
    try {
      if (client.isLoggedIn) {
        await client.logout();
      }
    } catch (_) {
      // Ignore logout errors.
    }
    try {
      await client.disconnect();
    } catch (_) {
      // Ignore disconnect errors.
    }
  }

  // ── Converters (enough_mail → domain entities) ────────────────────────

  Mailbox _convertMailbox(imap.Mailbox mb, String accountId) {
    return Mailbox(
      path: mb.path,
      name: mb.name,
      accountId: accountId,
      role: _mapMailboxRole(mb),
      totalMessages: mb.messagesExists,
      unseenMessages: mb.messagesUnseen,
      highestModSeq: mb.highestModSequence,
      uidValidity: mb.uidValidity,
      uidNext: mb.uidNext,
    );
  }

  MailboxRole _mapMailboxRole(imap.Mailbox mb) {
    if (mb.isInbox) return MailboxRole.inbox;
    if (mb.isSent) return MailboxRole.sent;
    if (mb.isDrafts) return MailboxRole.drafts;
    if (mb.isTrash) return MailboxRole.trash;
    if (mb.isArchive) return MailboxRole.archive;
    if (mb.isJunk) return MailboxRole.spam;
    if (mb.hasFlag(imap.MailboxFlag.flagged)) return MailboxRole.flagged;
    if (mb.hasFlag(imap.MailboxFlag.all)) return MailboxRole.all;
    return MailboxRole.custom;
  }

  EmailMessage _convertMessage(
    imap.MimeMessage msg,
    String accountId,
    String mailboxPath, {
    bool includeBody = false,
    String? existingId,
  }) {
    final envelope = msg.envelope;
    final from = _convertAddresses(envelope?.from ?? msg.from);
    final to = _convertAddresses(envelope?.to ?? msg.to);
    final cc = _convertAddresses(envelope?.cc ?? msg.cc);
    final replyTo = _convertAddresses(envelope?.replyTo ?? msg.replyTo);

    // Threading headers
    final messageId =
        envelope?.messageId ?? msg.getHeaderValue('message-id');
    final inReplyTo =
        envelope?.inReplyTo ?? msg.getHeaderValue('in-reply-to');
    final referencesRaw = msg.getHeaderValue('references') ?? '';
    final references = referencesRaw
        .split(RegExp(r'\s+'))
        .where((r) => r.isNotEmpty)
        .toList();

    // Compute thread ID from Message-ID chain.
    final threadId = _computeThreadId(messageId, inReplyTo, references);

    // Flags
    final flags = <EmailFlag>{};
    if (msg.isSeen) flags.add(EmailFlag.seen);
    if (msg.isFlagged) flags.add(EmailFlag.flagged);
    if (msg.isAnswered) flags.add(EmailFlag.answered);
    if (msg.isDeleted) flags.add(EmailFlag.deleted);

    // Snippet
    String snippet = '';
    String? textPlain;
    String? textHtml;

    if (includeBody) {
      textPlain = msg.decodeTextPlainPart();
      textHtml = msg.decodeTextHtmlPart();
      // Build snippet from plain text first, fall back to stripped HTML.
      if (textPlain != null && textPlain.isNotEmpty) {
        snippet = _makeSnippet(textPlain);
      } else if (textHtml != null && textHtml.isNotEmpty) {
        snippet = _makeSnippet(_stripHtml(textHtml));
      }
    } else {
      // For envelope-only fetch, try to get snippet from plain text if available.
      final plain = msg.decodeTextPlainPart();
      if (plain != null) {
        snippet = _makeSnippet(plain);
        textPlain = includeBody ? plain : null;
      }
    }

    // Attachments
    final hasAttachments = msg.hasAttachments();
    final attachmentInfos = msg.findContentInfo(
      disposition: imap.ContentDisposition.attachment,
    );
    final inlineInfos = msg.findContentInfo(
      disposition: imap.ContentDisposition.inline,
    );

    // Parse attachment metadata when fetching full body.
    final List<Attachment> parsedAttachments;
    if (includeBody) {
      parsedAttachments = [
        ...attachmentInfos.map((info) {
          final part = msg.getPart(info.fetchId);
          return Attachment(
            filename: info.fileName ?? 'attachment',
            mimeType: info.contentType?.mediaType.text ??
                'application/octet-stream',
            size: info.size ?? 0,
            contentId: info.cid,
            isInline: false,
            data: part?.decodeContentBinary(),
          );
        }),
        ...inlineInfos
            .where((info) =>
                info.contentType?.mediaType.text.startsWith('image/') ??
                false)
            .map((info) {
          final part = msg.getPart(info.fetchId);
          return Attachment(
            filename: info.fileName ?? 'inline-image',
            mimeType: info.contentType?.mediaType.text ?? 'image/png',
            size: info.size ?? 0,
            contentId: info.cid,
            isInline: true,
            data: part?.decodeContentBinary(),
          );
        }),
      ];
    } else {
      parsedAttachments = const [];
    }

    return EmailMessage(
      id: existingId ?? _uuid.v4(),
      accountId: accountId,
      mailboxPath: mailboxPath,
      uid: msg.uid ?? 0,
      from: from.isNotEmpty
          ? from.first
          : const EmailAddress(address: 'unknown@email.com'),
      to: to,
      cc: cc,
      replyTo: replyTo,
      subject: msg.decodeSubject() ?? envelope?.subject ?? '(No Subject)',
      date: msg.decodeDate() ?? envelope?.date ?? DateTime.now(),
      textPlain: textPlain,
      textHtml: textHtml,
      snippet: snippet,
      flags: flags,
      messageId: messageId,
      inReplyTo: inReplyTo,
      references: references,
      threadId: threadId,
      size: msg.size ?? 0,
      hasAttachments: hasAttachments,
      attachmentCount: attachmentInfos.length,
      attachments: parsedAttachments,
    );
  }

  List<EmailAddress> _convertAddresses(List<imap.MailAddress>? addresses) {
    if (addresses == null || addresses.isEmpty) return [];
    return addresses.map((a) {
      return EmailAddress(
        address: a.email,
        displayName: a.personalName,
      );
    }).toList();
  }

  /// Compute a thread ID from Message-ID / References chain.
  /// We use the first Message-ID in the references chain, or the
  /// In-Reply-To, or fall back to the message's own ID.
  String _computeThreadId(
    String? messageId,
    String? inReplyTo,
    List<String> references,
  ) {
    if (references.isNotEmpty) return references.first;
    if (inReplyTo != null && inReplyTo.isNotEmpty) return inReplyTo;
    return messageId ?? _uuid.v4();
  }

  /// Create a short snippet from plain text (~140 chars).
  String _makeSnippet(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= 140) return cleaned;
    return '${cleaned.substring(0, 140)}…';
  }

  /// Strip HTML tags to produce a plain-text approximation for snippets.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&#\d+;'), '')
        .replaceAll(RegExp(r'&\w+;'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exception
// ─────────────────────────────────────────────────────────────────────────────

class ImapException implements Exception {
  const ImapException(this.message);
  final String message;

  @override
  String toString() => 'ImapException: $message';
}
