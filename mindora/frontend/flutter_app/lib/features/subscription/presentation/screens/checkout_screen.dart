import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/subscription_providers.dart';
import '../../domain/models.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.planCode});
  final String planCode;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _busy = false;
  String? _error;
  CheckoutSession? _session;

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await ref
          .read(subscriptionRepositoryProvider)
          .startCheckout(widget.planCode);
      if (!mounted) return;
      setState(() => _session = session);

      // Open the checkout URL in a new tab/window (works on web).
      final uri = Uri.parse(session.checkoutUrl);
      final ok = await launchUrl(uri, webOnlyWindowName: '_self');
      if (!ok) {
        // Fallback: navigate within the same tab.
        if (mounted) {
          context.push('/subscription/return/${session.payment.reference}');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not start checkout. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ready to subscribe?', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You will be redirected to Flutterwave to complete the payment. '
                'After the payment, come back to this app.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (_session != null) ...[
                AppSurface(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment reference',
                          style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        _session!.payment.reference,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Status: ${_session!.payment.status}',
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Open checkout page again',
                  icon: Icons.open_in_new,
                  onPressed: () => launchUrl(
                    Uri.parse(_session!.checkoutUrl),
                    webOnlyWindowName: '_self',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'I have completed the payment',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.check_circle_outline,
                  onPressed: () => context
                      .push('/subscription/return/${_session!.payment.reference}'),
                ),
              ] else
                AppButton(
                  label: 'Continue to payment',
                  icon: Icons.payment_outlined,
                  loading: _busy,
                  onPressed: _busy ? null : _start,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
