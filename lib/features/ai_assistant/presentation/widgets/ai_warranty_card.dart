import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/ai_assistant/domain/models/ai_structured_response.dart';

class AIWarrantyCard extends StatelessWidget {
  final AIWarrantyItem warranty;

  const AIWarrantyCard({super.key, required this.warranty});

  void _openReceipt(BuildContext context) {
    final rId = warranty.receiptId?.trim();
    if (rId != null && rId.isNotEmpty) {
      context.push('/receipts/details/$rId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No original receipt linked to this manual warranty.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String badgeLabel;
    IconData badgeIcon;

    switch (warranty.status.toUpperCase()) {
      case 'ACTIVE':
        badgeColor = const Color(0xFF4EDEA3);
        badgeLabel = 'Active (${warranty.daysRemaining}d left)';
        badgeIcon = Icons.verified_outlined;
        break;
      case 'EXPIRING SOON':
        badgeColor = const Color(0xFFFFB300);
        badgeLabel = 'Expiring in ${warranty.daysRemaining}d';
        badgeIcon = Icons.alarm;
        break;
      case 'EXPIRED':
        badgeColor = const Color(0xFFFF6B6B);
        badgeLabel = 'Expired';
        badgeIcon = Icons.history_toggle_off;
        break;
      case 'LIFETIME':
        badgeColor = const Color(0xFFB388FF);
        badgeLabel = 'Lifetime Warranty';
        badgeIcon = Icons.all_inclusive;
        break;
      default:
        badgeColor = AppColors.onSurfaceVariant;
        badgeLabel = warranty.status;
        badgeIcon = Icons.shield_outlined;
    }

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
                Expanded(
                  child: Text(
                    warranty.productName,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 11, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.storefront_outlined, size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  warranty.merchantName,
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const Spacer(),
                Icon(Icons.event_available_outlined, size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${warranty.expiryDate}',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),

            if (warranty.receiptId != null && warranty.receiptId!.isNotEmpty) ...[
              const Divider(height: 18, color: AppColors.outlineVariant),
              InkWell(
                onTap: () => _openReceipt(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'View Associated Receipt #${warranty.receiptId}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
