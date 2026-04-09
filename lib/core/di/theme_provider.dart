/// Crusader — Theme Providers
///
/// Manages dark/light mode, accent color, and font family with persistence.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme Mode Notifier
// ─────────────────────────────────────────────────────────────────────────────

const _kThemeModeKey = 'crusader_theme_mode';

/// Provides the current [ThemeMode].
/// Defaults to [ThemeMode.dark] (dark-mode first).
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeModeKey);
    if (stored != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.dark,
      );
    }
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, state.name);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, state.name);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accent Color Notifier
// ─────────────────────────────────────────────────────────────────────────────

const _kAccentColorKey = 'crusader_accent_color';

/// All available accent color options with their names and derived colors.
class AccentColorOption {
  const AccentColorOption({
    required this.name,
    required this.primary,
    required this.primaryMuted,
    required this.primaryGlow,
    required this.secondary,
    required this.secondaryMuted,
    required this.secondaryGlow,
  });

  final String name;
  final Color primary;
  final Color primaryMuted;
  final Color primaryGlow;
  final Color secondary;
  final Color secondaryMuted;
  final Color secondaryGlow;
}

/// Available accent colors.
const accentColorOptions = [
  AccentColorOption(
    name: 'Cyan',
    primary: Color(0xFF00E5FF),
    primaryMuted: Color(0xFF00B8D4),
    primaryGlow: Color(0x4000E5FF),
    secondary: Color(0xFFFF2DBA),
    secondaryMuted: Color(0xFFD81B8A),
    secondaryGlow: Color(0x40FF2DBA),
  ),
  AccentColorOption(
    name: 'Magenta',
    primary: Color(0xFFFF2DBA),
    primaryMuted: Color(0xFFD81B8A),
    primaryGlow: Color(0x40FF2DBA),
    secondary: Color(0xFF00E5FF),
    secondaryMuted: Color(0xFF00B8D4),
    secondaryGlow: Color(0x4000E5FF),
  ),
  AccentColorOption(
    name: 'Gold',
    primary: Color(0xFFFFD740),
    primaryMuted: Color(0xFFFFAB00),
    primaryGlow: Color(0x40FFD740),
    secondary: Color(0xFFFF2DBA),
    secondaryMuted: Color(0xFFD81B8A),
    secondaryGlow: Color(0x40FF2DBA),
  ),
  AccentColorOption(
    name: 'Green',
    primary: Color(0xFF69F0AE),
    primaryMuted: Color(0xFF00C853),
    primaryGlow: Color(0x4069F0AE),
    secondary: Color(0xFF00E5FF),
    secondaryMuted: Color(0xFF00B8D4),
    secondaryGlow: Color(0x4000E5FF),
  ),
  AccentColorOption(
    name: 'Purple',
    primary: Color(0xFFB388FF),
    primaryMuted: Color(0xFF7C4DFF),
    primaryGlow: Color(0x40B388FF),
    secondary: Color(0xFF00E5FF),
    secondaryMuted: Color(0xFF00B8D4),
    secondaryGlow: Color(0x4000E5FF),
  ),
  AccentColorOption(
    name: 'Blue',
    primary: Color(0xFF448AFF),
    primaryMuted: Color(0xFF2962FF),
    primaryGlow: Color(0x40448AFF),
    secondary: Color(0xFFFF2DBA),
    secondaryMuted: Color(0xFFD81B8A),
    secondaryGlow: Color(0x40FF2DBA),
  ),
  AccentColorOption(
    name: 'Orange',
    primary: Color(0xFFFF6E40),
    primaryMuted: Color(0xFFDD2C00),
    primaryGlow: Color(0x40FF6E40),
    secondary: Color(0xFF00E5FF),
    secondaryMuted: Color(0xFF00B8D4),
    secondaryGlow: Color(0x4000E5FF),
  ),
  AccentColorOption(
    name: 'Rose',
    primary: Color(0xFFFF80AB),
    primaryMuted: Color(0xFFF50057),
    primaryGlow: Color(0x40FF80AB),
    secondary: Color(0xFFB388FF),
    secondaryMuted: Color(0xFF7C4DFF),
    secondaryGlow: Color(0x40B388FF),
  ),
  AccentColorOption(
    name: 'Teal',
    primary: Color(0xFF64FFDA),
    primaryMuted: Color(0xFF1DE9B6),
    primaryGlow: Color(0x4064FFDA),
    secondary: Color(0xFFFF2DBA),
    secondaryMuted: Color(0xFFD81B8A),
    secondaryGlow: Color(0x40FF2DBA),
  ),
  AccentColorOption(
    name: 'Lime',
    primary: Color(0xFFEEFF41),
    primaryMuted: Color(0xFFC6FF00),
    primaryGlow: Color(0x40EEFF41),
    secondary: Color(0xFFFF2DBA),
    secondaryMuted: Color(0xFFD81B8A),
    secondaryGlow: Color(0x40FF2DBA),
  ),
  AccentColorOption(
    name: 'Indigo',
    primary: Color(0xFF536DFE),
    primaryMuted: Color(0xFF3D5AFE),
    primaryGlow: Color(0x40536DFE),
    secondary: Color(0xFFFF80AB),
    secondaryMuted: Color(0xFFF50057),
    secondaryGlow: Color(0x40FF80AB),
  ),
  AccentColorOption(
    name: 'Ice',
    primary: Color(0xFF80D8FF),
    primaryMuted: Color(0xFF40C4FF),
    primaryGlow: Color(0x4080D8FF),
    secondary: Color(0xFFFF80AB),
    secondaryMuted: Color(0xFFF50057),
    secondaryGlow: Color(0x40FF80AB),
  ),
];

/// Provides the current accent color index.
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, int>((
  ref,
) {
  return AccentColorNotifier();
});

class AccentColorNotifier extends StateNotifier<int> {
  AccentColorNotifier() : super(0) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_kAccentColorKey);
    if (stored != null && stored >= 0 && stored < accentColorOptions.length) {
      state = stored;
    }
  }

  Future<void> setColor(int index) async {
    if (index < 0 || index >= accentColorOptions.length) return;
    state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAccentColorKey, index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Font Family Notifier
// ─────────────────────────────────────────────────────────────────────────────

const _kFontFamilyKey = 'crusader_font_family';

/// Available font families (Google Fonts keys).
const fontFamilyOptions = [
  'Inter',
  'JetBrains Mono',
  'Fira Sans',
  'Space Grotesk',
  'Plus Jakarta Sans',
  'DM Sans',
  'Outfit',
  'Sora',
  'Manrope',
  'Rubik',
  'Work Sans',
  'Nunito',
  'Poppins',
  'Raleway',
  'Lato',
  'Source Sans 3',
  'IBM Plex Sans',
  'Karla',
];

/// Provides the current font family name.
final fontFamilyProvider = StateNotifierProvider<FontFamilyNotifier, String>((
  ref,
) {
  return FontFamilyNotifier();
});

class FontFamilyNotifier extends StateNotifier<String> {
  FontFamilyNotifier() : super('Inter') {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kFontFamilyKey);
    if (stored != null && fontFamilyOptions.contains(stored)) {
      state = stored;
    }
  }

  Future<void> setFont(String fontFamily) async {
    if (!fontFamilyOptions.contains(fontFamily)) return;
    state = fontFamily;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontFamilyKey, fontFamily);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar Collapsed Notifier
// ─────────────────────────────────────────────────────────────────────────────

const _kSidebarCollapsedKey = 'crusader_sidebar_collapsed';
const _kSectionCollapseKey = 'crusader_section_collapse';

/// Provides whether the sidebar is in collapsed (icon rail) mode.
/// Defaults to `true` (collapsed) for the sleek Linear/Arc look.
final sidebarCollapsedProvider =
    StateNotifierProvider<SidebarCollapsedNotifier, bool>((ref) {
      return SidebarCollapsedNotifier();
    });

class SidebarCollapsedNotifier extends StateNotifier<bool> {
  SidebarCollapsedNotifier() : super(true) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_kSidebarCollapsedKey);
    if (stored != null) {
      state = stored;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSidebarCollapsedKey, state);
  }

  Future<void> setCollapsed(bool collapsed) async {
    state = collapsed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSidebarCollapsedKey, collapsed);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Collapse Notifier — persists label/more section state per account
// ─────────────────────────────────────────────────────────────────────────────

/// State shape: `{ accountId: { "labels": true, "system": false } }`
/// Maps account IDs to per-section expanded booleans.
final sectionCollapseProvider =
    StateNotifierProvider<
      SectionCollapseNotifier,
      Map<String, Map<String, bool>>
    >((ref) => SectionCollapseNotifier());

class SectionCollapseNotifier
    extends StateNotifier<Map<String, Map<String, bool>>> {
  SectionCollapseNotifier() : super({}) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSectionCollapseKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final result = <String, Map<String, bool>>{};
        for (final entry in decoded.entries) {
          final inner = entry.value as Map<String, dynamic>;
          result[entry.key] = inner.map((k, v) => MapEntry(k, v as bool));
        }
        state = result;
      } catch (_) {
        // Corrupted data — start fresh.
      }
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSectionCollapseKey, jsonEncode(state));
  }

  /// Whether a section is expanded for a given account.
  /// Defaults: labels = true, system = false.
  bool isSectionExpanded(String accountId, String section) {
    final defaults = {'labels': true, 'system': false};
    return state[accountId]?[section] ?? defaults[section] ?? true;
  }

  /// Toggle a section's expanded state for a given account.
  Future<void> toggleSection(String accountId, String section) async {
    final current = isSectionExpanded(accountId, section);
    final accountState = Map<String, bool>.from(state[accountId] ?? {});
    accountState[section] = !current;
    state = {...state, accountId: accountState};
    await _persist();
  }
}
