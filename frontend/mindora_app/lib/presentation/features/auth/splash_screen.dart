import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_config.dart';
import '../../../core/theme/spacing_tokens.dart';

/// Splash (section 10, screen 1). Purely presentational — the router's
/// redirect logic (driven by authControllerProvider) decides where to
/// go next; this screen just needs to look intentional while that
/// resolves, never a bare blank frame.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(BrandConfig.appName, style: theme.textTheme.displayLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(BrandConfig.tagline, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
