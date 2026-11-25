import 'package:flutter/material.dart';

/// Premium avatar with initial(s) + auto-generated color.
///
/// Usage:
///   MindoraAvatar(name: 'John Doe', size: 40)  // → 'JD' on blue circle
///   MindoraAvatar(name: 'Alice', size: 56)     // → 'A' on purple circle
class MindoraAvatar extends StatelessWidget {
  const MindoraAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.showBorder = false,
  });

  final String name;
  final double size;
  final bool showBorder;

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color get _backgroundColor {
    // Hash name → one of 8 brand-friendly colors
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    const colors = [
      Color(0xFF6366F1), // indigo
      Color(0xFF8B5CF6), // violet
      Color(0xFFEC4899), // pink
      Color(0xFFF59E0B), // amber
      Color(0xFF10B981), // emerald
      Color(0xFF3B82F6), // blue
      Color(0xFF06B6D4), // cyan
      Color(0xFFEF4444), // red
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _backgroundColor,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
