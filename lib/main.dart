/// Crusader — Main Entry Point
///
/// The sleek, modern email client that finally feels good to use.
///
/// Dark-mode first. Glassmorphism. Zero bloat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/router.dart';
import 'core/di/theme_provider.dart';
import 'core/theme/theme.dart';
import 'data/datasources/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: CrusaderApp()));
}

/// Root widget — wires theme, router, and Riverpod.
class CrusaderApp extends ConsumerWidget {
  const CrusaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accentIndex = ref.watch(accentColorProvider);
    final fontFamily = ref.watch(fontFamilyProvider);

    return MaterialApp.router(
      title: 'Crusader',
      debugShowCheckedModeBanner: false,

      // ── Theme (dark-mode first) ──
      theme: CrusaderTheme.light(
        accentIndex: accentIndex,
        fontFamily: fontFamily,
      ),
      darkTheme: CrusaderTheme.dark(
        accentIndex: accentIndex,
        fontFamily: fontFamily,
      ),
      themeMode: themeMode,

      // ── Router ──
      routerConfig: appRouter,
    );
  }
}
