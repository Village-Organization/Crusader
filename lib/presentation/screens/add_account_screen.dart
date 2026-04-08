/// Crusader — Add Account Screen
///
/// Beautiful provider selection with glass cards.
/// Launches OAuth2 flow on tap.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glass_theme.dart';
import '../../domain/entities/email_account.dart';
import '../../features/auth/auth_providers.dart';
import '../widgets/glass_panel.dart';

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
              Text(
                'Add Account',
                style: textTheme.displayMedium,
              ).animate().fadeIn(duration: 400.ms).slideY(
                    begin: -0.05,
                    end: 0,
                    duration: 400.ms,
                  ),

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
                      Icon(Icons.error_outline_rounded,
                          color: accents.error, size: 18),
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
                ).animate().fadeIn(duration: 300.ms).shake(
                      hz: 3,
                      offset: const Offset(4, 0),
                      duration: 400.ms,
                    ),

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
                  onTap: () =>
                      ref.read(accountProvider.notifier).addAccount(
                            EmailProvider.gmail,
                          ),
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
                  onTap: () =>
                      ref.read(accountProvider.notifier).addAccount(
                            EmailProvider.outlook,
                          ),
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
              ],

              const Spacer(),

              // ── Footer note ──
              Center(
                child: Text(
                  'We use OAuth2 — your password is never stored.',
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
                      Text(
                        title,
                        style: textTheme.headlineSmall,
                      ),
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
