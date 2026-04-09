/// Crusader — Thread Tile Widget
///
/// A single email thread row in the inbox list. Glassmorphic,
/// animated, with sender avatar, subject, snippet, date, flags.
/// Designed to feel like Superhuman meets Linear.
///
/// Supports right-click context menu via [onSecondaryTap].
/// Shows hover quick-action buttons (archive, snooze, delete, star)
/// on mouse hover for fast triage without right-clicking.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';
import '../../domain/entities/email_thread.dart';
import '../../features/inbox/inbox_providers.dart';
import 'glass_components.dart';

class ThreadTile extends ConsumerStatefulWidget {
  const ThreadTile({
    super.key,
    required this.thread,
    required this.onTap,
    this.onLongPress,
    this.onFlagToggle,
    this.onSecondaryTap,
    this.onArchive,
    this.onDelete,
    this.onSnooze,
    this.isSelected = false,
    this.animationDelay = Duration.zero,
  });

  final EmailThread thread;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFlagToggle;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onSnooze;

  /// Called on right-click with the tap-down position (for context menu).
  final void Function(Offset globalPosition)? onSecondaryTap;
  final bool isSelected;
  final Duration animationDelay;

  @override
  ConsumerState<ThreadTile> createState() => _ThreadTileState();
}

class _ThreadTileState extends ConsumerState<ThreadTile> {
  bool _hasAnimated = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;
    final textTheme = Theme.of(context).textTheme;
    final isUnread = widget.thread.hasUnread;

    // Gravatar lookup — async, returns null while loading or on miss.
    final avatarAsync = ref.watch(avatarProvider(widget.thread.from.address));
    final avatarBytes = avatarAsync.valueOrNull;

    final shouldAnimate = !_hasAnimated;
    if (!_hasAnimated) _hasAnimated = true;

    Widget tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onSecondaryTapDown: widget.onSecondaryTap != null
              ? (details) => widget.onSecondaryTap!(details.globalPosition)
              : null,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              hoverColor: glass.panelColor,
              splashColor: accents.primaryGlow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: widget.isSelected
                      ? accents.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: widget.isSelected
                      ? Border.all(
                          color: accents.primary.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    // ── Unread dot ──
                    SizedBox(
                      width: 8,
                      child: isUnread
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accents.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: accents.primaryGlow,
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // ── Avatar ──
                    SenderAvatar(
                      initial: widget.thread.from.initial,
                      color: _avatarColor(widget.thread.from.address, accents),
                      avatarBytes: avatarBytes,
                    ),
                    const SizedBox(width: 14),

                    // ── Content ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: sender + date / hover actions
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.thread.from.shortLabel,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: isUnread
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isUnread
                                              ? CrusaderGrays.bright
                                              : CrusaderGrays.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.thread.isConversation) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          color: CrusaderGrays.border,
                                        ),
                                        child: Text(
                                          '${widget.thread.messageCount}',
                                          style: textTheme.labelSmall?.copyWith(
                                            fontSize: 10,
                                            color: CrusaderGrays.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // ── Hover quick actions OR date ──
                              if (_isHovered)
                                _HoverActions(
                                  thread: widget.thread,
                                  accents: accents,
                                  onArchive: widget.onArchive,
                                  onSnooze: widget.onSnooze,
                                  onDelete: widget.onDelete,
                                  onFlag: widget.onFlagToggle,
                                )
                              else
                                Text(
                                  widget.thread.relativeDate,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: isUnread
                                        ? accents.primary
                                        : CrusaderGrays.muted,
                                    fontWeight: isUnread
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 3),

                          // Subject
                          Text(
                            widget.thread.subject.isEmpty
                                ? '(No Subject)'
                                : widget.thread.subject,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: isUnread
                                  ? CrusaderGrays.bright
                                  : CrusaderGrays.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),

                          // Snippet + icons
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.thread.snippet,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: CrusaderGrays.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.thread.hasAttachments) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 13,
                                  color: CrusaderGrays.muted,
                                ),
                              ],
                              if (widget.thread.isFlagged) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: accents.tertiary,
                                ),
                              ],
                            ],
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
    );

    if (shouldAnimate) {
      tile = tile
          .animate(delay: widget.animationDelay)
          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
          .slideX(begin: 0.02, end: 0, duration: 300.ms);
    }

    return tile;
  }

  /// Deterministic avatar color from email address hash.
  Color _avatarColor(String email, CrusaderAccentTheme accents) {
    final colors = [
      accents.primary,
      accents.secondary,
      accents.tertiary,
      CrusaderAccents.green,
    ];
    return colors[email.hashCode.abs() % colors.length];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hover Quick Actions — inline icons that appear on thread tile hover
// ─────────────────────────────────────────────────────────────────────────────

class _HoverActions extends StatelessWidget {
  const _HoverActions({
    required this.thread,
    required this.accents,
    this.onArchive,
    this.onSnooze,
    this.onDelete,
    this.onFlag,
  });

  final EmailThread thread;
  final CrusaderAccentTheme accents;
  final VoidCallback? onArchive;
  final VoidCallback? onSnooze;
  final VoidCallback? onDelete;
  final VoidCallback? onFlag;

  @override
  Widget build(BuildContext context) {
    return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HoverActionIcon(
              icon: Icons.archive_outlined,
              tooltip: 'Archive (E)',
              onTap: onArchive,
              hoverColor: accents.primary,
            ),
            const SizedBox(width: 2),
            _HoverActionIcon(
              icon: Icons.snooze_rounded,
              tooltip: 'Snooze (B)',
              onTap: onSnooze,
              hoverColor: accents.tertiary,
            ),
            const SizedBox(width: 2),
            _HoverActionIcon(
              icon: thread.isFlagged
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              tooltip: thread.isFlagged ? 'Unflag (S)' : 'Flag (S)',
              onTap: onFlag,
              hoverColor: accents.tertiary,
              isActive: thread.isFlagged,
            ),
            const SizedBox(width: 2),
            _HoverActionIcon(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete (#)',
              onTap: onDelete,
              hoverColor: CrusaderAccents.red,
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 120.ms)
        .slideX(begin: 0.05, end: 0, duration: 150.ms, curve: Curves.easeOut);
  }
}

class _HoverActionIcon extends StatefulWidget {
  const _HoverActionIcon({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.hoverColor,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? hoverColor;
  final bool isActive;

  @override
  State<_HoverActionIcon> createState() => _HoverActionIconState();
}

class _HoverActionIconState extends State<_HoverActionIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.hoverColor ?? CrusaderGrays.secondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        preferBelow: false,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _isHovered
                  ? color.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: widget.isActive
                  ? color
                  : _isHovered
                  ? color
                  : CrusaderGrays.muted,
            ),
          ),
        ),
      ),
    );
  }
}
