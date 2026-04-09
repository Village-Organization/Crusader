/// Crusader — Inbox Screen
///
/// Shows threaded email list with glassmorphic design.
/// - Desktop wide (>1200px): Master-detail split view
/// - Desktop narrow / tablet: Full-width list, push to detail
/// - Mobile: Full-width list, push to detail
///
/// Loading states use shimmer skeletons. Empty states are elegant
/// glass panels with gradient icons.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';
import '../../domain/entities/email_thread.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/inbox/inbox_providers.dart';
import '../widgets/glass_components.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_toast.dart';
import '../widgets/snooze_picker.dart';
import '../widgets/thread_tile.dart';
import 'thread_detail_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String? _selectedThreadId;
  int _focusedIndex = -1;
  final _scrollController = ScrollController();

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryInitialSync();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _tryInitialSync() {
    final accountState = ref.read(accountProvider);
    if (accountState.hasAccounts) {
      _smartSync();
    }
  }

  /// Calls syncAllAccounts when in unified mode, syncInbox otherwise.
  Future<void> _smartSync() {
    final notifier = ref.read(inboxProvider.notifier);
    if (ref.read(inboxProvider).isUnifiedInbox) {
      return notifier.syncAllAccounts();
    }
    return notifier.syncInbox();
  }

  /// Get the currently focused thread (if any).
  EmailThread? get _focusedThread {
    final threads = ref.read(inboxProvider).threads;
    if (_focusedIndex >= 0 && _focusedIndex < threads.length) {
      return threads[_focusedIndex];
    }
    return null;
  }

  /// Handle inbox-specific keyboard shortcuts (J/K/Enter/R/F/E/#/S).
  KeyEventResult _handleInboxKey(FocusNode node, KeyEvent event) {
    if (!_isDesktop) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Don't handle if modifier keys are pressed.
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }

    final threads = ref.read(inboxProvider).threads;
    if (threads.isEmpty) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyJ:
      case LogicalKeyboardKey.arrowDown:
        // Move down.
        setState(() {
          _focusedIndex = (_focusedIndex + 1).clamp(0, threads.length - 1);
          _selectedThreadId = threads[_focusedIndex].id;
        });
        _ensureVisible(_focusedIndex);
        // In master-detail, auto-open.
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth >= AppConstants.desktopBreakpoint) {
          ref
              .read(inboxProvider.notifier)
              .markThreadAsRead(threads[_focusedIndex]);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyK:
      case LogicalKeyboardKey.arrowUp:
        // Move up.
        setState(() {
          _focusedIndex = (_focusedIndex - 1).clamp(0, threads.length - 1);
          _selectedThreadId = threads[_focusedIndex].id;
        });
        _ensureVisible(_focusedIndex);
        final w = MediaQuery.of(context).size.width;
        if (w >= AppConstants.desktopBreakpoint) {
          ref
              .read(inboxProvider.notifier)
              .markThreadAsRead(threads[_focusedIndex]);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter:
        // Open thread.
        final thread = _focusedThread;
        if (thread != null) {
          ref.read(inboxProvider.notifier).markThreadAsRead(thread);
          final w = MediaQuery.of(context).size.width;
          if (w < AppConstants.desktopBreakpoint) {
            context.push('/thread/${thread.id}');
          }
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyR:
        // Reply to focused thread.
        final thread = _focusedThread;
        if (thread != null) {
          context.go('${CrusaderRoutes.compose}?replyTo=${thread.id}');
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyF:
        // Forward focused thread.
        final thread = _focusedThread;
        if (thread != null) {
          context.go('${CrusaderRoutes.compose}?forward=${thread.id}');
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyS:
        // Star/flag toggle.
        final thread = _focusedThread;
        if (thread != null) {
          ref.read(inboxProvider.notifier).toggleThreadFlag(thread);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyE:
        // Archive.
        final thread = _focusedThread;
        if (thread != null) {
          ref.read(inboxProvider.notifier).archiveThread(thread);
          CrusaderToast.withUndo(
            context,
            'Archived',
            icon: Icons.archive_outlined,
            onUndo: () => ref.read(inboxProvider.notifier).syncInbox(),
          );
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyU:
        // Toggle read/unread.
        final thread = _focusedThread;
        if (thread != null) {
          if (thread.hasUnread) {
            ref.read(inboxProvider.notifier).markThreadAsRead(thread);
          } else {
            ref.read(inboxProvider.notifier).markThreadAsUnread(thread);
          }
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.keyB:
        // Snooze.
        final thread = _focusedThread;
        if (thread != null) {
          showSnoozePicker(context).then((until) {
            if (until != null && mounted) {
              ref.read(inboxProvider.notifier).snoozeThread(thread, until);
              CrusaderToast.success(
                context,
                'Snoozed',
                icon: Icons.snooze_rounded,
              );
            }
          });
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.digit3: // # key (Shift+3)
        if (HardwareKeyboard.instance.isShiftPressed) {
          final thread = _focusedThread;
          if (thread != null) {
            ref.read(inboxProvider.notifier).moveThreadToTrash(thread);
            CrusaderToast.withUndo(
              context,
              'Moved to Trash',
              icon: Icons.delete_outline_rounded,
              onUndo: () => ref.read(inboxProvider.notifier).syncInbox(),
            );
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;

      default:
        return KeyEventResult.ignored;
    }
  }

  void _ensureVisible(int index) {
    if (!_scrollController.hasClients) return;
    // Approximate row height of ~70px.
    const rowHeight = 70.0;
    final offset = (index * rowHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final textTheme = Theme.of(context).textTheme;
    final accountState = ref.watch(accountProvider);
    final inboxState = ref.watch(inboxProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMasterDetail = screenWidth >= AppConstants.desktopBreakpoint;

    return Focus(
      onKeyEvent: _handleInboxKey,
      child: SafeArea(
        child: isMasterDetail
            ? _MasterDetailLayout(
                selectedThreadId: _selectedThreadId,
                onSelectThread: (thread) {
                  setState(() {
                    _selectedThreadId = thread.id;
                    _focusedIndex = inboxState.threads.indexOf(thread);
                  });
                  ref.read(inboxProvider.notifier).markThreadAsRead(thread);
                },
                listPane: _InboxListPane(
                  accountState: accountState,
                  inboxState: inboxState,
                  accents: accents,
                  textTheme: textTheme,
                  selectedThreadId: _selectedThreadId,
                  scrollController: _scrollController,
                  onTapThread: (thread) {
                    setState(() {
                      _selectedThreadId = thread.id;
                      _focusedIndex = inboxState.threads.indexOf(thread);
                    });
                    ref.read(inboxProvider.notifier).markThreadAsRead(thread);
                  },
                  onFlagThread: (thread) {
                    ref.read(inboxProvider.notifier).toggleThreadFlag(thread);
                  },
                  onRefresh: () => _smartSync(),
                ),
              )
            : _InboxListPane(
                accountState: accountState,
                inboxState: inboxState,
                accents: accents,
                textTheme: textTheme,
                scrollController: _scrollController,
                onTapThread: (thread) {
                  setState(() {
                    _focusedIndex = inboxState.threads.indexOf(thread);
                  });
                  ref.read(inboxProvider.notifier).markThreadAsRead(thread);
                  context.push('/thread/${thread.id}');
                },
                onFlagThread: (thread) {
                  ref.read(inboxProvider.notifier).toggleThreadFlag(thread);
                },
                onRefresh: () => _smartSync(),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Master-Detail Split Layout (wide desktop)
// ─────────────────────────────────────────────────────────────────────────────

class _MasterDetailLayout extends StatefulWidget {
  const _MasterDetailLayout({
    required this.listPane,
    required this.selectedThreadId,
    required this.onSelectThread,
  });

  final Widget listPane;
  final String? selectedThreadId;
  final ValueChanged<EmailThread> onSelectThread;

  @override
  State<_MasterDetailLayout> createState() => _MasterDetailLayoutState();
}

class _MasterDetailLayoutState extends State<_MasterDetailLayout> {
  double _listWidth = 380;
  static const _minListWidth = 280.0;
  static const _maxListWidth = 600.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    return Row(
      children: [
        // ── List pane ──
        SizedBox(width: _listWidth, child: widget.listPane),

        // ── Draggable divider ──
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
            onHorizontalDragUpdate: (details) {
              setState(() {
                _listWidth = (_listWidth + details.delta.dx).clamp(
                  _minListWidth,
                  _maxListWidth,
                );
              });
            },
            onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isDragging ? 3 : 1,
              color: _isDragging
                  ? accents.primary.withValues(alpha: 0.6)
                  : CrusaderGrays.border.withValues(alpha: 0.4),
            ),
          ),
        ),

        // ── Detail pane ──
        Expanded(
          child: widget.selectedThreadId != null
              ? ThreadDetailScreen(
                  threadId: widget.selectedThreadId!,
                  embedded: true,
                )
              : const _DetailPlaceholder(),
        ),
      ],
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accents.primary.withValues(alpha: 0.12),
                  accents.secondary.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 24,
              color: accents.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select an email',
            style: textTheme.bodyLarge?.copyWith(color: CrusaderGrays.muted),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a conversation to read',
            style: textTheme.bodySmall?.copyWith(color: CrusaderGrays.subtle),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inbox List Pane — header + thread list
// ─────────────────────────────────────────────────────────────────────────────

class _InboxListPane extends ConsumerWidget {
  const _InboxListPane({
    required this.accountState,
    required this.inboxState,
    required this.accents,
    required this.textTheme,
    required this.onTapThread,
    required this.onFlagThread,
    required this.onRefresh,
    this.selectedThreadId,
    this.scrollController,
  });

  final AccountState accountState;
  final InboxState inboxState;
  final CrusaderAccentTheme accents;
  final TextTheme textTheme;
  final ValueChanged<EmailThread> onTapThread;
  final ValueChanged<EmailThread> onFlagThread;
  final Future<void> Function() onRefresh;
  final String? selectedThreadId;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child:
              Row(
                    children: [
                      if (inboxState.isUnifiedInbox) ...[
                        Icon(
                          Icons.all_inbox_rounded,
                          size: 22,
                          color: accents.primary,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        inboxState.isUnifiedInbox ? 'All Inboxes' : 'Inbox',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (inboxState.unreadCount > 0) ...[
                        const SizedBox(width: 10),
                        GlassBadge(
                          count: inboxState.unreadCount,
                          color: accents.primary,
                        ),
                      ],
                      const Spacer(),
                      if (inboxState.isSyncing)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(accents.primary),
                          ),
                        )
                      else
                        GlassIconButton(
                          icon: Icons.refresh_rounded,
                          onPressed: onRefresh,
                          tooltip: 'Refresh',
                        ),
                    ],
                  )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: -0.04, end: 0, duration: 350.ms),
        ),

        const SizedBox(height: 12),

        // ── Quick filter bar ──
        _QuickFilterBar(
          activeFilters: inboxState.activeFilters,
          onToggle: (filter) =>
              ref.read(inboxProvider.notifier).toggleFilter(filter),
          accents: accents,
          textTheme: textTheme,
        ),

        // ── Divider ──
        const GlassDivider(indent: 20, endIndent: 20),
        const SizedBox(height: 4),

        // ── Content ──
        Expanded(child: _buildContent(context, ref)),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    // No accounts connected.
    if (!accountState.hasAccounts) {
      return _EmptyState(
        icon: Icons.mail_outline_rounded,
        title: 'Welcome to Crusader',
        subtitle: 'Connect an email account to get started.',
        actionLabel: 'Add Account',
        onAction: () => context.push(CrusaderRoutes.addAccount),
        accents: accents,
        textTheme: textTheme,
      );
    }

    // Initial loading — shimmer skeletons.
    if (inboxState.isInitialLoad) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: 8,
        itemBuilder: (context, index) => ThreadTileSkeleton(
          index: index,
        ).animate(delay: (index * 40).ms).fadeIn(duration: 300.ms),
      );
    }

    // Error state.
    if (inboxState.error != null && inboxState.threads.isEmpty) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        subtitle: inboxState.error!,
        actionLabel: 'Retry',
        onAction: onRefresh,
        accents: accents,
        textTheme: textTheme,
        isError: true,
      );
    }

    // No emails — Inbox Zero celebration!
    if (inboxState.threads.isEmpty) {
      return _InboxZeroCelebration(
        accents: accents,
        textTheme: textTheme,
        onRefresh: onRefresh,
      );
    }

    // ── Thread list ──
    final displayThreads = inboxState.filteredThreads;

    if (displayThreads.isEmpty && inboxState.activeFilters.isNotEmpty) {
      return _EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'No matching emails',
        subtitle: 'Try adjusting your filters.',
        actionLabel: 'Clear Filters',
        onAction: () => ref.read(inboxProvider.notifier).clearFilters(),
        accents: accents,
        textTheme: textTheme,
      );
    }

    return RefreshIndicator(
      color: accents.primary,
      backgroundColor: CrusaderBlacks.elevated,
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 4, bottom: 80),
        itemCount: displayThreads.length,
        itemBuilder: (context, index) {
          final thread = displayThreads[index];
          return ThreadTile(
            thread: thread,
            isSelected: thread.id == selectedThreadId,
            animationDelay: Duration(milliseconds: (index * 25).clamp(0, 250)),
            onTap: () => onTapThread(thread),
            onFlagToggle: () => onFlagThread(thread),
            onArchive: () {
              ref.read(inboxProvider.notifier).archiveThread(thread);
              CrusaderToast.withUndo(
                context,
                'Archived',
                icon: Icons.archive_outlined,
                onUndo: () => ref.read(inboxProvider.notifier).syncInbox(),
              );
            },
            onDelete: () {
              ref.read(inboxProvider.notifier).moveThreadToTrash(thread);
              CrusaderToast.withUndo(
                context,
                'Moved to Trash',
                icon: Icons.delete_outline_rounded,
                onUndo: () => ref.read(inboxProvider.notifier).syncInbox(),
              );
            },
            onSnooze: () async {
              final until = await showSnoozePicker(context);
              if (until != null && context.mounted) {
                ref.read(inboxProvider.notifier).snoozeThread(thread, until);
                CrusaderToast.success(
                  context,
                  'Snoozed',
                  icon: Icons.snooze_rounded,
                );
              }
            },
            onSecondaryTap: (position) =>
                _showThreadContextMenu(context, ref, position, thread),
          );
        },
      ),
    );
  }

  /// Shows a glassmorphic context menu for a thread.
  void _showThreadContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    EmailThread thread,
  ) async {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: CrusaderBlacks.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: CrusaderGrays.border.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      elevation: 8,
      items: [
        _contextMenuItem(
          'reply',
          Icons.reply_rounded,
          'Reply',
          'R',
          accents.primary,
        ),
        _contextMenuItem(
          'forward',
          Icons.forward_rounded,
          'Forward',
          'F',
          accents.primary,
        ),
        const PopupMenuDivider(height: 8),
        _contextMenuItem(
          'read',
          thread.hasUnread
              ? Icons.mark_email_read_outlined
              : Icons.mark_email_unread_outlined,
          thread.hasUnread ? 'Mark as Read' : 'Mark as Unread',
          'U',
          CrusaderGrays.secondary,
        ),
        _contextMenuItem(
          'flag',
          thread.isFlagged ? Icons.star_rounded : Icons.star_outline_rounded,
          thread.isFlagged ? 'Unflag' : 'Flag',
          'S',
          accents.tertiary,
        ),
        _contextMenuItem(
          'snooze',
          Icons.snooze_rounded,
          'Snooze',
          'B',
          accents.tertiary,
        ),
        const PopupMenuDivider(height: 8),
        _contextMenuItem(
          'archive',
          Icons.archive_outlined,
          'Archive',
          'E',
          CrusaderGrays.secondary,
        ),
        _contextMenuItem(
          'delete',
          Icons.delete_outline_rounded,
          'Delete',
          '#',
          CrusaderAccents.red,
        ),
      ],
    );

    if (result == null || !context.mounted) return;

    switch (result) {
      case 'reply':
        context.go('${CrusaderRoutes.compose}?replyTo=${thread.id}');
        break;
      case 'forward':
        context.go('${CrusaderRoutes.compose}?forward=${thread.id}');
        break;
      case 'read':
        // Toggle read state — mark as read or unread.
        if (thread.hasUnread) {
          ref.read(inboxProvider.notifier).markThreadAsRead(thread);
        } else {
          ref.read(inboxProvider.notifier).markThreadAsUnread(thread);
        }
        CrusaderToast.info(
          context,
          thread.hasUnread ? 'Marked as read' : 'Marked as unread',
          icon: thread.hasUnread
              ? Icons.mark_email_read_outlined
              : Icons.mark_email_unread_outlined,
        );
        break;
      case 'flag':
        onFlagThread(thread);
        break;
      case 'snooze':
        final until = await showSnoozePicker(context);
        if (until != null && context.mounted) {
          ref.read(inboxProvider.notifier).snoozeThread(thread, until);
          CrusaderToast.success(context, 'Snoozed', icon: Icons.snooze_rounded);
        }
        break;
      case 'archive':
        ref.read(inboxProvider.notifier).archiveThread(thread);
        CrusaderToast.withUndo(
          context,
          'Archived',
          icon: Icons.archive_outlined,
          onUndo: () => ref.read(inboxProvider.notifier).syncInbox(),
        );
        break;
      case 'delete':
        ref.read(inboxProvider.notifier).moveThreadToTrash(thread);
        CrusaderToast.withUndo(
          context,
          'Moved to Trash',
          icon: Icons.delete_outline_rounded,
          onUndo: () => ref.read(inboxProvider.notifier).syncInbox(),
        );
        break;
    }
  }

  PopupMenuItem<String> _contextMenuItem(
    String value,
    IconData icon,
    String label,
    String? shortcut,
    Color iconColor,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: CrusaderGrays.primary, fontSize: 13),
            ),
          ),
          if (shortcut != null)
            Text(
              shortcut,
              style: TextStyle(color: CrusaderGrays.muted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.accents,
    required this.textTheme,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final CrusaderAccentTheme accents;
  final TextTheme textTheme;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final iconColor = isError ? accents.error : accents.primary;
    final bgColor = isError ? accents.error : accents.secondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child:
            GlassPanel(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 40,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              iconColor.withValues(alpha: 0.18),
                              bgColor.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(icon, size: 26, color: iconColor),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: CrusaderGrays.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: onAction,
                        icon: Icon(
                          isError ? Icons.refresh_rounded : Icons.add_rounded,
                          size: 16,
                        ),
                        label: Text(actionLabel),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 150.ms)
                .scale(
                  begin: const Offset(0.97, 0.97),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  delay: 150.ms,
                  curve: Curves.easeOutCubic,
                ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inbox Zero Celebration — delightful "all caught up" state
// ─────────────────────────────────────────────────────────────────────────────

class _InboxZeroCelebration extends StatelessWidget {
  const _InboxZeroCelebration({
    required this.accents,
    required this.textTheme,
    required this.onRefresh,
  });

  final CrusaderAccentTheme accents;
  final TextTheme textTheme;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated gradient ring with checkmark ──
            _GlowingCheckmark(accents: accents)
                .animate()
                .fadeIn(duration: 600.ms, delay: 100.ms)
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 700.ms,
                  delay: 100.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 28),

            // ── Title ──
            Text(
                  'You\'re all caught up',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 350.ms)
                .slideY(begin: 0.1, end: 0, duration: 500.ms, delay: 350.ms),

            const SizedBox(height: 8),

            // ── Subtitle ──
            Text(
                  'Nothing to see here. Go enjoy your day.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: CrusaderGrays.secondary,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 500.ms)
                .slideY(begin: 0.08, end: 0, duration: 500.ms, delay: 500.ms),

            const SizedBox(height: 32),

            // ── Refresh button ──
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Check for new mail'),
              style: TextButton.styleFrom(
                foregroundColor: accents.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
          ],
        ),
      ),
    );
  }
}

/// Animated checkmark with gradient glow ring.
class _GlowingCheckmark extends StatefulWidget {
  const _GlowingCheckmark({required this.accents});

  final CrusaderAccentTheme accents;

  @override
  State<_GlowingCheckmark> createState() => _GlowingCheckmarkState();
}

class _GlowingCheckmarkState extends State<_GlowingCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 0.5 + 0.5 * _pulseController.value;
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                widget.accents.primary.withValues(alpha: 0.15 * pulse),
                widget.accents.secondary.withValues(alpha: 0.08 * pulse),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accents.primaryGlow.withValues(
                  alpha: 0.2 * pulse,
                ),
                blurRadius: 30,
                spreadRadius: -5,
              ),
              BoxShadow(
                color: widget.accents.secondaryGlow.withValues(
                  alpha: 0.1 * pulse,
                ),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  widget.accents.primary.withValues(alpha: 0.12),
                  widget.accents.secondary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: widget.accents.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 32,
              color: widget.accents.primary,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Filter Bar — toggle chips for Unread / Attachments / Starred
// ─────────────────────────────────────────────────────────────────────────────

class _QuickFilterBar extends StatelessWidget {
  const _QuickFilterBar({
    required this.activeFilters,
    required this.onToggle,
    required this.accents,
    required this.textTheme,
  });

  final Set<InboxFilter> activeFilters;
  final ValueChanged<InboxFilter> onToggle;
  final CrusaderAccentTheme accents;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Unread',
            icon: Icons.mark_email_unread_outlined,
            isActive: activeFilters.contains(InboxFilter.unread),
            onTap: () => onToggle(InboxFilter.unread),
            accents: accents,
            textTheme: textTheme,
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Attachments',
            icon: Icons.attach_file_rounded,
            isActive: activeFilters.contains(InboxFilter.hasAttachments),
            onTap: () => onToggle(InboxFilter.hasAttachments),
            accents: accents,
            textTheme: textTheme,
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Starred',
            icon: Icons.star_outline_rounded,
            isActive: activeFilters.contains(InboxFilter.starred),
            onTap: () => onToggle(InboxFilter.starred),
            accents: accents,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.accents,
    required this.textTheme,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final CrusaderAccentTheme accents;
  final TextTheme textTheme;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: widget.isActive
                ? widget.accents.primary.withValues(alpha: 0.15)
                : _isHovered
                ? CrusaderGrays.border.withValues(alpha: 0.3)
                : Colors.transparent,
            border: Border.all(
              color: widget.isActive
                  ? widget.accents.primary.withValues(alpha: 0.4)
                  : CrusaderGrays.border.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: widget.isActive
                    ? widget.accents.primary
                    : CrusaderGrays.muted,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: widget.textTheme.labelSmall?.copyWith(
                  color: widget.isActive
                      ? widget.accents.primary
                      : CrusaderGrays.secondary,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
