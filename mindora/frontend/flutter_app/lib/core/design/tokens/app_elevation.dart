import 'package:flutter/material.dart';

class AppElevation {
  AppElevation._();

  /// Soft, low-contrast shadows — the app must feel calm, not busy.
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 14, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 24, offset: Offset(0, 12)),
  ];
}
