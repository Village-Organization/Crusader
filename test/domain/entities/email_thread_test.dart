import 'package:flutter_test/flutter_test.dart';
import 'package:crusader/domain/entities/email_address.dart';
import 'package:crusader/domain/entities/email_message.dart';
import 'package:crusader/domain/entities/email_thread.dart';

void main() {
  // Helpers
  EmailMessage makeMessage({
    String id = 'msg-1',
    String accountId = 'acc-1',
    String mailboxPath = 'INBOX',
    int uid = 100,
    String subject = 'Test Subject',
    DateTime? date,
    Set<EmailFlag>? flags,
    EmailAddress? from,
    List<EmailAddress>? to,
    bool hasAttachments = false,
    String snippet = 'Preview',
  }) {
    return EmailMessage(
      id: id,
      accountId: accountId,
      mailboxPath: mailboxPath,
      uid: uid,
      from: from ??
          const EmailAddress(
            address: 'sender@test.com',
            displayName: 'Sender',
          ),
      to: to ?? const [EmailAddress(address: 'me@test.com')],
      subject: subject,
      date: date ?? DateTime(2025, 6, 15, 10, 0),
      flags: flags ?? const {},
      hasAttachments: hasAttachments,
      snippet: snippet,
    );
  }

  EmailThread makeThread({
    String id = 'thread-1',
    String accountId = 'acc-1',
    List<EmailMessage>? messages,
  }) {
    return EmailThread(
      id: id,
      accountId: accountId,
      messages: messages ??
          [
            makeMessage(
              id: 'msg-1',
              subject: 'Hello',
              date: DateTime(2025, 6, 15, 9, 0),
            ),
            makeMessage(
              id: 'msg-2',
              subject: 'Re: Hello',
              date: DateTime(2025, 6, 15, 10, 0),
            ),
          ],
    );
  }

  group('EmailThread', () {
    group('latest', () {
      test('returns the last message in the list', () {
        final thread = makeThread();

        expect(thread.latest.id, 'msg-2');
      });

      test('returns the only message in a single-message thread', () {
        final thread = makeThread(
          messages: [makeMessage(id: 'only')],
        );

        expect(thread.latest.id, 'only');
      });
    });

    group('subject', () {
      test('strips Re: prefix from latest message subject', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', subject: 'Hello'),
            makeMessage(id: 'm2', subject: 'Re: Hello'),
          ],
        );

        expect(thread.subject, 'Hello');
      });

      test('strips Fwd: prefix', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', subject: 'Fwd: Important Doc'),
          ],
        );

        expect(thread.subject, 'Important Doc');
      });

      test('strips Fw: prefix', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', subject: 'Fw: Check this'),
          ],
        );

        expect(thread.subject, 'Check this');
      });

      test('strips one Re: prefix (replaceAll with ^ anchor)', () {
        // The regex uses ^ anchor, so replaceAll only matches at position 0.
        // "Re: Re: Hello" → "Re: Hello" (only the first prefix is stripped).
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', subject: 'Re: Re: Hello'),
          ],
        );

        expect(thread.subject, 'Re: Hello');
      });

      test('is case-insensitive for prefix stripping (one level)', () {
        // "RE: FWD: Hello" → "FWD: Hello" (strips first prefix only)
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', subject: 'RE: FWD: Hello'),
          ],
        );

        expect(thread.subject, 'FWD: Hello');
      });

      test('preserves subject without prefix', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', subject: 'Meeting Tomorrow'),
          ],
        );

        expect(thread.subject, 'Meeting Tomorrow');
      });
    });

    group('rawSubject', () {
      test('returns unmodified subject from latest message', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', subject: 'Re: Hello'),
          ],
        );

        expect(thread.rawSubject, 'Re: Hello');
      });
    });

    group('snippet', () {
      test('returns snippet from latest message', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', snippet: 'Old snippet'),
            makeMessage(id: 'm2', snippet: 'Latest snippet'),
          ],
        );

        expect(thread.snippet, 'Latest snippet');
      });
    });

    group('date and relativeDate', () {
      test('returns date of latest message', () {
        final latestDate = DateTime(2025, 6, 15, 10, 0);
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', date: DateTime(2025, 6, 14, 10, 0)),
            makeMessage(id: 'm2', date: latestDate),
          ],
        );

        expect(thread.date, latestDate);
      });

      test('relativeDate delegates to latest message', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', date: DateTime(2023, 1, 1)),
          ],
        );

        expect(thread.relativeDate, 'Jan 1, 2023');
      });
    });

    group('from', () {
      test('returns sender of latest message', () {
        const latestSender = EmailAddress(
          address: 'latest@test.com',
          displayName: 'Latest',
        );
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1'),
            makeMessage(id: 'm2', from: latestSender),
          ],
        );

        expect(thread.from, latestSender);
      });
    });

    group('participants', () {
      test('collects unique participants from all messages', () {
        const alice = EmailAddress(address: 'alice@test.com');
        const bob = EmailAddress(address: 'bob@test.com');
        const charlie = EmailAddress(address: 'charlie@test.com');

        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', from: alice, to: [bob]),
            makeMessage(id: 'm2', from: bob, to: [alice, charlie]),
          ],
        );

        final participants = thread.participants;
        expect(participants.length, 3);
        expect(participants, contains(alice));
        expect(participants, contains(bob));
        expect(participants, contains(charlie));
      });

      test('deduplicates case-insensitively', () {
        const alice1 = EmailAddress(address: 'Alice@Test.com');
        const alice2 = EmailAddress(address: 'alice@test.com');

        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', from: alice1, to: [alice2]),
          ],
        );

        expect(thread.participants.length, 1);
      });
    });

    group('messageCount and isConversation', () {
      test('messageCount returns number of messages', () {
        final thread = makeThread();

        expect(thread.messageCount, 2);
      });

      test('isConversation is true for multi-message thread', () {
        final thread = makeThread();

        expect(thread.isConversation, isTrue);
      });

      test('isConversation is false for single-message thread', () {
        final thread = makeThread(
          messages: [makeMessage()],
        );

        expect(thread.isConversation, isFalse);
      });
    });

    group('unread tracking', () {
      test('isUnread is true when latest message is not read', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', flags: {EmailFlag.seen}),
            makeMessage(id: 'm2', flags: {}),
          ],
        );

        expect(thread.isUnread, isTrue);
      });

      test('isUnread is false when latest message is read', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', flags: {}),
            makeMessage(id: 'm2', flags: {EmailFlag.seen}),
          ],
        );

        expect(thread.isUnread, isFalse);
      });

      test('hasUnread is true when any message is unread', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', flags: {}),
            makeMessage(id: 'm2', flags: {EmailFlag.seen}),
          ],
        );

        expect(thread.hasUnread, isTrue);
      });

      test('hasUnread is false when all messages are read', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', flags: {EmailFlag.seen}),
            makeMessage(id: 'm2', flags: {EmailFlag.seen}),
          ],
        );

        expect(thread.hasUnread, isFalse);
      });

      test('unreadCount returns number of unread messages', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', flags: {}),
            makeMessage(id: 'm2', flags: {EmailFlag.seen}),
            makeMessage(id: 'm3', uid: 101, flags: {}),
          ],
        );

        expect(thread.unreadCount, 2);
      });
    });

    group('isFlagged', () {
      test('returns true when any message is flagged', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', flags: {}),
            makeMessage(id: 'm2', flags: {EmailFlag.flagged}),
          ],
        );

        expect(thread.isFlagged, isTrue);
      });

      test('returns false when no messages are flagged', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', flags: {EmailFlag.seen}),
          ],
        );

        expect(thread.isFlagged, isFalse);
      });
    });

    group('hasAttachments', () {
      test('returns true when any message has attachments', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', hasAttachments: false),
            makeMessage(id: 'm2', hasAttachments: true),
          ],
        );

        expect(thread.hasAttachments, isTrue);
      });

      test('returns false when no messages have attachments', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', hasAttachments: false),
          ],
        );

        expect(thread.hasAttachments, isFalse);
      });
    });

    group('mailboxPath', () {
      test('returns mailboxPath of latest message', () {
        final thread = makeThread(
          messages: [
            makeMessage(id: 'm1', mailboxPath: 'INBOX'),
            makeMessage(id: 'm2', mailboxPath: 'Sent'),
          ],
        );

        expect(thread.mailboxPath, 'Sent');
      });
    });

    group('equality', () {
      test('two threads with same id are equal', () {
        final a = makeThread(id: 'same-id');
        final b = EmailThread(
          id: 'same-id',
          accountId: 'other-acc',
          messages: [makeMessage(id: 'different')],
        );

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('two threads with different ids are not equal', () {
        final a = makeThread(id: 'id-1');
        final b = makeThread(id: 'id-2');

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('includes subject and message count', () {
        final thread = makeThread();
        final str = thread.toString();

        expect(str, contains('EmailThread'));
        expect(str, contains('2 messages'));
      });
    });
  });
}
