import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/subscription_providers.dart';
import '../../domain/models.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plansAsync = ref.watch(plansProvider);
    final currentSubAsync = ref.watch(mySubscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your plan')),
      body: SafeArea(
        child: plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load plans',
            message: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(plansProvider),
          ),
          data: (plans) {
            final currentSub = currentSubAsync.maybeWhen(
              data: (s) => s,
              orElse: () => null,
            );

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Unlock everything',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Unlimited AI chat, mock exams, and document downloads.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                if (currentSub != null && currentSub.isActive) ...[
                  AppSurface(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    color: const Color(0xFF10B981).withValues(alpha: 0.10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF10B981), size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active: ${currentSub.plan?.name ?? "subscription"}',
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                '${currentSub.daysRemaining} days remaining',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push('/subscription/manage'),
                          child: const Text('Manage'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                for (var i = 0; i < plans.length; i++) ...[
                  _PlanCard(
                    plan: plans[i],
                    featured: i == 1, // highlight the middle plan
                    disabled: currentSub?.isActive == true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'Secure payment via Flutterwave. Cancel anytime.',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.massive),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.featured,
    required this.disabled,
  });

  final Plan plan;
  final bool featured;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: featured
          ? theme.colorScheme.primary.withValues(alpha: 0.06)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'POPULAR',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(plan.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          if (plan.description != null)
            Text(plan.description!, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.displayAmount,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(plan.cycleLabel, style: theme.textTheme.labelMedium),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          for (final feature in _visibleFeatures(plan.features))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(feature, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: disabled ? 'Already subscribed' : 'Choose this plan',
            icon: Icons.lock_open_outlined,
            onPressed: disabled
                ? null
                : () => context.push('/subscription/checkout/${plan.code}'),
          ),
        ],
      ),
    );
  }

  static List<String> _visibleFeatures(Map<String, dynamic> features) {
    final out = <String>[];
    if (features['unlimited_downloads'] == true) {
      out.add('Unlimited document downloads');
    }
    if (features['ai_chat_unlimited'] == true) {
      out.add('Unlimited AI tutor conversations');
    }
    if (features['mock_exams_unlimited'] == true) {
      out.add('Unlimited mock exams with corrections');
    }
    if (features['priority_support'] == true) {
      out.add('Priority support');
    }
    if (features['early_access'] == true) {
      out.add('Early access to new features');
    }
    return out;
  }
}
