/// Crusader — Snooze Picker Dialog
///
/// Beautiful glassmorphic dialog for choosing when to snooze a thread.
/// Offers preset options (later today, tomorrow, next week) and a
/// custom date/time picker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';

/// Shows the snooze picker and returns the chosen [DateTime], or null
/// if the user cancelled.
Future<DateTime?> showSnoozePicker(BuildContext context) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => const _SnoozePickerDialog(),
  );
}

class _SnoozePickerDialog extends StatelessWidget {
  const _SnoozePickerDialog();

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;
    final textTheme = Theme.of(context).textTheme;

    final now = DateTime.now();

    // Compute preset snooze targets.
    final presets = _buildPresets(now);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: glass.panelColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: glass.panelBorderColor,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.snooze_rounded,
                      size: 20,
                      color: accents.tertiary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Snooze until...',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──
              Divider(
                height: 1,
                thickness: 0.5,
                color: CrusaderGrays.border.withValues(alpha: 0.3),
              ),

              // ── Preset Options ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final preset in presets)
                      _SnoozeOption(
                        icon: preset.icon,
                        label: preset.label,
                        subtitle: preset.subtitle,
                        color: accents.tertiary,
                        onTap: () =>
                            Navigator.of(context).pop(preset.dateTime),
                      ),

                    // ── Custom date/time ──
                    _SnoozeOption(
                      icon: Icons.calendar_month_rounded,
                      label: 'Pick a date & time',
                      subtitle: 'Custom',
                      color: CrusaderGrays.secondary,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: now.add(const Duration(days: 1)),
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: accents.primary,
                                surface: CrusaderBlacks.elevated,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (date == null || !context.mounted) return;

                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: accents.primary,
                                surface: CrusaderBlacks.elevated,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (time == null || !context.mounted) return;

                        final result = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        Navigator.of(context).pop(result);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 200.ms)
            .scaleXY(begin: 0.95, end: 1, duration: 200.ms),
      ),
    );
  }

  List<_SnoozePreset> _buildPresets(DateTime now) {
    final presets = <_SnoozePreset>[];

    // "Later today" — 3 hours from now (only if before 9pm)
    if (now.hour < 21) {
      final laterToday = now.add(const Duration(hours: 3));
      presets.add(_SnoozePreset(
        icon: Icons.access_time_rounded,
        label: 'Later today',
        subtitle: _formatTime(laterToday),
        dateTime: laterToday,
      ));
    }

    // "Tomorrow morning" — tomorrow at 8am
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 8, 0);
    presets.add(_SnoozePreset(
      icon: Icons.wb_sunny_outlined,
      label: 'Tomorrow morning',
      subtitle: _formatDateShort(tomorrow),
      dateTime: tomorrow,
    ));

    // "This weekend" — next Saturday at 9am (only if today is Mon-Thu)
    if (now.weekday <= 4) {
      final daysUntilSat = 6 - now.weekday;
      final saturday = DateTime(
        now.year, now.month, now.day + daysUntilSat, 9, 0,
      );
      presets.add(_SnoozePreset(
        icon: Icons.weekend_outlined,
        label: 'This weekend',
        subtitle: _formatDateShort(saturday),
        dateTime: saturday,
      ));
    }

    // "Next week" — next Monday at 8am
    final daysUntilMon = (8 - now.weekday) % 7;
    final nextMonday = DateTime(
      now.year,
      now.month,
      now.day + (daysUntilMon == 0 ? 7 : daysUntilMon),
      8,
      0,
    );
    presets.add(_SnoozePreset(
      icon: Icons.next_week_outlined,
      label: 'Next week',
      subtitle: _formatDateShort(nextMonday),
      dateTime: nextMonday,
    ));

    return presets;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  String _formatDateShort(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day} at ${_formatTime(dt)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SnoozePreset {
  const _SnoozePreset({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.dateTime,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final DateTime dateTime;
}

// ─────────────────────────────────────────────────────────────────────────────

class _SnoozeOption extends StatefulWidget {
  const _SnoozeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_SnoozeOption> createState() => _SnoozeOptionState();
}

class _SnoozeOptionState extends State<_SnoozeOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _isHovered
                ? CrusaderGrays.border.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: _isHovered ? widget.color : CrusaderGrays.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: CrusaderGrays.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
