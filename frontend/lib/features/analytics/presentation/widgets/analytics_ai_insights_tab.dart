import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/analytics/data/services/financial_ai_service.dart';
import 'package:receipto/features/analytics/domain/models/financial_overview_data.dart';

class AnalyticsAiInsightsTab extends ConsumerStatefulWidget {
  final FinancialOverviewData data;

  const AnalyticsAiInsightsTab({
    super.key,
    required this.data,
  });

  @override
  ConsumerState<AnalyticsAiInsightsTab> createState() => _AnalyticsAiInsightsTabState();
}

class _AnalyticsAiInsightsTabState extends ConsumerState<AnalyticsAiInsightsTab> {
  bool _isLoading = false;
  List<FinancialInsightItem> _insights = [];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  @override
  void didUpdateWidget(covariant AnalyticsAiInsightsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _loadInsights();
    }
  }

  Future<void> _loadInsights({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final aiService = ref.read(financialAiServiceProvider);
      final list = await aiService.generateInsights(widget.data, forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _insights = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Month-End Expenditure Forecast Card
          _buildForecastCard(data),
          const SizedBox(height: 16),

          // 2. AI Insights List Header with Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'AI Intelligence & Insights',
                    style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.refresh, color: AppColors.primary, size: 18),
                onPressed: _isLoading ? null : () => _loadInsights(forceRefresh: true),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Insights list
          if (_isLoading && _insights.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ] else ...[
            ..._insights.map((item) => _buildInsightCard(item)),
          ],
          const SizedBox(height: 16),

          // 3. Payment Method Intelligence Card
          _buildPaymentMethodsCard(data),
          const SizedBox(height: 16),

          // 4. Interactive AI Assistant Button
          _buildAiAssistantTrigger(),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildForecastCard(FinancialOverviewData data) {
    final hasOverrun = data.projectedBudgetOverrun != null && data.projectedBudgetOverrun! > 0;

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
                'Month-End Expenditure Forecast',
                style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'STATISTICAL ESTIMATE',
                  style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Projected Total Spend', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(data.projectedMonthEndSpend),
                    style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (data.overallBudget != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Budget Limit', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(data.overallBudget!),
                      style: GoogleFonts.hankenGrotesk(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasOverrun
                  ? Colors.redAccent.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasOverrun
                    ? Colors.redAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasOverrun ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: hasOverrun ? Colors.redAccent : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.forecastExplanation,
                    style: GoogleFonts.inter(
                      color: hasOverrun ? Colors.redAccent : Colors.white70,
                      fontSize: 12,
                      height: 1.35,
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

  Widget _buildInsightCard(FinancialInsightItem item) {
    Color typeColor;
    IconData typeIcon;

    switch (item.type) {
      case 'alert':
        typeColor = const Color(0xFFF59E0B);
        typeIcon = Icons.warning_amber_outlined;
        break;
      case 'fact':
        typeColor = AppColors.secondary;
        typeIcon = Icons.insights;
        break;
      case 'recommendation':
      default:
        typeColor = AppColors.primary;
        typeIcon = Icons.lightbulb_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: AppRadius.md,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: typeColor.withValues(alpha: 0.12),
              child: Icon(typeIcon, color: typeColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (item.metric != null)
                        Text(
                          item.metric!,
                          style: GoogleFonts.inter(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard(FinancialOverviewData data) {
    if (data.paymentMethodTotals.isEmpty) return const SizedBox.shrink();

    final sorted = data.paymentMethodTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Payment Method Breakdown',
            style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...sorted.map((e) {
            final double pct = data.netSpending > 0 ? (e.value / data.netSpending).clamp(0.0, 1.0) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                      Text(
                        '${CurrencyFormatter.format(e.value)} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: GoogleFonts.hankenGrotesk(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 4,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiAssistantTrigger() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.35),
            AppColors.cardSurface,
            const Color(0xFF005236).withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Need Deeper Financial Analysis?',
                style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ask the interactive AI Assistant questions about your spending, warranty eligibility, or monthly forecast.',
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/ai-assistant'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Open AI Assistant',
                style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
