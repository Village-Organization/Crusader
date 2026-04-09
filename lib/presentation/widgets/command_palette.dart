/// Crusader — Command Palette
///
/// Superhuman/Linear-style command palette triggered by Ctrl+K.
/// Fuzzy-searches across:
/// - Navigation actions (Inbox, Search, Settings, Compose)
/// - Email actions (Archive, Delete, Reply, Forward, Star)
/// - Account switching
/// - Mailbox navigation
/// - Theme / appearance toggles
///
/// Glass-morphic floating modal with keyboard navigation (arrow keys + Enter).
library;

import 'dart:math' as math;
import 'dart:ui';

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
import '../../features/auth/auth_providers.dart';
import '../../features/inbox/inbox_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Command Palette Entry Point
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the command palette overlay. Call from keyboard shortcut handler.
void showCommandPalette(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    barrierDismissible: true,
    builder: (ctx) => const _CommandPaletteDialog(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Command Definition
// ─────────────────────────────────────────────────────────────────────────────

enum CommandCategory { navigation, action, account, appearance }

class PaletteCommand {
  const PaletteCommand({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
    this.subtitle,
    this.shortcut,
    this.keywords = const [],
  });

  final String id;
  final String label;
  final IconData icon;
  final CommandCategory category;
  final String? subtitle;
  final String? shortcut;
  final List<String> keywords;

  /// Simple fuzzy match — checks if all query characters appear in order.
  double matchScore(String query) {
    if (query.isEmpty) return 1.0;
    final lower = label.toLowerCase();
    final q = query.toLowerCase();

    // Exact prefix match scores highest.
    if (lower.startsWith(q)) return 2.0;

    // Substring match.
    if (lower.contains(q)) return 1.5;

    // Keyword match.
    for (final kw in keywords) {
      if (kw.toLowerCase().contains(q)) return 1.3;
    }
    if (subtitle != null && subtitle!.toLowerCase().contains(q)) return 1.2;

    // Fuzzy character match.
    int qi = 0;
    for (int i = 0; i < lower.length && qi < q.length; i++) {
      if (lower[i] == q[qi]) qi++;
    }
    if (qi == q.length) return 1.0;

    return 0;
  }
}

String _categoryLabel(CommandCategory cat) {
  switch (cat) {
    case CommandCategory.navigation:
      return 'Navigation';
    case CommandCategory.action:
      return 'Actions';
    case CommandCategory.account:
      return 'Accounts';
    case CommandCategory.appearance:
      return 'Appearance';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Command Palette Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CommandPaletteDialog extends ConsumerStatefulWidget {
  const _CommandPaletteDialog();

  @override
  ConsumerState<_CommandPaletteDialog> createState() =>
      _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends ConsumerState<_CommandPaletteDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<PaletteCommand> _buildCommands() {
    final accountState = ref.read(accountProvider);
    final themeMode = ref.read(themeModeProvider);
    final mailboxes = ref.read(inboxProvider.select((s) => s.mailboxes));

    final commands = <PaletteCommand>[
      // ── Navigation ──
      const PaletteCommand(
        id: 'nav:inbox',
        label: 'Go to Inbox',
        icon: Icons.inbox_rounded,
        category: CommandCategory.navigation,
        shortcut: 'G I',
        keywords: ['home', 'mail', 'messages'],
      ),
      const PaletteCommand(
        id: 'nav:search',
        label: 'Search Emails',
        icon: Icons.search_rounded,
        category: CommandCategory.navigation,
        shortcut: '/',
        keywords: ['find', 'query', 'filter'],
      ),
      const PaletteCommand(
        id: 'nav:compose',
        label: 'Compose New Email',
        icon: Icons.edit_rounded,
        category: CommandCategory.navigation,
        shortcut: 'C',
        keywords: ['write', 'new', 'send', 'create'],
      ),
      const PaletteCommand(
        id: 'nav:settings',
        label: 'Open Settings',
        icon: Icons.settings_rounded,
        category: CommandCategory.navigation,
        shortcut: 'G S',
        keywords: ['preferences', 'config', 'options'],
      ),
      const PaletteCommand(
        id: 'nav:add_account',
        label: 'Add Email Account',
        icon: Icons.person_add_rounded,
        category: CommandCategory.navigation,
        keywords: ['connect', 'gmail', 'outlook', 'new account'],
      ),

      // ── Appearance ──
      PaletteCommand(
        id: 'appearance:theme',
        label: themeMode == ThemeMode.dark
            ? 'Switch to Light Mode'
            : 'Switch to Dark Mode',
        icon: themeMode == ThemeMode.dark
            ? Icons.light_mode_rounded
            : Icons.dark_mode_rounded,
        category: CommandCategory.appearance,
        keywords: ['theme', 'dark', 'light', 'mode'],
      ),
      const PaletteCommand(
        id: 'appearance:sidebar',
        label: 'Toggle Sidebar',
        icon: Icons.view_sidebar_rounded,
        category: CommandCategory.appearance,
        shortcut: 'Ctrl+B',
        keywords: ['collapse', 'expand', 'panel'],
      ),

      // ── Mailboxes ──
      for (final mailbox in mailboxes)
        PaletteCommand(
          id: 'mailbox:${mailbox.path}',
          label: 'Go to ${mailbox.name}',
          icon: _mailboxIcon(mailbox.name),
          category: CommandCategory.navigation,
          subtitle: mailbox.unseenMessages > 0
              ? '${mailbox.unseenMessages} unread'
              : null,
          keywords: [mailbox.name.toLowerCase(), 'folder', 'mailbox'],
        ),

      // ── Accounts ──
      for (final account in accountState.accounts)
        PaletteCommand(
          id: 'account:${account.id}',
          label: 'Switch to ${account.displayName}',
          icon: account.provider == EmailProvider.gmail
              ? Icons.email_rounded
              : Icons.email_outlined,
          category: CommandCategory.account,
          subtitle: account.email,
          keywords: [
            account.email.toLowerCase(),
            account.displayName.toLowerCase(),
            account.provider.name,
          ],
        ),
    ];

    return commands;
  }

  IconData _mailboxIcon(String name) {
    final n = name.toUpperCase();
    if (n.contains('INBOX')) return Icons.inbox_rounded;
    if (n.contains('SENT')) return Icons.send_rounded;
    if (n.contains('DRAFT')) return Icons.edit_note_rounded;
    if (n.contains('TRASH') || n.contains('DELETE')) {
      return Icons.delete_outline_rounded;
    }
    if (n.contains('ARCHIVE')) return Icons.archive_outlined;
    if (n.contains('SPAM') || n.contains('JUNK')) {
      return Icons.report_gmailerrorred_outlined;
    }
    return Icons.folder_outlined;
  }

  List<PaletteCommand> _filteredCommands() {
    final all = _buildCommands();
    if (_query.isEmpty) return all;

    final scored =
        all
            .map((cmd) => (cmd: cmd, score: cmd.matchScore(_query)))
            .where((e) => e.score > 0)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    return scored.map((e) => e.cmd).toList();
  }

  void _executeCommand(PaletteCommand cmd) {
    Navigator.of(context).pop();

    final ctx = context;
    switch (cmd.id) {
      case 'nav:inbox':
        GoRouter.of(ctx).go(CrusaderRoutes.inbox);
      case 'nav:search':
        GoRouter.of(ctx).go(CrusaderRoutes.search);
      case 'nav:compose':
        GoRouter.of(ctx).go(CrusaderRoutes.compose);
      case 'nav:settings':
        GoRouter.of(ctx).go(CrusaderRoutes.settings);
      case 'nav:add_account':
        GoRouter.of(ctx).push(CrusaderRoutes.addAccount);
      case 'appearance:theme':
        ref.read(themeModeProvider.notifier).toggle();
      case 'appearance:sidebar':
        ref.read(sidebarCollapsedProvider.notifier).toggle();
      default:
        if (cmd.id.startsWith('account:')) {
          final accountId = cmd.id.replaceFirst('account:', '');
          ref.read(accountProvider.notifier).switchAccount(accountId);
          ref.read(inboxProvider.notifier).syncInbox();
        } else if (cmd.id.startsWith('mailbox:')) {
          final path = cmd.id.replaceFirst('mailbox:', '');
          final mailboxes = ref.read(inboxProvider.select((s) => s.mailboxes));
          final mailbox = mailboxes.where((m) => m.path == path).firstOrNull;
          if (mailbox != null) {
            GoRouter.of(ctx).go(CrusaderRoutes.inbox);
            ref.read(inboxProvider.notifier).selectMailbox(mailbox);
          }
        }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final commands = _filteredCommands();

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, commands.length - 1);
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, commands.length - 1);
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (commands.isNotEmpty && _selectedIndex < commands.length) {
        _executeCommand(commands[_selectedIndex]);
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;
    final textTheme = Theme.of(context).textTheme;
    final commands = _filteredCommands();

    // Clamp selection to bounds.
    if (_selectedIndex >= commands.length) {
      _selectedIndex = math.max(0, commands.length - 1);
    }

    // Group commands by category for display.
    final grouped = <CommandCategory, List<(int, PaletteCommand)>>{};
    for (int i = 0; i < commands.length; i++) {
      final cmd = commands[i];
      grouped.putIfAbsent(cmd.category, () => []).add((i, cmd));
    }

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child:
          Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: 540,
                          constraints: const BoxConstraints(maxHeight: 480),
                          decoration: BoxDecoration(
                            color: CrusaderBlacks.elevated.withValues(
                              alpha: 0.92,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: glass.panelBorderColor,
                              width: glass.borderWidth,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 0,
                                offset: const Offset(0, 16),
                              ),
                              BoxShadow(
                                color: accents.primaryGlow.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 60,
                                spreadRadius: -10,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── Search Input ──
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        size: 20,
                                        color: accents.primary.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _focusNode,
                                          autofocus: true,
                                          onChanged: (value) {
                                            setState(() {
                                              _query = value;
                                              _selectedIndex = 0;
                                            });
                                          },
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: CrusaderGrays.bright,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Type a command...',
                                            hintStyle: textTheme.bodyLarge
                                                ?.copyWith(
                                                  color: CrusaderGrays.muted,
                                                ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            fillColor: Colors.transparent,
                                            filled: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          color: CrusaderGrays.border
                                              .withValues(alpha: 0.5),
                                        ),
                                        child: Text(
                                          'ESC',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: CrusaderGrays.muted,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Divider
                                Container(
                                  height: 0.5,
                                  color: CrusaderGrays.border.withValues(
                                    alpha: 0.5,
                                  ),
                                ),

                                // ── Command List ──
                                if (commands.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          size: 28,
                                          color: CrusaderGrays.subtle,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No matching commands',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: CrusaderGrays.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Flexible(
                                    child: ListView(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      shrinkWrap: true,
                                      children: [
                                        for (final cat in grouped.keys) ...[
                                          // Section header
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              10,
                                              16,
                                              4,
                                            ),
                                            child: Text(
                                              _categoryLabel(cat).toUpperCase(),
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: CrusaderGrays.muted,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1.2,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                          for (final (index, cmd)
                                              in grouped[cat]!)
                                            _CommandRow(
                                              command: cmd,
                                              isSelected:
                                                  index == _selectedIndex,
                                              accents: accents,
                                              textTheme: textTheme,
                                              onTap: () => _executeCommand(cmd),
                                              onHover: () {
                                                setState(
                                                  () => _selectedIndex = index,
                                                );
                                              },
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),

                                // ── Footer hints ──
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: CrusaderGrays.border.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _HintBadge(label: '\u2191\u2193'),
                                      const SizedBox(width: 4),
                                      Text(
                                        'navigate',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: CrusaderGrays.muted,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      _HintBadge(label: '\u21B5'),
                                      const SizedBox(width: 4),
                                      Text(
                                        'select',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: CrusaderGrays.muted,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      _HintBadge(label: 'esc'),
                                      const SizedBox(width: 4),
                                      Text(
                                        'close',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: CrusaderGrays.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 150.ms)
              .scale(
                begin: const Offset(0.97, 0.97),
                end: const Offset(1, 1),
                duration: 200.ms,
                curve: Curves.easeOutCubic,
              )
              .slideY(begin: -0.02, end: 0, duration: 200.ms),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Command Row
// ─────────────────────────────────────────────────────────────────────────────

class _CommandRow extends StatefulWidget {
  const _CommandRow({
    required this.command,
    required this.isSelected,
    required this.accents,
    required this.textTheme,
    required this.onTap,
    required this.onHover,
  });

  final PaletteCommand command;
  final bool isSelected;
  final CrusaderAccentTheme accents;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  State<_CommandRow> createState() => _CommandRowState();
}

class _CommandRowState extends State<_CommandRow> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isSelected
                ? widget.accents.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                widget.command.icon,
                size: 16,
                color: widget.isSelected
                    ? widget.accents.primary
                    : CrusaderGrays.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.command.label,
                      style: widget.textTheme.bodyMedium?.copyWith(
                        color: widget.isSelected
                            ? CrusaderGrays.bright
                            : CrusaderGrays.primary,
                        fontWeight: widget.isSelected
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                    if (widget.command.subtitle != null)
                      Text(
                        widget.command.subtitle!,
                        style: widget.textTheme.labelSmall?.copyWith(
                          color: CrusaderGrays.muted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.command.shortcut != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: CrusaderGrays.border.withValues(alpha: 0.5),
                    border: Border.all(
                      color: CrusaderGrays.subtle.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    widget.command.shortcut!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: CrusaderGrays.muted,
                      letterSpacing: 0.5,
                    ),
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
// Hint Badge — small keyboard hint in footer
// ─────────────────────────────────────────────────────────────────────────────

class _HintBadge extends StatelessWidget {
  const _HintBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: CrusaderGrays.border.withValues(alpha: 0.5),
        border: Border.all(
          color: CrusaderGrays.subtle.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: CrusaderGrays.muted,
        ),
      ),
    );
  }
}
