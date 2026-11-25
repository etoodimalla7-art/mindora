import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/brand_logo.dart';
import '../../../core/forms/validated_email_field.dart';
import '../../../core/forms/validated_password_field.dart';
import '../../../core/router/routes.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _submitting = false;

  bool get _canSubmit =>
      _emailValid && _passwordValid && !_submitting;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _submitting = true);

    final ok = await ref.read(authControllerProvider.notifier).login(
          email: _email.text.trim(),
          password: _password.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      final authState = ref.read(authControllerProvider);
      final user = authState.session?.user;
      if (user == null) return;
      if (user.isAdmin) {
        context.go(AppRoutes.adminDashboard);
      } else if (!user.hasCompletedOnboarding) {
        context.go(AppRoutes.onboarding);
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      final err = ref.read(authControllerProvider).error ?? 'Login failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);
    final isLoading = state.loading || _submitting;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ListView(
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              const Center(child: BrandLogo(size: 80)),
              const SizedBox(height: AppSpacing.xl),

              Text('Welcome back', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in to continue.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Email with real-time validation
              ValidatedEmailField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                onValidChanged: (valid) {
                  if (valid != _emailValid) {
                    setState(() => _emailValid = valid);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Password with real-time validation
              ValidatedPasswordField(
                controller: _password,
                label: 'Password',
                hint: 'Your password',
                showStrength: false,
                onValidChanged: (valid) {
                  if (valid != _passwordValid) {
                    setState(() => _passwordValid = valid);
                  }
                },
              ),

              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Submit button (disabled if form invalid)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign in'),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Register link
              Center(
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.register),
                  child: const Text('Create a new account'),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Skip for testing
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.onboarding),
                  child: Text(
                    'Continue without account',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
