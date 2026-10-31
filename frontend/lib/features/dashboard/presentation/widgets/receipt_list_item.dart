import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/utils/currency_formatter.dart';

class ReceiptData {
  final String id;
  final String merchant;
  final String date;
  final double amount;
  final String category;
  final IconData icon;
  final String? currency;

  ReceiptData({
    required this.id,
    required this.merchant,
    required this.date,
    required this.amount,
    required this.category,
    required this.icon,
    this.currency,
  });
}

class ReceiptListItem extends StatelessWidget {
  final ReceiptData data;
  final VoidCallback onTap;

  const ReceiptListItem({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final double absoluteAmount = data.amount.abs();
    final String formattedText = CurrencyFormatter.format(absoluteAmount, currency: data.currency);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: GlassCard(
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Left: Icon + merchant info
              Expanded(
                child: Row(
                  children: [
                    // Merchant icon box
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Icon(
                        data.icon,
                        color: AppColors.onSurface,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Merchant & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.merchant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data.date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.codeSm.copyWith(
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Right: Amount + category chip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formattedText,
                      style: GoogleFonts.inter(
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: AppRadius.full,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text(
                      data.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
