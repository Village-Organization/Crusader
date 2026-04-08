/// Crusader — OAuth Service
///
/// Handles the actual OAuth2 flows for Gmail and Outlook.
/// Uses flutter_appauth for iOS/Android (PKCE authorization code flow),
/// and a local loopback HTTP server approach for desktop platforms
/// (Windows, macOS, Linux) where flutter_appauth is not available.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/email_account.dart';
import '../../domain/entities/oauth_token.dart';
import 'desktop_oauth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OAuth Configuration
// ─────────────────────────────────────────────────────────────────────────────

/// OAuth client IDs — replace with your own registered app credentials.
/// These are placeholders and MUST be configured before real auth works.
abstract final class OAuthConfig {
  // ── Gmail ──
  static const String gmailClientId =
      '867081363742-lbef895cghuoh2d72id90l07isjchrp7.apps.googleusercontent.com';
  static const String gmailClientSecret = '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';
  static const String gmailRedirectUri =
      'com.crusader.app:/oauth2redirect/google';
  static const List<String> gmailScopes = [
    'openid',
    'email',
    'profile',
    'https://mail.google.com/', // Full IMAP/SMTP access
  ];
  static const String gmailAuthEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String gmailTokenEndpoint =
      'https://oauth2.googleapis.com/token';
  static const String gmailDiscoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';

  // ── Outlook / Microsoft 365 ──
  static const String outlookClientId = 'YOUR_OUTLOOK_CLIENT_ID';
  static const String outlookRedirectUri =
      'com.crusader.app://oauth2redirect/microsoft';
  static const List<String> outlookScopes = [
    'openid',
    'email',
    'profile',
    'offline_access',
    'https://outlook.office365.com/IMAP.AccessAsUser.All',
    'https://outlook.office365.com/SMTP.Send',
  ];
  static const String outlookAuthEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const String outlookTokenEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/token';
}

// ─────────────────────────────────────────────────────────────────────────────
// OAuth Service
// ─────────────────────────────────────────────────────────────────────────────

class OAuthService {
  OAuthService({FlutterAppAuth? appAuth})
      : _appAuth = appAuth ?? const FlutterAppAuth(),
        _desktopOAuth = DesktopOAuthService();

  final FlutterAppAuth _appAuth;
  final DesktopOAuthService _desktopOAuth;

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Perform OAuth2 authorization code flow with PKCE for the given provider.
  /// Returns an [OAuthResult] with the token and user info on success.
  Future<OAuthResult> authenticate(EmailProvider provider) async {
    if (_isDesktop) {
      return _desktopOAuth.authenticate(provider);
    }
    return _authenticateMobile(provider);
  }

  /// Refresh an expired token.
  Future<OAuthToken> refreshToken(
    EmailProvider provider,
    String refreshToken,
  ) async {
    if (_isDesktop) {
      return _desktopOAuth.refreshToken(provider, refreshToken);
    }
    return _refreshMobile(provider, refreshToken);
  }

  /// Mobile OAuth via flutter_appauth.
  Future<OAuthResult> _authenticateMobile(EmailProvider provider) async {
    final config = _configFor(provider);

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          config.clientId,
          config.redirectUri,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: config.authEndpoint,
            tokenEndpoint: config.tokenEndpoint,
          ),
          scopes: config.scopes,
          preferEphemeralSession: true,
        ),
      );

      final token = OAuthToken(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
        expiresAt: result.accessTokenExpirationDateTime ??
            DateTime.now().add(const Duration(hours: 1)),
        idToken: result.idToken,
        scopes: config.scopes,
      );

      // Fetch user profile info
      final userInfo = await _fetchUserInfo(provider, token.accessToken);

      return OAuthResult(token: token, userInfo: userInfo);
    } catch (e) {
      if (e is OAuthException) rethrow;
      throw OAuthException('Authentication failed: $e');
    }
  }

  /// Refresh an expired token via flutter_appauth (mobile).
  Future<OAuthToken> _refreshMobile(
    EmailProvider provider,
    String refreshToken,
  ) async {
    final config = _configFor(provider);

    try {
      final result = await _appAuth.token(
        TokenRequest(
          config.clientId,
          config.redirectUri,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: config.authEndpoint,
            tokenEndpoint: config.tokenEndpoint,
          ),
          refreshToken: refreshToken,
          scopes: config.scopes,
        ),
      );

      return OAuthToken(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? refreshToken,
        expiresAt: result.accessTokenExpirationDateTime ??
            DateTime.now().add(const Duration(hours: 1)),
        idToken: result.idToken,
        scopes: config.scopes,
      );
    } catch (e) {
      if (e is OAuthException) rethrow;
      throw OAuthException('Token refresh failed: $e');
    }
  }

  /// Fetch user info (email, name, avatar) from the provider's userinfo endpoint.
  Future<OAuthUserInfo> _fetchUserInfo(
    EmailProvider provider,
    String accessToken,
  ) async {
    final uri = switch (provider) {
      EmailProvider.gmail =>
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
      EmailProvider.outlook =>
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
    };

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        return OAuthUserInfo(email: 'unknown@email.com', displayName: 'User');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return switch (provider) {
        EmailProvider.gmail => OAuthUserInfo(
            email: data['email'] as String? ?? 'unknown@gmail.com',
            displayName: data['name'] as String? ?? 'Gmail User',
            avatarUrl: data['picture'] as String?,
          ),
        EmailProvider.outlook => OAuthUserInfo(
            email: data['mail'] as String? ??
                data['userPrincipalName'] as String? ??
                'unknown@outlook.com',
            displayName: data['displayName'] as String? ?? 'Outlook User',
          ),
      };
    } catch (_) {
      return OAuthUserInfo(email: 'unknown@email.com', displayName: 'User');
    }
  }

  _OAuthProviderConfig _configFor(EmailProvider provider) {
    return switch (provider) {
      EmailProvider.gmail => const _OAuthProviderConfig(
          clientId: OAuthConfig.gmailClientId,
          redirectUri: OAuthConfig.gmailRedirectUri,
          scopes: OAuthConfig.gmailScopes,
          authEndpoint: OAuthConfig.gmailAuthEndpoint,
          tokenEndpoint: OAuthConfig.gmailTokenEndpoint,
        ),
      EmailProvider.outlook => const _OAuthProviderConfig(
          clientId: OAuthConfig.outlookClientId,
          redirectUri: OAuthConfig.outlookRedirectUri,
          scopes: OAuthConfig.outlookScopes,
          authEndpoint: OAuthConfig.outlookAuthEndpoint,
          tokenEndpoint: OAuthConfig.outlookTokenEndpoint,
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting Types
// ─────────────────────────────────────────────────────────────────────────────

class _OAuthProviderConfig {
  const _OAuthProviderConfig({
    required this.clientId,
    required this.redirectUri,
    required this.scopes,
    required this.authEndpoint,
    required this.tokenEndpoint,
  });

  final String clientId;
  final String redirectUri;
  final List<String> scopes;
  final String authEndpoint;
  final String tokenEndpoint;
}

class OAuthResult {
  const OAuthResult({required this.token, required this.userInfo});

  final OAuthToken token;
  final OAuthUserInfo userInfo;
}

class OAuthUserInfo {
  const OAuthUserInfo({
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  final String email;
  final String displayName;
  final String? avatarUrl;
}

class OAuthException implements Exception {
  const OAuthException(this.message);
  final String message;

  @override
  String toString() => 'OAuthException: $message';
}
