import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'admin_router.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'MINDORA Admin',
      debugShowCheckedModeBanner: false,
      theme: _buildAdminTheme(Brightness.dark),
      darkTheme: _buildAdminTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        // Fix Flutter Web bug: viewInsets negative when keyboard dismiss
        final media = MediaQuery.of(context);
        final safeInsets = EdgeInsets.fromLTRB(
          media.viewInsets.left.clamp(0.0, double.infinity),
          media.viewInsets.top.clamp(0.0, double.infinity),
          media.viewInsets.right.clamp(0.0, double.infinity),
          media.viewInsets.bottom.clamp(0.0, double.infinity),
        );
        final safePadding = EdgeInsets.fromLTRB(
          media.padding.left.clamp(0.0, double.infinity),
          media.padding.top.clamp(0.0, double.infinity),
          media.padding.right.clamp(0.0, double.infinity),
          media.padding.bottom.clamp(0.0, double.infinity),
        );
        return MediaQuery(
          data: media.copyWith(
            viewInsets: safeInsets,
            padding: safePadding,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  ThemeData _buildAdminTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6E8DFF),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0A0E1A),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF151B2E),
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
