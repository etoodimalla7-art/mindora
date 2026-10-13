import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/widgets.dart';
import '../../../core/router/routes.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const AppEmptyState(
          icon: Icons.person_outline,
          title: 'Not signed in',
          message: 'Sign in to see your profile.',
        ),
      );
    }

    final user = session.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  AppAvatar(
                    initials: (user.fullName ?? user.email).substring(0, 1),
                    size: 80,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.fullName ?? 'Student',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(user.email, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Account section
            Text('Account', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  AppListTile(
                    title: 'Language',
                    subtitle: user.preferredLanguage.toUpperCase(),
                    leadingIcon: Icons.language,
                  ),
                  const AppDivider(),
                  AppListTile(
                    title: 'Country',
                    subtitle: user.countryCode,
                    leadingIcon: Icons.public,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // App section
            Text('App', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  AppListTile(
                    title: 'Notifications',
                    leadingIcon: Icons.notifications_none,
                    showChevron: true,
                    onTap: () {},
                  ),
                  const AppDivider(),
                  AppListTile(
                    title: 'Downloads',
                    leadingIcon: Icons.download_outlined,
                    showChevron: true,
                    onTap: () {},
                  ),
                  const AppDivider(),
                  AppListTile(
                    title: 'Credits',
                    leadingIcon: Icons.card_giftcard,
                    showChevron: true,
                    onTap: () {},
                  ),
                  const AppDivider(),
                  AppListTile(
                    title: 'Help & feedback',
                    leadingIcon: Icons.help_outline,
                    showChevron: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Logout
            AppButton(
              label: 'Sign out',
              icon: Icons.logout,
              variant: AppButtonVariant.danger,
              onPressed: () async {
                final confirmed = await AppDialog.show(
                  context,
                  title: 'Sign out?',
                  message: 'You will need to sign in again to access your plans.',
                  confirmLabel: 'Sign out',
                  destructive: true,
                );
                if (!confirmed) return;
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.onboarding);
              },
            ),
            const SizedBox(height: AppSpacing.massive),
          ],
        ),
      ),
    );
  }
}
