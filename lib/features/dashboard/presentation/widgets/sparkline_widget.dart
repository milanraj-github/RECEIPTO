import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';

class SparklineWidget extends StatelessWidget {
  final List<double> heights;
  final double maxHeight;

  const SparklineWidget({
    super.key,
    required this.heights,
    this.maxHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (heights.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights.asMap().entries.map((entry) {
        final index = entry.key;
        final heightPercentage = entry.value.clamp(0.08, 1.0);
        final isLast = index == heights.length - 1;
        final bool isResting = heightPercentage <= 0.08;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              height: heightPercentage * maxHeight,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
                color: isLast
                    ? AppColors.primary
                    : (isResting
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.primary.withValues(alpha: 0.2 + (index * 0.08))),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
