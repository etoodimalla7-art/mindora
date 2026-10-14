import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/subscription_providers.dart';

class ManageSubscriptionScreen extends ConsumerWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subAsync = ref.watch(mySubscriptionProvider);
    final paymentsAsync = ref.watch(paymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My subscription')),
      body: SafeArea(
        child: subAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load subscription',
            message: 'Please try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(mySubscriptionProvider),
          ),
          data: (sub) {
            if (sub == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: AppEmptyState(
                    icon: Icons.workspace_premium_outlined,
                    title: 'No active subscription',
                    message:
                        'Subscribe to unlock unlimited downloads, AI chat, and mock exams.',
                    actionLabel: 'See plans',
                    onAction: () => context.push('/subscription/plans'),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                AppSurface(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  color: const Color(0xFF10B981).withValues(alpha: 0.10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium,
                              color: Color(0xFF10B981), size: 28),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              sub.plan?.name ?? 'Subscription',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          AppBadge(
                            label: sub.status.toUpperCase(),
                            tone: sub.isActive
                                ? AppBadgeTone.success
                                : AppBadgeTone.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _kv(context, 'Started', _fmt(sub.currentPeriodStart)),
                      _kv(context, 'Renews on', _fmt(sub.currentPeriodEnd)),
                      _kv(context, 'Days remaining', '${sub.daysRemaining}'),
                      _kv(context, 'Reference',
                          sub.providerReference ?? '-'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  label: 'Cancel subscription',
                  icon: Icons.cancel_outlined,
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    final confirmed = await AppDialog.show(
                      context,
                      title: 'Cancel subscription?',
                      message:
                          'Access remains until the end of the current period.',
                      confirmLabel: 'Cancel',
                      destructive: true,
                    );
                    if (!confirmed) return;
                    try {
                      await ref
                          .read(subscriptionRepositoryProvider)
                          .cancel();
                      ref.invalidate(mySubscriptionProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Subscription cancelled.')),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not cancel.')),
                        );
                      }
                    }
                  },
                ),

                const SizedBox(height: AppSpacing.xxl),
                Text('Payment history', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),

                paymentsAsync.when(
                  loading: () => const AppSkeleton(height: 80),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (payments) {
                    if (payments.isEmpty) {
                      return Text('No payments yet.',
                          style: theme.textTheme.bodySmall);
                    }
                    return Column(
                      children: [
                        for (final p in payments)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: AppSurface(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  Icon(
                                    p.status == 'succeeded'
                                        ? Icons.check_circle
                                        : Icons.error_outline,
                                    color: p.status == 'succeeded'
                                        ? const Color(0xFF10B981)
                                        : theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.reference,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                        Text(
                                          DateFormat.yMMMd()
                                              .add_Hm()
                                              .format(p.createdAt),
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${(p.amountMinor / 100).toStringAsFixed(0)} ${p.currency}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.massive),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _fmt(DateTime? d) =>
      d == null ? '-' : DateFormat.yMMMd().format(d);

  static Widget _kv(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k, style: theme.textTheme.labelMedium)),
          Text(v, style: theme.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
