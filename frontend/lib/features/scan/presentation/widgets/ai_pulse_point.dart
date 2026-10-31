import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';

class AIPulsePoint extends StatefulWidget {
  final int delay;

  const AIPulsePoint({
    super.key,
    this.delay = 0,
  });

  @override
  State<AIPulsePoint> createState() => _AIPulsePointState();
}

class _AIPulsePointState extends State<AIPulsePoint> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseScale = Tween<double>(begin: 0.5, end: 2.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Initial delayed start
    if (widget.delay > 0) {
      _delayTimer = Timer(Duration(milliseconds: widget.delay), () {
        if (mounted) {
          _pulseController.repeat();
        }
      });
    } else {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing outer ring
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseScale.value,
              child: Opacity(
                opacity: _pulseOpacity.value,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            );
          },
        ),
        
        // Steady inner center dot
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}
