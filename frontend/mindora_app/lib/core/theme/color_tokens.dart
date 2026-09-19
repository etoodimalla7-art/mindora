import 'package:flutter/material.dart';
import 'brand_config.dart';

/// Semantic color tokens. Widgets should reference these — never raw
/// Color(...) literals — so the whole app can be reskinned by editing
/// [BrandConfig] alone.
class AppColors {
  const AppColors._();

  static const Color primary = Color(BrandConfig.primarySeedColorValue);
  static const Color secondary = Color(BrandConfig.secondarySeedColorValue);

  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE0A100);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF3454D1);

  // Light surfaces
  static const Color lightBackground = Color(0xFFF7F8FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE4E7EE);
  static const Color lightTextPrimary = Color(0xFF12141C);
  static const Color lightTextSecondary = Color(0xFF5B6072);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF171A23);
  static const Color darkBorder = Color(0xFF2A2E3A);
  static const Color darkTextPrimary = Color(0xFFF3F4F8);
  static const Color darkTextSecondary = Color(0xFFA1A6B6);
}
