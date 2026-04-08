/// Crusader — Widget Tests for GlassPanel & GlassIconButton
///
/// Tests structural rendering, theming, custom parameters,
/// tap interactions, and tooltip display.
library;

import 'package:crusader/core/theme/glass_theme.dart';
import 'package:crusader/core/theme/theme.dart';
import 'package:crusader/presentation/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] in a MaterialApp with the dark Crusader theme.
Widget _themed(Widget child) {
  return MaterialApp(
    theme: CrusaderTheme.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // GlassPanel
  // ═══════════════════════════════════════════════════════════════════════════
  group('GlassPanel', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(_themed(
        const GlassPanel(child: Text('Hello Crusader')),
      ));

      expect(find.text('Hello Crusader'), findsOneWidget);
    });

    testWidgets('contains BackdropFilter for blur effect', (tester) async {
      await tester.pumpWidget(_themed(
        const GlassPanel(child: SizedBox.shrink()),
      ));

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('contains ClipRRect for border radius', (tester) async {
      await tester.pumpWidget(_themed(
        const GlassPanel(child: SizedBox.shrink()),
      ));

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('uses theme defaults when no overrides provided',
        (tester) async {
      await tester.pumpWidget(_themed(
        const GlassPanel(child: Text('Default')),
      ));

      // BackdropFilter should use theme's blurSigma (24.0 for dark)
      final backdrop =
          tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      final filter = backdrop.filter;
      // The filter exists — confirms backdrop blur is applied
      expect(filter, isNotNull);

      // Container should use theme colors
      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(CrusaderGlassTheme.dark().panelColor));
    });

    testWidgets('applies custom borderRadius', (tester) async {
      await tester.pumpWidget(_themed(
        const GlassPanel(borderRadius: 32, child: SizedBox.shrink()),
      ));

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(
        clipRRect.borderRadius,
        equals(BorderRadius.circular(32)),
      );
    });

    testWidgets('applies custom color override', (tester) async {
      const customColor = Color(0xFF112233);

      await tester.pumpWidget(_themed(
        const GlassPanel(color: customColor, child: Text('Colored')),
      ));

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(customColor));
    });

    testWidgets('applies custom borderColor override', (tester) async {
      const customBorder = Color(0xFFAABBCC);

      await tester.pumpWidget(_themed(
        const GlassPanel(borderColor: customBorder, child: SizedBox.shrink()),
      ));

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(
        (decoration.border! as Border).top.color,
        equals(customBorder),
      );
    });

    testWidgets('applies custom width and height', (tester) async {
      await tester.pumpWidget(_themed(
        const GlassPanel(
          width: 200,
          height: 100,
          child: SizedBox.shrink(),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).last);
      expect(container.constraints?.maxWidth, equals(200));
      expect(container.constraints?.maxHeight, equals(100));
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(_themed(
        const GlassPanel(
          padding: EdgeInsets.all(32),
          child: SizedBox.shrink(),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).last);
      expect(container.padding, equals(const EdgeInsets.all(32)));
    });

    testWidgets('uses default padding of 16 when none specified',
        (tester) async {
      await tester.pumpWidget(_themed(
        const GlassPanel(child: SizedBox.shrink()),
      ));

      final container = tester.widget<Container>(find.byType(Container).last);
      expect(container.padding, equals(const EdgeInsets.all(16)));
    });

    testWidgets('has box shadows for depth and highlight', (tester) async {
      await tester.pumpWidget(_themed(
        const GlassPanel(child: SizedBox.shrink()),
      ));

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      // Should have 2 shadows: outer depth + inner highlight
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, equals(2));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GlassIconButton
  // ═══════════════════════════════════════════════════════════════════════════
  group('GlassIconButton', () {
    testWidgets('renders the icon', (tester) async {
      await tester.pumpWidget(_themed(
        GlassIconButton(
          icon: Icons.star,
          onPressed: () {},
        ),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(_themed(
        GlassIconButton(
          icon: Icons.star,
          onPressed: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(GlassIconButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      await tester.pumpWidget(_themed(
        GlassIconButton(
          icon: Icons.delete,
          onPressed: () {},
          tooltip: 'Delete',
        ),
      ));

      expect(find.byType(Tooltip), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('Delete'));
    });

    testWidgets('does not show tooltip when not provided', (tester) async {
      await tester.pumpWidget(_themed(
        GlassIconButton(
          icon: Icons.star,
          onPressed: () {},
        ),
      ));

      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('uses custom size', (tester) async {
      await tester.pumpWidget(_themed(
        GlassIconButton(
          icon: Icons.star,
          onPressed: () {},
          size: 48,
        ),
      ));

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(SizedBox),
        ),
      );
      final outerBox = sizedBoxes.first;
      expect(outerBox.width, equals(48));
      expect(outerBox.height, equals(48));
    });

    testWidgets('uses custom iconSize', (tester) async {
      await tester.pumpWidget(_themed(
        GlassIconButton(
          icon: Icons.star,
          onPressed: () {},
          iconSize: 24,
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.size, equals(24));
    });

    testWidgets('uses default size 36 and iconSize 18', (tester) async {
      await tester.pumpWidget(_themed(
        GlassIconButton(
          icon: Icons.star,
          onPressed: () {},
        ),
      ));

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(SizedBox),
        ),
      );
      final outerBox = sizedBoxes.first;
      expect(outerBox.width, equals(36));
      expect(outerBox.height, equals(36));

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.size, equals(18));
    });

    testWidgets('contains InkWell for tap feedback', (tester) async {
      await tester.pumpWidget(_themed(
        GlassIconButton(
          icon: Icons.star,
          onPressed: () {},
        ),
      ));

      expect(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
    });

    testWidgets('InkWell uses glass theme colors', (tester) async {
      await tester.pumpWidget(_themed(
        GlassIconButton(
          icon: Icons.star,
          onPressed: () {},
        ),
      ));

      final glass = CrusaderGlassTheme.dark();
      final inkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byType(GlassIconButton),
          matching: find.byType(InkWell),
        ),
      );

      expect(inkWell.hoverColor, equals(glass.panelColor));
      expect(inkWell.splashColor, equals(glass.panelHighlightColor));
    });
  });
}
