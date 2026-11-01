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
    this.maxHeight = 42,
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
          if (widget.amounts != null && _selectedIndex! < widget.amounts!.length) {
            final amt = widget.amounts![_selectedIndex!];
            tooltipText = CurrencyFormatter.format(amt);
          } else {
            tooltipText = '₹0.00';
          }
        }

        const double tooltipWidth = 58;
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
              // Amount Tooltip directly above the pressed bar
              if (_selectedIndex != null && tooltipText != null)
                Positioned(
                  top: 0,
                  left: tooltipLeft,
                  child: Container(
                    width: tooltipWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
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
                        padding: const EdgeInsets.only(left: 3, right: 1),
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
                                      color: AppColors.primary.withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
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
