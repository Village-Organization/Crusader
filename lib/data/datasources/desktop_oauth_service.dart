/// Crusader — Desktop OAuth Service
///
/// Implements OAuth2 authorization code flow with PKCE for desktop platforms
/// (Windows, macOS, Linux) by opening the system browser and running a
/// temporary local HTTP server to catch the redirect.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/email_account.dart';
import '../../domain/entities/oauth_token.dart';
import 'oauth_service.dart';

class DesktopOAuthService {
  /// Perform the full OAuth2 authorization code flow with PKCE.
  ///
  /// 1. Generate PKCE code verifier + challenge
  /// 2. Start a local HTTP server on a random port
  /// 3. Open the auth URL in the system browser
  /// 4. Wait for the redirect with the auth code
  /// 5. Exchange the code for tokens
  Future<OAuthResult> authenticate(EmailProvider provider) async {
    final config = _configFor(provider);

    // Generate PKCE pair
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    // Bind local server on a random available port
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final redirectUri = 'http://localhost:$port';

    // Build authorization URL
    final authUrl = Uri.parse(config.authEndpoint).replace(
      queryParameters: {
        'client_id': config.clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': config.scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );

    // Open browser
    await _openBrowser(authUrl.toString());

    try {
      // Wait for the redirect (timeout after 5 minutes)
      final code = await _waitForAuthCode(server)
          .timeout(const Duration(minutes: 5));

      // Exchange auth code for tokens
      final tokenResponse = await _exchangeCode(
        config: config,
        code: code,
        redirectUri: redirectUri,
        codeVerifier: codeVerifier,
      );

      // Fetch user info
      final userInfo = await _fetchUserInfo(
        provider,
        tokenResponse.accessToken,
      );

      return OAuthResult(token: tokenResponse, userInfo: userInfo);
    } catch (e) {
      throw OAuthException('Authentication failed: $e');
    } finally {
      await server.close(force: true);
    }
  }

  /// Refresh an expired token via HTTP POST.
  Future<OAuthToken> refreshToken(
    EmailProvider provider,
    String refreshToken,
  ) async {
    final config = _configFor(provider);

    try {
      final response = await http.post(
        Uri.parse(config.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': config.clientId,
        if (config.clientSecret != null) 'client_secret': config.clientSecret!,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      );

      if (response.statusCode != 200) {
        throw OAuthException(
          'Token refresh failed (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return OAuthToken(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String? ?? refreshToken,
        expiresAt: DateTime.now().add(
          Duration(seconds: (data['expires_in'] as int?) ?? 3600),
        ),
        idToken: data['id_token'] as String?,
        scopes: config.scopes,
      );
    } catch (e) {
      if (e is OAuthException) rethrow;
      throw OAuthException('Token refresh failed: $e');
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Wait for the browser to redirect back with an auth code.
  Future<String> _waitForAuthCode(HttpServer server) async {
    await for (final request in server) {
      final uri = request.uri;
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        // Send error page to browser
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(_errorPage(error))
          ..close();
        throw OAuthException('Authorization denied: $error');
      }

      if (code != null) {
        // Send success page to browser
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(_successPage())
          ..close();
        return code;
      }

      // Ignore other requests (e.g., favicon)
      request.response
        ..statusCode = 404
        ..close();
    }

    throw OAuthException('Server closed without receiving auth code');
  }

  /// Exchange authorization code for tokens.
  Future<OAuthToken> _exchangeCode({
    required _DesktopOAuthConfig config,
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    final response = await http.post(
      Uri.parse(config.tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': config.clientId,
        if (config.clientSecret != null) 'client_secret': config.clientSecret!,
        'code': code,
        'code_verifier': codeVerifier,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode != 200) {
      throw OAuthException(
        'Token exchange failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return OAuthToken(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String?,
      expiresAt: DateTime.now().add(
        Duration(seconds: (data['expires_in'] as int?) ?? 3600),
      ),
      idToken: data['id_token'] as String?,
      scopes: config.scopes,
    );
  }

  /// Fetch user profile info from provider API.
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

  /// Open a URL in the system default browser.
  ///
  /// On Windows, we use `rundll32 url.dll,FileProtocolHandler` instead of
  /// `cmd /c start` because `start` treats `&` as a command separator,
  /// truncating query-string parameters like `response_type`.
  Future<void> _openBrowser(String url) async {
    if (Platform.isWindows) {
      await Process.run(
        'rundll32',
        ['url.dll,FileProtocolHandler', url],
      );
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    }
  }

  // ── PKCE helpers ────────────────────────────────────────────────────────

  /// Generate a cryptographically random code verifier (43–128 chars).
  String _generateCodeVerifier() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Generate S256 code challenge from verifier.
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  _DesktopOAuthConfig _configFor(EmailProvider provider) {
    return switch (provider) {
      EmailProvider.gmail => _DesktopOAuthConfig(
          clientId: OAuthConfig.gmailClientId,
          clientSecret: OAuthConfig.gmailClientSecret,
          scopes: OAuthConfig.gmailScopes,
          authEndpoint: OAuthConfig.gmailAuthEndpoint,
          tokenEndpoint: OAuthConfig.gmailTokenEndpoint,
        ),
      EmailProvider.outlook => _DesktopOAuthConfig(
          clientId: OAuthConfig.outlookClientId,
          scopes: OAuthConfig.outlookScopes,
          authEndpoint: OAuthConfig.outlookAuthEndpoint,
          tokenEndpoint: OAuthConfig.outlookTokenEndpoint,
        ),
    };
  }

  // ── HTML pages for browser feedback ─────────────────────────────────────

  String _successPage() => '''
<!DOCTYPE html>
<html>
<head><title>Crusader</title>
<style>
  body { background: #0A0A0E; color: #E0E0E0; font-family: Inter, sans-serif;
         display: flex; justify-content: center; align-items: center;
         height: 100vh; margin: 0; }
  .card { text-align: center; padding: 48px; }
  h1 { color: #00E5FF; font-size: 24px; margin-bottom: 8px; }
  p { color: #888; font-size: 14px; }
</style></head>
<body><div class="card">
  <h1>Authenticated</h1>
  <p>You can close this tab and return to Crusader.</p>
</div></body>
</html>
''';

  String _errorPage(String error) => '''
<!DOCTYPE html>
<html>
<head><title>Crusader — Error</title>
<style>
  body { background: #0A0A0E; color: #E0E0E0; font-family: Inter, sans-serif;
         display: flex; justify-content: center; align-items: center;
         height: 100vh; margin: 0; }
  .card { text-align: center; padding: 48px; }
  h1 { color: #FF5252; font-size: 24px; margin-bottom: 8px; }
  p { color: #888; font-size: 14px; }
</style></head>
<body><div class="card">
  <h1>Authentication Failed</h1>
  <p>$error</p>
</div></body>
</html>
''';
}

class _DesktopOAuthConfig {
  const _DesktopOAuthConfig({
    required this.clientId,
    this.clientSecret,
    required this.scopes,
    required this.authEndpoint,
    required this.tokenEndpoint,
  });

  final String clientId;
  final String? clientSecret;
  final List<String> scopes;
  final String authEndpoint;
  final String tokenEndpoint;
}
