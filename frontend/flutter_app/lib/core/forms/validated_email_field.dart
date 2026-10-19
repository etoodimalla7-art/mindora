import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

/// Email field with real-time inline validation.
///
/// Usage:
///   ValidatedEmailField(
///     controller: _emailCtrl,
///     label: 'Email',
///     onValidChanged: (isValid) => setState(() => _emailValid = isValid),
///   )
class ValidatedEmailField extends StatefulWidget {
  const ValidatedEmailField({
    super.key,
    required this.controller,
    this.label = 'Email',
    this.hint = 'you@example.com',
    this.onValidChanged,
    this.required = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<bool>? onValidChanged;
  final bool required;

  @override
  State<ValidatedEmailField> createState() => _ValidatedEmailFieldState();
}

class _ValidatedEmailFieldState extends State<ValidatedEmailField> {
  String? _error;
  bool _touched = false;

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

  void _validate() {
    if (!_touched) return;
    final value = widget.controller.text.trim();
    String? error;

    if (value.isEmpty) {
      error = widget.required ? 'Email is required' : null;
    } else if (!EmailValidator.validate(value)) {
      error = 'Please enter a valid email address';
    }

    setState(() => _error = error);
    widget.onValidChanged?.call(error == null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            if (!_touched) _touched = true;
            _validate();
          },
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.mail_outline),
            errorText: _error,
            suffixIcon: _touched && _error == null
                ? Icon(Icons.check_circle, color: Colors.green.shade600)
                : null,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
