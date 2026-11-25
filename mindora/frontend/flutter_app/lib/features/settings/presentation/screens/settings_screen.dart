import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/theme/theme_mode_provider.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/mindora_app_bar.dart';
import '../../../../core/locale/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: const MindoraAppBar(title: 'Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // ============ APPEARANCE ============
            Text('Appearance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),

            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setMode(v!),
                    title: const Text('Follow system'),
                    subtitle: const Text('Match your device settings'),
                    secondary: const Icon(Icons.brightness_auto_outlined),
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setMode(v!),
                    title: const Text('Light'),
                    subtitle: const Text('Always use light mode'),
                    secondary: const Icon(Icons.light_mode_outlined),
                  ),
                  const Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setMode(v!),
                    title: const Text('Dark'),
                    subtitle: const Text('Always use dark mode'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ============ LANGUAGE ============
            Text('Language', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),

            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'en',
                    groupValue: locale.languageCode,
                    onChanged: (v) => ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('en')),
                    title: const Text('English'),
                    secondary: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'fr',
                    groupValue: locale.languageCode,
                    onChanged: (v) => ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('fr')),
                    title: const Text('Français'),
                    secondary: const Text('🇫🇷', style: TextStyle(fontSize: 22)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ============ ABOUT ============
            Text('About', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    trailing: Text(
                      '0.1.0',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.massive),
          ],
        ),
      ),
    );
  }
}
