import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/ai_assistant/domain/models/ai_structured_response.dart';

class AISummaryCard extends StatelessWidget {
  final AISummaryItem summary;

  const AISummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: GlassCard(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(16),
        backgroundColor: AppColors.cardSurface.withValues(alpha: 0.6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'FINANCIAL SUMMARY • ${summary.periodLabel.toUpperCase()}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Expenditure', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(summary.totalSpending, currency: summary.currency),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF66F2C1),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transactions', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.transactionCount} receipts',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.outlineVariant),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 13, color: AppColors.secondary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Top Cat: ${summary.topCategory}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 13, color: AppColors.tertiary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Top Merchant: ${summary.topMerchant}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
