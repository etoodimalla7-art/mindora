import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale. One display font (headings) + one text font (body)
/// keeps the product feeling designed rather than default-Material.
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32, fontWeight: FontWeight.w700, color: primaryText, height: 1.2,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24, fontWeight: FontWeight.w700, color: primaryText, height: 1.25,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w600, color: primaryText,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: primaryText, height: 1.5),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: secondaryText, height: 1.5),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
    );
  }
}
