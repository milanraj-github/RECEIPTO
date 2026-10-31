import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Cosmic Prism design tokens for the Subtle Living Neural Mesh
class _MeshColors {
  static const Color laserCyan = Color(0xFF00D9FF);
  static const Color neonViolet = Color(0xFF813BFF);
  static const Color electricBlue = Color(0xFF3867FF);
}

/// A node definition in the living neural mesh.
class _NeuralNode {
  final double anchorX; // Normalized 0.0 .. 1.0
  final double anchorY; // Normalized 0.0 .. 1.0
  final double freqX1;
  final double freqX2;
  final double freqY1;
  final double freqY2;
  final double phaseX;
  final double phaseY;
  final double radiusX;
  final double radiusY;
  final double baseRadius;
  final double pulseFreq;
  final double pulsePhase;
  final double baseOpacity;
  final Color color;

  const _NeuralNode({
    required this.anchorX,
    required this.anchorY,
    required this.freqX1,
    required this.freqX2,
    required this.freqY1,
    required this.freqY2,
    required this.phaseX,
    required this.phaseY,
    required this.radiusX,
    required this.radiusY,
    required this.baseRadius,
    required this.pulseFreq,
    required this.pulsePhase,
    required this.baseOpacity,
    required this.color,
  });
}

/// Subtle Living Neural Mesh
///
/// A barely visible, slowly moving neural mesh background across Receipto's
/// dark-themed screens. Features ultra-thin connections (0.5-1px) at 3-7% opacity,
/// tiny nodes at 5-12% opacity, and gentle harmonic drifting in cyan, violet, and electric blue.
class SubtleNeuralMesh extends StatefulWidget {
  const SubtleNeuralMesh({super.key});

  @override
  State<SubtleNeuralMesh> createState() => _SubtleNeuralMeshState();
}

class _SubtleNeuralMeshState extends State<SubtleNeuralMesh>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final List<_NeuralNode> _nodes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Smooth progression: 32-second cycle for active yet serene living movement
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    );

    _nodes = _generateNodes();
    _startAnimationIfAllowed();
  }

  void _startAnimationIfAllowed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bool reduceMotion = MediaQuery.of(context).disableAnimations;
      if (!reduceMotion && !_controller.isAnimating) {
        _controller.repeat();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted && !MediaQuery.of(context).disableAnimations) {
        if (!_controller.isAnimating) _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// Generates a balanced set of 28 nodes distributed across normalized screen space.
  static List<_NeuralNode> _generateNodes() {
    final colors = [
      _MeshColors.laserCyan,
      _MeshColors.neonViolet,
      _MeshColors.electricBlue,
    ];

    // 4 columns x 7 rows jittered grid for even screen coverage
    const int cols = 4;
    const int rows = 7;
    final List<_NeuralNode> nodes = [];

    final random = math.Random(42); // Deterministic seed for consistent layout

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Base anchor with gentle random jitter
        final double jitterX = (random.nextDouble() - 0.5) * 0.12;
        final double jitterY = (random.nextDouble() - 0.5) * 0.08;
        final double ax = ((c + 0.5) / cols + jitterX).clamp(0.04, 0.96);
        final double ay = ((r + 0.5) / rows + jitterY).clamp(0.03, 0.97);

        // Dynamic harmonic drift parameters (increased movement & range)
        final double fX1 = 0.20 + random.nextDouble() * 0.18;
        final double fX2 = 0.14 + random.nextDouble() * 0.14;
        final double fY1 = 0.18 + random.nextDouble() * 0.16;
        final double fY2 = 0.12 + random.nextDouble() * 0.12;

        final double pX = random.nextDouble() * 2 * math.pi;
        final double pY = random.nextDouble() * 2 * math.pi;

        final double rX = 22.0 + random.nextDouble() * 24.0; // 22-46 px drift
        final double rY = 20.0 + random.nextDouble() * 22.0; // 20-42 px drift

        final Color col = colors[(r * cols + c) % colors.length];

        nodes.add(_NeuralNode(
          anchorX: ax,
          anchorY: ay,
          freqX1: fX1,
          freqX2: fX2,
          freqY1: fY1,
          freqY2: fY2,
          phaseX: pX,
          phaseY: pY,
          radiusX: rX,
          radiusY: rY,
          baseRadius: 2.2 + random.nextDouble() * 0.7, // 2.2 - 2.9 px dot
          pulseFreq: 0.50 + random.nextDouble() * 0.45, // Gentle breathing
          pulsePhase: random.nextDouble() * 2 * math.pi,
          baseOpacity: 0.14 + random.nextDouble() * 0.06, // 14% - 20% base opacity
          color: col,
        ));
      }
    }

    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _NeuralMeshPainter(
              progress: _controller.value,
              nodes: _nodes,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _NeuralMeshPainter extends CustomPainter {
  final double progress;
  final List<_NeuralNode> nodes;

  _NeuralMeshPainter({
    required this.progress,
    required this.nodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double t = progress * 2 * math.pi * 4.0; // Scaled time for active yet smooth living motion

    // Calculate current positions and opacities for all nodes
    final int count = nodes.length;
    final List<Offset> positions = List.filled(count, Offset.zero);
    final List<double> opacities = List.filled(count, 0.0);

    for (int i = 0; i < count; i++) {
      final n = nodes[i];
      final double dx = math.sin(t * n.freqX1 + n.phaseX) * n.radiusX +
          math.cos(t * n.freqX2) * (n.radiusX * 0.4);
      final double dy = math.cos(t * n.freqY1 + n.phaseY) * n.radiusY +
          math.sin(t * n.freqY2) * (n.radiusY * 0.4);

      positions[i] = Offset(
        n.anchorX * size.width + dx,
        n.anchorY * size.height + dy,
      );

      // Pulse: gently breathes within 12% - 24% opacity
      final double pulse = math.sin(t * n.pulseFreq + n.pulsePhase);
      opacities[i] = (n.baseOpacity + pulse * 0.04).clamp(0.12, 0.24);
    }

    // 1. Draw connection lines (0.9 px, 7% - 15% opacity)
    // Distance threshold scaled smoothly to viewport width (up to 155px for active dynamic bridges)
    final double maxDist = math.min(size.width * 0.38, 155.0);
    final double maxDistSq = maxDist * maxDist;

    final linePaint = Paint()
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < count; i++) {
      final p1 = positions[i];
      final n1 = nodes[i];

      for (int j = i + 1; j < count; j++) {
        final p2 = positions[j];
        final double dx = p1.dx - p2.dx;
        final double dy = p1.dy - p2.dy;
        final double distSq = dx * dx + dy * dy;

        if (distSq < maxDistSq) {
          final double dist = math.sqrt(distSq);
          final double proximity = 1.0 - (dist / maxDist);

          // Line opacity: refined bump to 7% - 15%
          final double lineOpacity = (0.06 + proximity * 0.09).clamp(0.07, 0.15);

          // Use cyan or violet accent based on primary node
          linePaint.color = n1.color.withValues(alpha: lineOpacity);
          canvas.drawLine(p1, p2, linePaint);
        }
      }
    }

    // 2. Draw neural nodes with luminous ambient glow (12% - 24% opacity)
    final glowPaint = Paint()..style = PaintingStyle.fill;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final p = positions[i];
      final n = nodes[i];
      final double op = opacities[i];

      // Soft outer ambient halo
      glowPaint.color = n.color.withValues(alpha: op * 0.45);
      canvas.drawCircle(p, n.baseRadius * 2.8, glowPaint);

      // Core neural dot
      dotPaint.color = n.color.withValues(alpha: op);
      canvas.drawCircle(p, n.baseRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralMeshPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
