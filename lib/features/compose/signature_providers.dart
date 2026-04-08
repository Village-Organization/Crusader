/// Crusader — Signature Providers (Riverpod)
///
/// Per-account email signature management with persistence.
/// Signatures are stored as plain text in SharedPreferences, keyed by account ID.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kSignaturesKey = 'crusader_signatures';
const _kSignatureEnabledKey = 'crusader_signature_enabled';

// ─────────────────────────────────────────────────────────────────────────────
// Signature State
// ─────────────────────────────────────────────────────────────────────────────

class SignatureState {
  const SignatureState({this.signatures = const {}, this.isEnabled = true});

  /// Map of accountId -> signature text.
  final Map<String, String> signatures;

  /// Global toggle: whether to auto-append signatures.
  final bool isEnabled;

  /// Get signature for a specific account, or empty string if none.
  String getSignature(String accountId) => signatures[accountId] ?? '';

  /// Whether a specific account has a non-empty signature.
  bool hasSignature(String accountId) =>
      signatures.containsKey(accountId) &&
      signatures[accountId]!.trim().isNotEmpty;

  SignatureState copyWith({Map<String, String>? signatures, bool? isEnabled}) {
    return SignatureState(
      signatures: signatures ?? this.signatures,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signature Notifier
// ─────────────────────────────────────────────────────────────────────────────

final signatureProvider =
    StateNotifierProvider<SignatureNotifier, SignatureState>((ref) {
      return SignatureNotifier();
    });

class SignatureNotifier extends StateNotifier<SignatureState> {
  SignatureNotifier() : super(const SignatureState()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load enabled state.
    final enabled = prefs.getBool(_kSignatureEnabledKey) ?? true;

    // Load signatures map.
    final json = prefs.getString(_kSignaturesKey);
    Map<String, String> signatures = {};
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        signatures = decoded.map((k, v) => MapEntry(k, v as String));
      } catch (_) {
        // Corrupted data — start fresh.
      }
    }

    state = SignatureState(signatures: signatures, isEnabled: enabled);
  }

  /// Set the signature for a specific account.
  Future<void> setSignature(String accountId, String signature) async {
    final updated = Map<String, String>.from(state.signatures);
    if (signature.trim().isEmpty) {
      updated.remove(accountId);
    } else {
      updated[accountId] = signature;
    }
    state = state.copyWith(signatures: updated);
    await _persist();
  }

  /// Remove signature for a specific account.
  Future<void> removeSignature(String accountId) async {
    final updated = Map<String, String>.from(state.signatures);
    updated.remove(accountId);
    state = state.copyWith(signatures: updated);
    await _persist();
  }

  /// Toggle global signature enable/disable.
  Future<void> toggleEnabled() async {
    state = state.copyWith(isEnabled: !state.isEnabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSignatureEnabledKey, state.isEnabled);
  }

  /// Get the formatted signature block for insertion into email body.
  /// Returns empty string if disabled or no signature set.
  String getFormattedSignature(String accountId) {
    if (!state.isEnabled) return '';
    final sig = state.getSignature(accountId);
    if (sig.trim().isEmpty) return '';
    return '\n\n--\n$sig';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSignaturesKey, jsonEncode(state.signatures));
    await prefs.setBool(_kSignatureEnabledKey, state.isEnabled);
  }
}
