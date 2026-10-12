class AppMotion {
  AppMotion._();

  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve entrance = Curves.easeOutBack;
}
