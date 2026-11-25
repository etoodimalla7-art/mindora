import 'package:flutter/widgets.dart';

class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius smAll  = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll  = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll  = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
