import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/ai_assistant/domain/models/ai_structured_response.dart';

class AIProductCard extends StatefulWidget {
  final AIProductItem product;

  const AIProductCard({super.key, required this.product});

  @override
  State<AIProductCard> createState() => _AIProductCardState();
}

class _AIProductCardState extends State<AIProductCard> {
  bool _expanded = false;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')} ${_monthNames[d.month - 1]} ${d.year}';
  }

  void _openReceipt(BuildContext context) {
    final receiptId = widget.product.receiptId.trim();
    if (receiptId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Original receipt record is no longer available.')),
      );
      return;
    }
    context.push('/receipts/details/$receiptId');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final dateStr = p.purchaseDate != null
        ? _formatDate(p.purchaseDate!)
        : (p.purchaseDateStr ?? 'Date unavailable');

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
            // Top Row: Category chip & Warranty Badge
            Row(
              children: [
                _buildCategoryPill(p.category),
                const Spacer(),
                if (p.warrantyStatus != null) _buildWarrantyBadge(p.warrantyStatus!, p.daysRemaining),
              ],
            ),
            const SizedBox(height: 10),

            // Product Name
            Text(
              p.name,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Price & Quantity
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  p.price != null
                      ? CurrencyFormatter.format(p.price!, currency: p.currency)
                      : 'Price not recorded',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.price != null ? const Color(0xFF66F2C1) : AppColors.onSurfaceVariant,
                  ),
                ),
                if (p.quantity > 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Qty: ${p.quantity}${p.unitPrice != null ? ' @ ${CurrencyFormatter.formatCompact(p.unitPrice!, currency: p.currency)}' : ''}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Merchant and Date info
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    p.merchantName,
                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const Divider(height: 18, color: AppColors.outlineVariant),

            // Action row: View Receipt + optional Expand other items
            Row(
              children: [
                InkWell(
                  onTap: () => _openReceipt(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'View Receipt #${p.receiptId}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (p.otherItemsInReceipt.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          Text(
                            '+${p.otherItemsInReceipt.length} other items',
                            style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                          ),
                          Icon(
                            _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Expanded other items
            if (_expanded && p.otherItemsInReceipt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Other items purchased on this receipt:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    ...p.otherItemsInReceipt.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.label_outline, size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            cat,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyBadge(String status, int? daysRemaining) {
    Color color;
    String label;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        color = const Color(0xFF4EDEA3);
        label = daysRemaining != null ? 'Warranty Active ($daysRemaining d left)' : 'Active Warranty';
        icon = Icons.verified_outlined;
        break;
      case 'EXPIRING SOON':
        color = const Color(0xFFFFB300);
        label = daysRemaining != null ? 'Expiring in $daysRemaining d' : 'Expiring Soon';
        icon = Icons.alarm;
        break;
      case 'EXPIRED':
        color = const Color(0xFFFF6B6B);
        label = 'Warranty Expired';
        icon = Icons.history_toggle_off;
        break;
      case 'LIFETIME':
        color = const Color(0xFFB388FF);
        label = 'Lifetime Warranty';
        icon = Icons.all_inclusive;
        break;
      default:
        color = AppColors.onSurfaceVariant;
        label = 'No Warranty';
        icon = Icons.shield_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
