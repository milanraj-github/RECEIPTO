import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/ai_assistant/domain/models/ai_structured_response.dart';

class AICategoryBreakdownCard extends StatelessWidget {
  final List<AICategoryItem> categories;

  const AICategoryBreakdownCard({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: GlassCard(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(14),
        backgroundColor: AppColors.cardSurface.withValues(alpha: 0.6),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_outline_rounded, size: 16, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(
                  'CATEGORY SPENDING BREAKDOWN',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...categories.take(5).map((cat) {
              final pct = cat.percentage / 100.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cat.category,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${cat.count} receipt${cat.count > 1 ? 's' : ''})',
                          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                        const Spacer(),
                        Text(
                          CurrencyFormatter.format(cat.amount),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${cat.percentage.toStringAsFixed(1)}%',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66F2C1)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
