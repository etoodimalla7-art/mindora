import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'spacing_tokens.dart';
import 'typography_tokens.dart';

/// Builds the Light/Dark ThemeData from the token files. Screens should
/// never set colors/fonts inline — they pull from Theme.of(context).
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final textTheme = AppTypography.textTheme(
      AppColors.lightTextPrimary,
      AppColors.lightTextSecondary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.danger,
        surface: AppColors.lightSurface,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: AppElevation.card,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerColor: AppColors.lightBorder,
    );
  }

  static ThemeData dark() {
    final textTheme = AppTypography.textTheme(
      AppColors.darkTextPrimary,
      AppColors.darkTextSecondary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.danger,
        surface: AppColors.darkSurface,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: AppElevation.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerColor: AppColors.darkBorder,
    );
  }
}
