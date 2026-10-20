import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/brand_logo.dart';
import '../../../core/forms/validated_email_field.dart';
import '../../../core/forms/validated_password_field.dart';
import '../../../core/router/routes.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmValid = false;
  bool _termsAccepted = false;
  bool _submitting = false;
  String? _confirmError;

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      _emailValid &&
      _passwordValid &&
      _confirmValid &&
      _termsAccepted &&
      !_submitting;

  @override
  void initState() {
    super.initState();
    _confirm.addListener(_validateConfirm);
    _name.addListener(_refresh);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _validateConfirm() {
    final match = _password.text == _confirm.text;
    setState(() {
      _confirmValid = match && _confirm.text.isNotEmpty;
      _confirmError = _confirm.text.isEmpty
          ? null
          : (match ? null : 'Passwords do not match');
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _submitting = true);

    final ok = await ref.read(authControllerProvider.notifier).register(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      context.push('${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(_email.text.trim())}&purpose=verify_email');
    } else {
      final err = ref.read(authControllerProvider).error ?? 'Registration failed.';
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ListView(
            children: [
              const Center(child: BrandLogo(size: 64)),
              const SizedBox(height: AppSpacing.lg),

              Text('Create your account',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Join thousands of students preparing smarter.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Name
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Email
              ValidatedEmailField(
                controller: _email,
                onValidChanged: (valid) {
                  if (valid != _emailValid) {
                    setState(() => _emailValid = valid);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Password with strength
              ValidatedPasswordField(
                controller: _password,
                showStrength: true,
                onValidChanged: (valid) {
                  if (valid != _passwordValid) {
                    setState(() => _passwordValid = valid);
                  }
                  _validateConfirm();
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Confirm password
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _confirmError,
                  suffixIcon: _confirmValid
                      ? Icon(Icons.check_circle, color: Colors.green.shade600)
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Terms checkbox
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                title: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall,
                    children: const [
                      TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Submit
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
                      : const Text('Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
