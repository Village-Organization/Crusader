/// Crusader — App Router
///
/// go_router configuration with typed routes.
/// Shell route wraps the main layout (sidebar + content on desktop,
/// bottom nav on mobile).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/layouts/app_shell.dart';
import '../../presentation/screens/add_account_screen.dart';
import '../../presentation/screens/compose_screen.dart';
import '../../presentation/screens/inbox_screen.dart';
import '../../presentation/screens/search_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/thread_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route Paths
// ─────────────────────────────────────────────────────────────────────────────

abstract final class CrusaderRoutes {
  static const String inbox = '/';
  static const String compose = '/compose';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String addAccount = '/add-account';
  static const String thread = '/thread/:threadId';
}

// ─────────────────────────────────────────────────────────────────────────────
// Router Configuration
// ─────────────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: CrusaderRoutes.inbox,
  routes: [
    // ── Add Account (full-screen, outside shell) ──
    GoRoute(
      path: CrusaderRoutes.addAccount,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const AddAccountScreen(),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    ),

    // ── Thread Detail (full-screen, outside shell) ──
    GoRoute(
      path: '/thread/:threadId',
      pageBuilder: (context, state) {
        final threadId = state.pathParameters['threadId']!;
        return CustomTransitionPage(
          child: ThreadDetailScreen(threadId: threadId),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        );
      },
    ),

    // ── Main Shell ──
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: CrusaderRoutes.inbox,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InboxScreen(),
          ),
        ),
        GoRoute(
          path: CrusaderRoutes.compose,
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const ComposeScreen(),
            transitionsBuilder: (context, animation, _, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
          ),
        ),
        GoRoute(
          path: CrusaderRoutes.search,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchScreen(),
          ),
        ),
        GoRoute(
          path: CrusaderRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);
