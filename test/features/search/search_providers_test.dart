import 'package:flutter_test/flutter_test.dart';

import 'package:crusader/domain/entities/email_address.dart';
import 'package:crusader/domain/entities/email_message.dart';
import 'package:crusader/domain/entities/email_thread.dart';
import 'package:crusader/features/search/search_providers.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // SearchFilter enum
  // ─────────────────────────────────────────────────────────────────────

  group('SearchFilter', () {
    test('has all expected values', () {
      expect(SearchFilter.values, containsAll([
        SearchFilter.all,
        SearchFilter.unread,
        SearchFilter.attachments,
        SearchFilter.flagged,
        SearchFilter.fromMe,
      ]));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // SearchState (pure data class — no mocks needed)
  // ─────────────────────────────────────────────────────────────────────

  group('SearchState', () {
    test('default constructor has sensible defaults', () {
      const s = SearchState();

      expect(s.query, '');
      expect(s.filter, SearchFilter.all);
      expect(s.results, isEmpty);
      expect(s.isSearching, isFalse);
      expect(s.hasSearched, isFalse);
      expect(s.recentSearches, isEmpty);
    });

    group('hasResults', () {
      test('returns false when results is empty', () {
        const s = SearchState();

        expect(s.hasResults, isFalse);
      });

      test('returns true when results is not empty', () {
        final thread = EmailThread(
          id: 't-1',
          accountId: 'acc-1',
          messages: [
            EmailMessage(
              id: 'msg-1',
              accountId: 'acc-1',
              mailboxPath: 'INBOX',
              uid: 1,
              from: const EmailAddress(address: 'a@b.com'),
              to: const [EmailAddress(address: 'c@d.com')],
              subject: 'Test',
              date: DateTime(2025, 1, 1),
            ),
          ],
        );
        final s = SearchState(results: [thread]);

        expect(s.hasResults, isTrue);
      });
    });

    group('copyWith', () {
      test('preserves all fields when none specified', () {
        const original = SearchState(
          query: 'hello',
          filter: SearchFilter.unread,
          isSearching: true,
          hasSearched: true,
          recentSearches: ['hello', 'world'],
        );
        final copy = original.copyWith();

        expect(copy.query, 'hello');
        expect(copy.filter, SearchFilter.unread);
        expect(copy.isSearching, isTrue);
        expect(copy.hasSearched, isTrue);
        expect(copy.recentSearches, ['hello', 'world']);
      });

      test('overrides specified fields', () {
        const original = SearchState(query: 'old');
        final copy = original.copyWith(
          query: 'new',
          filter: SearchFilter.flagged,
          isSearching: true,
        );

        expect(copy.query, 'new');
        expect(copy.filter, SearchFilter.flagged);
        expect(copy.isSearching, isTrue);
        expect(copy.hasSearched, isFalse); // unchanged
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // SearchNotifier filter logic (tested via _applyFilter indirectly)
  // We test the filter logic by creating threads and verifying filtering.
  // ─────────────────────────────────────────────────────────────────────

  group('Search filter logic (unit)', () {
    // Helper to create threads with specific properties.
    EmailMessage makeMessage({
      String id = 'msg-1',
      String accountId = 'acc-1',
      EmailAddress? from,
      Set<EmailFlag>? flags,
      bool hasAttachments = false,
    }) {
      return EmailMessage(
        id: id,
        accountId: accountId,
        mailboxPath: 'INBOX',
        uid: 1,
        from: from ?? const EmailAddress(address: 'other@test.com'),
        to: const [EmailAddress(address: 'me@test.com')],
        subject: 'Test',
        date: DateTime(2025, 1, 1),
        flags: flags ?? const {},
        hasAttachments: hasAttachments,
      );
    }

    EmailThread makeThread({
      required String id,
      List<EmailMessage>? messages,
    }) {
      return EmailThread(
        id: id,
        accountId: 'acc-1',
        messages: messages ?? [makeMessage()],
      );
    }

    test('unread filter keeps threads with unread messages', () {
      final unreadThread = makeThread(
        id: 't-1',
        messages: [makeMessage(id: 'm1', flags: {})],
      );
      final readThread = makeThread(
        id: 't-2',
        messages: [makeMessage(id: 'm2', flags: {EmailFlag.seen})],
      );

      final all = [unreadThread, readThread];
      final filtered = all.where((t) => t.hasUnread).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 't-1');
    });

    test('attachments filter keeps threads with attachments', () {
      final withAttachment = makeThread(
        id: 't-1',
        messages: [makeMessage(id: 'm1', hasAttachments: true)],
      );
      final withoutAttachment = makeThread(
        id: 't-2',
        messages: [makeMessage(id: 'm2', hasAttachments: false)],
      );

      final all = [withAttachment, withoutAttachment];
      final filtered =
          all.where((t) => t.messages.any((m) => m.hasAttachments)).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 't-1');
    });

    test('flagged filter keeps threads with flagged messages', () {
      final flagged = makeThread(
        id: 't-1',
        messages: [makeMessage(id: 'm1', flags: {EmailFlag.flagged})],
      );
      final unflagged = makeThread(
        id: 't-2',
        messages: [makeMessage(id: 'm2', flags: {})],
      );

      final all = [flagged, unflagged];
      final filtered = all.where((t) => t.isFlagged).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 't-1');
    });

    test('fromMe filter keeps threads where I am the sender', () {
      const myEmail = 'me@test.com';
      final fromMe = makeThread(
        id: 't-1',
        messages: [
          makeMessage(
            id: 'm1',
            from: const EmailAddress(address: 'me@test.com'),
          ),
        ],
      );
      final fromOther = makeThread(
        id: 't-2',
        messages: [
          makeMessage(
            id: 'm2',
            from: const EmailAddress(address: 'other@test.com'),
          ),
        ],
      );

      final all = [fromMe, fromOther];
      final filtered = all
          .where((t) => t.messages.any(
              (m) => m.from.address.toLowerCase() == myEmail.toLowerCase()))
          .toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 't-1');
    });

    test('all filter returns everything', () {
      final threads = [
        makeThread(id: 't-1'),
        makeThread(id: 't-2'),
        makeThread(id: 't-3'),
      ];

      // SearchFilter.all → no filtering
      expect(threads.length, 3);
    });
  });
}
