import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';

/// A custom cybernetic cat robot head avatar for Receipto AI Agent.
class CatRobotAvatar extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const CatRobotAvatar({
    super.key,
    this.size = 32.0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppColors.primary;
    final bg = backgroundColor ?? primaryColor.withValues(alpha: 0.15);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.12),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.72,
          height: size * 0.72,
          child: CustomPaint(
            painter: CatRobotHeadPainter(color: primaryColor),
          ),
        ),
      ),
    );
  }
}

/// Standalone vector icon of the cat robot head without circular badge enclosure.
class CatRobotHeadIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const CatRobotHeadIcon({
    super.key,
    this.size = 20.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppColors.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CatRobotHeadPainter(color: primaryColor),
      ),
    );
  }
}

/// Custom vector painter that renders an adorable, futuristic cat robot head.
class CatRobotHeadPainter extends CustomPainter {
  final Color color;

  CatRobotHeadPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final solidPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Triangular Cat Robot Ears
    // Left ear
    final leftEarPath = Path()
      ..moveTo(0.18 * w, 0.42 * h)
      ..lineTo(0.14 * w, 0.10 * h) // outer tip
      ..lineTo(0.38 * w, 0.26 * h) // inner base
      ..close();
    canvas.drawPath(leftEarPath, fillPaint);
    canvas.drawPath(leftEarPath, strokePaint);

    // Left inner ear cyber glow
    final leftInnerEar = Path()
      ..moveTo(0.22 * w, 0.36 * h)
      ..lineTo(0.19 * w, 0.18 * h)
      ..lineTo(0.34 * w, 0.27 * h)
      ..close();
    canvas.drawPath(
      leftInnerEar,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );

    // Right ear
    final rightEarPath = Path()
      ..moveTo(0.82 * w, 0.42 * h)
      ..lineTo(0.86 * w, 0.10 * h) // outer tip
      ..lineTo(0.62 * w, 0.26 * h) // inner base
      ..close();
    canvas.drawPath(rightEarPath, fillPaint);
    canvas.drawPath(rightEarPath, strokePaint);

    // Right inner ear cyber glow
    final rightInnerEar = Path()
      ..moveTo(0.78 * w, 0.36 * h)
      ..lineTo(0.81 * w, 0.18 * h)
      ..lineTo(0.66 * w, 0.27 * h)
      ..close();
    canvas.drawPath(
      rightInnerEar,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );

    // 2. Center Robot Antenna / Head Sensor
    canvas.drawLine(
      Offset(0.50 * w, 0.28 * h),
      Offset(0.50 * w, 0.14 * h),
      strokePaint..strokeWidth = 1.2,
    );
    canvas.drawCircle(Offset(0.50 * w, 0.12 * h), 0.04 * w, solidPaint);

    // 3. Rounded Robot Chassis (Head)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.12 * w, 0.28 * h, 0.76 * w, 0.60 * h),
      Radius.circular(0.22 * w),
    );
    canvas.drawRRect(
      headRect,
      Paint()
        ..color = const Color(0xFF0C1A1E)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(headRect, strokePaint..strokeWidth = 1.5);

    // 4. Dark Visor / Face Screen
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.20 * w, 0.37 * h, 0.60 * w, 0.43 * h),
      Radius.circular(0.14 * w),
    );
    canvas.drawRRect(
      visorRect,
      Paint()
        ..color = const Color(0xFF040A0C)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      visorRect,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // 5. Glowing LED Cat Robot Eyes (pill shaped)
    final leftEye = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0.36 * w, 0.54 * h), width: 0.13 * w, height: 0.15 * h),
      Radius.circular(0.065 * w),
    );
    canvas.drawRRect(leftEye, solidPaint);

    final rightEye = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0.64 * w, 0.54 * h), width: 0.13 * w, height: 0.15 * h),
      Radius.circular(0.065 * w),
    );
    canvas.drawRRect(rightEye, solidPaint);

    // Tiny cute eye reflection specks
    final reflectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0.38 * w, 0.51 * h), 0.025 * w, reflectionPaint);
    canvas.drawCircle(Offset(0.66 * w, 0.51 * h), 0.025 * w, reflectionPaint);

    // 6. Cute Robot Cat Mouth (subtle 'ω' smile)
    final mouthPath = Path()
      ..moveTo(0.44 * w, 0.68 * h)
      ..quadraticBezierTo(0.47 * w, 0.72 * h, 0.50 * w, 0.68 * h)
      ..quadraticBezierTo(0.53 * w, 0.72 * h, 0.56 * w, 0.68 * h);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );

    // 7. Tech Whiskers (Dual horizontal cyber bars on sides)
    final whiskerPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Left whiskers
    canvas.drawLine(Offset(0.04 * w, 0.53 * h), Offset(0.12 * w, 0.53 * h), whiskerPaint);
    canvas.drawLine(Offset(0.06 * w, 0.63 * h), Offset(0.13 * w, 0.63 * h), whiskerPaint);

    // Right whiskers
    canvas.drawLine(Offset(0.88 * w, 0.53 * h), Offset(0.96 * w, 0.53 * h), whiskerPaint);
    canvas.drawLine(Offset(0.87 * w, 0.63 * h), Offset(0.94 * w, 0.63 * h), whiskerPaint);
  }

  @override
  bool shouldRepaint(covariant CatRobotHeadPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
