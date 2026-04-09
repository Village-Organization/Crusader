/// Crusader — Auth Repository
///
/// Manages OAuth2 flows, token storage, and account persistence.
/// Tokens stored in flutter_secure_storage (never in plain storage).
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/email_account.dart';
import '../../domain/entities/oauth_token.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth Repository
// ─────────────────────────────────────────────────────────────────────────────

class AuthRepository {
  AuthRepository({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  static const _uuid = Uuid();

  // Storage keys
  static const _accountsKey = 'crusader_accounts';
  static const _activeAccountKey = 'crusader_active_account';
  static const _tokenPrefix = 'crusader_token_';
  static const _passwordPrefix = 'crusader_pwd_';

  // ── Account Management ──────────────────────────────────────────────────

  /// Load all saved accounts from SharedPreferences.
  Future<List<EmailAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_accountsKey);
    if (raw == null || raw.isEmpty) return [];

    return raw
        .map(
          (json) =>
              EmailAccount.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList();
  }

  /// Save an account (add or update).
  Future<void> saveAccount(EmailAccount account) async {
    final accounts = await loadAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }
    await _persistAccounts(accounts);
  }

  /// Remove an account and its tokens.
  Future<void> removeAccount(String accountId) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.id == accountId);
    await _persistAccounts(accounts);
    await deleteToken(accountId);
    await deletePassword(accountId);

    // If removed the active account, switch to first remaining.
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_activeAccountKey);
    if (activeId == accountId) {
      if (accounts.isNotEmpty) {
        await setActiveAccount(accounts.first.id);
      } else {
        await prefs.remove(_activeAccountKey);
      }
    }
  }

  /// Get/set the active account ID.
  Future<String?> getActiveAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeAccountKey);
  }

  Future<void> setActiveAccount(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeAccountKey, accountId);
  }

  Future<void> _persistAccounts(List<EmailAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = accounts.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_accountsKey, raw);
  }

  // ── Token Management (Secure Storage) ─────────────────────────────────

  /// Store OAuth token securely.
  Future<void> saveToken(String accountId, OAuthToken token) async {
    await _secureStorage.write(
      key: '$_tokenPrefix$accountId',
      value: jsonEncode(token.toJson()),
    );
  }

  /// Retrieve OAuth token.
  Future<OAuthToken?> getToken(String accountId) async {
    final raw = await _secureStorage.read(key: '$_tokenPrefix$accountId');
    if (raw == null) return null;
    return OAuthToken.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Delete OAuth token.
  Future<void> deleteToken(String accountId) async {
    await _secureStorage.delete(key: '$_tokenPrefix$accountId');
  }

  // ── Password Management (Secure Storage) ──────────────────────────────

  /// Store a password/app-password securely.
  Future<void> savePassword(String accountId, String password) async {
    await _secureStorage.write(
      key: '$_passwordPrefix$accountId',
      value: password,
    );
  }

  /// Retrieve a stored password.
  Future<String?> getPassword(String accountId) async {
    return _secureStorage.read(key: '$_passwordPrefix$accountId');
  }

  /// Delete a stored password.
  Future<void> deletePassword(String accountId) async {
    await _secureStorage.delete(key: '$_passwordPrefix$accountId');
  }

  // ── Account Creation Helpers ──────────────────────────────────────────

  /// Create a new account entry after successful OAuth.
  EmailAccount createAccount({
    required String email,
    required String displayName,
    required EmailProvider provider,
    String? avatarUrl,
  }) {
    return EmailAccount.fromProvider(
      id: _uuid.v4(),
      email: email,
      displayName: displayName,
      provider: provider,
      avatarUrl: avatarUrl,
    );
  }

  /// Create a custom IMAP/SMTP account with password auth.
  EmailAccount createCustomAccount({
    required String email,
    required String displayName,
    required String imapHost,
    required int imapPort,
    required String smtpHost,
    required int smtpPort,
  }) {
    return EmailAccount(
      id: _uuid.v4(),
      email: email,
      displayName: displayName,
      provider: EmailProvider.custom,
      imapHost: imapHost,
      imapPort: imapPort,
      smtpHost: smtpHost,
      smtpPort: smtpPort,
      authMethod: AuthMethod.password,
    );
  }
}
