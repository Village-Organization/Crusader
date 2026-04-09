/// Crusader — Add Account Screen
///
/// Beautiful provider selection with glass cards.
/// Launches OAuth2 flow for Gmail/Outlook, or shows a manual IMAP/SMTP
/// form for custom/company email accounts.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';
import '../../domain/entities/email_account.dart';
import '../../features/auth/auth_providers.dart';
import '../widgets/glass_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Account Screen
// ─────────────────────────────────────────────────────────────────────────────

class AddAccountScreen extends ConsumerWidget {
  const AddAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountProvider);
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back button ──
              GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
                tooltip: 'Back',
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 32),

              // ── Header ──
              Text('Add Account', style: textTheme.displayMedium)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05, end: 0, duration: 400.ms),

              const SizedBox(height: 8),

              Text(
                'Connect your email to get started with Crusader.',
                style: textTheme.bodyLarge?.copyWith(
                  color: CrusaderGrays.secondary,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 40),

              // ── Error message ──
              if (accountState.error != null)
                Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: accents.error.withValues(alpha: 0.1),
                        border: Border.all(
                          color: accents.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: accents.error,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              accountState.error!,
                              style: textTheme.bodySmall?.copyWith(
                                color: accents.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .shake(hz: 3, offset: const Offset(4, 0), duration: 400.ms),

              // ── Loading ──
              if (accountState.isLoading)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accents.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Authenticating...',
                        style: textTheme.bodyMedium?.copyWith(
                          color: CrusaderGrays.secondary,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

              // ── Provider Cards ──
              if (!accountState.isLoading) ...[
                _ProviderCard(
                      provider: EmailProvider.gmail,
                      icon: Icons.mail_rounded,
                      title: 'Google',
                      subtitle: 'Gmail, Google Workspace',
                      gradientColors: [
                        const Color(0xFF4285F4),
                        const Color(0xFF34A853),
                      ],
                      onTap: () => ref
                          .read(accountProvider.notifier)
                          .addAccount(EmailProvider.gmail),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 500.ms,
                      delay: 200.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 16),

                _ProviderCard(
                      provider: EmailProvider.outlook,
                      icon: Icons.business_rounded,
                      title: 'Microsoft',
                      subtitle: 'Outlook, Office 365, Hotmail',
                      gradientColors: [
                        const Color(0xFF0078D4),
                        const Color(0xFF50E6FF),
                      ],
                      onTap: () => ref
                          .read(accountProvider.notifier)
                          .addAccount(EmailProvider.outlook),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 300.ms)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 500.ms,
                      delay: 300.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 16),

                _ProviderCard(
                      provider: EmailProvider.custom,
                      icon: Icons.dns_rounded,
                      title: 'Other / IMAP',
                      subtitle: 'Company email, Yahoo, iCloud, custom server',
                      gradientColors: [
                        const Color(0xFF7C3AED),
                        const Color(0xFFA78BFA),
                      ],
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const _CustomAccountFormScreen(),
                            transitionsBuilder: (_, animation, __, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                            reverseTransitionDuration: const Duration(
                              milliseconds: 200,
                            ),
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 400.ms)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 500.ms,
                      delay: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],

              const Spacer(),

              // ── Footer note ──
              Center(
                child: Text(
                  'OAuth providers never store your password. '
                  'Custom accounts store credentials securely on-device.',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: CrusaderGrays.subtle,
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  final EmailProvider provider;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<CrusaderGlassTheme>()!;
    final textTheme = Theme.of(context).textTheme;

    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(glass.borderRadius),
          onTap: onTap,
          splashColor: gradientColors.first.withValues(alpha: 0.1),
          hoverColor: gradientColors.first.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),

                const SizedBox(width: 18),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.headlineSmall),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: CrusaderGrays.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_rounded,
                  color: CrusaderGrays.subtle,
                  size: 20,
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
// Server Preset
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-configured IMAP/SMTP settings for well-known providers.
class _ServerPreset {
  const _ServerPreset({
    required this.label,
    required this.imapHost,
    required this.imapPort,
    required this.smtpHost,
    required this.smtpPort,
    this.emailSuffix,
  });

  final String label;
  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;

  /// Optional hint, e.g. "@yahoo.com" — used only for display.
  final String? emailSuffix;

  static const List<_ServerPreset> presets = [
    _ServerPreset(
      label: 'Yahoo Mail',
      imapHost: 'imap.mail.yahoo.com',
      imapPort: 993,
      smtpHost: 'smtp.mail.yahoo.com',
      smtpPort: 465,
      emailSuffix: '@yahoo.com',
    ),
    _ServerPreset(
      label: 'iCloud Mail',
      imapHost: 'imap.mail.me.com',
      imapPort: 993,
      smtpHost: 'smtp.mail.me.com',
      smtpPort: 587,
      emailSuffix: '@icloud.com',
    ),
    _ServerPreset(
      label: 'AOL Mail',
      imapHost: 'imap.aol.com',
      imapPort: 993,
      smtpHost: 'smtp.aol.com',
      smtpPort: 465,
      emailSuffix: '@aol.com',
    ),
    _ServerPreset(
      label: 'Zoho Mail',
      imapHost: 'imap.zoho.com',
      imapPort: 993,
      smtpHost: 'smtp.zoho.com',
      smtpPort: 465,
      emailSuffix: '@zoho.com',
    ),
    _ServerPreset(
      label: 'FastMail',
      imapHost: 'imap.fastmail.com',
      imapPort: 993,
      smtpHost: 'smtp.fastmail.com',
      smtpPort: 465,
      emailSuffix: '@fastmail.com',
    ),
    _ServerPreset(
      label: 'ProtonMail Bridge',
      imapHost: '127.0.0.1',
      imapPort: 1143,
      smtpHost: '127.0.0.1',
      smtpPort: 1025,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Account Form Screen
// ─────────────────────────────────────────────────────────────────────────────

class _CustomAccountFormScreen extends ConsumerStatefulWidget {
  const _CustomAccountFormScreen();

  @override
  ConsumerState<_CustomAccountFormScreen> createState() =>
      _CustomAccountFormScreenState();
}

class _CustomAccountFormScreenState
    extends ConsumerState<_CustomAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _imapHostCtrl = TextEditingController();
  final _imapPortCtrl = TextEditingController(text: '993');
  final _smtpHostCtrl = TextEditingController();
  final _smtpPortCtrl = TextEditingController(text: '465');

  bool _obscurePassword = true;
  bool _showAdvanced = false;
  _ServerPreset? _selectedPreset;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    _imapHostCtrl.dispose();
    _imapPortCtrl.dispose();
    _smtpHostCtrl.dispose();
    _smtpPortCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(_ServerPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _imapHostCtrl.text = preset.imapHost;
      _imapPortCtrl.text = preset.imapPort.toString();
      _smtpHostCtrl.text = preset.smtpHost;
      _smtpPortCtrl.text = preset.smtpPort.toString();
      _showAdvanced = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(accountProvider.notifier)
        .addCustomAccount(
          email: _emailCtrl.text.trim(),
          displayName: _displayNameCtrl.text.trim().isEmpty
              ? _emailCtrl.text.trim().split('@').first
              : _displayNameCtrl.text.trim(),
          password: _passwordCtrl.text,
          imapHost: _imapHostCtrl.text.trim(),
          imapPort: int.parse(_imapPortCtrl.text.trim()),
          smtpHost: _smtpHostCtrl.text.trim(),
          smtpPort: int.parse(_smtpPortCtrl.text.trim()),
        );

    // If no error, account was added — pop back to wherever we came from.
    if (mounted) {
      final state = ref.read(accountProvider);
      if (state.error == null && !state.isLoading) {
        Navigator.of(context).pop(); // pop form
        if (Navigator.of(context).canPop()) {
          // Also pop the AddAccountScreen if we're stacked above it.
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back ──
              GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              // ── Title ──
              Text(
                'Custom Email',
                style: textTheme.displayMedium,
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 4),

              Text(
                'Enter your IMAP/SMTP server details.',
                style: textTheme.bodyMedium?.copyWith(
                  color: CrusaderGrays.secondary,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 24),

              // ── Error ──
              if (accountState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: accents.error.withValues(alpha: 0.1),
                    border: Border.all(
                      color: accents.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: accents.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          accountState.error!,
                          style: textTheme.bodySmall?.copyWith(
                            color: accents.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

              // ── Form ──
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick-pick presets
                        Text(
                          'QUICK SETUP',
                          style: textTheme.labelSmall?.copyWith(
                            color: CrusaderGrays.muted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _ServerPreset.presets.map((preset) {
                            final selected = _selectedPreset == preset;
                            return _PresetChip(
                              label: preset.label,
                              selected: selected,
                              onTap: () => _applyPreset(preset),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Account fields
                        _GlassTextField(
                          controller: _emailCtrl,
                          label: 'Email Address',
                          hint: 'you@company.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _GlassTextField(
                          controller: _passwordCtrl,
                          label: 'Password / App Password',
                          hint: 'Your mail password or app-specific password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                              color: CrusaderGrays.muted,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _GlassTextField(
                          controller: _displayNameCtrl,
                          label: 'Display Name (optional)',
                          hint: 'John Doe',
                          icon: Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 20),

                        // Server settings toggle
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showAdvanced = !_showAdvanced),
                          child: Row(
                            children: [
                              Icon(
                                _showAdvanced
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: accents.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Server Settings',
                                style: textTheme.labelMedium?.copyWith(
                                  color: accents.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_showAdvanced) ...[
                          const SizedBox(height: 16),

                          // IMAP
                          Text(
                            'INCOMING MAIL (IMAP)',
                            style: textTheme.labelSmall?.copyWith(
                              color: CrusaderGrays.muted,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _GlassTextField(
                                  controller: _imapHostCtrl,
                                  label: 'IMAP Host',
                                  hint: 'imap.company.com',
                                  icon: Icons.dns_outlined,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: _GlassTextField(
                                  controller: _imapPortCtrl,
                                  label: 'Port',
                                  hint: '993',
                                  icon: Icons.tag_rounded,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final port = int.tryParse(v.trim());
                                    if (port == null ||
                                        port < 1 ||
                                        port > 65535) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // SMTP
                          Text(
                            'OUTGOING MAIL (SMTP)',
                            style: textTheme.labelSmall?.copyWith(
                              color: CrusaderGrays.muted,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _GlassTextField(
                                  controller: _smtpHostCtrl,
                                  label: 'SMTP Host',
                                  hint: 'smtp.company.com',
                                  icon: Icons.send_outlined,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: _GlassTextField(
                                  controller: _smtpPortCtrl,
                                  label: 'Port',
                                  hint: '465',
                                  icon: Icons.tag_rounded,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final port = int.tryParse(v.trim());
                                    if (port == null ||
                                        port < 1 ||
                                        port > 65535) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 28),

                        // ── Submit button ──
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: _GlassSubmitButton(
                            label: 'Add Account',
                            isLoading: accountState.isLoading,
                            onPressed: accountState.isLoading ? null : _submit,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Helper text
                        Text(
                          'Tip: Many providers require an app-specific password '
                          'instead of your regular password. Check your provider\'s '
                          'security settings.',
                          style: textTheme.labelSmall?.copyWith(
                            color: CrusaderGrays.subtle,
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
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
// Glass Text Field
// ─────────────────────────────────────────────────────────────────────────────

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(color: CrusaderGrays.primary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: CrusaderGrays.muted, fontSize: 13),
        hintStyle: TextStyle(color: CrusaderGrays.subtle, fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: CrusaderGrays.muted)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: CrusaderBlacks.softBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CrusaderGrays.subtle.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CrusaderGrays.subtle.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: accents.primary.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accents.error.withValues(alpha: 0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: accents.error.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset Chip
// ─────────────────────────────────────────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? accents.primary.withValues(alpha: 0.15)
                : CrusaderBlacks.softBlack,
            border: Border.all(
              color: selected
                  ? accents.primary.withValues(alpha: 0.5)
                  : CrusaderGrays.subtle.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? accents.primary : CrusaderGrays.secondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Submit Button
// ─────────────────────────────────────────────────────────────────────────────

class _GlassSubmitButton extends StatelessWidget {
  const _GlassSubmitButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<CrusaderAccentTheme>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: accents.primary.withValues(alpha: 0.15),
            border: Border.all(color: accents.primary.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: accents.primary.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accents.primary,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: accents.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
