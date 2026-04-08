/// Crusader — Settings Screen
///
/// Polished settings with sections:
/// - Appearance (theme toggle, accent color, font family)
/// - Accounts (list, add, remove)
/// - Notifications
/// - Keyboard shortcuts preview
/// - About & version info
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/di/router.dart';
import '../../core/di/theme_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';
import '../../domain/entities/email_account.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/compose/compose_providers.dart';
import '../../features/compose/signature_providers.dart';
import '../widgets/glass_components.dart';
import '../widgets/glass_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final textTheme = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final accountState = ref.watch(accountProvider);
    final accentIndex = ref.watch(accentColorProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final signatureState = ref.watch(signatureProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
                  'Settings',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: -0.04, end: 0, duration: 350.ms),

            const SizedBox(height: 20),

            // ── Appearance Section ──
            _SectionHeader(title: 'APPEARANCE', delay: 80),
            const SizedBox(height: 8),
            GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.dark_mode_rounded,
                        iconColor: accents.tertiary,
                        label: 'Dark Mode',
                        subtitle: 'Deep blacks with neon accents',
                        trailing: Switch.adaptive(
                          value: themeMode == ThemeMode.dark,
                          activeTrackColor: accents.primary,
                          onChanged: (_) {
                            ref.read(themeModeProvider.notifier).toggle();
                          },
                        ),
                      ),
                      const GlassDivider(indent: 50),
                      _SettingsRow(
                        icon: Icons.palette_outlined,
                        iconColor: accents.primary,
                        label: 'Accent Color',
                        subtitle: accentColorOptions[accentIndex].name,
                        trailing: Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              for (
                                int i = 0;
                                i < accentColorOptions.length;
                                i++
                              )
                                _ColorDot(
                                  color: accentColorOptions[i].primary,
                                  isSelected: i == accentIndex,
                                  onTap: () {
                                    ref
                                        .read(accentColorProvider.notifier)
                                        .setColor(i);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const GlassDivider(indent: 50),
                      _SettingsRow(
                        icon: Icons.text_fields_rounded,
                        iconColor: accents.secondary,
                        label: 'Font Family',
                        subtitle: fontFamily,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: CrusaderGrays.muted,
                          size: 20,
                        ),
                        onTap: () => _showFontPicker(context, ref, fontFamily),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 20),

            // ── Accounts Section ──
            _SectionHeader(title: 'ACCOUNTS', delay: 160),
            const SizedBox(height: 8),
            GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.add_rounded,
                        iconColor: accents.primary,
                        label: 'Add Email Account',
                        subtitle: 'Gmail, Outlook, or any IMAP provider',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: CrusaderGrays.muted,
                          size: 20,
                        ),
                        onTap: () => context.push(CrusaderRoutes.addAccount),
                      ),
                      if (accountState.hasAccounts) ...[
                        const GlassDivider(indent: 50),
                        ...accountState.accounts.map(
                          (account) => _AccountRow(
                            account: account,
                            accents: accents,
                            isActive:
                                account.id == accountState.activeAccount?.id,
                            onRemove: () => ref
                                .read(accountProvider.notifier)
                                .removeAccount(account.id),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 180.ms)
                .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 180.ms),

            const SizedBox(height: 20),

            // ── Signatures Section ──
            _SectionHeader(title: 'SIGNATURES', delay: 200),
            const SizedBox(height: 8),
            GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.draw_rounded,
                        iconColor: accents.secondary,
                        label: 'Auto-append Signature',
                        subtitle: 'Add signature to outgoing emails',
                        trailing: Switch.adaptive(
                          value: signatureState.isEnabled,
                          activeTrackColor: accents.primary,
                          onChanged: (_) {
                            ref
                                .read(signatureProvider.notifier)
                                .toggleEnabled();
                          },
                        ),
                      ),
                      if (accountState.hasAccounts) ...[
                        const GlassDivider(indent: 50),
                        ...accountState.accounts.map(
                          (account) => _SignatureRow(
                            account: account,
                            accents: accents,
                            hasSignature: signatureState.hasSignature(
                              account.id,
                            ),
                            onTap: () => _showSignatureEditor(
                              context,
                              ref,
                              account,
                              signatureState.getSignature(account.id),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 220.ms)
                .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 220.ms),

            const SizedBox(height: 20),

            // ── Sending Section ──
            _SectionHeader(title: 'SENDING', delay: 240),
            const SizedBox(height: 8),
            GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: _SettingsRow(
                    icon: Icons.undo_rounded,
                    iconColor: accents.tertiary,
                    label: 'Undo Send Delay',
                    subtitle: _sendDelayLabel(ref.watch(sendDelayProvider)),
                    trailing: DropdownButton<int>(
                      value: ref.watch(sendDelayProvider),
                      dropdownColor: CrusaderBlacks.elevated,
                      borderRadius: BorderRadius.circular(10),
                      underline: const SizedBox.shrink(),
                      icon: Icon(
                        Icons.expand_more_rounded,
                        color: CrusaderGrays.muted,
                        size: 18,
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: CrusaderGrays.primary,
                      ),
                      items: sendDelayOptions.map((seconds) {
                        return DropdownMenuItem(
                          value: seconds,
                          child: Text(seconds == 0 ? 'Off' : '${seconds}s'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(sendDelayProvider.notifier).setDelay(value);
                        }
                      },
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 260.ms)
                .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 260.ms),

            const SizedBox(height: 20),

            // ── Keyboard Shortcuts Section ──
            _SectionHeader(title: 'KEYBOARD SHORTCUTS', delay: 320),
            const SizedBox(height: 8),
            GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      _ShortcutRow(label: 'Compose new email', shortcut: 'C'),
                      GlassDivider(indent: 8),
                      _ShortcutRow(label: 'Go to Inbox', shortcut: 'G I'),
                      GlassDivider(indent: 8),
                      _ShortcutRow(label: 'Search', shortcut: '/'),
                      GlassDivider(indent: 8),
                      _ShortcutRow(label: 'Reply', shortcut: 'R'),
                      GlassDivider(indent: 8),
                      _ShortcutRow(label: 'Forward', shortcut: 'F'),
                      GlassDivider(indent: 8),
                      _ShortcutRow(label: 'Archive', shortcut: 'E'),
                      GlassDivider(indent: 8),
                      _ShortcutRow(label: 'Delete', shortcut: '#'),
                      GlassDivider(indent: 8),
                      _ShortcutRow(label: 'Send', shortcut: 'Ctrl+Enter'),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 20),

            // ── About Section ──
            _SectionHeader(title: 'ABOUT', delay: 360),
            const SizedBox(height: 8),
            GlassPanel(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [accents.primary, accents.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crusader',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'v0.1.0 (Phase 5)',
                                style: textTheme.labelSmall?.copyWith(
                                  color: CrusaderGrays.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const GlassDivider(),
                      const SizedBox(height: 14),
                      Text(
                        'The sleek, modern email client that finally '
                        'feels good to use.',
                        style: textTheme.bodySmall?.copyWith(
                          color: CrusaderGrays.secondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 380.ms)
                .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 380.ms),
          ],
        ),
      ),
    );
  }

  void _showFontPicker(
    BuildContext context,
    WidgetRef ref,
    String currentFont,
  ) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _FontPickerDialog(
        currentFont: currentFont,
        accents: accents,
        glass: glass,
        onSelect: (font) {
          ref.read(fontFamilyProvider.notifier).setFont(font);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSignatureEditor(
    BuildContext context,
    WidgetRef ref,
    EmailAccount account,
    String currentSignature,
  ) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _SignatureEditorDialog(
        account: account,
        currentSignature: currentSignature,
        accents: accents,
        glass: glass,
        onSave: (signature) {
          ref
              .read(signatureProvider.notifier)
              .setSignature(account.id, signature);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  String _sendDelayLabel(int seconds) {
    if (seconds == 0) return 'Send immediately (no undo)';
    return 'Wait ${seconds}s before sending';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signature Row — per-account signature summary
// ─────────────────────────────────────────────────────────────────────────────

class _SignatureRow extends StatefulWidget {
  const _SignatureRow({
    required this.account,
    required this.accents,
    required this.hasSignature,
    required this.onTap,
  });

  final EmailAccount account;
  final CrusaderAccentTheme accents;
  final bool hasSignature;
  final VoidCallback onTap;

  @override
  State<_SignatureRow> createState() => _SignatureRowState();
}

class _SignatureRowState extends State<_SignatureRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final providerColor = widget.account.provider == EmailProvider.gmail
        ? const Color(0xFF4285F4)
        : const Color(0xFF0078D4);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _isHovered
                ? CrusaderGrays.border.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: providerColor.withValues(alpha: 0.1),
                ),
                child: Icon(
                  widget.account.provider == EmailProvider.gmail
                      ? Icons.mail_rounded
                      : Icons.business_rounded,
                  size: 17,
                  color: providerColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.account.email,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.hasSignature ? 'Signature set' : 'No signature',
                      style: textTheme.labelSmall?.copyWith(
                        color: widget.hasSignature
                            ? widget.accents.primary.withValues(alpha: 0.7)
                            : CrusaderGrays.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.hasSignature)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accents.primary,
                    boxShadow: [
                      BoxShadow(
                        color: widget.accents.primary.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                ),
              Icon(
                Icons.edit_rounded,
                size: 15,
                color: _isHovered
                    ? widget.accents.primary
                    : CrusaderGrays.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signature Editor Dialog — glassmorphic per-account signature editor
// ─────────────────────────────────────────────────────────────────────────────

class _SignatureEditorDialog extends StatefulWidget {
  const _SignatureEditorDialog({
    required this.account,
    required this.currentSignature,
    required this.accents,
    required this.glass,
    required this.onSave,
  });

  final EmailAccount account;
  final String currentSignature;
  final CrusaderAccentTheme accents;
  final CrusaderGlassTheme glass;
  final ValueChanged<String> onSave;

  @override
  State<_SignatureEditorDialog> createState() => _SignatureEditorDialogState();
}

class _SignatureEditorDialogState extends State<_SignatureEditorDialog> {
  late final TextEditingController _controller;
  bool _saveHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentSignature);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 520,
              constraints: const BoxConstraints(maxHeight: 520),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xF0141420),
                border: Border.all(
                  color: CrusaderGrays.border.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 60,
                    spreadRadius: -10,
                  ),
                  BoxShadow(
                    color: widget.accents.primary.withValues(alpha: 0.04),
                    blurRadius: 80,
                    spreadRadius: -20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 16, 20),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                widget.accents.secondary.withValues(
                                  alpha: 0.15,
                                ),
                                widget.accents.primary.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.draw_rounded,
                            size: 18,
                            color: widget.accents.secondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Signature',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.account.email,
                                style: textTheme.labelSmall?.copyWith(
                                  color: CrusaderGrays.muted,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: CrusaderGrays.muted,
                          ),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: widget.glass.panelBorderColor),

                  // ── Editor ──
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: CrusaderBlacks.deepBlack,
                          border: Border.all(
                            color: CrusaderGrays.border.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: textTheme.bodySmall?.copyWith(
                            color: CrusaderGrays.primary,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Enter your signature...\n\n'
                                'Example:\n'
                                'Best regards,\n'
                                'John Doe\n'
                                'john@example.com',
                            hintStyle: textTheme.bodySmall?.copyWith(
                              color: CrusaderGrays.muted.withValues(alpha: 0.5),
                              height: 1.6,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Footer ──
                  Divider(height: 1, color: widget.glass.panelBorderColor),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: CrusaderGrays.muted.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Appended after "-- " separator',
                            style: textTheme.labelSmall?.copyWith(
                              color: CrusaderGrays.muted.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        MouseRegion(
                          onEnter: (_) => setState(() => _saveHovered = true),
                          onExit: (_) => setState(() => _saveHovered = false),
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => widget.onSave(_controller.text),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: _saveHovered
                                    ? widget.accents.primary
                                    : widget.accents.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                boxShadow: _saveHovered
                                    ? [
                                        BoxShadow(
                                          color: widget.accents.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          spreadRadius: -3,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Save',
                                style: textTheme.labelSmall?.copyWith(
                                  color: _saveHovered
                                      ? CrusaderBlacks.deepBlack
                                      : widget.accents.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scaleXY(begin: 0.95, end: 1, duration: 250.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.delay = 0});

  final String title;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: CrusaderGrays.muted,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontSize: 10,
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: delay.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Row
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsRow extends StatefulWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.trailing,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _isHovered && widget.onTap != null
                ? CrusaderGrays.border.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: widget.iconColor.withValues(alpha: 0.1),
                ),
                child: Icon(widget.icon, size: 17, color: widget.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: textTheme.labelSmall?.copyWith(
                          color: CrusaderGrays.muted,
                        ),
                      ),
                  ],
                ),
              ),
              widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Row
// ─────────────────────────────────────────────────────────────────────────────

class _AccountRow extends StatefulWidget {
  const _AccountRow({
    required this.account,
    required this.accents,
    required this.isActive,
    required this.onRemove,
  });

  final EmailAccount account;
  final CrusaderAccentTheme accents;
  final bool isActive;
  final VoidCallback onRemove;

  @override
  State<_AccountRow> createState() => _AccountRowState();
}

class _AccountRowState extends State<_AccountRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final providerColor = widget.account.provider == EmailProvider.gmail
        ? const Color(0xFF4285F4)
        : const Color(0xFF0078D4);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: providerColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                widget.account.provider == EmailProvider.gmail
                    ? Icons.mail_rounded
                    : Icons.business_rounded,
                size: 17,
                color: providerColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.account.email,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: widget.accents.primary.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: widget.accents.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    widget.account.provider == EmailProvider.gmail
                        ? 'Gmail'
                        : 'Outlook',
                    style: textTheme.labelSmall?.copyWith(
                      color: CrusaderGrays.muted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                icon: Icon(
                  Icons.remove_circle_outline_rounded,
                  color: widget.accents.error.withValues(alpha: 0.7),
                  size: 17,
                ),
                onPressed: widget.onRemove,
                tooltip: 'Remove account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shortcut Row
// ─────────────────────────────────────────────────────────────────────────────

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.label, required this.shortcut});

  final String label;
  final String shortcut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: CrusaderGrays.secondary),
            ),
          ),
          KeyboardShortcutBadge(shortcut: shortcut),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Color Dot — accent color selector
// ─────────────────────────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.isSelected = false, this.onTap});

  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isSelected ? 1 : 0.4),
            border: isSelected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Font Picker Dialog — glassmorphic dialog with font previews
// ─────────────────────────────────────────────────────────────────────────────

class _FontPickerDialog extends StatelessWidget {
  const _FontPickerDialog({
    required this.currentFont,
    required this.accents,
    required this.glass,
    required this.onSelect,
  });

  final String currentFont;
  final CrusaderAccentTheme accents;
  final CrusaderGlassTheme glass;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 620),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xF0141420),
                border: Border.all(
                  color: CrusaderGrays.border.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 60,
                    spreadRadius: -10,
                  ),
                  BoxShadow(
                    color: accents.primary.withValues(alpha: 0.04),
                    blurRadius: 80,
                    spreadRadius: -20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 16, 20),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                accents.secondary.withValues(alpha: 0.15),
                                accents.primary.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.text_fields_rounded,
                            size: 18,
                            color: accents.secondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Font',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${fontFamilyOptions.length} typefaces available',
                              style: textTheme.labelSmall?.copyWith(
                                color: CrusaderGrays.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: CrusaderGrays.muted,
                          ),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: glass.panelBorderColor),

                  // ── Font List ──
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      itemCount: fontFamilyOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final font = fontFamilyOptions[index];
                        final isSelected = font == currentFont;
                        return _FontOptionTile(
                          fontName: font,
                          isSelected: isSelected,
                          accentColor: accents.primary,
                          onTap: () => onSelect(font),
                        );
                      },
                    ),
                  ),

                  // ── Footer hint ──
                  Divider(height: 1, color: glass.panelBorderColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 28,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: CrusaderGrays.muted.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Font applies to the entire interface',
                          style: textTheme.labelSmall?.copyWith(
                            color: CrusaderGrays.muted.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scaleXY(begin: 0.95, end: 1, duration: 250.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Font Option Tile — individual font preview row
// ─────────────────────────────────────────────────────────────────────────────

class _FontOptionTile extends StatefulWidget {
  const _FontOptionTile({
    required this.fontName,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final String fontName;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_FontOptionTile> createState() => _FontOptionTileState();
}

class _FontOptionTileState extends State<_FontOptionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.07)
                : _isHovered
                ? CrusaderGrays.border.withValues(alpha: 0.08)
                : Colors.transparent,
            border: widget.isSelected
                ? Border.all(
                    color: widget.accentColor.withValues(alpha: 0.2),
                    width: 1,
                  )
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              // ── Accent indicator ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: widget.isSelected ? 32 : 0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: widget.accentColor,
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: -1,
                          ),
                        ]
                      : null,
                ),
              ),
              SizedBox(width: widget.isSelected ? 14 : 0),

              // ── Font info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Font name in its own typeface
                    Text(
                      widget.fontName,
                      style: GoogleFonts.getFont(
                        widget.fontName,
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: widget.isSelected
                              ? widget.accentColor
                              : isActive
                              ? Colors.white.withValues(alpha: 0.95)
                              : Colors.white.withValues(alpha: 0.75),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Preview sentence in the font
                    Text(
                      'The quick brown fox jumps over the lazy dog',
                      style: GoogleFonts.getFont(
                        widget.fontName,
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isActive
                              ? CrusaderGrays.secondary
                              : CrusaderGrays.muted,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Check icon ──
              AnimatedOpacity(
                opacity: widget.isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: widget.accentColor,
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
