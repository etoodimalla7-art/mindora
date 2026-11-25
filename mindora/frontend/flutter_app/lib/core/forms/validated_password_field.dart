import 'package:flutter/material.dart';

/// Password field with strength meter + real-time validation.
///
/// Strength is computed in pure Dart (no external package).
class ValidatedPasswordField extends StatefulWidget {
  const ValidatedPasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint = 'Minimum 8 characters',
    this.onValidChanged,
    this.showStrength = false,
    this.minLength = 8,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<bool>? onValidChanged;
  final bool showStrength;
  final int minLength;

  @override
  State<ValidatedPasswordField> createState() => _ValidatedPasswordFieldState();
}

class _ValidatedPasswordFieldState extends State<ValidatedPasswordField> {
  String? _error;
  bool _obscure = true;
  bool _touched = false;
  double _strength = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validate);
    super.dispose();
  }

  /// Compute password strength (0..1) in pure Dart.
  double _estimateStrength(String password) {
    if (password.isEmpty) return 0;
    double score = 0;

    // Length contributions
    if (password.length >= 8) score += 0.25;
    if (password.length >= 12) score += 0.15;
    if (password.length >= 16) score += 0.10;

    // Character variety
    if (password.contains(RegExp(r'[a-z]'))) score += 0.10;
    if (password.contains(RegExp(r'[A-Z]'))) score += 0.10;
    if (password.contains(RegExp(r'[0-9]'))) score += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 0.15;

    return score.clamp(0.0, 1.0);
  }

  void _validate() {
    final value = widget.controller.text;
    if (value.isEmpty) {
      if (_touched) setState(() => _error = 'Password is required');
      widget.onValidChanged?.call(false);
      return;
    }

    // Update strength
    if (widget.showStrength) {
      _strength = _estimateStrength(value);
    }

    String? error;
    if (value.length < widget.minLength) {
      error = 'At least ${widget.minLength} characters';
    } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
      error = 'Add at least one uppercase letter';
    } else if (!RegExp(r'[0-9]').hasMatch(value)) {
      error = 'Add at least one number';
    }

    setState(() => _error = _touched ? error : null);
    widget.onValidChanged?.call(error == null);
  }

  String get _strengthLabel {
    if (_strength < 0.3) return 'Weak';
    if (_strength < 0.6) return 'Medium';
    return 'Strong';
  }

  Color get _strengthColor {
    if (_strength < 0.3) return Colors.red;
    if (_strength < 0.6) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          onChanged: (_) {
            if (!_touched) _touched = true;
            _validate();
          },
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.lock_outline),
            errorText: _error,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showStrength && widget.controller.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _strengthLabel,
                      style: TextStyle(
                        color: _strengthColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ],
            ),
          ),
        ),
        // Strength meter bar
        if (widget.showStrength && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _strength,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(_strengthColor),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
