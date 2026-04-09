/// Crusader — Glass Toast Notifications
///
/// Custom glass-morphic toast notification system that replaces plain
/// SnackBars with branded, animated overlay toasts. Features:
/// - Glass-blur background matching the design system
/// - Undo action support (for archive, delete, snooze)
/// - Auto-dismiss with progress indicator
/// - Stacked toasts with smooth animations
/// - Success, error, info, and action variants
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Toast Types
// ─────────────────────────────────────────────────────────────────────────────

enum GlassToastType { info, success, error, action }

// ─────────────────────────────────────────────────────────────────────────────
// Toast Data
// ─────────────────────────────────────────────────────────────────────────────

class GlassToastData {
  const GlassToastData({
    required this.message,
    this.type = GlassToastType.info,
    this.icon,
    this.duration = const Duration(seconds: 3),
    this.undoLabel,
    this.onUndo,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final GlassToastType type;
  final IconData? icon;
  final Duration duration;
  final String? undoLabel;
  final VoidCallback? onUndo;
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get hasAction => onUndo != null || onAction != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast Controller — manages toast overlay entries
// ─────────────────────────────────────────────────────────────────────────────

class CrusaderToast {
  CrusaderToast._();

  static final CrusaderToast _instance = CrusaderToast._();
  static CrusaderToast get instance => _instance;

  OverlayEntry? _currentEntry;
  Timer? _dismissTimer;

  /// Show a toast notification.
  void show(BuildContext context, GlassToastData data) {
    dismiss();

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (ctx) => _GlassToastOverlay(data: data, onDismiss: dismiss),
    );

    overlay.insert(_currentEntry!);

    _dismissTimer = Timer(data.duration, dismiss);
  }

  /// Dismiss the current toast.
  void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  // ── Convenience factories ──

  static void info(BuildContext context, String message, {IconData? icon}) {
    _instance.show(
      context,
      GlassToastData(
        message: message,
        type: GlassToastType.info,
        icon: icon ?? Icons.info_outline_rounded,
      ),
    );
  }

  static void success(BuildContext context, String message, {IconData? icon}) {
    _instance.show(
      context,
      GlassToastData(
        message: message,
        type: GlassToastType.success,
        icon: icon ?? Icons.check_circle_outline_rounded,
      ),
    );
  }

  static void error(BuildContext context, String message, {IconData? icon}) {
    _instance.show(
      context,
      GlassToastData(
        message: message,
        type: GlassToastType.error,
        icon: icon ?? Icons.error_outline_rounded,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static void withUndo(
    BuildContext context,
    String message, {
    IconData? icon,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
    _instance.show(
      context,
      GlassToastData(
        message: message,
        type: GlassToastType.action,
        icon: icon,
        undoLabel: 'Undo',
        onUndo: onUndo,
        duration: duration,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Toast Overlay Widget
// ─────────────────────────────────────────────────────────────────────────────

class _GlassToastOverlay extends StatefulWidget {
  const _GlassToastOverlay({required this.data, required this.onDismiss});

  final GlassToastData data;
  final VoidCallback onDismiss;

  @override
  State<_GlassToastOverlay> createState() => _GlassToastOverlayState();
}

class _GlassToastOverlayState extends State<_GlassToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.data.duration,
    )..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Color _typeColor(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>();
    switch (widget.data.type) {
      case GlassToastType.info:
        return accents?.primary ?? CrusaderAccents.cyan;
      case GlassToastType.success:
        return CrusaderAccents.green;
      case GlassToastType.error:
        return CrusaderAccents.red;
      case GlassToastType.action:
        return accents?.primary ?? CrusaderAccents.cyan;
    }
  }

  IconData _typeIcon() {
    if (widget.data.icon != null) return widget.data.icon!;
    switch (widget.data.type) {
      case GlassToastType.info:
        return Icons.info_outline_rounded;
      case GlassToastType.success:
        return Icons.check_circle_outline_rounded;
      case GlassToastType.error:
        return Icons.error_outline_rounded;
      case GlassToastType.action:
        return Icons.info_outline_rounded;
    }
  }

  void _handleUndo() {
    widget.data.onUndo?.call();
    widget.onDismiss();
  }

  void _handleAction() {
    widget.data.onAction?.call();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(context);
    final textTheme = Theme.of(context).textTheme;

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child:
            GestureDetector(
                  onTap: widget.onDismiss,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 440,
                          minWidth: 240,
                        ),
                        decoration: BoxDecoration(
                          color: CrusaderBlacks.elevated.withValues(
                            alpha: 0.88,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: color.withValues(alpha: 0.06),
                              blurRadius: 30,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon with glow
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color.withValues(alpha: 0.12),
                                    ),
                                    child: Icon(
                                      _typeIcon(),
                                      size: 15,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Message
                                  Flexible(
                                    child: Text(
                                      widget.data.message,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: CrusaderGrays.bright,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Undo / action button
                                  if (widget.data.onUndo != null) ...[
                                    const SizedBox(width: 16),
                                    _ToastActionButton(
                                      label: widget.data.undoLabel ?? 'Undo',
                                      color: color,
                                      onTap: _handleUndo,
                                    ),
                                  ],
                                  if (widget.data.onAction != null &&
                                      widget.data.onUndo == null) ...[
                                    const SizedBox(width: 16),
                                    _ToastActionButton(
                                      label:
                                          widget.data.actionLabel ?? 'Action',
                                      color: color,
                                      onTap: _handleAction,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Progress bar
                            AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    color: CrusaderGrays.border.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor:
                                        1.0 - _progressController.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                        ),
                                        gradient: LinearGradient(
                                          colors: [
                                            color.withValues(alpha: 0.6),
                                            color.withValues(alpha: 0.2),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 200.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                )
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  duration: 200.ms,
                ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _ToastActionButton extends StatefulWidget {
  const _ToastActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ToastActionButton> createState() => _ToastActionButtonState();
}

class _ToastActionButtonState extends State<_ToastActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _isHovered
                ? widget.color.withValues(alpha: 0.2)
                : widget.color.withValues(alpha: 0.1),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
