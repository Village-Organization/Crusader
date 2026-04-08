/// Crusader Design System — Theme Builder
///
/// Assembles Material 3 ThemeData with our custom extensions.
/// Dark mode is default and primary; light mode is available.
/// Supports dynamic accent color and font family.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../di/theme_provider.dart';
import 'colors.dart';
import 'glass_theme.dart';
import 'typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme Factory
// ─────────────────────────────────────────────────────────────────────────────

abstract final class CrusaderTheme {
  // ── Dark Theme (default) ──────────────────────────────────────────────────

  static ThemeData dark({
    int accentIndex = 0,
    String fontFamily = 'Inter',
  }) {
    final accent = accentColorOptions[accentIndex.clamp(0, accentColorOptions.length - 1)];
    final textTheme = CrusaderTypography.textTheme(isDark: true, fontFamily: fontFamily);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ── Colors ──
      colorScheme: ColorScheme.dark(
        surface: CrusaderBlacks.softBlack,
        onSurface: CrusaderGrays.bright,
        primary: accent.primary,
        onPrimary: CrusaderBlacks.trueBlack,
        secondary: accent.secondary,
        onSecondary: CrusaderBlacks.trueBlack,
        tertiary: CrusaderAccents.gold,
        onTertiary: CrusaderBlacks.trueBlack,
        error: CrusaderAccents.red,
        onError: CrusaderBlacks.trueBlack,
        surfaceContainerHighest: CrusaderBlacks.elevated,
        outline: CrusaderGrays.border,
        outlineVariant: CrusaderGrays.subtle,
      ),
      scaffoldBackgroundColor: CrusaderBlacks.deepBlack,
      canvasColor: CrusaderBlacks.softBlack,

      // ── Typography ──
      textTheme: textTheme,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(
          color: CrusaderGrays.primary,
          size: 20,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // ── Cards — glass feel ──
      cardTheme: CardThemeData(
        color: CrusaderGlass.panelFill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: CrusaderGlass.panelBorder,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: CrusaderGrays.border,
        thickness: 1,
        space: 1,
      ),

      // ── Icon ──
      iconTheme: const IconThemeData(
        color: CrusaderGrays.secondary,
        size: 20,
      ),

      // ── Input fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CrusaderBlacks.elevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CrusaderGrays.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CrusaderGrays.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent.primary, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: CrusaderGrays.muted,
        ),
      ),

      // ── Elevated buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent.primary,
          foregroundColor: CrusaderBlacks.trueBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ── Icon buttons ──
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: CrusaderGrays.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ── Bottom navigation ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: CrusaderBlacks.charcoal,
        selectedItemColor: accent.primary,
        unselectedItemColor: CrusaderGrays.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Scrollbar ──
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(CrusaderGrays.subtle),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: CrusaderBlacks.elevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CrusaderGrays.border),
        ),
        textStyle: textTheme.bodySmall,
      ),

      // ── Extensions ──
      extensions: <ThemeExtension>[
        CrusaderGlassTheme.dark(),
        CrusaderAccentTheme(
          primary: accent.primary,
          primaryMuted: accent.primaryMuted,
          primaryGlow: accent.primaryGlow,
          secondary: accent.secondary,
          secondaryMuted: accent.secondaryMuted,
          secondaryGlow: accent.secondaryGlow,
          tertiary: CrusaderAccents.gold,
          tertiaryMuted: CrusaderAccents.goldMuted,
          tertiaryGlow: CrusaderAccents.goldGlow,
          success: CrusaderAccents.green,
          error: CrusaderAccents.red,
        ),
      ],
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────

  static ThemeData light({
    int accentIndex = 0,
    String fontFamily = 'Inter',
  }) {
    final accent = accentColorOptions[accentIndex.clamp(0, accentColorOptions.length - 1)];
    final textTheme = CrusaderTypography.textTheme(isDark: false, fontFamily: fontFamily);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.light(
        surface: CrusaderLight.surface,
        onSurface: CrusaderLight.textPrimary,
        primary: accent.primaryMuted,
        onPrimary: Colors.white,
        secondary: accent.secondaryMuted,
        onSecondary: Colors.white,
        tertiary: CrusaderAccents.goldMuted,
        onTertiary: Colors.white,
        error: const Color(0xFFC62828),
        onError: Colors.white,
        surfaceContainerHighest: CrusaderLight.elevated,
        outline: CrusaderLight.border,
        outlineVariant: const Color(0xFFD0D0DA),
      ),
      scaffoldBackgroundColor: CrusaderLight.background,
      canvasColor: CrusaderLight.surface,

      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: IconThemeData(
          color: CrusaderLight.textPrimary,
          size: 20,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: CrusaderLight.panelFill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: CrusaderLight.panelBorder,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: CrusaderLight.border,
        thickness: 1,
        space: 1,
      ),

      extensions: <ThemeExtension>[
        CrusaderGlassTheme.light(),
        CrusaderAccentTheme(
          primary: accent.primaryMuted,
          primaryMuted: accent.primaryMuted,
          primaryGlow: accent.primaryGlow,
          secondary: accent.secondaryMuted,
          secondaryMuted: accent.secondaryMuted,
          secondaryGlow: accent.secondaryGlow,
          tertiary: CrusaderAccents.goldMuted,
          tertiaryMuted: const Color(0xFFFF8F00),
          tertiaryGlow: const Color(0x20FFAB00),
          success: const Color(0xFF2E7D32),
          error: const Color(0xFFC62828),
        ),
      ],
    );
  }
}
