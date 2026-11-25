import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme buildTextTheme(Color onSurface, Color muted) {
    final base = GoogleFonts.interTextTheme();

    TextStyle t(TextStyle s, {double? size, FontWeight? weight, double? height, Color? color, double? letterSpacing}) =>
        s.copyWith(
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? onSurface,
          letterSpacing: letterSpacing,
        );

    return base.copyWith(
      displayLarge: t(base.displayLarge!, size: 44, weight: FontWeight.w700, height: 1.1, letterSpacing: -1.2),
      displayMedium: t(base.displayMedium!, size: 36, weight: FontWeight.w700, height: 1.15, letterSpacing: -1.0),
      displaySmall: t(base.displaySmall!, size: 30, weight: FontWeight.w700, height: 1.2, letterSpacing: -0.6),

      headlineLarge: t(base.headlineLarge!, size: 26, weight: FontWeight.w700, height: 1.25, letterSpacing: -0.4),
      headlineMedium: t(base.headlineMedium!, size: 22, weight: FontWeight.w600, height: 1.3),
      headlineSmall: t(base.headlineSmall!, size: 20, weight: FontWeight.w600, height: 1.3),

      titleLarge: t(base.titleLarge!, size: 18, weight: FontWeight.w600, height: 1.35),
      titleMedium: t(base.titleMedium!, size: 16, weight: FontWeight.w600, height: 1.4),
      titleSmall: t(base.titleSmall!, size: 14, weight: FontWeight.w600, height: 1.4),

      bodyLarge: t(base.bodyLarge!, size: 16, weight: FontWeight.w400, height: 1.55),
      bodyMedium: t(base.bodyMedium!, size: 14, weight: FontWeight.w400, height: 1.55),
      bodySmall: t(base.bodySmall!, size: 12, weight: FontWeight.w400, height: 1.5, color: muted),

      labelLarge: t(base.labelLarge!, size: 14, weight: FontWeight.w600, height: 1.3, letterSpacing: 0.1),
      labelMedium: t(base.labelMedium!, size: 12, weight: FontWeight.w600, height: 1.3, letterSpacing: 0.2),
      labelSmall: t(base.labelSmall!, size: 11, weight: FontWeight.w600, height: 1.3, letterSpacing: 0.3, color: muted),
    );
  }
}
