/// Crusader — System Tray Service
///
/// Manages the Windows system tray icon with unread badge tooltip.
/// Shows a context menu with Show/Compose/Quit actions.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';

/// Callback types for tray menu actions.
typedef TrayCallback = void Function();

/// Singleton service for the system tray icon.
class SystemTrayService {
  SystemTrayService._();
  static final instance = SystemTrayService._();

  SystemTray? _systemTray;
  AppWindow? _appWindow;
  bool _initialized = false;

  TrayCallback? onShow;
  TrayCallback? onCompose;
  TrayCallback? onQuit;

  /// Initialize the system tray. Call once at app startup.
  Future<void> init({
    TrayCallback? onShow,
    TrayCallback? onCompose,
    TrayCallback? onQuit,
  }) async {
    if (_initialized) return;
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    this.onShow = onShow;
    this.onCompose = onCompose;
    this.onQuit = onQuit;

    try {
      _systemTray = SystemTray();
      _appWindow = AppWindow();

      await _systemTray!.initSystemTray(
        title: 'Crusader',
        iconPath: 'assets/icon/tray_icon.png',
        toolTip: 'Crusader — No unread emails',
      );

      // Register click handler — show app on left click.
      _systemTray!.registerSystemTrayEventHandler((eventName) {
        if (eventName == 'leftMouseUp') {
          _appWindow?.show();
          onShow?.call();
        } else if (eventName == 'rightMouseUp') {
          _systemTray?.popUpContextMenu();
        }
      });

      await _updateContextMenu();
      _initialized = true;
    } catch (e) {
      debugPrint('System tray init failed: $e');
    }
  }

  /// Update the tray tooltip and menu with the current unread count.
  Future<void> updateUnreadCount(int count) async {
    if (!_initialized || _systemTray == null) return;

    final tooltip = count > 0
        ? 'Crusader — $count unread email${count > 1 ? 's' : ''}'
        : 'Crusader — No unread emails';

    try {
      await _systemTray!.setToolTip(tooltip);
      await _updateContextMenu(unreadCount: count);
    } catch (_) {
      // Non-critical — tray update failed.
    }
  }

  /// Build and set the context menu.
  Future<void> _updateContextMenu({int unreadCount = 0}) async {
    if (_systemTray == null) return;

    final unreadLabel = unreadCount > 0 ? ' ($unreadCount unread)' : '';

    final menu = <MenuItemBase>[
      MenuItem(
        label: 'Show Crusader$unreadLabel',
        onClicked: () {
          _appWindow?.show();
          onShow?.call();
        },
      ),
      MenuSeparator(),
      MenuItem(
        label: 'Compose New Email',
        onClicked: () {
          _appWindow?.show();
          onCompose?.call();
        },
      ),
      MenuSeparator(),
      MenuItem(
        label: 'Quit Crusader',
        onClicked: () {
          onQuit?.call();
        },
      ),
    ];

    await _systemTray!.setContextMenu(menu);
  }

  /// Clean up the tray icon.
  void dispose() {
    _systemTray = null;
    _appWindow = null;
    _initialized = false;
  }
}
