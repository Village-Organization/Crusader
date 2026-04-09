/// Crusader — SMTP Email Service
///
/// Sends emails via SMTP with OAuth2 XOAUTH2 or password/PLAIN authentication.
/// Supports plain text, HTML, replies, and forwards.
///
/// This is the raw SMTP data source — no caching, no business logic.
library;

import 'dart:async';

import 'package:enough_mail/enough_mail.dart' as smtp;

import '../../domain/entities/email_account.dart';
import '../../domain/entities/email_address.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SMTP Service
// ─────────────────────────────────────────────────────────────────────────────

class SmtpService {
  /// Active SMTP client connections keyed by account ID.
  final Map<String, smtp.SmtpClient> _clients = {};

  // ── Connection ────────────────────────────────────────────────────────

  /// Connect and authenticate to an SMTP server (OAuth2 or password).
  Future<smtp.SmtpClient> connect({
    required EmailAccount account,
    required String accessToken,
  }) async {
    // Reuse existing connection if alive.
    final existing = _clients[account.id];
    if (existing != null && existing.isConnected) {
      return existing;
    }

    final client = smtp.SmtpClient('crusader.app', isLogEnabled: false);

    try {
      // Gmail uses port 465 (implicit SSL).
      // Outlook uses port 587 (STARTTLS).
      final useImplicitSsl = account.smtpPort == 465;

      await client.connectToServer(
        account.smtpHost,
        account.smtpPort,
        isSecure: useImplicitSsl,
      );

      await client.ehlo();

      // Upgrade to TLS if needed (port 587).
      if (!useImplicitSsl) {
        await client.startTls();
      }

      // Authenticate: password accounts use PLAIN, OAuth accounts use XOAUTH2.
      if (account.authMethod == AuthMethod.password) {
        await client.authenticate(
          account.email,
          accessToken,
          smtp.AuthMechanism.plain,
        );
      } else {
        await client.authenticate(
          account.email,
          accessToken,
          smtp.AuthMechanism.xoauth2,
        );
      }

      _clients[account.id] = client;
      return client;
    } catch (e) {
      await _safeDisconnect(client);
      throw SmtpException('SMTP connection failed: $e');
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

  // ── Send Operations ───────────────────────────────────────────────────

  /// Send a new email.
  Future<void> sendEmail({
    required String accountId,
    required EmailAddress from,
    required List<EmailAddress> to,
    List<EmailAddress> cc = const [],
    List<EmailAddress> bcc = const [],
    required String subject,
    String? textPlain,
    String? textHtml,
  }) async {
    final client = _requireClient(accountId);

    try {
      final builder =
          smtp.MessageBuilder.prepareMultipartAlternativeMessage(
              plainText: textPlain ?? _stripHtml(textHtml ?? ''),
              htmlText: textHtml,
            )
            ..from = [_toMailAddress(from)]
            ..to = to.map(_toMailAddress).toList()
            ..subject = subject;

      if (cc.isNotEmpty) {
        builder.cc = cc.map(_toMailAddress).toList();
      }
      if (bcc.isNotEmpty) {
        builder.bcc = bcc.map(_toMailAddress).toList();
      }

      final message = builder.buildMimeMessage();
      final response = await client.sendMessage(message);

      if (response.isFailedStatus) {
        throw SmtpException(
          'Send failed: ${response.responseLines.map((l) => l.message).join(', ')}',
        );
      }
    } catch (e) {
      if (e is SmtpException) rethrow;
      throw SmtpException('Failed to send email: $e');
    }
  }

  /// Send a reply to an existing message.
  Future<void> sendReply({
    required String accountId,
    required EmailAddress from,
    required smtp.MimeMessage originalMessage,
    required String bodyPlain,
    String? bodyHtml,
    bool replyAll = false,
  }) async {
    final client = _requireClient(accountId);

    try {
      final builder = smtp.MessageBuilder.prepareReplyToMessage(
        originalMessage,
        _toMailAddress(from),
        replyAll: replyAll,
        quoteOriginalText: true,
      );

      builder.addTextPlain(bodyPlain);
      if (bodyHtml != null) {
        builder.addTextHtml(bodyHtml);
      }

      final message = builder.buildMimeMessage();
      final response = await client.sendMessage(message);

      if (response.isFailedStatus) {
        throw SmtpException(
          'Reply failed: ${response.responseLines.map((l) => l.message).join(', ')}',
        );
      }
    } catch (e) {
      if (e is SmtpException) rethrow;
      throw SmtpException('Failed to send reply: $e');
    }
  }

  /// Forward an existing message.
  Future<void> sendForward({
    required String accountId,
    required EmailAddress from,
    required List<EmailAddress> to,
    required smtp.MimeMessage originalMessage,
    String? additionalText,
  }) async {
    final client = _requireClient(accountId);

    try {
      final builder = smtp.MessageBuilder.prepareForwardMessage(
        originalMessage,
        from: _toMailAddress(from),
      )..to = to.map(_toMailAddress).toList();

      if (additionalText != null && additionalText.isNotEmpty) {
        builder.addTextPlain(additionalText);
      }

      final message = builder.buildMimeMessage();
      final response = await client.sendMessage(message);

      if (response.isFailedStatus) {
        throw SmtpException(
          'Forward failed: ${response.responseLines.map((l) => l.message).join(', ')}',
        );
      }
    } catch (e) {
      if (e is SmtpException) rethrow;
      throw SmtpException('Failed to forward email: $e');
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────

  smtp.SmtpClient _requireClient(String accountId) {
    final client = _clients[accountId];
    if (client == null || !client.isConnected) {
      throw SmtpException('Not connected for account $accountId');
    }
    return client;
  }

  Future<void> _safeDisconnect(smtp.SmtpClient client) async {
    try {
      await client.quit();
    } catch (_) {
      // Ignore quit errors.
    }
    try {
      await client.disconnect();
    } catch (_) {
      // Ignore disconnect errors.
    }
  }

  smtp.MailAddress _toMailAddress(EmailAddress addr) {
    return smtp.MailAddress(addr.displayName, addr.address);
  }

  /// Simple HTML tag stripper for generating plain text fallback.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exception
// ─────────────────────────────────────────────────────────────────────────────

class SmtpException implements Exception {
  const SmtpException(this.message);
  final String message;

  @override
  String toString() => 'SmtpException: $message';
}
