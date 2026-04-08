/// Crusader — Widget Tests for ThreadTile
///
/// Tests rendering of thread data (sender, subject, snippet, date),
/// unread dot, flag star, attachment icon, conversation badge,
/// tap callbacks, selected state, and animations.
library;

import 'package:crusader/core/theme/theme.dart';
import 'package:crusader/domain/entities/email_address.dart';
import 'package:crusader/domain/entities/email_message.dart';
import 'package:crusader/domain/entities/email_thread.dart';
import 'package:crusader/presentation/widgets/thread_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] in a ProviderScope + MaterialApp with the dark Crusader theme.
Widget _themed(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: CrusaderTheme.dark(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

/// Creates a test email message with sensible defaults.
EmailMessage _msg({
  String id = 'msg-1',
  String accountId = 'acct-1',
  String mailboxPath = 'INBOX',
  int uid = 1,
  String fromAddr = 'alice@example.com',
  String? fromName = 'Alice Smith',
  String subject = 'Test Subject',
  String snippet = 'This is a preview snippet',
  Set<EmailFlag> flags = const {},
  bool hasAttachments = false,
  DateTime? date,
}) {
  return EmailMessage(
    id: id,
    accountId: accountId,
    mailboxPath: mailboxPath,
    uid: uid,
    from: EmailAddress(address: fromAddr, displayName: fromName),
    to: const [EmailAddress(address: 'bob@example.com', displayName: 'Bob')],
    subject: subject,
    date: date ?? DateTime.now().subtract(const Duration(hours: 2)),
    snippet: snippet,
    flags: flags,
    hasAttachments: hasAttachments,
  );
}

/// Creates a single-message thread.
EmailThread _thread({
  String id = 'thread-1',
  String accountId = 'acct-1',
  List<EmailMessage>? messages,
  EmailMessage? singleMessage,
}) {
  return EmailThread(
    id: id,
    accountId: accountId,
    messages: messages ?? [singleMessage ?? _msg()],
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Basic rendering
  // ═══════════════════════════════════════════════════════════════════════════
  group('ThreadTile — basic rendering', () {
    testWidgets('renders sender name', (tester) async {
      await tester.pumpWidget(_themed(
        ThreadTile(thread: _thread(), onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice Smith'), findsOneWidget);
    });

    testWidgets('renders subject line', (tester) async {
      await tester.pumpWidget(_themed(
        ThreadTile(thread: _thread(), onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Subject'), findsOneWidget);
    });

    testWidgets('renders snippet text', (tester) async {
      await tester.pumpWidget(_themed(
        ThreadTile(thread: _thread(), onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('This is a preview snippet'), findsOneWidget);
    });

    testWidgets('renders sender initial in avatar', (tester) async {
      await tester.pumpWidget(_themed(
        ThreadTile(thread: _thread(), onTap: () {}),
      ));
      await tester.pumpAndSettle();

      // 'A' for Alice Smith
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders relative date', (tester) async {
      await tester.pumpWidget(_themed(
        ThreadTile(thread: _thread(), onTap: () {}),
      ));
      await tester.pumpAndSettle();

      // 2 hours ago → "2h"
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('shows (No Subject) when subject is empty', (tester) async {
      final thread = _thread(
        singleMessage: _msg(subject: ''),
      );
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('(No Subject)'), findsOneWidget);
    });

    testWidgets('uses email address when displayName is null',
        (tester) async {
      final thread = _thread(
        singleMessage: _msg(fromName: null, fromAddr: 'noreply@service.com'),
      );
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('noreply@service.com'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Unread / read state
  // ═══════════════════════════════════════════════════════════════════════════
  group('ThreadTile — unread state', () {
    testWidgets('shows unread dot when message is unread', (tester) async {
      // No "seen" flag → unread
      final thread = _thread(singleMessage: _msg(flags: {}));
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      // The unread dot is a 6x6 Container with BoxShape.circle
      // We verify via the BoxDecoration's shape
      final decoratedContainers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          return dec.shape == BoxShape.circle;
        }
        return false;
      });
      // Should find at least one circle container (the unread dot)
      // The avatar also has a circle via border, but it uses a gradient
      // so BoxShape is not BoxShape.circle on the container itself
      expect(decoratedContainers, findsWidgets);
    });

    testWidgets('hides unread dot when message is read', (tester) async {
      final thread =
          _thread(singleMessage: _msg(flags: {EmailFlag.seen}));
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      // When read, there should be no circle-shaped BoxDecoration
      // (the unread dot is a Container with BoxShape.circle and the
      // accent primary color).
      final unreadDots = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          return dec.shape == BoxShape.circle && dec.boxShadow != null;
        }
        return false;
      });
      expect(unreadDots, findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Flags — attachment & starred
  // ═══════════════════════════════════════════════════════════════════════════
  group('ThreadTile — icons', () {
    testWidgets('shows attachment icon when hasAttachments', (tester) async {
      final thread = _thread(
        singleMessage: _msg(hasAttachments: true),
      );
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
    });

    testWidgets('hides attachment icon when no attachments', (tester) async {
      final thread = _thread(
        singleMessage: _msg(hasAttachments: false),
      );
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.attach_file_rounded), findsNothing);
    });

    testWidgets('shows star icon when flagged', (tester) async {
      final thread = _thread(
        singleMessage: _msg(flags: {EmailFlag.flagged}),
      );
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('hides star icon when not flagged', (tester) async {
      final thread = _thread(singleMessage: _msg(flags: {}));
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('shows both attachment and star icons', (tester) async {
      final thread = _thread(
        singleMessage: _msg(
          hasAttachments: true,
          flags: {EmailFlag.flagged},
        ),
      );
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Conversation badge (message count)
  // ═══════════════════════════════════════════════════════════════════════════
  group('ThreadTile — conversation badge', () {
    testWidgets('shows message count for multi-message threads',
        (tester) async {
      final thread = _thread(
        messages: [
          _msg(id: 'm1'),
          _msg(id: 'm2'),
          _msg(id: 'm3'),
        ],
      );
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hides message count for single-message threads',
        (tester) async {
      final thread = _thread(singleMessage: _msg());
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      // Single-message thread shouldn't show count badge
      expect(find.text('1'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Tap interactions
  // ═══════════════════════════════════════════════════════════════════════════
  group('ThreadTile — interactions', () {
    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(_themed(
        ThreadTile(
          thread: _thread(),
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      // Tap on the InkWell inside ThreadTile (animation wrapper may
      // offset the outer widget).
      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long-pressed', (tester) async {
      var longPressed = false;

      await tester.pumpWidget(_themed(
        ThreadTile(
          thread: _thread(),
          onTap: () {},
          onLongPress: () => longPressed = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(InkWell).first);
      expect(longPressed, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Selected state
  // ═══════════════════════════════════════════════════════════════════════════
  group('ThreadTile — selected state', () {
    testWidgets('applies selection styling when isSelected = true',
        (tester) async {
      await tester.pumpWidget(_themed(
        ThreadTile(
          thread: _thread(),
          onTap: () {},
          isSelected: true,
        ),
      ));
      await tester.pumpAndSettle();

      // The AnimatedContainer should have a border when selected.
      // Find the AnimatedContainer and check its decoration.
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.color, isNotNull);
      // The color should have non-zero alpha (selection highlight)
      expect(decoration.color!.a, greaterThan(0));
    });

    testWidgets('has transparent background when not selected',
        (tester) async {
      await tester.pumpWidget(_themed(
        ThreadTile(
          thread: _thread(),
          onTap: () {},
          isSelected: false,
        ),
      ));
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.transparent));
      expect(decoration.border, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Animation
  // ═══════════════════════════════════════════════════════════════════════════
  group('ThreadTile — animation', () {
    testWidgets('completes entrance animation', (tester) async {
      await tester.pumpWidget(_themed(
        ThreadTile(
          thread: _thread(),
          onTap: () {},
          animationDelay: Duration.zero,
        ),
      ));

      // Pump enough frames for the 300ms fade+slide animation
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // After animation settles, the widget should be fully visible
      expect(find.byType(ThreadTile), findsOneWidget);
      expect(find.text('Alice Smith'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Re: / Fwd: subject stripping
  // ═══════════════════════════════════════════════════════════════════════════
  group('ThreadTile — subject display', () {
    testWidgets('strips Re: prefix from subject', (tester) async {
      final thread = _thread(
        singleMessage: _msg(subject: 'Re: Hello World'),
      );
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      // EmailThread.subject strips one Re: prefix
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('strips Fwd: prefix from subject', (tester) async {
      final thread = _thread(
        singleMessage: _msg(subject: 'Fwd: Important Doc'),
      );
      await tester.pumpWidget(_themed(
        ThreadTile(thread: thread, onTap: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Important Doc'), findsOneWidget);
    });
  });
}
