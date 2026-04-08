/// Crusader — Notification Service
///
/// Lightweight wrapper around `local_notifier` for Windows desktop
/// toast notifications. Shows notifications for new incoming mail.
library;

import 'dart:io';

import 'package:local_notifier/local_notifier.dart';

/// Singleton service for showing Windows toast notifications.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  bool _initialized = false;

  /// Initialize the notifier. Must be called once at app startup.
  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    try {
      await localNotifier.setup(
        appName: 'Crusader',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _initialized = true;
    } catch (_) {
      // Notification setup failed — degrade gracefully.
    }
  }

  /// Show a notification for new incoming mail.
  ///
  /// [count] is the number of new messages.
  /// [senderName] and [subject] are from the most recent new message.
  Future<void> showNewMailNotification({
    required int count,
    String? senderName,
    String? subject,
  }) async {
    if (!_initialized) return;

    final title = count == 1
        ? 'New email${senderName != null ? ' from $senderName' : ''}'
        : '$count new emails';

    final body = count == 1 && subject != null && subject.isNotEmpty
        ? subject
        : count > 1 && senderName != null
        ? '$senderName and ${count - 1} other${count > 2 ? 's' : ''}'
        : null;

    final notification = LocalNotification(title: title, body: body);

    try {
      await notification.show();
    } catch (_) {
      // Notification failed — non-critical.
    }
  }
}
