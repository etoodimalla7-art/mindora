import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final surface      = isDark ? AppPalette.neutral900 : AppPalette.neutral0;
    final surfaceAlt   = isDark ? AppPalette.neutral800 : AppPalette.neutral50;
    final onSurface    = isDark ? AppPalette.neutral50  : AppPalette.neutral900;
    final muted        = isDark ? AppPalette.neutral400 : AppPalette.neutral500;
    final outline      = isDark ? AppPalette.neutral700 : AppPalette.neutral200;
    final primary      = isDark ? AppPalette.brand400   : AppPalette.brand600;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? AppPalette.neutral950 : AppPalette.neutral0,
      secondary: AppPalette.accent500,
      onSecondary: AppPalette.neutral950,
      error: AppPalette.danger,
      onError: AppPalette.neutral0,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceAlt,
      outline: outline,
      outlineVariant: outline,
    );

    final textTheme = AppTypography.buildTextTheme(onSurface, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      fontFamily: textTheme.bodyMedium?.fontFamily,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: onSurface, size: 22),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: isDark
              ? BorderSide(color: outline.withValues(alpha: 0.3))
              : BorderSide(color: outline.withValues(alpha: 0.5)),
        ),
      ),

      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted.withValues(alpha: 0.85)),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppPalette.danger),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
          elevation: isDark ? 0 : 2,
          shadowColor: primary.withValues(alpha: 0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: textTheme.labelLarge,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        side: BorderSide(color: outline),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: isDark ? 0.18 : 0.15),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : muted, size: 22);
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: primary, size: 22),
        unselectedIconTheme: IconThemeData(color: muted, size: 22),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: primary),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: muted),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppPalette.neutral100 : AppPalette.neutral900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppPalette.neutral900 : AppPalette.neutral50,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceAlt,
        circularTrackColor: surfaceAlt,
      ),
    );
  }
}
