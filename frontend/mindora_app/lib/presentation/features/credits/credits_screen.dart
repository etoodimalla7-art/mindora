import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/credits/credits_entity.dart';
import '../../providers/credits_providers.dart';

/// Section 29: credit balance and subscription plans. Displays
/// placeholder pricing plainly rather than a misleading amount — see
/// SubscriptionPlanEntity.displayPrice.
class CreditsScreen extends ConsumerStatefulWidget {
  const CreditsScreen({super.key});

  @override
  ConsumerState<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends ConsumerState<CreditsScreen> {
  List<SubscriptionPlanEntity> _plans = [];
  bool _isLoadingPlans = true;
  bool _isSubscribing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await ref.read(creditsRepositoryProvider).getPlans();
      setState(() {
        _plans = plans;
        _isLoadingPlans = false;
      });
    } catch (_) {
      setState(() => _isLoadingPlans = false);
    }
  }

  Future<void> _subscribe(String planCode) async {
    setState(() {
      _isSubscribing = true;
      _error = null;
    });
    try {
      await ref.read(creditsRepositoryProvider).subscribe(planCode);
      ref.invalidate(creditBalanceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscribed! Downloads are now unlimited.')),
        );
      }
    } catch (error) {
      setState(() => _error = extractApiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(creditBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Credits & Subscription')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(Icons.toll_rounded, size: 32, color: theme.colorScheme.primary),
                    const SizedBox(height: AppSpacing.sm),
                    balanceAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => Text('—', style: theme.textTheme.displayLarge),
                      data: (balance) => Text('$balance', style: theme.textTheme.displayLarge),
                    ),
                    Text('Downloads remaining', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Get unlimited downloads with Premium, or contribute 5 approved '
              'documents to earn more credits.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoadingPlans)
              const Center(child: CircularProgressIndicator())
            else
              for (final plan in _plans)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    title: Text(plan.name),
                    subtitle: Text('${plan.displayPrice} / ${plan.interval}'),
                    trailing: ElevatedButton(
                      onPressed: _isSubscribing ? null : () => _subscribe(plan.code),
                      child: const Text('Subscribe'),
                    ),
                  ),
                ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
