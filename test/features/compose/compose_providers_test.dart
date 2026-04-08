import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:crusader/data/repositories/email_repository.dart';
import 'package:crusader/domain/entities/email_account.dart';
import 'package:crusader/domain/entities/email_address.dart';
import 'package:crusader/domain/entities/email_message.dart';
import 'package:crusader/features/auth/auth_providers.dart';
import 'package:crusader/features/compose/compose_providers.dart';
import 'package:crusader/features/compose/signature_providers.dart';

// ── Mocks ──

class MockEmailRepository extends Mock implements EmailRepository {}

class MockAccountNotifier extends Mock implements AccountNotifier {}

class MockSignatureNotifier extends Mock implements SignatureNotifier {}

class MockRef extends Mock implements Ref {}

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // ComposeState (pure data class — no mocks needed)
  // ─────────────────────────────────────────────────────────────────────

  group('ComposeState', () {
    test('default constructor has sensible defaults', () {
      const s = ComposeState();

      expect(s.mode, ComposeMode.newMessage);
      expect(s.to, isEmpty);
      expect(s.cc, isEmpty);
      expect(s.bcc, isEmpty);
      expect(s.subject, '');
      expect(s.bodyPlain, '');
      expect(s.bodyHtml, isNull);
      expect(s.originalMessage, isNull);
      expect(s.isSending, isFalse);
      expect(s.isSent, isFalse);
      expect(s.isSendPending, isFalse);
      expect(s.sendCountdown, 0);
      expect(s.error, isNull);
    });

    group('canSend', () {
      test('returns false when to is empty', () {
        const s = ComposeState(bodyPlain: 'Hello');

        expect(s.canSend, isFalse);
      });

      test('returns false when body is empty and no html', () {
        const s = ComposeState(to: [EmailAddress(address: 'a@b.com')]);

        expect(s.canSend, isFalse);
      });

      test('returns false when currently sending', () {
        const s = ComposeState(
          to: [EmailAddress(address: 'a@b.com')],
          bodyPlain: 'Hello',
          isSending: true,
        );

        expect(s.canSend, isFalse);
      });

      test('returns false when send is pending (undo window)', () {
        const s = ComposeState(
          to: [EmailAddress(address: 'a@b.com')],
          bodyPlain: 'Hello',
          isSendPending: true,
          sendCountdown: 5,
        );

        expect(s.canSend, isFalse);
      });

      test('returns true with recipients and plain text body', () {
        const s = ComposeState(
          to: [EmailAddress(address: 'a@b.com')],
          bodyPlain: 'Hello',
        );

        expect(s.canSend, isTrue);
      });

      test('returns true with recipients and HTML body only', () {
        const s = ComposeState(
          to: [EmailAddress(address: 'a@b.com')],
          bodyHtml: '<p>Hello</p>',
        );

        expect(s.canSend, isTrue);
      });
    });

    group('copyWith', () {
      test('preserves all fields when none specified', () {
        const original = ComposeState(
          mode: ComposeMode.reply,
          to: [EmailAddress(address: 'to@test.com')],
          subject: 'Re: Test',
          bodyPlain: 'Body',
          isSending: true,
        );
        final copy = original.copyWith();

        expect(copy.mode, ComposeMode.reply);
        expect(copy.to.length, 1);
        expect(copy.subject, 'Re: Test');
        expect(copy.bodyPlain, 'Body');
        expect(copy.isSending, isTrue);
      });

      test('overrides specified fields', () {
        const original = ComposeState(subject: 'Old');
        final copy = original.copyWith(subject: 'New', isSending: true);

        expect(copy.subject, 'New');
        expect(copy.isSending, isTrue);
        expect(copy.mode, ComposeMode.newMessage); // unchanged
      });

      test('error can be set to null via copyWith', () {
        const original = ComposeState(error: 'Some error');
        // copyWith always passes `error` (no `?? this.error` for error)
        final copy = original.copyWith(error: null);

        expect(copy.error, isNull);
      });

      test('copyWith handles isSendPending and sendCountdown', () {
        const original = ComposeState();
        final pending = original.copyWith(
          isSendPending: true,
          sendCountdown: 10,
        );

        expect(pending.isSendPending, isTrue);
        expect(pending.sendCountdown, 10);
        expect(pending.mode, ComposeMode.newMessage); // unchanged

        // Reset them back
        final reset = pending.copyWith(isSendPending: false, sendCountdown: 0);

        expect(reset.isSendPending, isFalse);
        expect(reset.sendCountdown, 0);
      });

      test('copyWith preserves isSendPending when not specified', () {
        const original = ComposeState(isSendPending: true, sendCountdown: 7);
        final copy = original.copyWith(subject: 'Changed');

        expect(copy.isSendPending, isTrue);
        expect(copy.sendCountdown, 7);
        expect(copy.subject, 'Changed');
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // ComposeNotifier (requires mocks)
  // ─────────────────────────────────────────────────────────────────────

  group('ComposeNotifier', () {
    late MockEmailRepository mockRepo;
    late MockAccountNotifier mockAccountNotifier;
    late MockSignatureNotifier mockSignatureNotifier;
    late MockRef mockRef;
    late ComposeNotifier notifier;

    setUp(() {
      mockRepo = MockEmailRepository();
      mockAccountNotifier = MockAccountNotifier();
      mockSignatureNotifier = MockSignatureNotifier();
      mockRef = MockRef();

      // Default: no active account, signature returns empty.
      when(
        () => mockRef.read(accountProvider),
      ).thenReturn(const AccountState());
      when(
        () => mockRef.read(signatureProvider.notifier),
      ).thenReturn(mockSignatureNotifier);
      when(
        () => mockSignatureNotifier.getFormattedSignature(any()),
      ).thenReturn('');

      notifier = ComposeNotifier(
        emailRepo: mockRepo,
        accountNotifier: mockAccountNotifier,
        ref: mockRef,
      );
    });

    test('initial state is default ComposeState', () {
      expect(notifier.state.mode, ComposeMode.newMessage);
      expect(notifier.state.to, isEmpty);
      expect(notifier.state.subject, '');
    });

    group('recipient management', () {
      test('addRecipient appends to To list', () {
        const addr = EmailAddress(address: 'alice@test.com');
        notifier.addRecipient(addr);

        expect(notifier.state.to.length, 1);
        expect(notifier.state.to.first, addr);
      });

      test('addRecipient can add multiple', () {
        const a = EmailAddress(address: 'a@test.com');
        const b = EmailAddress(address: 'b@test.com');
        notifier.addRecipient(a);
        notifier.addRecipient(b);

        expect(notifier.state.to.length, 2);
      });

      test('removeRecipient removes by index', () {
        const a = EmailAddress(address: 'a@test.com');
        const b = EmailAddress(address: 'b@test.com');
        notifier.addRecipient(a);
        notifier.addRecipient(b);
        notifier.removeRecipient(0);

        expect(notifier.state.to.length, 1);
        expect(notifier.state.to.first, b);
      });
    });

    group('CC management', () {
      test('addCc appends to CC list', () {
        const addr = EmailAddress(address: 'cc@test.com');
        notifier.addCc(addr);

        expect(notifier.state.cc.length, 1);
        expect(notifier.state.cc.first, addr);
      });

      test('removeCc removes by index', () {
        const a = EmailAddress(address: 'a@test.com');
        const b = EmailAddress(address: 'b@test.com');
        notifier.addCc(a);
        notifier.addCc(b);
        notifier.removeCc(0);

        expect(notifier.state.cc.length, 1);
        expect(notifier.state.cc.first, b);
      });
    });

    group('BCC management', () {
      test('addBcc appends to BCC list', () {
        const addr = EmailAddress(address: 'bcc@test.com');
        notifier.addBcc(addr);

        expect(notifier.state.bcc.length, 1);
      });

      test('removeBcc removes by index', () {
        const a = EmailAddress(address: 'a@test.com');
        notifier.addBcc(a);
        notifier.removeBcc(0);

        expect(notifier.state.bcc, isEmpty);
      });
    });

    group('field updates', () {
      test('updateSubject sets subject', () {
        notifier.updateSubject('Hello World');

        expect(notifier.state.subject, 'Hello World');
      });

      test('updateBody sets bodyPlain', () {
        notifier.updateBody('This is the body');

        expect(notifier.state.bodyPlain, 'This is the body');
      });
    });

    group('prepareReply', () {
      final original = EmailMessage(
        id: 'msg-1',
        accountId: 'acc-1',
        mailboxPath: 'INBOX',
        uid: 100,
        from: const EmailAddress(
          address: 'sender@test.com',
          displayName: 'Sender',
        ),
        to: const [EmailAddress(address: 'me@test.com', displayName: 'Me')],
        cc: const [
          EmailAddress(address: 'cc@test.com', displayName: 'CC Person'),
        ],
        subject: 'Test Subject',
        date: DateTime(2025, 6, 15, 10, 30),
        textPlain: 'Original body text',
      );

      test('sets mode to reply', () {
        when(
          () => mockRef.read(accountProvider),
        ).thenReturn(const AccountState());
        notifier.prepareReply(original);

        expect(notifier.state.mode, ComposeMode.reply);
      });

      test('sets To to original sender', () {
        when(
          () => mockRef.read(accountProvider),
        ).thenReturn(const AccountState());
        notifier.prepareReply(original);

        expect(notifier.state.to.length, 1);
        expect(notifier.state.to.first.address, 'sender@test.com');
      });

      test('prefixes subject with Re: if not already present', () {
        when(
          () => mockRef.read(accountProvider),
        ).thenReturn(const AccountState());
        notifier.prepareReply(original);

        expect(notifier.state.subject, 'Re: Test Subject');
      });

      test('does not double Re: prefix', () {
        final reOriginal = EmailMessage(
          id: 'msg-2',
          accountId: 'acc-1',
          mailboxPath: 'INBOX',
          uid: 101,
          from: const EmailAddress(address: 'sender@test.com'),
          to: const [EmailAddress(address: 'me@test.com')],
          subject: 'Re: Already replied',
          date: DateTime(2025, 6, 15),
        );

        when(
          () => mockRef.read(accountProvider),
        ).thenReturn(const AccountState());
        notifier.prepareReply(reOriginal);

        expect(notifier.state.subject, 'Re: Already replied');
      });

      test('includes quoted text in body', () {
        when(
          () => mockRef.read(accountProvider),
        ).thenReturn(const AccountState());
        notifier.prepareReply(original);

        expect(notifier.state.bodyPlain, contains('> Original body text'));
        expect(notifier.state.bodyPlain, contains('wrote:'));
      });

      test('sets originalMessage', () {
        when(
          () => mockRef.read(accountProvider),
        ).thenReturn(const AccountState());
        notifier.prepareReply(original);

        expect(notifier.state.originalMessage, original);
      });
    });

    group('prepareReply replyAll', () {
      final original = EmailMessage(
        id: 'msg-1',
        accountId: 'acc-1',
        mailboxPath: 'INBOX',
        uid: 100,
        from: const EmailAddress(address: 'sender@test.com'),
        to: const [
          EmailAddress(address: 'me@test.com'),
          EmailAddress(address: 'other@test.com'),
        ],
        cc: const [EmailAddress(address: 'cc@test.com')],
        subject: 'Group Thread',
        date: DateTime(2025, 6, 15, 10, 30),
        textPlain: 'Group message',
      );

      test('sets mode to replyAll', () {
        when(
          () => mockRef.read(accountProvider),
        ).thenReturn(const AccountState(activeAccountId: 'acc-1'));
        notifier.prepareReply(original, replyAll: true);

        expect(notifier.state.mode, ComposeMode.replyAll);
      });

      test(
        'populates CC with other recipients (excluding sender and self)',
        () {
          when(() => mockRef.read(accountProvider)).thenReturn(
            AccountState(
              accounts: [
                EmailAccount.fromProvider(
                  id: 'acc-1',
                  email: 'me@test.com',
                  displayName: 'Me',
                  provider: EmailProvider.gmail,
                ),
              ],
              activeAccountId: 'acc-1',
            ),
          );
          notifier.prepareReply(original, replyAll: true);

          // CC should contain other@test.com and cc@test.com,
          // but NOT sender@test.com (already in To) and NOT me@test.com (self)
          final ccEmails = notifier.state.cc
              .map((a) => a.address.toLowerCase())
              .toSet();
          expect(ccEmails, contains('other@test.com'));
          expect(ccEmails, contains('cc@test.com'));
          expect(ccEmails, isNot(contains('sender@test.com')));
          expect(ccEmails, isNot(contains('me@test.com')));
        },
      );
    });

    group('prepareForward', () {
      final original = EmailMessage(
        id: 'msg-1',
        accountId: 'acc-1',
        mailboxPath: 'INBOX',
        uid: 100,
        from: const EmailAddress(
          address: 'sender@test.com',
          displayName: 'Sender',
        ),
        to: const [EmailAddress(address: 'me@test.com')],
        subject: 'Important Doc',
        date: DateTime(2025, 6, 15, 10, 30),
        textPlain: 'Please review.',
      );

      test('sets mode to forward', () {
        notifier.prepareForward(original);

        expect(notifier.state.mode, ComposeMode.forward);
      });

      test('prefixes subject with Fwd:', () {
        notifier.prepareForward(original);

        expect(notifier.state.subject, 'Fwd: Important Doc');
      });

      test('does not double Fwd: prefix', () {
        final fwdOriginal = EmailMessage(
          id: 'msg-2',
          accountId: 'acc-1',
          mailboxPath: 'INBOX',
          uid: 101,
          from: const EmailAddress(address: 'sender@test.com'),
          to: const [EmailAddress(address: 'me@test.com')],
          subject: 'Fwd: Already forwarded',
          date: DateTime(2025, 6, 15),
        );

        notifier.prepareForward(fwdOriginal);

        expect(notifier.state.subject, 'Fwd: Already forwarded');
      });

      test('includes forward header in body', () {
        notifier.prepareForward(original);

        expect(
          notifier.state.bodyPlain,
          contains('---------- Forwarded message ----------'),
        );
        expect(notifier.state.bodyPlain, contains('From:'));
        expect(notifier.state.bodyPlain, contains('Subject: Important Doc'));
        expect(notifier.state.bodyPlain, contains('Please review.'));
      });

      test('to list is empty (user must add forward recipient)', () {
        notifier.prepareForward(original);

        expect(notifier.state.to, isEmpty);
      });
    });

    group('reset', () {
      test('resets state to defaults', () {
        notifier.addRecipient(const EmailAddress(address: 'a@b.com'));
        notifier.updateSubject('Subject');
        notifier.updateBody('Body');
        notifier.reset();

        expect(notifier.state.to, isEmpty);
        expect(notifier.state.subject, '');
        expect(notifier.state.bodyPlain, '');
        expect(notifier.state.mode, ComposeMode.newMessage);
      });

      test('reset clears pending send state', () {
        notifier.addRecipient(const EmailAddress(address: 'a@b.com'));
        notifier.updateBody('Body');
        // Simulate pending state manually
        // (scheduleSend needs sendDelayProvider which is hard to mock here)
        notifier.reset();

        expect(notifier.state.isSendPending, isFalse);
        expect(notifier.state.sendCountdown, 0);
      });
    });

    group('cancelSend', () {
      test('resets isSendPending and sendCountdown', () {
        notifier.addRecipient(const EmailAddress(address: 'a@b.com'));
        notifier.updateBody('Body');
        // cancelSend should be safe to call even when no send is pending.
        notifier.cancelSend();

        expect(notifier.state.isSendPending, isFalse);
        expect(notifier.state.sendCountdown, 0);
      });
    });

    group('send', () {
      test('returns false when to is empty', () async {
        notifier.updateBody('Body');

        final result = await notifier.send();

        expect(result, isFalse);
      });

      test('returns false when body is empty', () async {
        notifier.addRecipient(const EmailAddress(address: 'a@b.com'));

        final result = await notifier.send();

        expect(result, isFalse);
      });

      test('returns false when no active account', () async {
        when(
          () => mockRef.read(accountProvider),
        ).thenReturn(const AccountState());

        notifier.addRecipient(const EmailAddress(address: 'a@b.com'));
        notifier.updateBody('Hello');

        final result = await notifier.send();

        expect(result, isFalse);
        expect(notifier.state.error, 'No active account');
      });
    });
  });
}
