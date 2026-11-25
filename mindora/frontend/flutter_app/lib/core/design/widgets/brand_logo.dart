import 'package:flutter/material.dart';

/// MINDORA brand logo — loads the real PNG from assets.
///
/// Usage:
///   BrandLogo(size: 120)          // splash, login
///   BrandLogo(size: 32)           // appbar
///   BrandLogo.wordmark(size: 24)  // logo + text "MINDORA"
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
    this.wordmarkSize = 24,
    this.wordmarkColor,
  });

  final double size;
  final bool showWordmark;
  final double wordmarkSize;
  final Color? wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/logo/mindora_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );

    if (!showWordmark) return logo;

    final color = wordmarkColor ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        SizedBox(width: size * 0.25),
        Text(
          'MINDORA',
          style: TextStyle(
            fontSize: wordmarkSize,
            fontWeight: FontWeight.w800,
            letterSpacing: wordmarkSize * 0.06,
            color: color,
          ),
        ),
      ],
    );
  }
}
