/// 4pt spacing scale — use these instead of magic numbers everywhere.
class AppSpacing {
  const AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radius scale.
class AppRadius {
  const AppRadius._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

/// Elevation / shadow scale.
class AppElevation {
  const AppElevation._();
  static const double none = 0;
  static const double card = 2;
  static const double dialog = 8;
  static const double modal = 16;
}

/// Animation durations shared across the app for consistent motion.
class AppMotion {
  const AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}
