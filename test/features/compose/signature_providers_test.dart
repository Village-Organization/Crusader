import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crusader/features/compose/signature_providers.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // SignatureState (pure data class)
  // ─────────────────────────────────────────────────────────────────────

  group('SignatureState', () {
    test('default constructor has sensible defaults', () {
      const s = SignatureState();

      expect(s.signatures, isEmpty);
      expect(s.isEnabled, isTrue);
    });

    test('getSignature returns empty string for unknown account', () {
      const s = SignatureState();

      expect(s.getSignature('unknown-id'), '');
    });

    test('getSignature returns signature for known account', () {
      const s = SignatureState(signatures: {'acc1': 'Best regards,\nJohn'});

      expect(s.getSignature('acc1'), 'Best regards,\nJohn');
    });

    test('hasSignature returns false for unknown account', () {
      const s = SignatureState();

      expect(s.hasSignature('unknown-id'), isFalse);
    });

    test('hasSignature returns false for empty/whitespace signature', () {
      const s = SignatureState(signatures: {'acc1': '   '});

      expect(s.hasSignature('acc1'), isFalse);
    });

    test('hasSignature returns true for non-empty signature', () {
      const s = SignatureState(signatures: {'acc1': 'Regards'});

      expect(s.hasSignature('acc1'), isTrue);
    });

    test('copyWith preserves fields when none specified', () {
      const original = SignatureState(
        signatures: {'acc1': 'Sig'},
        isEnabled: false,
      );
      final copy = original.copyWith();

      expect(copy.signatures, {'acc1': 'Sig'});
      expect(copy.isEnabled, isFalse);
    });

    test('copyWith overrides specified fields', () {
      const original = SignatureState(isEnabled: true);
      final copy = original.copyWith(isEnabled: false);

      expect(copy.isEnabled, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // SignatureNotifier (requires SharedPreferences mock)
  // ─────────────────────────────────────────────────────────────────────

  group('SignatureNotifier', () {
    setUp(() {
      // Initialize SharedPreferences with empty values for testing.
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state has no signatures and is enabled', () async {
      final notifier = SignatureNotifier();
      // Allow async _loadFromPrefs to complete.
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.signatures, isEmpty);
      expect(notifier.state.isEnabled, isTrue);
    });

    test('setSignature stores per-account signature', () async {
      final notifier = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.setSignature('acc1', 'Best regards,\nAlice');

      expect(notifier.state.getSignature('acc1'), 'Best regards,\nAlice');
      expect(notifier.state.hasSignature('acc1'), isTrue);
    });

    test('setSignature with empty string removes signature', () async {
      final notifier = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.setSignature('acc1', 'Hello');
      await notifier.setSignature('acc1', '');

      expect(notifier.state.hasSignature('acc1'), isFalse);
    });

    test('removeSignature removes the signature', () async {
      final notifier = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.setSignature('acc1', 'Hello');
      await notifier.removeSignature('acc1');

      expect(notifier.state.hasSignature('acc1'), isFalse);
    });

    test('toggleEnabled flips the enabled flag', () async {
      final notifier = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isEnabled, isTrue);
      await notifier.toggleEnabled();
      expect(notifier.state.isEnabled, isFalse);
      await notifier.toggleEnabled();
      expect(notifier.state.isEnabled, isTrue);
    });

    test('getFormattedSignature returns formatted block', () async {
      final notifier = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.setSignature('acc1', 'Best regards,\nAlice');
      final formatted = notifier.getFormattedSignature('acc1');

      expect(formatted, '\n\n--\nBest regards,\nAlice');
    });

    test('getFormattedSignature returns empty when disabled', () async {
      final notifier = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.setSignature('acc1', 'Best regards');
      await notifier.toggleEnabled();
      final formatted = notifier.getFormattedSignature('acc1');

      expect(formatted, '');
    });

    test('getFormattedSignature returns empty for unknown account', () async {
      final notifier = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      final formatted = notifier.getFormattedSignature('unknown');

      expect(formatted, '');
    });

    test('multiple accounts can have different signatures', () async {
      final notifier = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.setSignature('acc1', 'Sig 1');
      await notifier.setSignature('acc2', 'Sig 2');

      expect(notifier.state.getSignature('acc1'), 'Sig 1');
      expect(notifier.state.getSignature('acc2'), 'Sig 2');
    });

    test('persists and loads signatures', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier1 = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier1.setSignature('acc1', 'Persisted sig');

      // Create a new notifier that should load from prefs.
      final notifier2 = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      expect(notifier2.state.getSignature('acc1'), 'Persisted sig');
    });

    test('persists enabled state', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier1 = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier1.toggleEnabled(); // false

      final notifier2 = SignatureNotifier();
      await Future<void>.delayed(Duration.zero);

      expect(notifier2.state.isEnabled, isFalse);
    });
  });
}
