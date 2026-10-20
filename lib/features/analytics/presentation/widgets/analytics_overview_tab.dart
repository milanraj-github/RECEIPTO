import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/analytics/domain/models/financial_filter.dart';
import 'package:receipto/features/analytics/domain/models/financial_overview_data.dart';
import 'package:receipto/features/analytics/domain/models/savings_goal_model.dart';
import 'package:receipto/features/analytics/domain/models/recurring_expense_model.dart';

class AnalyticsOverviewTab extends StatefulWidget {
  final FinancialOverviewData data;
  final FinancialPeriod selectedPeriod;
  final Function(FinancialPeriod period) onPeriodChanged;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenExport;
  final VoidCallback onEditBudget;
  final List<SavingsGoal> goals;
  final List<RecurringExpense> recurring;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenRecurring;

  const AnalyticsOverviewTab({
    super.key,
    required this.data,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onOpenCalendar,
    required this.onOpenExport,
    required this.onEditBudget,
    required this.goals,
    required this.recurring,
    required this.onOpenGoals,
    required this.onOpenRecurring,
  });

  @override
  State<AnalyticsOverviewTab> createState() => _AnalyticsOverviewTabState();
}

class _AnalyticsOverviewTabState extends State<AnalyticsOverviewTab> {
  int _selectedTrendType = 0; // 0 = Weekly (7 days), 1 = 6 Months Trend

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Period Filter Pills
          _buildPeriodSelector(),
          const SizedBox(height: 16),

          // Total Expenditure Hero Card
          _buildHeroSpendingCard(data),
          const SizedBox(height: 16),

          // Key Metrics Grid
          _buildKeyMetricsGrid(data),
          const SizedBox(height: 16),

          // Quick Action Tools (Calendar & Export)
          _buildQuickActionsRow(),
          const SizedBox(height: 16),

          // Spending Trends Chart Card
          _buildSpendingTrendsCard(data),
          const SizedBox(height: 16),

          // Budget Progress Card
          _buildBudgetProgressCard(data),
          const SizedBox(height: 16),

          // Merchant Highlights Card
          _buildMerchantHighlightsCard(data),
          const SizedBox(height: 16),

          // Financial Health Snapshots (Goals & Recurring)
          _buildGoalsAndRecurringSnapshot(),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FinancialPeriod.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = FinancialPeriod.values[index];
          final isSelected = widget.selectedPeriod == p;
          return ChoiceChip(
            label: Text(
              p.label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.cardSurface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (_) => widget.onPeriodChanged(p),
          );
        },
      ),
    );
  }

  Widget _buildHeroSpendingCard(FinancialOverviewData data) {
    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Expenditure',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (data.totalRefunds > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Net of ${CurrencyFormatter.format(data.totalRefunds)} refunds',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(data.netSpending),
              style: GoogleFonts.hankenGrotesk(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Comparison label
          if (data.comparisonPercentageChange != null) ...[
            Row(
              children: [
                Icon(
                  data.comparisonPercentageChange! >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: data.comparisonPercentageChange! >= 0 ? Colors.redAccent : AppColors.tertiary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${data.comparisonPercentageChange! >= 0 ? "+" : ""}${data.comparisonPercentageChange!.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    color: data.comparisonPercentageChange! >= 0 ? Colors.redAccent : AppColors.tertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  data.comparisonPeriodLabel,
                  style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No previous period data for comparison',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid(FinancialOverviewData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Column(
          children: [
            Row(
              children: [
                _buildMiniMetricCard(
                  title: 'Transactions',
                  value: '${data.transactionCount}',
                  icon: Icons.receipt_long,
                  width: cardWidth,
                ),
                const SizedBox(width: 12),
                _buildMiniMetricCard(
                  title: 'Daily Average',
                  value: CurrencyFormatter.format(data.avgDailySpend),
                  icon: Icons.calendar_view_day_outlined,
                  width: cardWidth,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniMetricCard(
                  title: 'Avg Invoice Value',
                  value: CurrencyFormatter.format(data.avgTransactionValue),
                  icon: Icons.analytics_outlined,
                  width: cardWidth,
                ),
                const SizedBox(width: 12),
                _buildMiniMetricCard(
                  title: 'Total Saved',
                  value: CurrencyFormatter.format(data.totalSaved),
                  icon: Icons.savings_outlined,
                  width: cardWidth,
                  valueColor: AppColors.tertiary,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required double width,
    Color valueColor = Colors.white,
  }) {
    return GlassCard(
      width: width,
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.hankenGrotesk(
                      color: valueColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: widget.onOpenCalendar,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Spending Calendar',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: widget.onOpenExport,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download_outlined, color: AppColors.tertiary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Export Reports',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingTrendsCard(FinancialOverviewData data) {
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
                'Spending Trends',
                style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildTrendToggleChip('7 Days', 0),
                  const SizedBox(width: 6),
                  _buildTrendToggleChip('6 Months', 1),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_selectedTrendType == 0) ...[
            _buildWeeklyBarChart(data.weeklyDayTotals),
          ] else ...[
            _buildMonthlyTrendBars(data.monthlyTrends),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendToggleChip(String label, int index) {
    final isSel = _selectedTrendType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTrendType = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSel ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<double> dayTotals) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = dayTotals.fold(0.0, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final amt = dayTotals[i];
          final double pct = maxVal > 0 ? (amt / maxVal).clamp(0.06, 1.0) : 0.06;
          final isToday = (DateTime.now().weekday - 1) == i;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (amt > 0)
                Text(
                  CurrencyFormatter.formatCompact(amt),
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: 90 * pct,
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary
                      : amt > 0
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                days[i],
                style: GoogleFonts.inter(
                  color: isToday ? AppColors.primary : AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyTrendBars(List<MonthlyTrendPoint> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();
    final maxVal = trends.fold(0.0, (m, p) => p.amount > m ? p.amount : m);

    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trends.map((point) {
          final double pct = maxVal > 0 ? (point.amount / maxVal).clamp(0.06, 1.0) : 0.06;
          final isCurrent = point == trends.last;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (point.amount > 0)
                Text(
                  CurrencyFormatter.formatCompact(point.amount),
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 4),
              Container(
                width: 28,
                height: 90 * pct,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : point.amount > 0
                          ? AppColors.primary.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                point.monthLabel,
                style: GoogleFonts.inter(
                  color: isCurrent ? AppColors.primary : AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetProgressCard(FinancialOverviewData data) {
    final hasBudget = data.overallBudget != null && data.overallBudget! > 0;
    final budgetLimit = data.overallBudget ?? 0.0;
    final usedPct = data.budgetUsedPercentage / 100.0;
    final isExceeded = data.projectedBudgetOverrun != null && data.projectedBudgetOverrun! > 0;

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Monthly Budget Status',
                    style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onEditBudget,
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text(
                  hasBudget ? 'Edit Limit' : 'Set Budget',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (hasBudget) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${data.budgetUsedPercentage.toStringAsFixed(1)}% Used',
                  style: GoogleFonts.hankenGrotesk(
                    color: isExceeded ? Colors.redAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Remaining: ${CurrencyFormatter.format(data.budgetRemaining)}',
                  style: GoogleFonts.inter(
                    color: isExceeded ? Colors.redAccent : AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: usedPct.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExceeded ? Colors.redAccent : (usedPct > 0.8 ? const Color(0xFFF59E0B) : AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Limit: ${CurrencyFormatter.format(budgetLimit)}',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
            ),
          ] else ...[
            Text(
              'No overall monthly budget configured. Set a limit to monitor spending thresholds and receive budget overrun alerts.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMerchantHighlightsCard(FinancialOverviewData data) {
    final merchants = data.topMerchants.take(3).toList();

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
                'Top Merchants',
                style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'By expenditure',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (merchants.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No merchant activity in selected period.',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ] else ...[
            ...merchants.map((m) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${m.purchaseCount} purchases',
                            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(m.totalSpending),
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

  Widget _buildGoalsAndRecurringSnapshot() {
    return Row(
      children: [
        // Goals summary
        Expanded(
          child: GestureDetector(
            onTap: widget.onOpenGoals,
            child: GlassCard(
              borderRadius: AppRadius.md,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.track_changes, color: AppColors.tertiary, size: 18),
                      Text(
                        '${widget.goals.length} Goals',
                        style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Savings Goals',
                    style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.goals.isNotEmpty
                        ? '${(widget.goals.first.progressPercentage * 100).toInt()}% of top goal'
                        : 'Track target savings',
                    style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Recurring summary
        Expanded(
          child: GestureDetector(
            onTap: widget.onOpenRecurring,
            child: GlassCard(
              borderRadius: AppRadius.md,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.autorenew, color: AppColors.secondary, size: 18),
                      Text(
                        '${widget.recurring.length} Active',
                        style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Recurring Bills',
                    style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.recurring.isNotEmpty
                        ? '${widget.recurring.length} subscriptions'
                        : 'Manage recurring costs',
                    style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
