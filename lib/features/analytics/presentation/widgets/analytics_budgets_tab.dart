import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/analytics/domain/models/budget_model.dart';
import 'package:receipto/features/analytics/domain/models/financial_overview_data.dart';
import 'package:receipto/features/analytics/domain/models/recurring_expense_model.dart';
import 'package:receipto/features/analytics/domain/models/savings_goal_model.dart';

class AnalyticsBudgetsTab extends StatelessWidget {
  final FinancialOverviewData data;
  final List<AppBudget> budgets;
  final List<SavingsGoal> goals;
  final List<RecurringExpense> recurring;
  final VoidCallback onAddBudget;
  final Function(AppBudget budget) onEditBudget;
  final Function(String id) onDeleteBudget;
  final VoidCallback onAddGoal;
  final Function(SavingsGoal goal) onEditGoal;
  final Function(String id) onDeleteGoal;
  final VoidCallback onAddRecurring;
  final Function(RecurringExpense recurring) onToggleRecurring;
  final Function(String id) onDeleteRecurring;

  const AnalyticsBudgetsTab({
    super.key,
    required this.data,
    required this.budgets,
    required this.goals,
    required this.recurring,
    required this.onAddBudget,
    required this.onEditBudget,
    required this.onDeleteBudget,
    required this.onAddGoal,
    required this.onEditGoal,
    required this.onDeleteGoal,
    required this.onAddRecurring,
    required this.onToggleRecurring,
    required this.onDeleteRecurring,
  });

  @override
  Widget build(BuildContext context) {
    final overallBudget = budgets.where((b) => b.isOverall).fold<AppBudget?>(null, (prev, curr) => curr);
    final categoryBudgets = budgets.where((b) => !b.isOverall).toList();

    // Calculate total recurring monthly burden
    final double totalMonthlyRecurring = recurring.fold(0.0, (sum, r) => sum + r.monthlyNormalizedAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Overall Monthly Budget
          _buildOverallBudgetHero(context, overallBudget),
          const SizedBox(height: 20),

          // Section 2: Category Budgets
          _buildCategoryBudgetsSection(context, categoryBudgets),
          const SizedBox(height: 20),

          // Section 3: Savings Goals
          _buildSavingsGoalsSection(context),
          const SizedBox(height: 20),

          // Section 4: Recurring Expenses & Subscriptions
          _buildRecurringExpensesSection(context, totalMonthlyRecurring),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildOverallBudgetHero(BuildContext context, AppBudget? overallBudget) {
    final hasBudget = overallBudget != null && overallBudget.limitAmount > 0;
    final limit = overallBudget?.limitAmount ?? 0.0;
    final double currentMonthSpend = data.monthlyTrends.isNotEmpty ? data.monthlyTrends.last.amount : 0.0;
    final remaining = hasBudget ? (limit - currentMonthSpend).clamp(0.0, double.infinity) : 0.0;
    final usedPct = hasBudget && limit > 0 ? (currentMonthSpend / limit).clamp(0.0, 1.0) : 0.0;
    final isExceeded = hasBudget && currentMonthSpend > limit;

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
                  const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Overall Monthly Budget',
                    style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                onPressed: () {
                  if (overallBudget != null) {
                    onEditBudget(overallBudget);
                  } else {
                    onAddBudget();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (hasBudget) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Spend', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(currentMonthSpend),
                      style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Limit', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(limit),
                      style: GoogleFonts.hankenGrotesk(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: usedPct,
                minHeight: 10,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExceeded ? Colors.redAccent : (usedPct > 0.8 ? const Color(0xFFF59E0B) : AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(usedPct * 100).toStringAsFixed(1)}% Consumed',
                  style: GoogleFonts.inter(
                    color: isExceeded ? Colors.redAccent : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  isExceeded
                      ? 'Exceeded by ${CurrencyFormatter.format(currentMonthSpend - limit)}'
                      : 'Remaining: ${CurrencyFormatter.format(remaining)}',
                  style: GoogleFonts.inter(
                    color: isExceeded ? Colors.redAccent : AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No overall monthly budget configured. Tap "Set Limit" to track your threshold and forecast overruns.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAddBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Set Overall Budget', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsSection(BuildContext context, List<AppBudget> categoryBudgets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category Budgets',
              style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
              label: const Text('Add Category Limit', style: TextStyle(color: AppColors.primary, fontSize: 12)),
              onPressed: onAddBudget,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (categoryBudgets.isEmpty) ...[
          GlassCard(
            borderRadius: AppRadius.md,
            padding: const EdgeInsets.all(16),
            child: Text(
              'No category budgets yet. Set category limits for Groceries, Dining, or Electronics to maintain discipline.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12, height: 1.4),
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryBudgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final b = categoryBudgets[idx];
              final catSpend = data.categoryTotals[b.category] ?? 0.0;
              final pct = b.limitAmount > 0 ? (catSpend / b.limitAmount).clamp(0.0, 1.0) : 0.0;
              final isOver = catSpend > b.limitAmount;

              return GlassCard(
                borderRadius: AppRadius.md,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          b.category,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Row(
                          children: [
                            Text(
                              '${CurrencyFormatter.format(catSpend)} / ${CurrencyFormatter.format(b.limitAmount)}',
                              style: GoogleFonts.hankenGrotesk(
                                color: isOver ? Colors.redAccent : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                              onPressed: () => onDeleteBudget(b.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOver ? Colors.redAccent : (pct > 0.8 ? const Color(0xFFF59E0B) : AppColors.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSavingsGoalsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Savings Goals',
              style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16, color: AppColors.tertiary),
              label: const Text('New Goal', style: TextStyle(color: AppColors.tertiary, fontSize: 12)),
              onPressed: onAddGoal,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (goals.isEmpty) ...[
          GlassCard(
            borderRadius: AppRadius.md,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Create savings goals for future purchases, emergency buffers, or vacation funds to track your milestones.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12, height: 1.4),
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final g = goals[idx];
              final pct = g.progressPercentage;

              return GlassCard(
                borderRadius: AppRadius.md,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${g.daysRemaining} days left • ${g.category}',
                                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                          onPressed: () => onDeleteGoal(g.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saved: ${CurrencyFormatter.format(g.currentSaved)}',
                          style: GoogleFonts.hankenGrotesk(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Target: ${CurrencyFormatter.format(g.targetAmount)}',
                          style: GoogleFonts.hankenGrotesk(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.tertiary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRecurringExpensesSection(BuildContext context, double totalMonthlyRecurring) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recurring Bills & Subscriptions',
                  style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '~${CurrencyFormatter.format(totalMonthlyRecurring)}/month estimated',
                  style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16, color: AppColors.secondary),
              label: const Text('Add Bill', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
              onPressed: onAddRecurring,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (recurring.isEmpty) ...[
          GlassCard(
            borderRadius: AppRadius.md,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Add scheduled payments like Netflix, Broadband, Rent, or Insurance. (Note: Kept distinct from confirmed receipts until recorded).',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12, height: 1.4),
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recurring.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final r = recurring[idx];

              return GlassCard(
                borderRadius: AppRadius.md,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: r.isActive
                          ? AppColors.secondary.withValues(alpha: 0.15)
                          : Colors.white10,
                      child: Icon(
                        Icons.autorenew,
                        color: r.isActive ? AppColors.secondary : Colors.white38,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: GoogleFonts.inter(
                              color: r.isActive ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Due in ${r.daysUntilDue} days • ${r.frequency.toUpperCase()}',
                            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(r.amount),
                          style: GoogleFonts.hankenGrotesk(
                            color: r.isActive ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => onToggleRecurring(r.copyWith(isActive: !r.isActive)),
                              child: Text(
                                r.isActive ? 'Active' : 'Paused',
                                style: TextStyle(
                                  color: r.isActive ? AppColors.secondary : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => onDeleteRecurring(r.id),
                              child: const Icon(Icons.delete_outline, size: 14, color: Colors.white38),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
