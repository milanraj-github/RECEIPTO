import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';

class AIFollowUpChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  const AIFollowUpChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final text = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: const Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: AppColors.primary),
              label: Text(text),
              labelStyle: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.cardSurface.withValues(alpha: 0.7),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => onSelected(text),
            ),
          );
        },
      ),
    );
  }
}
