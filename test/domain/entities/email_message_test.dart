import 'package:flutter_test/flutter_test.dart';
import 'package:crusader/domain/entities/email_address.dart';
import 'package:crusader/domain/entities/email_message.dart';

void main() {
  // Helper to create a minimal EmailMessage for tests.
  EmailMessage makeMessage({
    String id = 'msg-1',
    String accountId = 'acc-1',
    String mailboxPath = 'INBOX',
    int uid = 100,
    EmailAddress? from,
    List<EmailAddress>? to,
    String subject = 'Test Subject',
    DateTime? date,
    Set<EmailFlag>? flags,
    String? textPlain,
    String? textHtml,
    String snippet = 'Preview text',
    bool hasAttachments = false,
    int attachmentCount = 0,
    int size = 1024,
    String? messageId,
    String? inReplyTo,
    List<String> references = const [],
    String? threadId,
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
      to: to ??
          const [
            EmailAddress(address: 'recipient@test.com'),
          ],
      subject: subject,
      date: date ?? DateTime(2025, 6, 15, 10, 30),
      flags: flags ?? const {},
      textPlain: textPlain,
      textHtml: textHtml,
      snippet: snippet,
      hasAttachments: hasAttachments,
      attachmentCount: attachmentCount,
      size: size,
      messageId: messageId,
      inReplyTo: inReplyTo,
      references: references,
      threadId: threadId,
    );
  }

  group('EmailFlag', () {
    test('has all expected values', () {
      expect(EmailFlag.values, containsAll([
        EmailFlag.seen,
        EmailFlag.flagged,
        EmailFlag.answered,
        EmailFlag.draft,
        EmailFlag.deleted,
      ]));
    });
  });

  group('EmailMessage', () {
    group('constructor defaults', () {
      test('cc, bcc, replyTo default to empty lists', () {
        final msg = makeMessage();

        expect(msg.cc, isEmpty);
        expect(msg.bcc, isEmpty);
        expect(msg.replyTo, isEmpty);
      });

      test('flags default to empty set', () {
        final msg = makeMessage();

        expect(msg.flags, isEmpty);
      });

      test('references defaults to empty list', () {
        final msg = makeMessage();

        expect(msg.references, isEmpty);
      });
    });

    group('flag convenience getters', () {
      test('isRead returns true when seen flag is set', () {
        final msg = makeMessage(flags: {EmailFlag.seen});

        expect(msg.isRead, isTrue);
      });

      test('isRead returns false when seen flag is absent', () {
        final msg = makeMessage(flags: {});

        expect(msg.isRead, isFalse);
      });

      test('isFlagged returns true when flagged flag is set', () {
        final msg = makeMessage(flags: {EmailFlag.flagged});

        expect(msg.isFlagged, isTrue);
      });

      test('isAnswered returns true when answered flag is set', () {
        final msg = makeMessage(flags: {EmailFlag.answered});

        expect(msg.isAnswered, isTrue);
      });

      test('isDraft returns true when draft flag is set', () {
        final msg = makeMessage(flags: {EmailFlag.draft});

        expect(msg.isDraft, isTrue);
      });

      test('isDeleted returns true when deleted flag is set', () {
        final msg = makeMessage(flags: {EmailFlag.deleted});

        expect(msg.isDeleted, isTrue);
      });

      test('multiple flags can be set simultaneously', () {
        final msg = makeMessage(flags: {
          EmailFlag.seen,
          EmailFlag.flagged,
          EmailFlag.answered,
        });

        expect(msg.isRead, isTrue);
        expect(msg.isFlagged, isTrue);
        expect(msg.isAnswered, isTrue);
        expect(msg.isDraft, isFalse);
      });
    });

    group('relativeDate', () {
      test('returns "Now" for less than 1 minute ago', () {
        final msg = makeMessage(
          date: DateTime.now().subtract(const Duration(seconds: 30)),
        );

        expect(msg.relativeDate, 'Now');
      });

      test('returns minutes for less than 1 hour ago', () {
        final msg = makeMessage(
          date: DateTime.now().subtract(const Duration(minutes: 25)),
        );

        expect(msg.relativeDate, '25m');
      });

      test('returns hours for less than 24 hours ago', () {
        final msg = makeMessage(
          date: DateTime.now().subtract(const Duration(hours: 5)),
        );

        expect(msg.relativeDate, '5h');
      });

      test('returns days for less than 7 days ago', () {
        final msg = makeMessage(
          date: DateTime.now().subtract(const Duration(days: 3)),
        );

        expect(msg.relativeDate, '3d');
      });

      test('returns "Mon DD" for same year, older than 7 days', () {
        // Use a date in the current year but far enough in the past.
        final now = DateTime.now();
        final oldDate = DateTime(now.year, 1, 15);
        // Only test if oldDate is > 7 days ago.
        if (now.difference(oldDate).inDays > 7) {
          final msg = makeMessage(date: oldDate);

          expect(msg.relativeDate, 'Jan 15');
        }
      });

      test('returns "Mon DD, YYYY" for a different year', () {
        final msg = makeMessage(date: DateTime(2023, 3, 5));

        expect(msg.relativeDate, 'Mar 5, 2023');
      });
    });

    group('copyWith', () {
      test('returns identical message when no fields specified', () {
        final original = makeMessage();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.subject, original.subject);
        expect(copy.from, original.from);
        expect(copy.flags, original.flags);
      });

      test('overrides specified fields only', () {
        final original = makeMessage(subject: 'Old Subject');
        final copy = original.copyWith(
          subject: 'New Subject',
          flags: {EmailFlag.seen},
        );

        expect(copy.subject, 'New Subject');
        expect(copy.isRead, isTrue);
        expect(copy.id, original.id);
        expect(copy.from, original.from);
      });

      test('can override uid and mailboxPath', () {
        final original = makeMessage(uid: 100, mailboxPath: 'INBOX');
        final copy = original.copyWith(uid: 200, mailboxPath: 'Sent');

        expect(copy.uid, 200);
        expect(copy.mailboxPath, 'Sent');
      });
    });

    group('equality', () {
      test('two messages with same id are equal', () {
        final a = makeMessage(id: 'same-id', subject: 'Subject A');
        final b = makeMessage(id: 'same-id', subject: 'Subject B');

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('two messages with different ids are not equal', () {
        final a = makeMessage(id: 'id-1');
        final b = makeMessage(id: 'id-2');

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('includes subject and from', () {
        final msg = makeMessage(subject: 'Hello World');
        final str = msg.toString();

        expect(str, contains('Hello World'));
        expect(str, contains('EmailMessage'));
      });
    });
  });
}
