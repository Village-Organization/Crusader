import 'package:flutter_test/flutter_test.dart';
import 'package:crusader/domain/entities/email_account.dart';

void main() {
  group('EmailProvider', () {
    test('has gmail and outlook values', () {
      expect(EmailProvider.values, containsAll([
        EmailProvider.gmail,
        EmailProvider.outlook,
      ]));
    });
  });

  group('EmailAccount', () {
    EmailAccount makeAccount({
      String id = 'acc-1',
      String email = 'user@gmail.com',
      String displayName = 'Test User',
      EmailProvider provider = EmailProvider.gmail,
      String imapHost = 'imap.gmail.com',
      int imapPort = 993,
      String smtpHost = 'smtp.gmail.com',
      int smtpPort = 465,
      String? avatarUrl,
      bool isActive = true,
    }) {
      return EmailAccount(
        id: id,
        email: email,
        displayName: displayName,
        provider: provider,
        imapHost: imapHost,
        imapPort: imapPort,
        smtpHost: smtpHost,
        smtpPort: smtpPort,
        avatarUrl: avatarUrl,
        isActive: isActive,
      );
    }

    group('fromProvider', () {
      test('Gmail: sets correct IMAP/SMTP hosts and ports', () {
        final account = EmailAccount.fromProvider(
          id: 'g1',
          email: 'alice@gmail.com',
          displayName: 'Alice',
          provider: EmailProvider.gmail,
        );

        expect(account.imapHost, 'imap.gmail.com');
        expect(account.imapPort, 993);
        expect(account.smtpHost, 'smtp.gmail.com');
        expect(account.smtpPort, 465);
        expect(account.provider, EmailProvider.gmail);
        expect(account.email, 'alice@gmail.com');
        expect(account.displayName, 'Alice');
        expect(account.isActive, isTrue);
      });

      test('Outlook: sets correct IMAP/SMTP hosts and ports', () {
        final account = EmailAccount.fromProvider(
          id: 'o1',
          email: 'bob@outlook.com',
          displayName: 'Bob',
          provider: EmailProvider.outlook,
        );

        expect(account.imapHost, 'outlook.office365.com');
        expect(account.imapPort, 993);
        expect(account.smtpHost, 'smtp.office365.com');
        expect(account.smtpPort, 587);
        expect(account.provider, EmailProvider.outlook);
      });

      test('passes avatarUrl through', () {
        final account = EmailAccount.fromProvider(
          id: 'g1',
          email: 'alice@gmail.com',
          displayName: 'Alice',
          provider: EmailProvider.gmail,
          avatarUrl: 'https://example.com/photo.jpg',
        );

        expect(account.avatarUrl, 'https://example.com/photo.jpg');
      });
    });

    group('copyWith', () {
      test('returns identical account when no fields specified', () {
        final original = makeAccount();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.email, original.email);
        expect(copy.displayName, original.displayName);
        expect(copy.provider, original.provider);
        expect(copy.isActive, original.isActive);
      });

      test('overrides specified fields', () {
        final original = makeAccount(isActive: true);
        final copy = original.copyWith(
          isActive: false,
          displayName: 'New Name',
        );

        expect(copy.isActive, isFalse);
        expect(copy.displayName, 'New Name');
        expect(copy.id, original.id);
        expect(copy.email, original.email);
      });

      test('can change provider and hosts', () {
        final original = makeAccount(provider: EmailProvider.gmail);
        final copy = original.copyWith(
          provider: EmailProvider.outlook,
          imapHost: 'outlook.office365.com',
          smtpHost: 'smtp.office365.com',
          smtpPort: 587,
        );

        expect(copy.provider, EmailProvider.outlook);
        expect(copy.imapHost, 'outlook.office365.com');
        expect(copy.smtpHost, 'smtp.office365.com');
        expect(copy.smtpPort, 587);
      });
    });

    group('toJson / fromJson', () {
      test('round-trips all fields', () {
        final original = makeAccount(
          id: 'test-42',
          email: 'test@outlook.com',
          displayName: 'Test User',
          provider: EmailProvider.outlook,
          imapHost: 'outlook.office365.com',
          imapPort: 993,
          smtpHost: 'smtp.office365.com',
          smtpPort: 587,
          avatarUrl: 'https://example.com/avatar.png',
          isActive: false,
        );

        final json = original.toJson();
        final restored = EmailAccount.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.email, original.email);
        expect(restored.displayName, original.displayName);
        expect(restored.provider, original.provider);
        expect(restored.imapHost, original.imapHost);
        expect(restored.imapPort, original.imapPort);
        expect(restored.smtpHost, original.smtpHost);
        expect(restored.smtpPort, original.smtpPort);
        expect(restored.avatarUrl, original.avatarUrl);
        expect(restored.isActive, original.isActive);
      });

      test('fromJson defaults isActive to true when missing', () {
        final json = {
          'id': 'acc-1',
          'email': 'x@y.com',
          'displayName': 'X',
          'provider': 'gmail',
          'imapHost': 'imap.gmail.com',
          'imapPort': 993,
          'smtpHost': 'smtp.gmail.com',
          'smtpPort': 465,
        };

        final account = EmailAccount.fromJson(json);
        expect(account.isActive, isTrue);
      });

      test('toJson serializes provider as name string', () {
        final account = makeAccount(provider: EmailProvider.gmail);
        final json = account.toJson();

        expect(json['provider'], 'gmail');
      });
    });

    group('equality', () {
      test('two accounts with same id are equal', () {
        final a = makeAccount(id: 'same', email: 'a@test.com');
        final b = makeAccount(id: 'same', email: 'b@test.com');

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different ids are not equal', () {
        final a = makeAccount(id: 'id-1');
        final b = makeAccount(id: 'id-2');

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('includes email and provider', () {
        final account = makeAccount(
          email: 'alice@gmail.com',
          provider: EmailProvider.gmail,
        );

        expect(account.toString(), 'EmailAccount(alice@gmail.com, EmailProvider.gmail)');
      });
    });
  });
}
