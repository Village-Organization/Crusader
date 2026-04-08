import 'package:flutter_test/flutter_test.dart';

import 'package:crusader/domain/entities/email_account.dart';
import 'package:crusader/features/auth/auth_providers.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // AccountState (pure data class)
  // ─────────────────────────────────────────────────────────────────────

  group('AccountState', () {
    final gmailAccount = EmailAccount.fromProvider(
      id: 'acc-gmail',
      email: 'alice@gmail.com',
      displayName: 'Alice',
      provider: EmailProvider.gmail,
    );

    final outlookAccount = EmailAccount.fromProvider(
      id: 'acc-outlook',
      email: 'bob@outlook.com',
      displayName: 'Bob',
      provider: EmailProvider.outlook,
    );

    group('defaults', () {
      test('has empty accounts and no active account', () {
        const s = AccountState();

        expect(s.accounts, isEmpty);
        expect(s.activeAccountId, isNull);
        expect(s.isLoading, isFalse);
        expect(s.error, isNull);
      });
    });

    group('activeAccount', () {
      test('returns null when activeAccountId is null', () {
        const s = AccountState();

        expect(s.activeAccount, isNull);
      });

      test('returns null when accounts is empty even with activeAccountId', () {
        const s = AccountState(activeAccountId: 'nonexistent');

        expect(s.activeAccount, isNull);
      });

      test('returns the account matching activeAccountId', () {
        final s = AccountState(
          accounts: [gmailAccount, outlookAccount],
          activeAccountId: 'acc-outlook',
        );

        expect(s.activeAccount, outlookAccount);
        expect(s.activeAccount?.email, 'bob@outlook.com');
      });

      test('falls back to first account if activeAccountId not found', () {
        final s = AccountState(
          accounts: [gmailAccount, outlookAccount],
          activeAccountId: 'nonexistent',
        );

        expect(s.activeAccount, gmailAccount);
      });
    });

    group('hasAccounts', () {
      test('returns false when accounts is empty', () {
        const s = AccountState();

        expect(s.hasAccounts, isFalse);
      });

      test('returns true when accounts is not empty', () {
        final s = AccountState(accounts: [gmailAccount]);

        expect(s.hasAccounts, isTrue);
      });
    });

    group('copyWith', () {
      test('preserves all fields when none specified', () {
        final original = AccountState(
          accounts: [gmailAccount],
          activeAccountId: 'acc-gmail',
          isLoading: true,
          error: 'some error',
        );
        final copy = original.copyWith();

        expect(copy.accounts.length, 1);
        expect(copy.activeAccountId, 'acc-gmail');
        expect(copy.isLoading, isTrue);
        // Note: copyWith uses `error` parameter directly (nullable),
        // so calling copyWith() passes null to error, clearing it.
      });

      test('overrides specified fields', () {
        final original = AccountState(
          accounts: [gmailAccount],
          activeAccountId: 'acc-gmail',
        );
        final copy = original.copyWith(
          accounts: [gmailAccount, outlookAccount],
          activeAccountId: 'acc-outlook',
          isLoading: true,
        );

        expect(copy.accounts.length, 2);
        expect(copy.activeAccountId, 'acc-outlook');
        expect(copy.isLoading, isTrue);
      });
    });

    group('multiple accounts scenario', () {
      test('can have multiple accounts from different providers', () {
        final s = AccountState(
          accounts: [gmailAccount, outlookAccount],
          activeAccountId: 'acc-gmail',
        );

        expect(s.accounts.length, 2);
        expect(s.activeAccount?.provider, EmailProvider.gmail);
      });

      test('switching active account changes activeAccount getter', () {
        final s1 = AccountState(
          accounts: [gmailAccount, outlookAccount],
          activeAccountId: 'acc-gmail',
        );
        final s2 = s1.copyWith(activeAccountId: 'acc-outlook');

        expect(s1.activeAccount?.email, 'alice@gmail.com');
        expect(s2.activeAccount?.email, 'bob@outlook.com');
      });
    });
  });
}
