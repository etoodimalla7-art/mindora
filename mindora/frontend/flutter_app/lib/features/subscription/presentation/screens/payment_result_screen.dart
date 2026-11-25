import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/subscription_providers.dart';
import '../../domain/models.dart';

class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({super.key, required this.reference});
  final String reference;

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  bool _busy = true;
  String? _error;
  Subscription? _subscription;
  String _status = 'pending';
  String _message = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sub = await ref
          .read(subscriptionRepositoryProvider)
          .confirmPayment(widget.reference);
      if (!mounted) return;
      setState(() {
        _subscription = sub;
        _status = sub != null && sub.isActive ? 'succeeded' : 'pending';
        _message = sub != null && sub.isActive
            ? 'Your subscription is active!'
            : 'Payment is being processed. Refresh in a few moments.';
      });
      ref.invalidate(mySubscriptionProvider);
      ref.invalidate(paymentHistoryProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'We could not confirm the payment. Please try again.';
        _status = 'unknown';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuccess = _status == 'succeeded';

    return Scaffold(
      appBar: AppBar(title: const Text('Payment status')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xxxl),

              if (_busy)
                const CircularProgressIndicator()
              else
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: (isSuccess
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.primary)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle
                        : Icons.hourglass_top_rounded,
                    size: 48,
                    color: isSuccess
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.primary,
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),
              Text(
                _busy
                    ? 'Confirming payment...'
                    : (isSuccess ? 'Subscribed!' : 'Payment status'),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error ?? _message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              if (_subscription != null && _subscription!.plan != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                AppSurface(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(_subscription!.plan!.name,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Active until ${_subscription!.currentPeriodEnd?.toLocal().toString().split(' ').first ?? "-"}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              if (!_busy) ...[
                AppButton(
                  label: 'Go to my subscription',
                  icon: Icons.dashboard_outlined,
                  onPressed: () => context.go('/subscription/manage'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Retry confirmation',
                  variant: AppButtonVariant.secondary,
                  onPressed: _confirm,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
