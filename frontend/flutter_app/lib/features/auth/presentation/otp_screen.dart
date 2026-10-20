import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/routes.dart';
import '../data/auth_repository.dart';
import '../data/otp_api.dart';

/// Screen shown after login/register to verify the user's email with a 6-digit OTP.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.email,
    this.purpose = 'verify_email',
  });

  final String email;
  final String purpose;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _submitting = false;
  bool _resending = false;
  String? _error;
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(60);
    // Auto-focus first input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    setState(() => _countdown = seconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() => _error = null);

    // Support paste of 6 digits
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (var i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      if (digits.length >= 6) {
        _focusNodes[5].unfocus();
        _submit();
      }
      return;
    }

    // Move to next
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    // Auto-submit when all 6 filled
    if (index == 5 && value.isNotEmpty && _code.length == 6) {
      _submit();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _submit() async {
    if (_submitting || _code.length != 6) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final api = OtpApi(ref.read(dioProvider));
      final ok = await api.verifyOtp(
        email: widget.email,
        code: _code,
        purpose: widget.purpose,
      );

      if (!mounted) return;

      if (ok) {
        // Refresh user (is_verified now true)
        final user = await AuthRepository(ref.read(dioProvider)).currentUser();
        if (!mounted) return;
        if (user != null && user.isAdmin) {
          context.go(AppRoutes.adminDashboard);
        } else {
          context.go(AppRoutes.home);
        }
      } else {
        setState(() => _error = 'Invalid code. Please try again.');
      }
    } catch (e) {
      setState(() => _error = _extractError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _countdown > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      final api = OtpApi(ref.read(dioProvider));
      await api.sendOtp(email: widget.email, purpose: widget.purpose);
      if (!mounted) return;
      _startCountdown(60);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New code sent to ${widget.email}')),
      );
    } catch (e) {
      setState(() => _error = _extractError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String _extractError(Object e) {
    try {
      final msg = (e as dynamic).response?.data?['error']?['message'];
      if (msg is String) return msg;
    } catch (_) {}
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              const SizedBox(height: AppSpacing.xl),
              Text('Verify your email',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to\n'),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 6 input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (e) => _onKeyEvent(i, e),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: theme.textTheme.headlineMedium,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (v) => _onDigitChanged(i, v),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              // Submit
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_submitting || _code.length != 6) ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Resend
              Center(
                child: _countdown > 0
                    ? Text(
                        'Resend in ${_countdown}s',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      )
                    : TextButton(
                        onPressed: _resending ? null : _resend,
                        child: _resending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Resend code'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
