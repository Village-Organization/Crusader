/// Crusader — App Constants
library;

/// App-level constants.
abstract final class AppConstants {
  static const String appName = 'Crusader';
  static const String appTagline = 'The sleek, modern email client that finally feels good to use.';
  static const String appVersion = '0.1.0';

  /// Animation durations used throughout the app.
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// Layout breakpoints.
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Sidebar width on desktop.
  static const double sidebarWidth = 220;
  static const double sidebarCollapsedWidth = 64;
}
