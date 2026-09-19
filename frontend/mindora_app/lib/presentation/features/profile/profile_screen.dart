import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../providers/user_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          AppBar(title: const Text('Profile'), automaticallyImplyLeading: false),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                userAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (user) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Text(user.email, style: theme.textTheme.titleLarge),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.toll_outlined),
                  title: const Text('Credits & Subscription'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/credits'),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/notifications'),
                ),
                // Only ever visible to an account with role == 'admin' —
                // there is no way to self-elevate from inside the app
                // (see core/deps.py::get_current_admin_user).
                userAsync.maybeWhen(
                  data: (user) => user.isAdmin
                      ? ListTile(
                          leading: const Icon(Icons.fact_check_outlined),
                          title: const Text('Review Queue'),
                          subtitle: const Text('Moderator tools'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/admin/review-queue'),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
