import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.imageUrl, this.initials, this.size = 40});

  final String? imageUrl;
  final String? initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary.withValues(alpha: 0.12);
    final fg = theme.colorScheme.primary;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(bg, fg, theme),
          errorWidget: (_, __, ___) => _placeholder(bg, fg, theme),
        ),
      );
    }
    return _placeholder(bg, fg, theme);
  }

  Widget _placeholder(Color bg, Color fg, ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        (initials ?? '?').toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(color: fg),
      ),
    );
  }
}
