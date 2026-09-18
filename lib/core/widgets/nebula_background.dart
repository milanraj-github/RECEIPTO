import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';

class AnimatedNebulaBackground extends StatelessWidget {
  final double opacity;

  const AnimatedNebulaBackground({
    super.key,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base dark background
          const ColoredBox(color: AppColors.background),

          // 2. Ambient top-left cyan/blue glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // 3. Ambient center-right AI purple glow
          Positioned(
            top: 250,
            right: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withValues(alpha: 0.09),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
