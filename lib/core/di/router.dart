/// Crusader — App Router
///
/// go_router configuration with typed routes.
/// Shell route wraps the main layout (sidebar + content on desktop,
/// bottom nav on mobile).
///
/// All routes use polished transitions:
/// - Sidebar nav routes: quick crossfade (no jarring hard cuts)
/// - Compose: slide-up + fade (modal feel)
/// - Thread detail: slide-right + fade (drill-in feel)
/// - Add account: slide-up + fade (overlay feel)
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
// Transition Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Quick crossfade for sidebar navigation routes (Inbox, Search, Settings).
/// Keeps the shell stable while content swaps smoothly.
CustomTransitionPage<void> _crossfadePage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// Slide-up + fade for modal-like routes (Compose).
CustomTransitionPage<void> _slideUpPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, _, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
  );
}

/// Slide-right + fade for drill-in routes (Thread Detail).
CustomTransitionPage<void> _slideRightPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      );
    },
  );
}

/// Scale-fade for overlay routes (Add Account).
CustomTransitionPage<void> _scaleFadePage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
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
      pageBuilder: (context, state) => _scaleFadePage(const AddAccountScreen()),
    ),

    // ── Thread Detail (full-screen, outside shell) ──
    GoRoute(
      path: '/thread/:threadId',
      pageBuilder: (context, state) {
        final threadId = state.pathParameters['threadId']!;
        return _slideRightPage(ThreadDetailScreen(threadId: threadId));
      },
    ),

    // ── Main Shell ──
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: CrusaderRoutes.inbox,
          pageBuilder: (context, state) => _crossfadePage(const InboxScreen()),
        ),
        GoRoute(
          path: CrusaderRoutes.compose,
          pageBuilder: (context, state) => _slideUpPage(const ComposeScreen()),
        ),
        GoRoute(
          path: CrusaderRoutes.search,
          pageBuilder: (context, state) => _crossfadePage(const SearchScreen()),
        ),
        GoRoute(
          path: CrusaderRoutes.settings,
          pageBuilder: (context, state) =>
              _crossfadePage(const SettingsScreen()),
        ),
      ],
    ),
  ],
);
