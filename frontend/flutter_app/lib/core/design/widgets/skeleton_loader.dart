import 'package:flutter/material.dart';

/// Shimmer-effect skeleton loaders for premium loading states.
///
/// Usage:
///   const SkeletonLoader.box(width: 120, height: 16)
///   const SkeletonLoader.circle(size: 40)
///   const SkeletonLoader.card(height: 100)
///   SkeletonLoader.list(count: 3)
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader._({
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = SkeletonShape.rect,
  });

  factory SkeletonLoader.box({
    double? width,
    double? height = 16,
    double borderRadius = 8,
  }) =>
      SkeletonLoader._(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );

  factory SkeletonLoader.circle({required double size}) => SkeletonLoader._(
        width: size,
        height: size,
        borderRadius: size / 2,
        shape: SkeletonShape.circle,
      );

  factory SkeletonLoader.card({double height = 100}) => SkeletonLoader._(
        width: double.infinity,
        height: height,
        borderRadius: 16,
      );

  static Widget list({int count = 3, double cardHeight = 80}) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonLoader.card(height: cardHeight),
        ),
      ),
    );
  }

  final double? width;
  final double? height;
  final double borderRadius;
  final SkeletonShape shape;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

enum SkeletonShape { rect, circle }

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final highlightColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + 2 * _ctrl.value, 0),
              end: Alignment(1.0 + 2 * _ctrl.value, 0),
            ),
          ),
        );
      },
    );
  }
}
