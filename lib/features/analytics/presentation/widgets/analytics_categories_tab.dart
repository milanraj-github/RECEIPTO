import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/analytics/domain/models/financial_overview_data.dart';
import 'package:receipto/features/receipts/presentation/widgets/receipt_card_item.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';

class AnalyticsCategoriesTab extends StatefulWidget {
  final FinancialOverviewData data;
  final Function(Map<String, dynamic> receipt) onReceiptTap;

  const AnalyticsCategoriesTab({
    super.key,
    required this.data,
    required this.onReceiptTap,
  });

  @override
  State<AnalyticsCategoriesTab> createState() => _AnalyticsCategoriesTabState();
}

class _AnalyticsCategoriesTabState extends State<AnalyticsCategoriesTab> {
  String? _selectedCategory; // null = all

  final List<Color> _categoryColors = const [
    Color(0xFF66F2C1), // Aurora Mint / Primary
    Color(0xFF38BDF8), // Cyan / Secondary
    Color(0xFFA78BFA), // Purple
    Color(0xFFF472B6), // Pink
    Color(0xFFFBBF24), // Amber
    Color(0xFF34D399), // Emerald
    Color(0xFFFB923C), // Orange
    Color(0xFF818CF8), // Indigo
    Color(0xFF94A3B8), // Slate
  ];

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final totalSpend = data.netSpending > 0 ? data.netSpending : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Donut Chart & Category Breakdown Card
          _buildDonutChartCard(data, totalSpend),
          const SizedBox(height: 16),

          // Essential vs Discretionary Split Card
          _buildEssentialVsDiscretionaryCard(data, totalSpend),
          const SizedBox(height: 16),

          // Category Selector Filter & Associated Receipts
          _buildCategoryInspectionSection(data),
          const SizedBox(height: 16),

          // Product Intelligence Card
          _buildProductIntelligenceCard(data),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildDonutChartCard(FinancialOverviewData data, double totalSpend) {
    if (data.categoryTotals.isEmpty) {
      return GlassCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No category data available for this period.',
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    final sortedEntries = data.categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final shares = sortedEntries.map((e) => e.value / totalSpend).toList();

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Category Distribution',
            style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Donut visualization
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _CategoryDonutPainter(
                      shares: shares,
                      colors: _categoryColors.take(shares.length).toList(),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Spent',
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatCompact(data.netSpending),
                      style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Legend
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedEntries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, idx) {
              final entry = sortedEntries[idx];
              final color = _categoryColors[idx % _categoryColors.length];
              final pct = ((entry.value / totalSpend) * 100).toStringAsFixed(0);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = _selectedCategory == entry.key ? null : entry.key;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedCategory == entry.key
                        ? color.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedCategory == entry.key ? color : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              entry.key,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$pct% (${CurrencyFormatter.formatCompact(entry.value)})',
                              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEssentialVsDiscretionaryCard(FinancialOverviewData data, double totalSpend) {
    final essPct = ((data.essentialSpending / totalSpend) * 100).clamp(0.0, 100.0);
    final discPct = ((data.discretionarySpending / totalSpend) * 100).clamp(0.0, 100.0);

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Needs vs Wants',
                style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'Essential vs Discretionary',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Double colored segmented progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: essPct.toInt(),
                    child: Container(color: AppColors.tertiary),
                  ),
                  Expanded(
                    flex: discPct.toInt() > 0 ? discPct.toInt() : (100 - essPct.toInt()),
                    child: Container(color: AppColors.secondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    'Essential: ${essPct.toStringAsFixed(0)}% (${CurrencyFormatter.formatCompact(data.essentialSpending)})',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    'Discretionary: ${discPct.toStringAsFixed(0)}% (${CurrencyFormatter.formatCompact(data.discretionarySpending)})',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInspectionSection(FinancialOverviewData data) {
    // Receipts associated with selected category (or all if none selected)
    final filtered = data.filteredReceipts.where((r) {
      if (_selectedCategory == null) return true;
      final rawCat = (r['category'] as String?)?.trim() ?? '';
      if (ReceiptInventoryItem.isCategoryMatch(rawCat, _selectedCategory!)) return true;

      // Check line items if mixed-category
      final items = (r['receipt_items'] as List<dynamic>?) ?? [];
      return items.any((it) {
        final itCat = (it['category'] as String?) ?? '';
        return ReceiptInventoryItem.isCategoryMatch(itCat, _selectedCategory!);
      });
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory != null ? 'Purchases in $_selectedCategory' : 'All Category Transactions',
              style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_selectedCategory != null)
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = null),
                child: Text(
                  'Show All',
                  style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (filtered.isEmpty) ...[
          GlassCard(
            borderRadius: AppRadius.md,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No purchases recorded in $_selectedCategory for this period.',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ),
        ] else ...[
          ...filtered.take(10).map((r) {
            final merchant = r['merchant_name'] as String? ?? 'Merchant';
            final date = r['date'] as String? ?? 'Unknown Date';
            final amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
            final cat = r['category'] as String? ?? 'Others';

            final rawItems = (r['receipt_items'] as List<dynamic>?) ?? [];
            final subItems = rawItems.map((it) {
              return ReceiptInventorySubItem(
                name: (it['name'] as String?) ?? 'Item',
                price: ReceiptModel.parseDouble(it['total_price']) ?? ReceiptModel.parseDouble(it['price']) ?? 0.0,
                quantity: (it['quantity'] as num?)?.toInt() ?? 1,
                category: (it['category'] as String?) ?? cat,
              );
            }).toList();

            final invItem = ReceiptInventoryItem(
              id: r['id'].toString(),
              merchant: merchant,
              date: date,
              amount: amt,
              category: cat,
              matchScore: 100,
              icon: Icons.receipt_long,
              items: subItems,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReceiptCardItem(
                item: invItem,
                selectedCategory: _selectedCategory,
                onTap: () => widget.onReceiptTap(r),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildProductIntelligenceCard(FinancialOverviewData data) {
    final topProducts = data.topProducts.take(5).toList();

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Spending Intelligence',
                style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 12),

          if (topProducts.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Line item product spending will display as receipts are digitized.',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ] else ...[
            ...topProducts.map((p) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.secondary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Purchased ${p.purchaseCount}x • Avg ${CurrencyFormatter.format(p.averagePrice)}',
                            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(p.totalSpending),
                      style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _CategoryDonutPainter extends CustomPainter {
  final List<double> shares;
  final List<Color> colors;

  _CategoryDonutPainter({required this.shares, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (shares.isEmpty) return;
    final strokeWidth = size.width * 0.16;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    double startAngle = -math.pi / 2;
    for (int i = 0; i < shares.length; i++) {
      final sweepAngle = shares[i] * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = colors[i % colors.length]
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryDonutPainter oldDelegate) => true;
}
