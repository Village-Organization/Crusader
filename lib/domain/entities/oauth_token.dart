/// Crusader — OAuth Token Model
///
/// Stores OAuth2 token data. Actual tokens go in flutter_secure_storage.
library;

class OAuthToken {
  const OAuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.idToken,
    this.scopes = const [],
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String? idToken;
  final List<String> scopes;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// True if token expires within the next 5 minutes.
  bool get isAboutToExpire =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
        'idToken': idToken,
        'scopes': scopes,
      };

  factory OAuthToken.fromJson(Map<String, dynamic> json) => OAuthToken(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        idToken: json['idToken'] as String?,
        scopes: (json['scopes'] as List<dynamic>?)
                ?.map((s) => s as String)
                .toList() ??
            [],
      );
}
