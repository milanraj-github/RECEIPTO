import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/subtle_neural_mesh.dart';

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
          // 1. Base Void Black canvas
          const ColoredBox(color: AppColors.voidBlack),

          // 2. Ambient Top-Right Liquid Aurora Ribbon (Warm Glow -> Neon Pink -> Magenta)
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 440,
              height: 440,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.warmGlow.withValues(alpha: 0.16),
                    AppColors.neonPink.withValues(alpha: 0.14),
                    AppColors.prismMagenta.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 3. Ambient Upper-Left Electric Blue & Neon Violet glow
          Positioned(
            top: -80,
            left: -100,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.electricBlue.withValues(alpha: 0.18),
                    AppColors.neonViolet.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.85],
                ),
              ),
            ),
          ),

          // 4. Center-Right Cosmic Prism Glow Ribbon
          Positioned(
            top: 280,
            right: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.neonViolet.withValues(alpha: 0.14),
                    AppColors.prismMagenta.withValues(alpha: 0.09),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 0.9],
                ),
              ),
            ),
          ),

          // 5. Lower-Left Laser Cyan Liquid Aura
          Positioned(
            bottom: -60,
            left: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.laserCyan.withValues(alpha: 0.12),
                    AppColors.electricBlue.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.85],
                ),
              ),
            ),
          ),

          // 6. Subtle Living Neural Mesh layer
          const Positioned.fill(
            child: IgnorePointer(
              child: SubtleNeuralMesh(),
            ),
          ),
        ],
      ),
    );
  }
}
