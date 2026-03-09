import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Loading durumları için shimmer placeholder
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.white.withValues(alpha: 0.15),
      highlightColor: highlightColor ?? Colors.white.withValues(alpha: 0.35),
      period: period,
      child: child,
    );
  }
}

/// Kart placeholder - shimmer için opak alan (parent ShimmerLoading ile kullanın)
class ShimmerCard extends StatelessWidget {
  final double height;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
