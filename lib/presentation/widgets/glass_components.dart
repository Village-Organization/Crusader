/// Crusader Design System — Glass Components
///
/// Extended glass-morphism widget library:
/// - GlassCard: Elevated glass with hover glow & press feedback
/// - GlassChip: Compact tag/filter chip
/// - GlassBadge: Notification count badge
/// - GlassTextField: Styled text input
/// - ShimmerSkeleton: Loading placeholder with animated shimmer
/// - NeonGlowBorder: Animated accent-colored border glow
/// - GlassTooltipBadge: Keyboard shortcut hint badge
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Glass Card — elevated glass panel with hover glow
// ─────────────────────────────────────────────────────────────────────────────

/// A glass panel that reacts to hover with a subtle neon glow effect.
/// Use for interactive cards (thread tiles, account cards, etc.)
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.borderRadius = 14,
    this.glowColor,
    this.isSelected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? glowColor;
  final bool isSelected;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final glow = widget.glowColor ?? accents.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: _isHovered
                ? glass.panelColor.withValues(alpha: 0.15)
                : widget.isSelected
                ? glow.withValues(alpha: 0.06)
                : glass.panelColor,
            border: Border.all(
              color: _isHovered
                  ? glow.withValues(alpha: 0.25)
                  : widget.isSelected
                  ? glow.withValues(alpha: 0.2)
                  : glass.panelBorderColor,
              width: glass.borderWidth,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: glow.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: -2,
                )
              else if (widget.isSelected)
                BoxShadow(
                  color: glow.withValues(alpha: 0.10),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              BoxShadow(
                color: glass.panelShadowColor.withValues(
                  alpha: glass.outerShadowOpacity,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: widget.padding ?? const EdgeInsets.all(16),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Chip — compact tag / filter / mailbox chip
// ─────────────────────────────────────────────────────────────────────────────

class GlassChip extends StatefulWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.isActive = false,
    this.activeColor,
    this.onTap,
    this.badge,
  });

  final String label;
  final IconData? icon;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;
  final int? badge;

  @override
  State<GlassChip> createState() => _GlassChipState();
}

class _GlassChipState extends State<GlassChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final textTheme = Theme.of(context).textTheme;
    final color = widget.activeColor ?? accents.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isActive
                ? color.withValues(alpha: 0.12)
                : _isHovered
                ? CrusaderGrays.border.withValues(alpha: 0.5)
                : CrusaderGrays.border.withValues(alpha: 0.25),
            border: Border.all(
              color: widget.isActive
                  ? color.withValues(alpha: 0.3)
                  : _isHovered
                  ? CrusaderGrays.border.withValues(alpha: 0.7)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.isActive ? color : CrusaderGrays.secondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: textTheme.labelMedium?.copyWith(
                  color: widget.isActive ? color : CrusaderGrays.secondary,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
              if (widget.badge != null && widget.badge! > 0) ...[
                const SizedBox(width: 6),
                GlassBadge(
                  count: widget.badge!,
                  color: widget.isActive ? color : CrusaderGrays.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Badge — compact notification count
// ─────────────────────────────────────────────────────────────────────────────

class GlassBadge extends StatelessWidget {
  const GlassBadge({
    super.key,
    required this.count,
    this.color,
    this.small = false,
  });

  final int count;
  final Color? color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final badgeColor = color ?? accents.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 5,
        vertical: small ? 0 : 1,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: badgeColor.withValues(alpha: 0.2),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
          height: 1.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Text Field — styled text input with glass background
// ─────────────────────────────────────────────────────────────────────────────

class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.borderRadius = 12,
    this.maxLines = 1,
    this.expands = false,
    this.textAlignVertical,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final double borderRadius;
  final int? maxLines;
  final bool expands;
  final TextAlignVertical? textAlignVertical;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: glass.panelColor,
        border: Border.all(
          color: _isFocused
              ? accents.primary.withValues(alpha: 0.4)
              : glass.panelBorderColor,
          width: glass.borderWidth,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: accents.primaryGlow.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (widget.prefixIcon != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Icon(
                widget.prefixIcon,
                size: 18,
                color: _isFocused ? accents.primary : CrusaderGrays.muted,
              ),
            ),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              maxLines: widget.expands ? null : widget.maxLines,
              expands: widget.expands,
              textAlignVertical: widget.textAlignVertical,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: CrusaderGrays.muted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.prefixIcon != null ? 10 : 14,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
          if (widget.suffixIcon != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: widget.suffixIcon,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Skeleton — loading placeholder with animated gradient
// ─────────────────────────────────────────────────────────────────────────────

/// A loading skeleton that shimmers. Use as a placeholder while data loads.
///
/// ```dart
/// ShimmerSkeleton(width: 200, height: 14, borderRadius: 4)
/// ```
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
    this.isCircle = false,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: isCircle ? height : width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            color: CrusaderGrays.border.withValues(alpha: 0.4),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: CrusaderGrays.subtle.withValues(alpha: 0.3),
        );
  }
}

/// A full email-row shaped skeleton for inbox loading states.
class ThreadTileSkeleton extends StatelessWidget {
  const ThreadTileSkeleton({super.key, this.index = 0});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Unread dot placeholder
            const SizedBox(width: 8),
            const SizedBox(width: 12),
            // Avatar
            const ShimmerSkeleton(height: 36, isCircle: true),
            const SizedBox(width: 14),
            // Text lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerSkeleton(
                        width: 100 + (index % 3) * 30,
                        height: 12,
                      ),
                      const Spacer(),
                      const ShimmerSkeleton(width: 40, height: 10),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ShimmerSkeleton(width: 180 + (index % 2) * 60, height: 12),
                  const SizedBox(height: 6),
                  const ShimmerSkeleton(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keyboard Shortcut Badge — shows a hotkey hint
// ─────────────────────────────────────────────────────────────────────────────

class KeyboardShortcutBadge extends StatelessWidget {
  const KeyboardShortcutBadge({super.key, required this.shortcut});

  final String shortcut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: CrusaderGrays.border.withValues(alpha: 0.5),
        border: Border.all(
          color: CrusaderGrays.subtle.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        shortcut,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: CrusaderGrays.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neon Glow Border — animated accent border for focus states
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps a child with an animated glowing neon border that pulses.
class NeonGlowBorder extends StatefulWidget {
  const NeonGlowBorder({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = 14,
    this.glowIntensity = 0.4,
    this.animate = true,
  });

  final Widget child;
  final Color? color;
  final double borderRadius;
  final double glowIntensity;
  final bool animate;

  @override
  State<NeonGlowBorder> createState() => _NeonGlowBorderState();
}

class _NeonGlowBorderState extends State<NeonGlowBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final color = widget.color ?? accents.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = widget.animate
            ? widget.glowIntensity *
                  (0.5 + 0.5 * math.sin(_controller.value * math.pi))
            : widget.glowIntensity;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: glow * 0.5),
                blurRadius: 12,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: color.withValues(alpha: glow * 0.2),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Divider — subtle themed divider
// ─────────────────────────────────────────────────────────────────────────────

class GlassDivider extends StatelessWidget {
  const GlassDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = 0.5,
  });

  final double indent;
  final double endIndent;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Container(
        height: thickness,
        color: CrusaderGrays.border.withValues(alpha: 0.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sender Avatar — reusable across thread tile, thread detail, compose
// ─────────────────────────────────────────────────────────────────────────────

class SenderAvatar extends StatelessWidget {
  const SenderAvatar({
    super.key,
    required this.initial,
    this.color,
    this.size = 36,
    this.fontSize = 14,
    this.avatarBytes,
  });

  final String initial;
  final Color? color;
  final double size;
  final double fontSize;

  /// Pre-fetched Gravatar image bytes. When non-null, the avatar image is
  /// displayed inside the circle instead of the text initial.
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final c = color ?? accents.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: avatarBytes == null
            ? LinearGradient(
                colors: [c.withValues(alpha: 0.2), c.withValues(alpha: 0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: avatarBytes != null
              ? c.withValues(alpha: 0.08)
              : c.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarBytes != null
          ? Image.memory(
              avatarBytes!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Fade in gracefully.
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: c,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),
            ),
    );
  }
}
