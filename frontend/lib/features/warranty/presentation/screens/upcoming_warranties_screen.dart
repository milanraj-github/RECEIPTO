import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/widgets/nebula_background.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';

class UpcomingWarrantiesScreen extends ConsumerWidget {
  final List<String> warrantyIds;

  const UpcomingWarrantiesScreen({
    super.key,
    required this.warrantyIds,
  });

  IconData _getProductIcon(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('laptop') || lower.contains('macbook') || lower.contains('computer') || lower.contains('notebook')) {
      return Icons.laptop_chromebook;
    }
    if (lower.contains('phone') || lower.contains('mobile') || lower.contains('iphone') || lower.contains('pixel') || lower.contains('android')) {
      return Icons.phone_android;
    }
    if (lower.contains('tv') || lower.contains('television') || lower.contains('monitor') || lower.contains('screen')) {
      return Icons.tv;
    }
    if (lower.contains('fridge') || lower.contains('oven') || lower.contains('kitchen') || lower.contains('cooker')) {
      return Icons.kitchen;
    }
    if (lower.contains('watch') || lower.contains('fitbit') || lower.contains('wearable')) {
      return Icons.watch;
    }
    if (lower.contains('headphone') || lower.contains('earbud') || lower.contains('speaker') || lower.contains('audio')) {
      return Icons.headphones;
    }
    return Icons.verified_user_outlined;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.greenAccent;
      case 'EXPIRING SOON':
      case 'EXPIRING_SOON':
        return Colors.orangeAccent;
      case 'EXPIRED':
        return AppColors.error;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warrantiesAsync = ref.watch(dbWarrantiesProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedNebulaBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upcoming Reminders',
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'The following products are nearing warranty expiration. Review details or view the full receipts below.',
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // List of products
                Expanded(
                  child: warrantiesAsync.when(
                    data: (allWarranties) {
                      final targetIds = warrantyIds.toSet();
                      final filtered = allWarranties.where((w) => targetIds.contains(w.id)).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No upcoming reminders found.',
                            style: GoogleFonts.inter(color: Colors.white30),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final w = filtered[index];
                          final daysRemaining = WarrantyUtils.calculateDaysRemaining(w.expiryDate);
                          final isExpired = daysRemaining < 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              borderRadius: AppRadius.lg,
                              padding: const EdgeInsets.all(16),
                              child: InkWell(
                                borderRadius: AppRadius.lg,
                                onTap: () {
                                  if (w.receiptId != null && w.receiptId!.isNotEmpty) {
                                    context.push('/receipts/details/${w.receiptId}');
                                  }
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Icon
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: Icon(
                                        _getProductIcon(w.productName),
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Product details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            w.productName,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            w.merchantName,
                                            style: GoogleFonts.inter(
                                              color: AppColors.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Meta rows
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white30),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Expires: ${w.expiryDate}',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (w.invoiceNumber != null && w.invoiceNumber!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.receipt_rounded, size: 12, color: Colors.white30),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Invoice: ${w.invoiceNumber}',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white54,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Status & Days remaining
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(w.status).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: _getStatusColor(w.status).withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            w.status,
                                            style: GoogleFonts.inter(
                                              color: _getStatusColor(w.status),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Days text
                                        Text(
                                          isExpired
                                              ? 'Expired'
                                              : (daysRemaining == 0
                                                  ? 'Expires Today'
                                                  : (daysRemaining == 1 ? '1 day left' : '$daysRemaining days left')),
                                          style: GoogleFonts.inter(
                                            color: isExpired
                                                ? AppColors.error
                                                : (daysRemaining <= 7 ? Colors.orangeAccent : Colors.white70),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Text(
                        'Error loading warranties',
                        style: GoogleFonts.inter(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
