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
    final fallbackColor = AppColors.cardSurface.withValues(alpha: 0.85);

    // Apply BackdropFilter only if blur is explicitly requested > 0.1
    if (blur > 0.1) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          boxShadow: boxShadow,
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
                border: border ??
                    Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.0,
                    ),
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
          boxShadow: boxShadow ?? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: border ??
              Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
        ),
        child: child,
      );
    }
  }
}
