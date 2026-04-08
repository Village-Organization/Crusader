/// Crusader Design System — Typography
///
/// Dynamic font selection via Google Fonts.
/// Falls back to system fonts (SF Pro on iOS, Segoe UI on Windows).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Type Scale
// ─────────────────────────────────────────────────────────────────────────────

abstract final class CrusaderTypography {
  /// Base text theme using the specified [fontFamily] (Google Fonts name).
  static TextTheme textTheme({
    bool isDark = true,
    String fontFamily = 'Inter',
  }) {
    final Color primary =
        isDark ? CrusaderGrays.bright : CrusaderLight.textPrimary;
    final Color secondary =
        isDark ? CrusaderGrays.secondary : CrusaderLight.textSecondary;

    final baseTheme = TextTheme(
      // ── Display ──
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        height: 1.15,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.2,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.25,
        color: primary,
      ),

      // ── Headlines ──
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.35,
        color: primary,
      ),

      // ── Title ──
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.4,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
        color: secondary,
      ),

      // ── Body ──
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: secondary,
      ),

      // ── Label ──
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.4,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: secondary,
      ),
    );

    return GoogleFonts.getTextTheme(fontFamily, baseTheme);
  }
}
