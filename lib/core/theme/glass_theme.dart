/// Crusader Design System — Glass Theme Extension
///
/// ThemeExtension for glassmorphism 2.0 + soft neumorphism.
/// Translucent frosted-glass panels, subtle blur, soft shadows.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import 'colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Glass Theme Extension
// ─────────────────────────────────────────────────────────────────────────────

/// Provides glass-morphism styling values accessible via
/// `Theme.of(context).extension<CrusaderGlassTheme>()`.
@immutable
class CrusaderGlassTheme extends ThemeExtension<CrusaderGlassTheme> {
  const CrusaderGlassTheme({
    required this.panelColor,
    required this.panelBorderColor,
    required this.panelHighlightColor,
    required this.panelShadowColor,
    required this.blurSigma,
    required this.borderRadius,
    required this.borderWidth,
    required this.elevation,
    required this.innerShadowOpacity,
    required this.outerShadowOpacity,
  });

  /// Default dark-mode glass panel.
  factory CrusaderGlassTheme.dark() => const CrusaderGlassTheme(
        panelColor: CrusaderGlass.panelFill,
        panelBorderColor: CrusaderGlass.panelBorder,
        panelHighlightColor: CrusaderGlass.panelHighlight,
        panelShadowColor: CrusaderGlass.panelShadow,
        blurSigma: 24.0,
        borderRadius: 16.0,
        borderWidth: 1.0,
        elevation: 0.0,
        innerShadowOpacity: 0.06,
        outerShadowOpacity: 0.12,
      );

  /// Light-mode glass (subtler, less contrast).
  factory CrusaderGlassTheme.light() => const CrusaderGlassTheme(
        panelColor: CrusaderLight.panelFill,
        panelBorderColor: CrusaderLight.panelBorder,
        panelHighlightColor: Color(0x08000000),
        panelShadowColor: Color(0x18000000),
        blurSigma: 20.0,
        borderRadius: 16.0,
        borderWidth: 1.0,
        elevation: 0.0,
        innerShadowOpacity: 0.04,
        outerShadowOpacity: 0.08,
      );

  final Color panelColor;
  final Color panelBorderColor;
  final Color panelHighlightColor;
  final Color panelShadowColor;
  final double blurSigma;
  final double borderRadius;
  final double borderWidth;
  final double elevation;
  final double innerShadowOpacity;
  final double outerShadowOpacity;

  @override
  CrusaderGlassTheme copyWith({
    Color? panelColor,
    Color? panelBorderColor,
    Color? panelHighlightColor,
    Color? panelShadowColor,
    double? blurSigma,
    double? borderRadius,
    double? borderWidth,
    double? elevation,
    double? innerShadowOpacity,
    double? outerShadowOpacity,
  }) {
    return CrusaderGlassTheme(
      panelColor: panelColor ?? this.panelColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      panelHighlightColor: panelHighlightColor ?? this.panelHighlightColor,
      panelShadowColor: panelShadowColor ?? this.panelShadowColor,
      blurSigma: blurSigma ?? this.blurSigma,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      elevation: elevation ?? this.elevation,
      innerShadowOpacity: innerShadowOpacity ?? this.innerShadowOpacity,
      outerShadowOpacity: outerShadowOpacity ?? this.outerShadowOpacity,
    );
  }

  @override
  CrusaderGlassTheme lerp(CrusaderGlassTheme? other, double t) {
    if (other == null) return this;
    return CrusaderGlassTheme(
      panelColor: Color.lerp(panelColor, other.panelColor, t)!,
      panelBorderColor:
          Color.lerp(panelBorderColor, other.panelBorderColor, t)!,
      panelHighlightColor:
          Color.lerp(panelHighlightColor, other.panelHighlightColor, t)!,
      panelShadowColor:
          Color.lerp(panelShadowColor, other.panelShadowColor, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      elevation: lerpDouble(elevation, other.elevation, t)!,
      innerShadowOpacity:
          lerpDouble(innerShadowOpacity, other.innerShadowOpacity, t)!,
      outerShadowOpacity:
          lerpDouble(outerShadowOpacity, other.outerShadowOpacity, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accent Theme Extension — neon highlight colors
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class CrusaderAccentTheme extends ThemeExtension<CrusaderAccentTheme> {
  const CrusaderAccentTheme({
    required this.primary,
    required this.primaryMuted,
    required this.primaryGlow,
    required this.secondary,
    required this.secondaryMuted,
    required this.secondaryGlow,
    required this.tertiary,
    required this.tertiaryMuted,
    required this.tertiaryGlow,
    required this.success,
    required this.error,
  });

  factory CrusaderAccentTheme.dark() => const CrusaderAccentTheme(
        primary: CrusaderAccents.cyan,
        primaryMuted: CrusaderAccents.cyanMuted,
        primaryGlow: CrusaderAccents.cyanGlow,
        secondary: CrusaderAccents.magenta,
        secondaryMuted: CrusaderAccents.magentaMuted,
        secondaryGlow: CrusaderAccents.magentaGlow,
        tertiary: CrusaderAccents.gold,
        tertiaryMuted: CrusaderAccents.goldMuted,
        tertiaryGlow: CrusaderAccents.goldGlow,
        success: CrusaderAccents.green,
        error: CrusaderAccents.red,
      );

  factory CrusaderAccentTheme.light() => const CrusaderAccentTheme(
        primary: CrusaderAccents.cyanMuted,
        primaryMuted: Color(0xFF0097A7),
        primaryGlow: Color(0x2000B8D4),
        secondary: CrusaderAccents.magentaMuted,
        secondaryMuted: Color(0xFFC2185B),
        secondaryGlow: Color(0x20D81B8A),
        tertiary: CrusaderAccents.goldMuted,
        tertiaryMuted: Color(0xFFFF8F00),
        tertiaryGlow: Color(0x20FFAB00),
        success: Color(0xFF2E7D32),
        error: Color(0xFFC62828),
      );

  final Color primary;
  final Color primaryMuted;
  final Color primaryGlow;
  final Color secondary;
  final Color secondaryMuted;
  final Color secondaryGlow;
  final Color tertiary;
  final Color tertiaryMuted;
  final Color tertiaryGlow;
  final Color success;
  final Color error;

  @override
  CrusaderAccentTheme copyWith({
    Color? primary,
    Color? primaryMuted,
    Color? primaryGlow,
    Color? secondary,
    Color? secondaryMuted,
    Color? secondaryGlow,
    Color? tertiary,
    Color? tertiaryMuted,
    Color? tertiaryGlow,
    Color? success,
    Color? error,
  }) {
    return CrusaderAccentTheme(
      primary: primary ?? this.primary,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      primaryGlow: primaryGlow ?? this.primaryGlow,
      secondary: secondary ?? this.secondary,
      secondaryMuted: secondaryMuted ?? this.secondaryMuted,
      secondaryGlow: secondaryGlow ?? this.secondaryGlow,
      tertiary: tertiary ?? this.tertiary,
      tertiaryMuted: tertiaryMuted ?? this.tertiaryMuted,
      tertiaryGlow: tertiaryGlow ?? this.tertiaryGlow,
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }

  @override
  CrusaderAccentTheme lerp(CrusaderAccentTheme? other, double t) {
    if (other == null) return this;
    return CrusaderAccentTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryMuted: Color.lerp(primaryMuted, other.primaryMuted, t)!,
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryMuted: Color.lerp(secondaryMuted, other.secondaryMuted, t)!,
      secondaryGlow: Color.lerp(secondaryGlow, other.secondaryGlow, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryMuted: Color.lerp(tertiaryMuted, other.tertiaryMuted, t)!,
      tertiaryGlow: Color.lerp(tertiaryGlow, other.tertiaryGlow, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
