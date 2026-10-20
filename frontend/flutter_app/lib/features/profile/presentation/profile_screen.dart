import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/widgets.dart';
import '../../../core/router/routes.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../documents/data/documents_providers.dart';
import '../../../core/design/widgets/mindora_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final creditsAsync = ref.watch(creditBalanceProvider);

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
    final isAdmin = user.isAdmin;

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
                  MindoraAvatar(
                    name: user.fullName ?? user.email,
                    size: 80,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.fullName ?? 'Student',
                        style: theme.textTheme.titleLarge,
                      ),
                      if (!user.isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Unverified',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email, style: theme.textTheme.bodySmall),
                  if (isAdmin) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const AppBadge(label: 'ADMIN', tone: AppBadgeTone.danger),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Credits
            creditsAsync.when(
              loading: () => const AppSkeleton(height: 80),
              error: (_, __) => const SizedBox.shrink(),
              data: (credits) => AppSurface(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.card_giftcard,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${credits.balance} credits',
                              style: theme.textTheme.titleMedium),
                          Text('Available for downloads',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Account
            Text('Account', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),

            // Verify email banner (only if not verified)
            if (!user.isVerified) ...[
              const SizedBox(height: AppSpacing.md),
              AppSurface(
                padding: EdgeInsets.zero,
                child: AppListTile(
                  title: 'Verify your email',
                  subtitle: 'Get full access and secure your account',
                  leadingIcon: Icons.mark_email_unread_outlined,
                  showChevron: true,
                  onTap: () => context.push(
                    '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(user.email)}&purpose=verify_email',
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
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

            // Admin
            if (isAdmin) ...[
              Text('Administration', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              AppSurface(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    AppListTile(
                      title: 'Moderation queue',
                      subtitle: 'Review and approve contributed documents',
                      leadingIcon: Icons.shield_outlined,
                      showChevron: true,
                      onTap: () => context.push('/admin/moderation'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // App
            Text('App', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  AppListTile(
                    title: 'My contributions',
                    leadingIcon: Icons.folder_copy_outlined,
                    showChevron: true,
                    onTap: () => context.push('/documents/mine'),
                  ),
                  const AppDivider(),
                  AppListTile(
                    title: 'Subscription',
                    subtitle: 'Manage your plan and payments',
                    leadingIcon: Icons.workspace_premium_outlined,
                    showChevron: true,
                    onTap: () => context.push('/subscription/manage'),
                  ),
                  const AppDivider(),
                  AppListTile(
                    title: 'Plans & pricing',
                    subtitle: 'See subscription options',
                    leadingIcon: Icons.sell_outlined,
                    showChevron: true,
                    onTap: () => context.push('/subscription/plans'),
                  ),
                  const AppDivider(),
                  AppListTile(
                    title: 'Mock exams',
                    subtitle: 'Practice tests generated by AI',
                    leadingIcon: Icons.quiz_outlined,
                    showChevron: true,
                    onTap: () => context.push('/mock-exams'),
                  ),
                  const AppDivider(),
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
                    title: 'Help & feedback',
                    leadingIcon: Icons.help_outline,
                    showChevron: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppSurface(
              padding: EdgeInsets.zero,
              child: AppListTile(
                title: 'Settings',
                subtitle: 'Theme, language, about',
                leadingIcon: Icons.settings_outlined,
                showChevron: true,
                onTap: () => context.push('/settings'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              label: 'Sign out',
              icon: Icons.logout,
              variant: AppButtonVariant.danger,
              onPressed: () async {
                final confirmed = await AppDialog.show(
                  context,
                  title: 'Sign out?',
                  message:
                      'You will need to sign in again to access your plans.',
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
