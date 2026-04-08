import 'package:flutter_test/flutter_test.dart';
import 'package:crusader/domain/entities/mailbox.dart';

void main() {
  group('MailboxRole', () {
    test('has all expected values', () {
      expect(MailboxRole.values, containsAll([
        MailboxRole.inbox,
        MailboxRole.sent,
        MailboxRole.drafts,
        MailboxRole.trash,
        MailboxRole.archive,
        MailboxRole.spam,
        MailboxRole.flagged,
        MailboxRole.all,
        MailboxRole.custom,
      ]));
    });
  });

  group('Mailbox', () {
    Mailbox makeMailbox({
      String path = 'INBOX',
      String name = 'Inbox',
      String accountId = 'acc-1',
      MailboxRole role = MailboxRole.inbox,
      int totalMessages = 100,
      int unseenMessages = 5,
      bool isSubscribed = true,
      int? highestModSeq,
      int? uidValidity,
      int? uidNext,
    }) {
      return Mailbox(
        path: path,
        name: name,
        accountId: accountId,
        role: role,
        totalMessages: totalMessages,
        unseenMessages: unseenMessages,
        isSubscribed: isSubscribed,
        highestModSeq: highestModSeq,
        uidValidity: uidValidity,
        uidNext: uidNext,
      );
    }

    group('constructor defaults', () {
      test('role defaults to custom', () {
        const mb = Mailbox(
          path: 'Custom',
          name: 'Custom',
          accountId: 'acc-1',
        );
        expect(mb.role, MailboxRole.custom);
      });

      test('totalMessages defaults to 0', () {
        const mb = Mailbox(
          path: 'INBOX',
          name: 'Inbox',
          accountId: 'acc-1',
        );
        expect(mb.totalMessages, 0);
      });

      test('unseenMessages defaults to 0', () {
        const mb = Mailbox(
          path: 'INBOX',
          name: 'Inbox',
          accountId: 'acc-1',
        );
        expect(mb.unseenMessages, 0);
      });

      test('isSubscribed defaults to true', () {
        const mb = Mailbox(
          path: 'INBOX',
          name: 'Inbox',
          accountId: 'acc-1',
        );
        expect(mb.isSubscribed, isTrue);
      });

      test('IMAP fields default to null', () {
        const mb = Mailbox(
          path: 'INBOX',
          name: 'Inbox',
          accountId: 'acc-1',
        );
        expect(mb.highestModSeq, isNull);
        expect(mb.uidValidity, isNull);
        expect(mb.uidNext, isNull);
      });
    });

    group('convenience getters', () {
      test('hasUnread returns true when unseenMessages > 0', () {
        final mb = makeMailbox(unseenMessages: 3);
        expect(mb.hasUnread, isTrue);
      });

      test('hasUnread returns false when unseenMessages is 0', () {
        final mb = makeMailbox(unseenMessages: 0);
        expect(mb.hasUnread, isFalse);
      });

      test('isInbox returns true for inbox role', () {
        final mb = makeMailbox(role: MailboxRole.inbox);
        expect(mb.isInbox, isTrue);
        expect(mb.isSent, isFalse);
      });

      test('isSent returns true for sent role', () {
        final mb = makeMailbox(role: MailboxRole.sent);
        expect(mb.isSent, isTrue);
      });

      test('isDrafts returns true for drafts role', () {
        final mb = makeMailbox(role: MailboxRole.drafts);
        expect(mb.isDrafts, isTrue);
      });

      test('isTrash returns true for trash role', () {
        final mb = makeMailbox(role: MailboxRole.trash);
        expect(mb.isTrash, isTrue);
      });

      test('isArchive returns true for archive role', () {
        final mb = makeMailbox(role: MailboxRole.archive);
        expect(mb.isArchive, isTrue);
      });

      test('isJunk and isSpam both return true for spam role', () {
        final mb = makeMailbox(role: MailboxRole.spam);
        expect(mb.isJunk, isTrue);
        expect(mb.isSpam, isTrue);
      });

      test('isFlagged returns true for flagged role', () {
        final mb = makeMailbox(role: MailboxRole.flagged);
        expect(mb.isFlagged, isTrue);
      });
    });

    group('copyWith', () {
      test('returns identical mailbox when no fields specified', () {
        final original = makeMailbox();
        final copy = original.copyWith();

        expect(copy.path, original.path);
        expect(copy.name, original.name);
        expect(copy.role, original.role);
        expect(copy.totalMessages, original.totalMessages);
      });

      test('overrides specified fields', () {
        final original = makeMailbox(
          totalMessages: 100,
          unseenMessages: 5,
        );
        final copy = original.copyWith(
          totalMessages: 150,
          unseenMessages: 10,
        );

        expect(copy.totalMessages, 150);
        expect(copy.unseenMessages, 10);
        expect(copy.path, original.path);
      });
    });

    group('toJson / fromJson', () {
      test('round-trips all fields', () {
        final original = makeMailbox(
          path: '[Gmail]/Sent Mail',
          name: 'Sent',
          accountId: 'acc-42',
          role: MailboxRole.sent,
          totalMessages: 250,
          unseenMessages: 0,
          isSubscribed: true,
          highestModSeq: 99999,
          uidValidity: 12345,
          uidNext: 500,
        );

        final json = original.toJson();
        final restored = Mailbox.fromJson(json);

        expect(restored.path, original.path);
        expect(restored.name, original.name);
        expect(restored.accountId, original.accountId);
        expect(restored.role, original.role);
        expect(restored.totalMessages, original.totalMessages);
        expect(restored.unseenMessages, original.unseenMessages);
        expect(restored.isSubscribed, original.isSubscribed);
        expect(restored.highestModSeq, original.highestModSeq);
        expect(restored.uidValidity, original.uidValidity);
        expect(restored.uidNext, original.uidNext);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'path': 'INBOX',
          'name': 'Inbox',
          'accountId': 'acc-1',
          'role': 'inbox',
        };

        final mb = Mailbox.fromJson(json);

        expect(mb.totalMessages, 0);
        expect(mb.unseenMessages, 0);
        expect(mb.isSubscribed, isTrue);
        expect(mb.highestModSeq, isNull);
      });

      test('fromJson falls back to custom for unknown role', () {
        final json = {
          'path': 'INBOX',
          'name': 'Inbox',
          'accountId': 'acc-1',
          'role': 'nonexistent_role',
        };

        final mb = Mailbox.fromJson(json);
        expect(mb.role, MailboxRole.custom);
      });
    });

    group('equality', () {
      test('two mailboxes with same path and accountId are equal', () {
        final a = makeMailbox(path: 'INBOX', accountId: 'acc-1');
        final b = makeMailbox(
          path: 'INBOX',
          accountId: 'acc-1',
          totalMessages: 999,
        );

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different paths are not equal', () {
        final a = makeMailbox(path: 'INBOX', accountId: 'acc-1');
        final b = makeMailbox(path: 'Sent', accountId: 'acc-1');

        expect(a, isNot(equals(b)));
      });

      test('same path but different accountIds are not equal', () {
        final a = makeMailbox(path: 'INBOX', accountId: 'acc-1');
        final b = makeMailbox(path: 'INBOX', accountId: 'acc-2');

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('includes name and path', () {
        final mb = makeMailbox(name: 'Inbox', path: 'INBOX');
        expect(mb.toString(), 'Mailbox(Inbox, INBOX)');
      });
    });
  });
}
