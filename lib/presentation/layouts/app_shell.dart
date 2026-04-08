/// Crusader — App Shell Layout
///
/// Responsive shell that wraps all routes:
/// - Desktop (Windows): Bento-grid sidebar + content pane
/// - Mobile (iOS): Bottom navigation bar
///
/// The desktop sidebar includes: brand, compose button, mailbox folders
/// with unread counts, nav items, keyboard shortcut hints, and account
/// switcher.
///
/// Global keyboard shortcuts are handled via [_GlobalShortcutHandler].
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/router.dart';
import '../../core/di/theme_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/entities/mailbox.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/inbox/inbox_providers.dart';
import '../widgets/glass_components.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Navigation Items
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.shortcut,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String? shortcut;
}

const _navItems = [
  _NavItem(
    icon: Icons.inbox_outlined,
    activeIcon: Icons.inbox_rounded,
    label: 'Inbox',
    route: CrusaderRoutes.inbox,
    shortcut: 'G I',
  ),
  _NavItem(
    icon: Icons.search_outlined,
    activeIcon: Icons.search_rounded,
    label: 'Search',
    route: CrusaderRoutes.search,
    shortcut: '/',
  ),
  _NavItem(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Settings',
    route: CrusaderRoutes.settings,
    shortcut: 'G S',
  ),
];

/// Mailbox icon mapping by role.
IconData _mailboxIcon(Mailbox mailbox) {
  if (mailbox.isInbox) return Icons.inbox_rounded;
  if (mailbox.isSent) return Icons.send_rounded;
  if (mailbox.isDrafts) return Icons.edit_note_rounded;
  if (mailbox.isTrash) return Icons.delete_outline_rounded;
  if (mailbox.isArchive) return Icons.archive_outlined;
  if (mailbox.isJunk) return Icons.report_gmailerrorred_outlined;
  return Icons.folder_outlined;
}

// ─────────────────────────────────────────────────────────────────────────────
// App Shell
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final shell = _isDesktop
        ? _DesktopShell(child: child)
        : _MobileShell(child: child) as Widget;

    // Wrap with global keyboard shortcuts (desktop only).
    if (_isDesktop) {
      return _GlobalShortcutHandler(child: shell);
    }
    return shell;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global Keyboard Shortcut Handler
// ─────────────────────────────────────────────────────────────────────────────

/// Handles global keyboard shortcuts across the app.
///
/// Single-key shortcuts:
/// - `C` or `Ctrl+N` — Compose new email
/// - `/` or `Ctrl+K` — Focus search
/// - `?` — Show keyboard shortcuts overlay
///
/// Two-key sequences (Vim/Superhuman style):
/// - `G` then `I` — Go to Inbox
/// - `G` then `S` — Go to Settings
class _GlobalShortcutHandler extends ConsumerStatefulWidget {
  const _GlobalShortcutHandler({required this.child});

  final Widget child;

  @override
  ConsumerState<_GlobalShortcutHandler> createState() =>
      _GlobalShortcutHandlerState();
}

class _GlobalShortcutHandlerState
    extends ConsumerState<_GlobalShortcutHandler> {
  /// Whether we're in a "G" prefix mode (waiting for second key).
  bool _gPrefixActive = false;
  Timer? _gPrefixTimer;

  @override
  void dispose() {
    _gPrefixTimer?.cancel();
    super.dispose();
  }

  void _resetGPrefix() {
    _gPrefixTimer?.cancel();
    setState(() => _gPrefixActive = false);
  }

  void _activateGPrefix() {
    setState(() => _gPrefixActive = true);
    // Auto-reset after 1s if no second key pressed.
    _gPrefixTimer?.cancel();
    _gPrefixTimer = Timer(const Duration(seconds: 1), _resetGPrefix);
  }

  bool _isModifierPressed(KeyEvent event) {
    return HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed;
  }

  bool _isControlOnly(KeyEvent event) {
    return HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isAltPressed;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Check if a text input field has focus.
    final focusedWidget = FocusManager.instance.primaryFocus;
    if (focusedWidget != null) {
      // Walk up the context tree to see if there's an EditableText ancestor.
      final context = focusedWidget.context;
      if (context != null) {
        bool isEditing = false;
        context.visitAncestorElements((element) {
          if (element.widget is EditableText) {
            isEditing = true;
            return false;
          }
          return true;
        });
        if (isEditing) {
          // Allow Ctrl+K and Ctrl+N even in text fields.
          if (_isControlOnly(event)) {
            if (event.logicalKey == LogicalKeyboardKey.keyK) {
              GoRouter.of(this.context).go(CrusaderRoutes.search);
              _resetGPrefix();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.keyN) {
              GoRouter.of(this.context).go(CrusaderRoutes.compose);
              _resetGPrefix();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        }
      }
    }

    // ── Ctrl+key shortcuts (work everywhere) ──
    if (_isControlOnly(event)) {
      if (event.logicalKey == LogicalKeyboardKey.keyN) {
        GoRouter.of(context).go(CrusaderRoutes.compose);
        _resetGPrefix();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyK) {
        GoRouter.of(context).go(CrusaderRoutes.search);
        _resetGPrefix();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyB) {
        ref.read(sidebarCollapsedProvider.notifier).toggle();
        _resetGPrefix();
        return KeyEventResult.handled;
      }
    }

    // ── Don't process single-key shortcuts if modifier is held ──
    if (_isModifierPressed(event)) return KeyEventResult.ignored;

    // ── Two-key sequences: G-prefix ──
    if (_gPrefixActive) {
      _resetGPrefix();
      if (event.logicalKey == LogicalKeyboardKey.keyI) {
        GoRouter.of(context).go(CrusaderRoutes.inbox);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        GoRouter.of(context).go(CrusaderRoutes.settings);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // ── Single-key shortcuts ──
    if (event.logicalKey == LogicalKeyboardKey.keyG) {
      _activateGPrefix();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyC) {
      GoRouter.of(context).go(CrusaderRoutes.compose);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.slash) {
      GoRouter.of(context).go(CrusaderRoutes.search);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.question ||
        (event.logicalKey == LogicalKeyboardKey.slash &&
            HardwareKeyboard.instance.isShiftPressed)) {
      _showShortcutsOverlay(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _showShortcutsOverlay(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) =>
          _KeyboardShortcutsDialog(accents: accents, glass: glass),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keyboard Shortcuts Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _KeyboardShortcutsDialog extends StatelessWidget {
  const _KeyboardShortcutsDialog({required this.accents, required this.glass});

  final CrusaderAccentTheme accents;
  final CrusaderGlassTheme glass;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
          backgroundColor: CrusaderBlacks.elevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: glass.panelBorderColor,
              width: glass.borderWidth,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.keyboard_rounded,
                        size: 20,
                        color: accents.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Keyboard Shortcuts',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: CrusaderGrays.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const GlassDivider(),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shortcutSection('Navigation', [
                            _shortcutRow('G then I', 'Go to Inbox'),
                            _shortcutRow('G then S', 'Go to Settings'),
                            _shortcutRow('/', 'Search'),
                            _shortcutRow('C', 'Compose'),
                          ], textTheme),
                          const SizedBox(height: 16),
                          _shortcutSection('Actions', [
                            _shortcutRow('Ctrl+N', 'New email'),
                            _shortcutRow('Ctrl+K', 'Quick search'),
                            _shortcutRow('Ctrl+B', 'Toggle sidebar'),
                            _shortcutRow('Ctrl+Enter', 'Send email'),
                            _shortcutRow('?', 'Show shortcuts'),
                          ], textTheme),
                          const SizedBox(height: 16),
                          _shortcutSection('Inbox', [
                            _shortcutRow('J / K', 'Next / Previous'),
                            _shortcutRow('Enter', 'Open thread'),
                            _shortcutRow('E', 'Archive'),
                            _shortcutRow('#', 'Delete'),
                            _shortcutRow('R', 'Reply'),
                            _shortcutRow('F', 'Forward'),
                            _shortcutRow('S', 'Star / Flag'),
                          ], textTheme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _shortcutSection(
    String title,
    List<Widget> rows,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: CrusaderGrays.muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget _shortcutRow(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: KeyboardShortcutBadge(shortcut: shortcut),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: CrusaderGrays.primary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Shell — Sidebar + Content
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopShell extends ConsumerStatefulWidget {
  const _DesktopShell({required this.child});

  final Widget child;

  @override
  ConsumerState<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<_DesktopShell> {
  /// Whether the mouse is hovering over the sidebar area (for expand-on-hover).
  bool _isHovering = false;

  static const _collapsedWidth = 56.0;
  static const _expandedWidth = 240.0;

  @override
  Widget build(BuildContext context) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    // When pinned open, the sidebar takes full expanded width in the row.
    // When collapsed, sidebar is the icon rail. On hover, an overlay expands.
    final showHoverOverlay = isCollapsed && _isHovering;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Main row: sidebar rail/expanded + divider + content ──
          Row(
            children: [
              // Sidebar: either collapsed rail or pinned expanded
              if (isCollapsed)
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovering = true),
                  onExit: (_) => setState(() => _isHovering = false),
                  child: _DesktopSidebar(
                    width: _collapsedWidth,
                    isCollapsed: true,
                  ),
                )
              else
                _DesktopSidebar(width: _expandedWidth, isCollapsed: false),

              // Divider
              Container(
                width: 1,
                color: CrusaderGrays.border.withValues(alpha: 0.5),
              ),

              // Main content
              Expanded(child: widget.child),
            ],
          ),

          // ── Hover overlay: expanded sidebar floating over content ──
          if (showHoverOverlay)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      elevation: 8,
                      shadowColor: Colors.black54,
                      color: Colors.transparent,
                      child: _DesktopSidebar(
                        width: _expandedWidth,
                        isCollapsed: false,
                      ),
                    ),
                    // Subtle shadow edge
                    Container(
                      width: 1,
                      color: CrusaderGrays.border.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends ConsumerStatefulWidget {
  const _DesktopSidebar({this.width = 240, this.isCollapsed = false});

  final double width;
  final bool isCollapsed;

  @override
  ConsumerState<_DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends ConsumerState<_DesktopSidebar> {
  bool _isComposeHovered = false;
  bool _hasAnimated = false;

  /// Tracks which accounts are expanded in the sidebar.
  final Set<String> _expandedAccounts = {};

  @override
  void initState() {
    super.initState();
    // Expand the active account by default after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeId = ref.read(accountProvider).activeAccountId;
      if (activeId != null && mounted) {
        setState(() => _expandedAccounts.add(activeId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;
    final textTheme = Theme.of(context).textTheme;
    final location = GoRouterState.of(context).uri.path;

    final accountState = ref.watch(accountProvider);
    final accounts = accountState.accounts;
    final activeAccount = accountState.activeAccount;
    final mailboxes = ref.watch(inboxProvider.select((s) => s.mailboxes));
    final selectedMailbox = ref.watch(
      inboxProvider.select((s) => s.selectedMailbox),
    );
    final isSyncing = ref.watch(inboxProvider.select((s) => s.isSyncing));
    final unreadCount = ref.watch(inboxProvider.select((s) => s.unreadCount));

    // Only animate on first build.
    final shouldAnimate = !_hasAnimated;
    if (!_hasAnimated) _hasAnimated = true;

    final collapsed = widget.isCollapsed;

    return ClipRect(
      child: Container(
        width: widget.width,
        padding: EdgeInsets.fromLTRB(
          collapsed ? 8 : 12,
          12,
          collapsed ? 8 : 12,
          12,
        ),
        decoration: BoxDecoration(
          color: collapsed
              ? CrusaderBlacks.softBlack.withValues(alpha: 0.6)
              : CrusaderBlacks.deepBlack,
        ),
        child: Column(
          crossAxisAlignment: collapsed
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            // ── Brand Header ──
            Builder(
              builder: (context) {
                Widget brandHeader = Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: collapsed ? 0 : 8,
                    vertical: 10,
                  ),
                  child: collapsed
                      ? Tooltip(
                          message: 'Crusader',
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [accents.primary, accents.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                gradient: LinearGradient(
                                  colors: [accents.primary, accents.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Crusader',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.clip,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                );
                if (shouldAnimate) {
                  brandHeader = brandHeader
                      .animate()
                      .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                      .slideX(begin: -0.08, end: 0, duration: 350.ms);
                }
                return brandHeader;
              },
            ),

            const SizedBox(height: 16),

            // ── Compose Button ──
            Builder(
              builder: (context) {
                Widget composeButton = Padding(
                  padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 4),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isComposeHovered = true),
                    onExit: (_) => setState(() => _isComposeHovered = false),
                    child: GestureDetector(
                      onTap: () => context.go(CrusaderRoutes.compose),
                      child: collapsed
                          ? Tooltip(
                              message: 'Compose (C)',
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    colors: _isComposeHovered
                                        ? [
                                            accents.primary,
                                            accents.secondary.withValues(
                                              alpha: 0.8,
                                            ),
                                          ]
                                        : [
                                            accents.primary.withValues(
                                              alpha: 0.85,
                                            ),
                                            accents.secondary.withValues(
                                              alpha: 0.65,
                                            ),
                                          ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: _isComposeHovered
                                      ? [
                                          BoxShadow(
                                            color: accents.primaryGlow
                                                .withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            spreadRadius: -3,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: accents.primaryGlow
                                                .withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            spreadRadius: -3,
                                          ),
                                        ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: _isComposeHovered
                                      ? [
                                          accents.primary,
                                          accents.secondary.withValues(
                                            alpha: 0.8,
                                          ),
                                        ]
                                      : [
                                          accents.primary.withValues(
                                            alpha: 0.85,
                                          ),
                                          accents.secondary.withValues(
                                            alpha: 0.65,
                                          ),
                                        ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: _isComposeHovered
                                    ? [
                                        BoxShadow(
                                          color: accents.primaryGlow.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 16,
                                          spreadRadius: -4,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: accents.primaryGlow.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: -4,
                                        ),
                                      ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Compose',
                                      style: textTheme.titleSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  KeyboardShortcutBadge(shortcut: 'C'),
                                ],
                              ),
                            ),
                    ),
                  ),
                );
                if (shouldAnimate) {
                  composeButton = composeButton
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 50.ms)
                      .slideX(begin: -0.05, end: 0, duration: 350.ms);
                }
                return composeButton;
              },
            ),

            const SizedBox(height: 16),

            // ── Scrollable middle section ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: collapsed
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    // ── Accounts + Mailboxes ──
                    if (accounts.isNotEmpty) ...[
                      if (!collapsed)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ACCOUNTS',
                            style: textTheme.labelSmall?.copyWith(
                              color: CrusaderGrays.muted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      if (!collapsed) const SizedBox(height: 6),

                      // ── Unified Inbox (All Inboxes) ──
                      if (accounts.length > 1) ...[
                        Builder(
                          builder: (context) {
                            final isUnified = ref.watch(
                              inboxProvider.select((s) => s.isUnifiedInbox),
                            );
                            final totalUnread =
                                mailboxes
                                    .where(
                                      (m) =>
                                          m.name.toUpperCase() == 'INBOX' ||
                                          m.role == MailboxRole.inbox,
                                    )
                                    .fold<int>(
                                      0,
                                      (sum, m) => sum + m.unseenMessages,
                                    ) +
                                (isUnified ? 0 : unreadCount);
                            final displayUnread = isUnified
                                ? unreadCount
                                : totalUnread;

                            Widget allInboxes = collapsed
                                ? _CollapsedNavIcon(
                                    icon: Icons.all_inbox_rounded,
                                    tooltip: 'All Inboxes',
                                    isActive:
                                        isUnified &&
                                        location == CrusaderRoutes.inbox,
                                    accents: accents,
                                    badgeCount: displayUnread,
                                    onTap: () {
                                      if (location != CrusaderRoutes.inbox) {
                                        context.go(CrusaderRoutes.inbox);
                                      }
                                      ref
                                          .read(inboxProvider.notifier)
                                          .selectUnifiedInbox();
                                    },
                                  )
                                : _AllInboxesItem(
                                    isActive:
                                        isUnified &&
                                        location == CrusaderRoutes.inbox,
                                    unreadCount: displayUnread,
                                    accents: accents,
                                    onTap: () {
                                      if (location != CrusaderRoutes.inbox) {
                                        context.go(CrusaderRoutes.inbox);
                                      }
                                      ref
                                          .read(inboxProvider.notifier)
                                          .selectUnifiedInbox();
                                    },
                                  );
                            if (shouldAnimate) {
                              allInboxes = allInboxes
                                  .animate(delay: 80.ms)
                                  .fadeIn(
                                    duration: 250.ms,
                                    curve: Curves.easeOut,
                                  )
                                  .slideX(
                                    begin: -0.04,
                                    end: 0,
                                    duration: 250.ms,
                                  );
                            }
                            return allInboxes;
                          },
                        ),
                        const SizedBox(height: 4),
                      ],

                      ...accounts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final account = entry.value;
                        final isActive = account.id == activeAccount?.id;
                        final isExpanded = _expandedAccounts.contains(
                          account.id,
                        );
                        final accountMailboxes = isActive
                            ? mailboxes
                            : <Mailbox>[];

                        if (collapsed) {
                          // In collapsed mode, show just a provider icon
                          // with a tooltip + active dot.
                          Widget icon = _CollapsedAccountIcon(
                            account: account,
                            isActive: isActive,
                            accents: accents,
                            onTap: () {
                              ref
                                  .read(accountProvider.notifier)
                                  .switchAccount(account.id);
                              _expandedAccounts.add(account.id);
                              Future.microtask(() {
                                ref.read(inboxProvider.notifier).syncInbox();
                              });
                            },
                          );
                          if (shouldAnimate) {
                            icon = icon
                                .animate(delay: (60 * index + 100).ms)
                                .fadeIn(
                                  duration: 250.ms,
                                  curve: Curves.easeOut,
                                );
                          }
                          return icon;
                        }

                        Widget section = _AccountSection(
                          account: account,
                          isActive: isActive,
                          isExpanded: isExpanded,
                          mailboxes: accountMailboxes,
                          selectedMailbox: selectedMailbox,
                          currentLocation: location,
                          accents: accents,
                          onToggleExpand: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedAccounts.remove(account.id);
                              } else {
                                _expandedAccounts.add(account.id);
                              }
                            });
                          },
                          onSwitchAccount: () {
                            ref
                                .read(accountProvider.notifier)
                                .switchAccount(account.id);
                            _expandedAccounts.add(account.id);
                            Future.microtask(() {
                              ref.read(inboxProvider.notifier).syncInbox();
                            });
                          },
                          onSelectMailbox: (mailbox) {
                            if (location != CrusaderRoutes.inbox) {
                              context.go(CrusaderRoutes.inbox);
                            }
                            ref
                                .read(inboxProvider.notifier)
                                .selectMailbox(mailbox);
                          },
                        );
                        if (shouldAnimate) {
                          section = section
                              .animate(delay: (60 * index + 100).ms)
                              .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                              .slideX(begin: -0.04, end: 0, duration: 250.ms);
                        }
                        return section;
                      }),

                      // ── Add Account button ──
                      if (!collapsed)
                        Builder(
                          builder: (context) {
                            Widget addBtn = _AddAccountButton(
                              accents: accents,
                              onTap: () =>
                                  context.push(CrusaderRoutes.addAccount),
                            );
                            if (shouldAnimate) {
                              addBtn = addBtn
                                  .animate(
                                    delay: (60 * accounts.length + 100).ms,
                                  )
                                  .fadeIn(duration: 250.ms);
                            }
                            return addBtn;
                          },
                        ),

                      if (!collapsed) ...[
                        const SizedBox(height: 12),
                        const GlassDivider(indent: 8, endIndent: 8),
                        const SizedBox(height: 12),
                      ],
                      if (collapsed) const SizedBox(height: 8),
                    ],

                    // ── Nav Items ──
                    ..._navItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isActive = location == item.route;

                      if (collapsed) {
                        Widget navIcon = _CollapsedNavIcon(
                          icon: isActive ? item.activeIcon : item.icon,
                          tooltip: item.label,
                          isActive: isActive,
                          accents: accents,
                          badgeCount: item.route == CrusaderRoutes.inbox
                              ? unreadCount
                              : 0,
                          onTap: () => context.go(item.route),
                        );
                        if (shouldAnimate) {
                          navIcon = navIcon
                              .animate(delay: (80 * index + 200).ms)
                              .fadeIn(duration: 280.ms, curve: Curves.easeOut);
                        }
                        return navIcon;
                      }

                      Widget navItem = _SidebarNavItem(
                        item: item,
                        isActive: isActive,
                        accents: accents,
                        glass: glass,
                        onTap: () => context.go(item.route),
                        inboxUnread: item.route == CrusaderRoutes.inbox
                            ? unreadCount
                            : 0,
                      );
                      if (shouldAnimate) {
                        navItem = navItem
                            .animate(delay: (80 * index + 200).ms)
                            .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                            .slideX(begin: -0.04, end: 0, duration: 280.ms);
                      }
                      return navItem;
                    }),
                  ],
                ),
              ),
            ),

            // ── Sync status (pinned at bottom) ──
            if (isSyncing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: collapsed
                    ? Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation(
                              accents.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation(
                                accents.primary.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Syncing\u2026',
                            style: textTheme.labelSmall?.copyWith(
                              color: CrusaderGrays.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsed Nav Icon — icon-only sidebar item with tooltip + badge
// ─────────────────────────────────────────────────────────────────────────────

class _CollapsedNavIcon extends StatefulWidget {
  const _CollapsedNavIcon({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.accents,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final CrusaderAccentTheme accents;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_CollapsedNavIcon> createState() => _CollapsedNavIconState();
}

class _CollapsedNavIconState extends State<_CollapsedNavIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Tooltip(
          message: widget.tooltip,
          preferBelow: false,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: widget.isActive
                    ? widget.accents.primary.withValues(alpha: 0.12)
                    : _isHovered
                    ? CrusaderGrays.border.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isActive
                        ? widget.accents.primary
                        : _isHovered
                        ? CrusaderGrays.secondary
                        : CrusaderGrays.muted,
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accents.primary,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accents.primaryGlow.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsed Account Icon — small provider icon for collapsed sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _CollapsedAccountIcon extends StatefulWidget {
  const _CollapsedAccountIcon({
    required this.account,
    required this.isActive,
    required this.accents,
    required this.onTap,
  });

  final EmailAccount account;
  final bool isActive;
  final CrusaderAccentTheme accents;
  final VoidCallback onTap;

  @override
  State<_CollapsedAccountIcon> createState() => _CollapsedAccountIconState();
}

class _CollapsedAccountIconState extends State<_CollapsedAccountIcon> {
  bool _isHovered = false;

  Color get _providerColor => widget.account.provider == EmailProvider.gmail
      ? const Color(0xFF4285F4)
      : const Color(0xFF0078D4);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Tooltip(
          message: widget.account.email,
          preferBelow: false,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _isHovered
                    ? CrusaderGrays.border.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _providerColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      widget.account.provider == EmailProvider.gmail
                          ? Icons.mail_rounded
                          : Icons.business_rounded,
                      size: 13,
                      color: _providerColor,
                    ),
                  ),
                  if (widget.isActive)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accents.success,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accents.success.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Section — collapsible account with mailbox folders
// ─────────────────────────────────────────────────────────────────────────────
// Account Section — collapsible account with mailbox folders
// ─────────────────────────────────────────────────────────────────────────────

class _AccountSection extends StatefulWidget {
  const _AccountSection({
    required this.account,
    required this.isActive,
    required this.isExpanded,
    required this.mailboxes,
    required this.selectedMailbox,
    required this.currentLocation,
    required this.accents,
    required this.onToggleExpand,
    required this.onSwitchAccount,
    required this.onSelectMailbox,
  });

  final EmailAccount account;
  final bool isActive;
  final bool isExpanded;
  final List<Mailbox> mailboxes;
  final Mailbox? selectedMailbox;
  final String currentLocation;
  final CrusaderAccentTheme accents;
  final VoidCallback onToggleExpand;
  final VoidCallback onSwitchAccount;
  final ValueChanged<Mailbox> onSelectMailbox;

  @override
  State<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<_AccountSection> {
  bool _isHeaderHovered = false;

  Color get _providerColor => widget.account.provider == EmailProvider.gmail
      ? const Color(0xFF4285F4)
      : const Color(0xFF0078D4);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Account header row (click to expand/collapse) ──
          MouseRegion(
            onEnter: (_) => setState(() => _isHeaderHovered = true),
            onExit: (_) => setState(() => _isHeaderHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                // If not active, switch to this account first.
                if (!widget.isActive) {
                  widget.onSwitchAccount();
                }
                widget.onToggleExpand();
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: widget.isActive
                      ? widget.accents.primary.withValues(alpha: 0.06)
                      : _isHeaderHovered
                      ? CrusaderGrays.border.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    // Provider icon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: _providerColor.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        widget.account.provider == EmailProvider.gmail
                            ? Icons.mail_rounded
                            : Icons.business_rounded,
                        size: 13,
                        color: _providerColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Account info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.account.displayName,
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: widget.isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 12,
                              color: widget.isActive
                                  ? null
                                  : CrusaderGrays.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.account.email,
                            style: textTheme.labelSmall?.copyWith(
                              color: CrusaderGrays.muted,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Active badge
                    if (widget.isActive)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accents.success,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accents.success.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    // Expand/collapse chevron
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: CrusaderGrays.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Collapsible mailbox list ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Column(
                children: widget.mailboxes.map((mailbox) {
                  final isMailboxActive =
                      mailbox.path == widget.selectedMailbox?.path &&
                      widget.currentLocation == CrusaderRoutes.inbox &&
                      widget.isActive;
                  return _MailboxNavItem(
                    mailbox: mailbox,
                    isActive: isMailboxActive,
                    onTap: () {
                      if (!widget.isActive) {
                        widget.onSwitchAccount();
                      }
                      widget.onSelectMailbox(mailbox);
                    },
                  );
                }).toList(),
              ),
            ),
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Account Button — subtle inline button in accounts section
// ─────────────────────────────────────────────────────────────────────────────

class _AddAccountButton extends StatefulWidget {
  const _AddAccountButton({required this.accents, required this.onTap});

  final CrusaderAccentTheme accents;
  final VoidCallback onTap;

  @override
  State<_AddAccountButton> createState() => _AddAccountButtonState();
}

class _AddAccountButtonState extends State<_AddAccountButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _isHovered
                ? CrusaderGrays.border.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: CrusaderGrays.muted.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: CrusaderGrays.muted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Add account',
                style: textTheme.bodySmall?.copyWith(
                  color: CrusaderGrays.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mailbox Nav Item — folder row in the sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _MailboxNavItem extends StatefulWidget {
  const _MailboxNavItem({
    required this.mailbox,
    required this.isActive,
    required this.onTap,
  });

  final Mailbox mailbox;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_MailboxNavItem> createState() => _MailboxNavItemState();
}

class _MailboxNavItemState extends State<_MailboxNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.isActive
                  ? accents.primary.withValues(alpha: 0.1)
                  : _isHovered
                  ? CrusaderGrays.border.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  _mailboxIcon(widget.mailbox),
                  size: 16,
                  color: widget.isActive
                      ? accents.primary
                      : _isHovered
                      ? CrusaderGrays.secondary
                      : CrusaderGrays.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.mailbox.name,
                    style: textTheme.bodyMedium?.copyWith(
                      color: widget.isActive
                          ? accents.primary
                          : CrusaderGrays.primary,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.mailbox.unseenMessages > 0)
                  GlassBadge(
                    count: widget.mailbox.unseenMessages,
                    color: widget.isActive
                        ? accents.primary
                        : CrusaderGrays.muted,
                    small: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All Inboxes Item — unified inbox toggle in sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _AllInboxesItem extends StatefulWidget {
  const _AllInboxesItem({
    required this.isActive,
    required this.unreadCount,
    required this.accents,
    required this.onTap,
  });

  final bool isActive;
  final int unreadCount;
  final CrusaderAccentTheme accents;
  final VoidCallback onTap;

  @override
  State<_AllInboxesItem> createState() => _AllInboxesItemState();
}

class _AllInboxesItemState extends State<_AllInboxesItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.isActive
                  ? widget.accents.primary.withValues(alpha: 0.12)
                  : _isHovered
                  ? CrusaderGrays.border.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.all_inbox_rounded,
                  size: 17,
                  color: widget.isActive
                      ? widget.accents.primary
                      : _isHovered
                      ? CrusaderGrays.secondary
                      : CrusaderGrays.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All Inboxes',
                    style: textTheme.bodyMedium?.copyWith(
                      color: widget.isActive
                          ? widget.accents.primary
                          : CrusaderGrays.primary,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.unreadCount > 0)
                  GlassBadge(
                    count: widget.unreadCount,
                    color: widget.isActive
                        ? widget.accents.primary
                        : CrusaderGrays.muted,
                    small: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar Nav Item — with keyboard shortcut hints and hover glow
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.accents,
    required this.glass,
    required this.onTap,
    this.inboxUnread = 0,
  });

  final _NavItem item;
  final bool isActive;
  final CrusaderAccentTheme accents;
  final CrusaderGlassTheme glass;
  final VoidCallback onTap;
  final int inboxUnread;

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.isActive
                  ? widget.accents.primary.withValues(alpha: 0.1)
                  : _isHovered
                  ? CrusaderGrays.border.withValues(alpha: 0.25)
                  : Colors.transparent,
              border: widget.isActive
                  ? Border.all(
                      color: widget.accents.primary.withValues(alpha: 0.15),
                      width: 0.5,
                    )
                  : null,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: widget.accents.primaryGlow.withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  widget.isActive ? widget.item.activeIcon : widget.item.icon,
                  size: 17,
                  color: widget.isActive
                      ? widget.accents.primary
                      : _isHovered
                      ? CrusaderGrays.secondary
                      : CrusaderGrays.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: widget.isActive
                          ? widget.accents.primary
                          : CrusaderGrays.primary,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (widget.inboxUnread > 0) ...[
                  GlassBadge(
                    count: widget.inboxUnread,
                    color: widget.accents.primary,
                    small: true,
                  ),
                  const SizedBox(width: 6),
                ],
                if (widget.item.shortcut != null && _isHovered)
                  KeyboardShortcutBadge(
                    shortcut: widget.item.shortcut!,
                  ).animate().fadeIn(duration: 150.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Shell — Bottom Navigation
// ─────────────────────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    int currentIndex = 0;
    for (var i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].route) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(CrusaderRoutes.compose),
        backgroundColor: accents.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.edit_rounded, size: 22),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: CrusaderGrays.border.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => context.go(_navItems[index].route),
          selectedItemColor: accents.primary,
          unselectedItemColor: CrusaderGrays.muted,
          backgroundColor: CrusaderBlacks.charcoal,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: _navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}
