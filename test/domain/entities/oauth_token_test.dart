import 'package:flutter_test/flutter_test.dart';
import 'package:crusader/domain/entities/oauth_token.dart';

void main() {
  group('OAuthToken', () {
    OAuthToken makeToken({
      String accessToken = 'access_abc123',
      String? refreshToken = 'refresh_xyz789',
      DateTime? expiresAt,
      String? idToken,
      List<String> scopes = const ['openid', 'email'],
    }) {
      return OAuthToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 1)),
        idToken: idToken,
        scopes: scopes,
      );
    }

    group('constructor', () {
      test('creates token with all fields', () {
        final expiresAt = DateTime(2025, 12, 31);
        final token = OAuthToken(
          accessToken: 'at',
          refreshToken: 'rt',
          expiresAt: expiresAt,
          idToken: 'idt',
          scopes: ['openid'],
        );

        expect(token.accessToken, 'at');
        expect(token.refreshToken, 'rt');
        expect(token.expiresAt, expiresAt);
        expect(token.idToken, 'idt');
        expect(token.scopes, ['openid']);
      });

      test('refreshToken and idToken can be null', () {
        final token = OAuthToken(
          accessToken: 'at',
          refreshToken: null,
          expiresAt: DateTime.now(),
        );

        expect(token.refreshToken, isNull);
        expect(token.idToken, isNull);
      });

      test('scopes defaults to empty list', () {
        final token = OAuthToken(
          accessToken: 'at',
          refreshToken: null,
          expiresAt: DateTime.now(),
        );

        expect(token.scopes, isEmpty);
      });
    });

    group('isExpired', () {
      test('returns false when token has not expired', () {
        final token = makeToken(
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(token.isExpired, isFalse);
      });

      test('returns true when token is past expiry', () {
        final token = makeToken(
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(token.isExpired, isTrue);
      });
    });

    group('isAboutToExpire', () {
      test('returns false when token has more than 5 minutes left', () {
        final token = makeToken(
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );

        expect(token.isAboutToExpire, isFalse);
      });

      test('returns true when token has less than 5 minutes left', () {
        final token = makeToken(
          expiresAt: DateTime.now().add(const Duration(minutes: 3)),
        );

        expect(token.isAboutToExpire, isTrue);
      });

      test('returns true when token is already expired', () {
        final token = makeToken(
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );

        expect(token.isAboutToExpire, isTrue);
      });

      test('returns true at exactly 5 minute boundary', () {
        // At exactly 5 minutes before expiry, the subtract will make
        // the check DateTime equal to now, and isAfter returns false
        // for equal dates. So at exactly 5 min, isAboutToExpire is false.
        // But at 4min59s, it should be true.
        final token = makeToken(
          expiresAt: DateTime.now().add(
            const Duration(minutes: 4, seconds: 59),
          ),
        );

        expect(token.isAboutToExpire, isTrue);
      });
    });

    group('toJson / fromJson', () {
      test('round-trips all fields', () {
        final original = makeToken(
          accessToken: 'my_access_token',
          refreshToken: 'my_refresh_token',
          expiresAt: DateTime.utc(2025, 12, 31, 23, 59, 59),
          idToken: 'my_id_token',
          scopes: ['openid', 'email', 'profile'],
        );

        final json = original.toJson();
        final restored = OAuthToken.fromJson(json);

        expect(restored.accessToken, original.accessToken);
        expect(restored.refreshToken, original.refreshToken);
        expect(restored.expiresAt, original.expiresAt);
        expect(restored.idToken, original.idToken);
        expect(restored.scopes, original.scopes);
      });

      test('round-trips with null optional fields', () {
        final original = OAuthToken(
          accessToken: 'at',
          refreshToken: null,
          expiresAt: DateTime.utc(2025, 1, 1),
          idToken: null,
          scopes: [],
        );

        final json = original.toJson();
        final restored = OAuthToken.fromJson(json);

        expect(restored.refreshToken, isNull);
        expect(restored.idToken, isNull);
        expect(restored.scopes, isEmpty);
      });

      test('fromJson handles missing scopes', () {
        final json = {
          'accessToken': 'at',
          'refreshToken': null,
          'expiresAt': '2025-01-01T00:00:00.000Z',
        };

        final token = OAuthToken.fromJson(json);

        expect(token.scopes, isEmpty);
      });

      test('toJson serializes expiresAt as ISO 8601', () {
        final token = makeToken(
          expiresAt: DateTime.utc(2025, 6, 15, 12, 0, 0),
        );
        final json = token.toJson();

        expect(json['expiresAt'], '2025-06-15T12:00:00.000Z');
      });
    });
  });
}
