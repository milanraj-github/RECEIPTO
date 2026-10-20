import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double blur;
  final Border? border;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.backgroundColor,
    this.blur = 0.0,
    this.border,
    this.padding = const EdgeInsets.all(16.0),
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.lg;
    // Translucent dark glass surface (78–85% opacity as specified)
    final fallbackColor = AppColors.glassSurface.withValues(alpha: 0.82);

    // Subtle luminous glass border (soft light on top/edge)
    final effectiveBorder = border ??
        Border.all(
          color: const Color(0xFF3867FF).withValues(alpha: 0.18),
          width: 1.0,
        );

    // Soft dark shadow plus restrained colored ambient glow
    final effectiveShadow = boxShadow ?? [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: const Color(0xFF3867FF).withValues(alpha: 0.04),
        blurRadius: 28,
        spreadRadius: 1,
      ),
    ];

    // Apply BackdropFilter only if blur is explicitly requested > 0.1
    if (blur > 0.1) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          boxShadow: effectiveShadow,
        ),
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor ?? fallbackColor,
                borderRadius: effectiveRadius,
                border: effectiveBorder,
              ),
              child: child,
            ),
          ),
        ),
      );
    } else {
      // High-performance direct rendering: 100% artifact-free & 120fps smooth
      return Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? fallbackColor,
          borderRadius: effectiveRadius,
          boxShadow: effectiveShadow,
          border: effectiveBorder,
        ),
        child: child,
      );
    }
  }
}
