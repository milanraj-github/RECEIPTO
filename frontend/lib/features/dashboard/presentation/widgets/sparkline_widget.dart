import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';

class SparklineWidget extends StatefulWidget {
  final List<double> heights;
  final List<double>? amounts;
  final List<String>? labels;
  final double maxHeight;

  const SparklineWidget({
    super.key,
    required this.heights,
    this.amounts,
    this.labels,
    this.maxHeight = 36,
  });

  @override
  State<SparklineWidget> createState() => _SparklineWidgetState();
}

class _SparklineWidgetState extends State<SparklineWidget> {
  int? _selectedIndex;

  void _handleTouch(Offset localPosition, double totalWidth) {
    if (widget.heights.isEmpty || totalWidth <= 0) return;
    final barWidth = totalWidth / widget.heights.length;
    final index = (localPosition.dx / barWidth).floor().clamp(0, widget.heights.length - 1);
    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _clearTouch() {
    if (_selectedIndex != null) {
      setState(() {
        _selectedIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.heights.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final barWidth = totalWidth / widget.heights.length;

        // Tooltip text calculation
        String? tooltipText;
        if (_selectedIndex != null) {
          final amt = (widget.amounts != null && _selectedIndex! < widget.amounts!.length)
              ? widget.amounts![_selectedIndex!]
              : 0.0;
          final label = (widget.labels != null && _selectedIndex! < widget.labels!.length)
              ? widget.labels![_selectedIndex!]
              : '';
          final formattedAmt = CurrencyFormatter.format(amt);
          tooltipText = label.isNotEmpty ? '$label • $formattedAmt' : formattedAmt;
        }

        const double tooltipWidth = 78;
        final double barCenterX = _selectedIndex != null ? (_selectedIndex! + 0.5) * barWidth : 0.0;
        final double tooltipLeft = (barCenterX - tooltipWidth / 2)
            .clamp(0.0, (totalWidth - tooltipWidth).clamp(0.0, double.infinity));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handleTouch(d.localPosition, totalWidth),
          onTapUp: (_) => _clearTouch(),
          onTapCancel: () => _clearTouch(),
          onLongPressStart: (d) => _handleTouch(d.localPosition, totalWidth),
          onLongPressMoveUpdate: (d) => _handleTouch(d.localPosition, totalWidth),
          onLongPressEnd: (_) => _clearTouch(),
          onPanDown: (d) => _handleTouch(d.localPosition, totalWidth),
          onPanUpdate: (d) => _handleTouch(d.localPosition, totalWidth),
          onPanEnd: (_) => _clearTouch(),
          onPanCancel: () => _clearTouch(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Floating Amount Tooltip positioned HIGH ABOVE the bars (clear of the user's thumb)
              if (_selectedIndex != null && tooltipText != null)
                Positioned(
                  top: 0,
                  left: tooltipLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: tooltipWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              tooltipText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Downward pointer arrow pointing down towards the touched bar
                      CustomPaint(
                        size: const Size(8, 4),
                        painter: _TooltipArrowPainter(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),

              // Bars at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: widget.maxHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: widget.heights.asMap().entries.map((entry) {
                    final index = entry.key;
                    final heightPercentage = entry.value.clamp(0.08, 1.0);
                    final isLast = index == widget.heights.length - 1;
                    final bool isResting = heightPercentage <= 0.08;
                    final bool isSelected = _selectedIndex == index;

                    Color barColor;
                    if (_selectedIndex != null) {
                      if (isSelected) {
                        barColor = AppColors.primary;
                      } else {
                        barColor = isResting
                            ? Colors.white.withValues(alpha: 0.04)
                            : AppColors.primary.withValues(alpha: 0.15);
                      }
                    } else {
                      barColor = isLast
                          ? AppColors.primary
                          : (isResting
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.primary.withValues(alpha: 0.2 + (index * 0.08)));
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          height: heightPercentage * widget.maxHeight,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3),
                            ),
                            color: barColor,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.7),
                                      blurRadius: 8,
                                      spreadRadius: 1.5,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final Color color;
  _TooltipArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
