import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _tappedDayIndex = -1;
  double? _userBudgetLimit;

  // Cache to optimize performance
  List<Map<String, dynamic>>? _cachedReceipts;
  List<WarrantyModel>? _cachedWarranties;
  _AnalyticsData? _cachedData;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userBudgetLimit = prefs.getDouble('monthly_budget');
      _cachedData = null;
    });
  }

  Future<void> _saveBudget(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('monthly_budget');
    } else {
      await prefs.setDouble('monthly_budget', value);
    }
    setState(() {
      _userBudgetLimit = value;
      _cachedData = null;
    });
  }

  void _showSetBudgetDialog() {
    final controller = TextEditingController(
      text: _userBudgetLimit != null ? _userBudgetLimit!.toInt().toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Set Monthly Budget',
          style: GoogleFonts.hankenGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter amount (e.g. 50000)',
            hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final double? val = double.tryParse(controller.text);
              _saveBudget(val);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(dbReceiptsListProvider);
    final warrantiesAsync = ref.watch(dbWarrantiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: receiptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text('Error loading data: $err')),
              data: (receipts) {
                return warrantiesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, stack) => Center(child: Text('Error loading data: $err')),
                  data: (warranties) {
                    if (receipts.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    // Check cache hits
                    if (_cachedReceipts != receipts || _cachedWarranties != warranties || _cachedData == null) {
                      _cachedReceipts = receipts;
                      _cachedWarranties = warranties;
                      _cachedData = _calculateAnalytics(receipts, warranties, _userBudgetLimit);
                    }

                    final data = _cachedData!;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                        vertical: AppSpacing.base,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 24),

                          // Monthly Spending Overview Card
                          _buildMonthlySpending(context, data),
                          const SizedBox(height: 24),

                          // Summary grid metrics
                          _buildSummaryGrid(context, data),
                          const SizedBox(height: 24),

                          // Charts Section: Category breakdown & Weekly Activity
                          _buildChartsSection(data),
                          const SizedBox(height: 24),

                          // Budget & Forecast section
                          _buildBudgetForecastCard(context, data),
                          const SizedBox(height: 24),

                          // Top Merchants section
                          _buildMerchantAnalyticsCard(context, data),
                          const SizedBox(height: 24),

                          // Warranty Analytics Overview
                          _buildWarrantyOverviewCard(context, data),
                          const SizedBox(height: 24),

                          // AI Insights list
                          _buildAIInsightsSection(context, data),
                          const SizedBox(height: 24),

                          // Visual trends details card
                          _buildVisualTrendsSection(context, data),

                          const SizedBox(height: 120),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            bottom: 96,
            right: 20,
            child: _buildFAB(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassCard(
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics_outlined, size: 72, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'No receipts available.',
                style: GoogleFonts.hankenGrotesk(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Scan more receipts to unlock insights.',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = ref.watch(firebaseAuthServiceProvider).currentUser;
    final photoURL = user?.photoURL;
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                StatefulNavigationShell.of(context).goBranch(4);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  image: DecorationImage(
                    image: NetworkImage(
                      hasPhoto ? photoURL : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Financial Analytics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }

  Widget _buildMonthlySpending(BuildContext context, _AnalyticsData data) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Spending',
            style: textTheme.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(data.currentMonthTotal),
                style: textTheme.displayLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              if (data.monthPercentageChange != null) ...[
                Row(
                  children: [
                    Icon(
                      data.monthPercentageChange! >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: data.monthPercentageChange! >= 0 ? Colors.redAccent : AppColors.tertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data.monthPercentageChange! >= 0 ? "+" : ""}${data.monthPercentageChange!.toStringAsFixed(1)}%',
                      style: textTheme.labelMd.copyWith(
                        color: data.monthPercentageChange! >= 0 ? Colors.redAccent : AppColors.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.monthPercentageChange != null ? 'Compared to Last Month' : 'No previous month data',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, _AnalyticsData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 16) / 2;
        return Column(
          children: [
            Row(
              children: [
                _buildSummaryMiniCard('Receipts Scanned', '${data.scannedCount}', Icons.receipt_long, width),
                const SizedBox(width: 16),
                _buildSummaryMiniCard('Products Protected', '${data.productsProtected}', Icons.verified_user_outlined, width),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryMiniCard('Total Spent', CurrencyFormatter.formatCompact(data.totalSpending), Icons.account_balance_wallet_outlined, width),
                const SizedBox(width: 16),
                _buildSummaryMiniCard('Avg Invoice Value', CurrencyFormatter.formatCompact(data.avgReceiptValue), Icons.analytics_outlined, width),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryMiniCard(String label, String value, IconData icon, double width) {
    return GlassCard(
      width: width,
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.hankenGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(_AnalyticsData data) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final categoryCard = _buildCategoryBreakdownCard(data);
    final weeklyActivityCard = _buildWeeklyActivityCard(data);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: categoryCard),
          const SizedBox(width: 24),
          Expanded(child: weeklyActivityCard),
        ],
      );
    } else {
      return Column(
        children: [
          categoryCard,
          const SizedBox(height: 24),
          weeklyActivityCard,
        ],
      );
    }
  }

  Widget _buildCategoryBreakdownCard(_AnalyticsData data) {
    final textTheme = Theme.of(context).textTheme;

    final sortedCategories = data.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.length <= 1) {
      return GlassCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Category Breakdown',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'More category insights will appear as you scan receipts from different categories.',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final List<double> shares = [];
    final List<Color> colors = [
      AppColors.primary,
      AppColors.tertiary,
      AppColors.secondary,
      const Color(0xFF7C4DFF),
      const Color(0xFFFF5252),
      const Color(0xFFFFD740),
      const Color(0xFF00E676),
      const Color(0xFFFF9100),
    ];
    
    final List<Widget> legendItems = [];
    int colorIdx = 0;

    for (final entry in sortedCategories) {
      final double share = data.totalSpending > 0 ? entry.value / data.totalSpending : 0.0;
      shares.add(share);
      final Color color = colors[colorIdx % colors.length];

      final double percentage = share * 100;
      legendItems.add(
        _buildLegendItem(entry.key, '${percentage.toStringAsFixed(0)}%', CurrencyFormatter.formatCompact(entry.value), color),
      );
      colorIdx++;
    }

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Category Breakdown',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      shares: shares,
                      colors: colors.take(shares.length).toList(),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Spent',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatCompact(data.totalSpending),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 10,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: legendItems.length,
            itemBuilder: (context, idx) => legendItems[idx],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String category, String percentage, String amount, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$category ($percentage)',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                amount,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyActivityCard(_AnalyticsData data) {
    final textTheme = Theme.of(context).textTheme;

    final double weeklyTotal = data.dayTotals.reduce((a, b) => a + b);
    if (weeklyTotal == 0.0) {
      return GlassCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Weekly Activity',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No spending recorded this week.',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    double maxTotal = 0.0;
    double minTotal = double.infinity;
    int maxIdx = 0;
    int minIdx = 0;

    for (int i = 0; i < data.dayTotals.length; i++) {
      final val = data.dayTotals[i];
      if (val > maxTotal) {
        maxTotal = val;
        maxIdx = i;
      }
      if (val > 0.0 && val < minTotal) {
        minTotal = val;
        minIdx = i;
      }
    }

    final double maxBarHeight = maxTotal > 0 ? maxTotal : 1.0;
    final List<double> heights = data.dayTotals.map((t) => t / maxBarHeight).toList();

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Weekly Activity',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Interactivity display
          if (_tappedDayIndex != -1) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getDayName(_tappedDayIndex),
                    style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    CurrencyFormatter.format(data.dayTotals[_tappedDayIndex]),
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final dayChars = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final isPeak = i == maxIdx && data.dayTotals[i] > 0;
                final isLow = i == minIdx && data.dayTotals[i] > 0;
                final isTapped = i == _tappedDayIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _tappedDayIndex = _tappedDayIndex == i ? -1 : i;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 22,
                        height: 90 * heights[i] + 4,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          gradient: isPeak 
                              ? AppGradients.primaryBlueCyan 
                              : isLow 
                                  ? const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]) 
                                  : null,
                          color: (isPeak || isLow) 
                              ? null 
                              : isTapped 
                                  ? AppColors.primary.withValues(alpha: 0.4) 
                                  : AppColors.cardSurface.withValues(alpha: 0.5),
                          border: isTapped
                              ? Border.all(color: AppColors.primary, width: 1.5)
                              : Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayChars[i],
                        style: GoogleFonts.inter(
                          color: isPeak 
                              ? AppColors.primary 
                              : isLow 
                                  ? Colors.orangeAccent 
                                  : AppColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: (isPeak || isLow) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricSubItem('Weekly Total', CurrencyFormatter.formatCompact(weeklyTotal), textTheme),
              _buildMetricSubItem('Peak Day', _getDayName(maxIdx), textTheme),
              _buildMetricSubItem('Daily Avg', CurrencyFormatter.formatCompact(weeklyTotal / 7), textTheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSubItem(String label, String value, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBudgetForecastCard(BuildContext context, _AnalyticsData data) {
    final textTheme = Theme.of(context).textTheme;

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
                'Budget & Forecast',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                onPressed: _showSetBudgetDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.budget == null) ...[
            Text(
              'No monthly budget configured.',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _showSetBudgetDialog,
              child: const Text('Set Monthly Budget', style: TextStyle(color: AppColors.primary)),
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${CurrencyFormatter.format(data.currentMonthTotal)}',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Budget: ${CurrencyFormatter.format(data.budget!)}',
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (data.currentMonthTotal / data.budget!).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: data.currentMonthTotal > data.budget! ? Colors.redAccent : AppColors.primary,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining:',
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
                    ),
                    Text(
                      CurrencyFormatter.format(data.remainingBudget),
                      style: GoogleFonts.inter(
                        color: data.remainingBudget >= 0 ? AppColors.tertiary : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.budgetStatus,
                  style: GoogleFonts.inter(
                    color: data.forecastSpent > data.budget! ? Colors.orangeAccent : AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMerchantAnalyticsCard(BuildContext context, _AnalyticsData data) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Merchant Analytics',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (data.topMerchants.isEmpty) ...[
            Text('No merchant activity found.', style: TextStyle(color: AppColors.onSurfaceVariant))
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(data.topMerchants.length, 5),
              separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                final m = data.topMerchants[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.storefront, color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${m.purchaseCount} Purchase${m.purchaseCount > 1 ? "s" : ""}',
                              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(m.totalSpending),
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarrantyOverviewCard(BuildContext context, _AnalyticsData data) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Warranty Analytics',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewBubble('Active', '${data.activeWarrantiesCount}', AppColors.primary),
              _buildOverviewBubble('Expiring', '${data.expiringSoonCount}', Colors.orangeAccent),
              _buildOverviewBubble('Expired', '${data.expiredCount}', Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average Remaining Days:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              Text(
                '${data.avgRemainingDays.toStringAsFixed(0)} Days',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Longest Warranty:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              Flexible(
                child: Text(
                  data.longestWarrantyProduct,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewBubble(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.hankenGrotesk(color: color, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAIInsightsSection(BuildContext context, _AnalyticsData data) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '🤖 AI Spending Insights',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...data.aiInsights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GlassCard(
                borderRadius: AppRadius.md,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildVisualTrendsSection(BuildContext context, _AnalyticsData data) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Visual Trends',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTrendItem('Top Spending Category', data.topCategory, Icons.category_outlined),
              _buildTrendItem('Top Brand', data.topBrand, Icons.branding_watermark_outlined),
              _buildTrendItem('Most Expensive Purchase', data.mostExpensivePurchaseProduct, Icons.payment_outlined),
              _buildTrendItem('Average Receipt Value', CurrencyFormatter.format(data.avgReceiptValue), Icons.bar_chart_outlined),
              _buildTrendItem('Most Frequent Merchant', data.topFrequentMerchant, Icons.local_mall_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primaryBlueCyan,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary,
            blurRadius: 16,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/scan'),
          customBorder: const CircleBorder(),
          child: const Center(
            child: Icon(
              Icons.add,
              color: AppColors.onPrimary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  String _getDayName(int index) {
    switch (index) {
      case 0: return 'Monday';
      case 1: return 'Tuesday';
      case 2: return 'Wednesday';
      case 3: return 'Thursday';
      case 4: return 'Friday';
      case 5: return 'Saturday';
      case 6: return 'Sunday';
      default: return '';
    }
  }

  _AnalyticsData _calculateAnalytics(List<Map<String, dynamic>> receipts, List<WarrantyModel> warranties, double? budgetLimit) {
    double totalSpending = 0.0;
    double totalSaved = 0.0;
    int scannedCount = receipts.length;
    int productsProtected = warranties.length;

    double maxPurchaseVal = 0.0;
    String maxPurchaseMerchant = 'N/A';

    final Map<String, double> categoryTotals = {};
    final Map<String, double> merchantSpendMap = {};
    final Map<String, int> merchantCountMap = {};
    final Map<String, int> brandCountMap = {};

    double mostExpensivePurchasePrice = 0.0;
    String mostExpensivePurchaseProduct = 'N/A';

    // 1. Weekly activity initialization
    final List<double> dayTotals = List.filled(7, 0.0);
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final monday = now.subtract(Duration(days: currentWeekday - 1));
    final mondayMidnight = DateTime(monday.year, monday.month, monday.day);
    final nextMondayMidnight = mondayMidnight.add(const Duration(days: 7));

    // 2. Monthly calculation variables
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 1);

    double currentMonthTotal = 0.0;
    double prevMonthTotal = 0.0;

    // 3. Loop over receipts
    for (final r in receipts) {
      final double amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
      final double disc = ReceiptModel.parseDouble(r['discount']) ?? 0.0;
      totalSpending += amt;
      totalSaved += disc;

      final String merchant = r['merchant_name'] as String? ?? 'Unknown Merchant';
      merchantSpendMap[merchant] = (merchantSpendMap[merchant] ?? 0.0) + amt;
      merchantCountMap[merchant] = (merchantCountMap[merchant] ?? 0) + 1;

      if (amt > maxPurchaseVal) {
        maxPurchaseVal = amt;
        maxPurchaseMerchant = merchant;
      }

      final String category = r['category'] as String? ?? 'Others';
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amt;

      final String? dateStr = r['date'] as String?;
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          // Weekly
          if (date.isAfter(mondayMidnight.subtract(const Duration(seconds: 1))) && date.isBefore(nextMondayMidnight)) {
            dayTotals[date.weekday - 1] += amt;
          }

          // Monthly
          if (date.isAfter(currentMonthStart.subtract(const Duration(seconds: 1))) && date.isBefore(currentMonthEnd)) {
            currentMonthTotal += amt;
          } else if (date.isAfter(prevMonthStart.subtract(const Duration(seconds: 1))) && date.isBefore(prevMonthEnd)) {
            prevMonthTotal += amt;
          }
        }
      }
    }

    // 4. Percentage comparison
    double? monthPercentageChange;
    if (prevMonthTotal > 0.0) {
      monthPercentageChange = ((currentMonthTotal - prevMonthTotal) / prevMonthTotal) * 100;
    }

    // 5. Category resolution
    String topCategory = 'N/A';
    double topCategorySpend = 0.0;
    if (categoryTotals.isNotEmpty) {
      final sorted = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sorted.first.key;
      topCategorySpend = sorted.first.value;
    }

    // 6. Merchant statistics
    final List<_MerchantStat> topMerchants = [];
    merchantSpendMap.forEach((mName, spend) {
      topMerchants.add(_MerchantStat(
        name: mName,
        totalSpending: spend,
        purchaseCount: merchantCountMap[mName] ?? 0,
      ));
    });
    topMerchants.sort((a, b) => b.totalSpending.compareTo(a.totalSpending));

    String topFrequentMerchant = 'N/A';
    int maxMerchantCount = 0;
    merchantCountMap.forEach((mName, count) {
      if (count > maxMerchantCount) {
        maxMerchantCount = count;
        topFrequentMerchant = mName;
      }
    });

    // 7. Warranties overview & analytics
    int activeWarrantiesCount = 0;
    int expiringSoonCount = 0;
    int expiredCount = 0;
    double totalRemainingDays = 0.0;
    int remainingCount = 0;

    String longestWarrantyProduct = 'N/A';
    String longestWarrantyExpiry = 'N/A';
    int maxRemainingDays = -9999;

    for (final w in warranties) {
      if (w.status == 'ACTIVE') {
        activeWarrantiesCount++;
      } else if (w.status == 'EXPIRING SOON') {
        expiringSoonCount++;
      } else if (w.status == 'EXPIRED') {
        expiredCount++;
      }

      final daysRemaining = WarrantyUtils.calculateDaysRemaining(w.expiryDate);
      if (daysRemaining >= 0) {
        totalRemainingDays += daysRemaining;
        remainingCount++;

        if (daysRemaining > maxRemainingDays) {
          maxRemainingDays = daysRemaining;
          longestWarrantyProduct = w.productName;
          longestWarrantyExpiry = w.expiryDate;
        }
      }

      // Brand aggregation
      String brand = w.brand ?? '';
      if (brand.isEmpty) {
        final parts = w.productName.trim().split(' ');
        if (parts.isNotEmpty) brand = parts.first;
      }
      if (brand.isNotEmpty) {
        brandCountMap[brand] = (brandCountMap[brand] ?? 0) + 1;
      }
    }

    double avgRemainingDays = remainingCount > 0 ? totalRemainingDays / remainingCount : 0.0;

    String topBrand = 'N/A';
    int maxBrandCount = 0;
    brandCountMap.forEach((bName, count) {
      if (count > maxBrandCount) {
        maxBrandCount = count;
        topBrand = bName;
      }
    });

    // 8. Visual trends bento data
    // Most expensive item from items or warranties
    for (final w in warranties) {
      final receipt = receipts.firstWhere((r) => r['id'].toString() == w.receiptId, orElse: () => {});
      if (receipt.isNotEmpty) {
        final double rVal = ReceiptModel.parseDouble(receipt['grand_total']) ?? ReceiptModel.parseDouble(receipt['total']) ?? 0.0;
        if (rVal > mostExpensivePurchasePrice) {
          mostExpensivePurchasePrice = rVal;
          mostExpensivePurchaseProduct = w.productName;
        }
      }
    }
    // Fallback if no warranties
    if (mostExpensivePurchasePrice == 0.0 && maxPurchaseVal > 0.0) {
      mostExpensivePurchasePrice = maxPurchaseVal;
      mostExpensivePurchaseProduct = maxPurchaseMerchant;
    }

    // Monthly spending trend last 6 months
    final List<_MonthlyTrend> spendingTrend = [];
    for (int i = 5; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      double targetMonthTotal = 0.0;
      for (final r in receipts) {
        final String? dateStr = r['date'] as String?;
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          if (date != null && date.year == targetMonth.year && date.month == targetMonth.month) {
            targetMonthTotal += ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
          }
        }
      }
      final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      spendingTrend.add(_MonthlyTrend(
        monthLabel: '${monthNames[targetMonth.month - 1]} ${targetMonth.year}',
        amount: targetMonthTotal,
      ));
    }

    // 9. Forecast and budget status
    final elapsedDays = now.day;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    final dailyAverage = elapsedDays > 0 ? currentMonthTotal / elapsedDays : currentMonthTotal;
    final forecastSpent = dailyAverage * totalDays;

    final remainingBudget = budgetLimit != null ? budgetLimit - currentMonthTotal : 0.0;
    String budgetStatusText = 'No monthly budget configured.';
    if (budgetLimit != null) {
      if (forecastSpent > budgetLimit) {
        budgetStatusText = 'Likely to exceed budget by ${CurrencyFormatter.format(forecastSpent - budgetLimit)}';
      } else {
        budgetStatusText = 'On track. Projected monthly spending is ${CurrencyFormatter.format(forecastSpent)}';
      }
    }

    // 10. Generate Real AI insights
    final List<String> aiInsightsList = [];
    if (totalSpending > 0.0 && topCategory != 'N/A') {
      final topCatPct = (topCategorySpend / totalSpending) * 100;
      aiInsightsList.add('You spent ${topCatPct.toStringAsFixed(0)}% of your total shopping on $topCategory.');
    }
    if (maxPurchaseVal > 0.0) {
      aiInsightsList.add('Your largest purchase this month was ${CurrencyFormatter.format(maxPurchaseVal)} at $maxPurchaseMerchant.');
    }
    if (topFrequentMerchant != 'N/A') {
      final freqCount = merchantCountMap[topFrequentMerchant] ?? 0;
      aiInsightsList.add('$topFrequentMerchant is your most visited merchant with $freqCount purchases.');
    }
    if (productsProtected > 0) {
      aiInsightsList.add('You have $productsProtected protected products with an average of ${avgRemainingDays.toStringAsFixed(0)} days of warranty remaining.');
    }
    if (expiringSoonCount > 0) {
      aiInsightsList.add('Attention: $expiringSoonCount warranties are expiring within the next 30 days.');
    } else if (expiredCount > 0) {
      aiInsightsList.add('$expiredCount of your product warranties have expired.');
    } else if (totalSaved > 0.0) {
      aiInsightsList.add('You saved ${CurrencyFormatter.format(totalSaved)} in discount benefits across all receipts.');
    }

    // Slice to 3-5 insights
    final finalInsights = aiInsightsList.take(5).toList();
    while (finalInsights.length < 3) {
      finalInsights.add('Scan more receipts from different categories to unlock more AI insights.');
    }

    return _AnalyticsData(
      totalSpending: totalSpending,
      totalSaved: totalSaved,
      scannedCount: scannedCount,
      productsProtected: productsProtected,
      avgReceiptValue: scannedCount > 0 ? totalSpending / scannedCount : 0.0,
      maxPurchaseVal: maxPurchaseVal,
      maxPurchaseMerchant: maxPurchaseMerchant,
      topCategory: topCategory,
      topCategorySpend: topCategorySpend,
      topBrand: topBrand,
      avgRemainingDays: avgRemainingDays,
      longestWarrantyProduct: longestWarrantyProduct,
      longestWarrantyExpiry: longestWarrantyExpiry,
      activeWarrantiesCount: activeWarrantiesCount,
      expiringSoonCount: expiringSoonCount,
      expiredCount: expiredCount,
      currentMonthTotal: currentMonthTotal,
      prevMonthTotal: prevMonthTotal,
      monthPercentageChange: monthPercentageChange,
      categoryTotals: categoryTotals,
      dayTotals: dayTotals,
      topMerchants: topMerchants,
      spendingTrend: spendingTrend,
      aiInsights: finalInsights,
      budget: budgetLimit,
      forecastSpent: forecastSpent,
      budgetStatus: budgetStatusText,
      remainingBudget: remainingBudget,
      topFrequentMerchant: topFrequentMerchant,
      mostExpensivePurchaseProduct: mostExpensivePurchaseProduct,
      mostExpensivePurchasePrice: mostExpensivePurchasePrice,
    );
  }
}

class _MerchantStat {
  final String name;
  final double totalSpending;
  final int purchaseCount;

  _MerchantStat({required this.name, required this.totalSpending, required this.purchaseCount});
}

class _MonthlyTrend {
  final String monthLabel;
  final double amount;

  _MonthlyTrend({required this.monthLabel, required this.amount});
}

class _AnalyticsData {
  final double totalSpending;
  final double totalSaved;
  final int scannedCount;
  final int productsProtected;
  final double avgReceiptValue;
  final double maxPurchaseVal;
  final String maxPurchaseMerchant;
  final String topCategory;
  final double topCategorySpend;
  final String topBrand;
  final double avgRemainingDays;
  final String longestWarrantyProduct;
  final String longestWarrantyExpiry;
  final int activeWarrantiesCount;
  final int expiringSoonCount;
  final int expiredCount;
  final double currentMonthTotal;
  final double prevMonthTotal;
  final double? monthPercentageChange;
  final Map<String, double> categoryTotals;
  final List<double> dayTotals;
  final List<_MerchantStat> topMerchants;
  final List<_MonthlyTrend> spendingTrend;
  final List<String> aiInsights;
  final double? budget;
  final double forecastSpent;
  final String budgetStatus;
  final double remainingBudget;
  final String topFrequentMerchant;
  final String mostExpensivePurchaseProduct;
  final double mostExpensivePurchasePrice;

  _AnalyticsData({
    required this.totalSpending,
    required this.totalSaved,
    required this.scannedCount,
    required this.productsProtected,
    required this.avgReceiptValue,
    required this.maxPurchaseVal,
    required this.maxPurchaseMerchant,
    required this.topCategory,
    required this.topCategorySpend,
    required this.topBrand,
    required this.avgRemainingDays,
    required this.longestWarrantyProduct,
    required this.longestWarrantyExpiry,
    required this.activeWarrantiesCount,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.currentMonthTotal,
    required this.prevMonthTotal,
    required this.monthPercentageChange,
    required this.categoryTotals,
    required this.dayTotals,
    required this.topMerchants,
    required this.spendingTrend,
    required this.aiInsights,
    required this.budget,
    required this.forecastSpent,
    required this.budgetStatus,
    required this.remainingBudget,
    required this.topFrequentMerchant,
    required this.mostExpensivePurchaseProduct,
    required this.mostExpensivePurchasePrice,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<double> shares;
  final List<Color> colors;

  _DonutChartPainter({required this.shares, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth);
    double startAngle = -math.pi / 2;

    for (int i = 0; i < shares.length; i++) {
      final sweepAngle = shares[i] * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle + 0.05, sweepAngle - 0.1, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
