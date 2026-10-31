import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/ai_assistant/domain/models/ai_structured_response.dart';

class AIReceiptCard extends StatelessWidget {
  final AIReceiptItem receipt;

  const AIReceiptCard({super.key, required this.receipt});

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')} ${_monthNames[d.month - 1]} ${d.year}';
  }

  void _openReceipt(BuildContext context) {
    final id = receipt.receiptId.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt record ID unavailable.')),
      );
      return;
    }
    context.push('/receipts/details/$id');
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = receipt.purchaseDate != null
        ? _formatDate(receipt.purchaseDate!)
        : (receipt.purchaseDateStr ?? 'Date unavailable');

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
            // Top Row: Category and Items count badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined, size: 11, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        receipt.category,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (receipt.itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${receipt.itemCount} item${receipt.itemCount > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Merchant Name & Total Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.merchantName,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(receipt.total, currency: receipt.currency),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF66F2C1),
                  ),
                ),
              ],
            ),

            // Items preview
            if (receipt.itemNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        receipt.itemNames.take(3).join(', ') + (receipt.itemNames.length > 3 ? '...' : ''),
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 18, color: AppColors.outlineVariant),

            // Action: View Receipt
            InkWell(
              onTap: () => _openReceipt(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_outlined, size: 15, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Open Receipt Details',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
