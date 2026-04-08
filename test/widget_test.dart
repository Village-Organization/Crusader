import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crusader/main.dart';

void main() {
  testWidgets('Crusader app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CrusaderApp()),
    );
    await tester.pumpAndSettle();

    // Verify that the app renders with the Crusader branding.
    expect(find.text('Inbox'), findsWidgets);
  });
}
