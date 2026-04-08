/// Crusader Design System — Color Palette
///
/// Dark-mode-first palette inspired by Linear, Arc, Superhuman.
/// Deep blacks, muted grays, electric neon accents (cyan / magenta / gold).
library;

import 'dart:ui';

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core Palette
// ─────────────────────────────────────────────────────────────────────────────

/// Deep background blacks – the canvas.
abstract final class CrusaderBlacks {
  static const Color trueBlack = Color(0xFF000000);
  static const Color deepBlack = Color(0xFF0A0A0E);
  static const Color softBlack = Color(0xFF111118);
  static const Color charcoal = Color(0xFF18181F);
  static const Color elevated = Color(0xFF1E1E28);
}

/// Muted grays – structure & text hierarchy.
abstract final class CrusaderGrays {
  static const Color border = Color(0xFF2A2A35);
  static const Color subtle = Color(0xFF3A3A48);
  static const Color muted = Color(0xFF5A5A6E);
  static const Color secondary = Color(0xFF8A8A9E);
  static const Color primary = Color(0xFFC8C8D8);
  static const Color bright = Color(0xFFEAEAF4);
}

/// Electric neon accents – the soul of Crusader.
abstract final class CrusaderAccents {
  static const Color cyan = Color(0xFF00E5FF);
  static const Color cyanMuted = Color(0xFF00B8D4);
  static const Color cyanGlow = Color(0x4000E5FF); // 25% opacity glow

  static const Color magenta = Color(0xFFFF2DBA);
  static const Color magentaMuted = Color(0xFFD81B8A);
  static const Color magentaGlow = Color(0x40FF2DBA);

  static const Color gold = Color(0xFFFFD740);
  static const Color goldMuted = Color(0xFFFFAB00);
  static const Color goldGlow = Color(0x40FFD740);

  static const Color green = Color(0xFF69F0AE);
  static const Color red = Color(0xFFFF5252);
}

/// Glass / frosted panel colors.
abstract final class CrusaderGlass {
  static const Color panelFill = Color(0x18FFFFFF); // ~9% white
  static const Color panelBorder = Color(0x20FFFFFF); // ~12% white
  static const Color panelHighlight = Color(0x0AFFFFFF); // ~4% white
  static const Color panelShadow = Color(0x30000000); // subtle black shadow
}

// ─────────────────────────────────────────────────────────────────────────────
// Light Mode Palette (optional — kept minimal)
// ─────────────────────────────────────────────────────────────────────────────

abstract final class CrusaderLight {
  static const Color background = Color(0xFFF8F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color elevated = Color(0xFFF0F0F6);
  static const Color border = Color(0xFFE0E0EA);
  static const Color textPrimary = Color(0xFF1A1A24);
  static const Color textSecondary = Color(0xFF5A5A6E);

  static const Color panelFill = Color(0x30FFFFFF);
  static const Color panelBorder = Color(0x18000000);
}
