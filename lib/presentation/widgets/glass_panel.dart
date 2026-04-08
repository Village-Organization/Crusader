/// Crusader Design System — Glass Panel Widget
///
/// Reusable frosted-glass container with backdrop blur,
/// subtle border glow, and soft inner/outer shadows.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/glass_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Glass Panel
// ─────────────────────────────────────────────────────────────────────────────

/// A frosted-glass panel that reads its styling from [CrusaderGlassTheme].
///
/// Usage:
/// ```dart
/// GlassPanel(
///   child: Text('Hello, Crusader'),
/// )
/// ```
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blurSigma,
    this.color,
    this.borderColor,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? blurSigma;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;

    final radius = borderRadius ?? glass.borderRadius;
    final sigma = blurSigma ?? glass.blurSigma;
    final fill = color ?? glass.panelColor;
    final border = borderColor ?? glass.panelBorderColor;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: border,
                width: glass.borderWidth,
              ),
              boxShadow: [
                // Outer shadow – depth
                BoxShadow(
                  color: glass.panelShadowColor.withValues(
                    alpha: glass.outerShadowOpacity,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                // Inner highlight – top-left glow
                BoxShadow(
                  color: glass.panelHighlightColor.withValues(
                    alpha: glass.innerShadowOpacity,
                  ),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Icon Button — minimal icon button with glass hover
// ─────────────────────────────────────────────────────────────────────────────

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;

    Widget button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(glass.borderRadius * 0.6),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(glass.borderRadius * 0.6),
          onTap: onPressed,
          hoverColor: glass.panelColor,
          splashColor: glass.panelHighlightColor,
          child: Center(
            child: Icon(icon, size: iconSize),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
