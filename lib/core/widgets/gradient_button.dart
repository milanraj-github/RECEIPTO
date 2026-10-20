import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final bool isLoading;
  final double height;
  final double? width;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient = AppGradients.primaryBlueViolet,
    this.isLoading = false,
    this.height = 54.0,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: disabled ? null : gradient,
        color: disabled ? AppColors.surfaceVariant.withValues(alpha: 0.5) : null,
        borderRadius: AppRadius.md,
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.electricBlue.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.neonViolet.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: AppRadius.md,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: disabled
                              ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
                              : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: GoogleFonts.inter(
                          color: disabled
                              ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
