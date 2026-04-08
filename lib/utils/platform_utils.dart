/// Crusader — Platform Utilities
library;

import 'dart:io';

/// Quick platform checks.
abstract final class PlatformUtils {
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  static bool get isMobile => Platform.isIOS || Platform.isAndroid;

  static bool get isWindows => Platform.isWindows;

  static bool get isIOS => Platform.isIOS;
}
