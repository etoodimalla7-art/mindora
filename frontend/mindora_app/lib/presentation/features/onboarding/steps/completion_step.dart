import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../providers/onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Final onboarding screen: submits the collected profile to the
/// backend (PUT /users/me/education-profile) and marks onboarding
/// complete locally before handing off to /home.
class CompletionStep extends ConsumerStatefulWidget {
  const CompletionStep({super.key});

  @override
  ConsumerState<CompletionStep> createState() => _CompletionStepState();
}

class _CompletionStepState extends ConsumerState<CompletionStep> {
  bool _isSubmitting = false;
  String? _error;

  Future<void> _finish() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final success = await ref.read(onboardingControllerProvider.notifier).submit();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      OnboardingStepContext.of(context).onNext();
    } else {
      setState(() => _error = "We couldn't save your profile. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.celebration_outlined, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text("You're all set!", style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your dashboard, study plan and AI tutor are ready.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _finish,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Go to my dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
