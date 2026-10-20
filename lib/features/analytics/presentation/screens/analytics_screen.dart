import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/analytics/data/services/financial_analytics_service.dart';
import 'package:receipto/features/analytics/data/services/financial_persistence_service.dart';
import 'package:receipto/features/analytics/domain/models/budget_model.dart';
import 'package:receipto/features/analytics/domain/models/financial_filter.dart';
import 'package:receipto/features/analytics/domain/models/recurring_expense_model.dart';
import 'package:receipto/features/analytics/domain/models/refund_model.dart';
import 'package:receipto/features/analytics/domain/models/savings_goal_model.dart';
import 'package:receipto/features/analytics/presentation/widgets/add_edit_budget_dialog.dart';
import 'package:receipto/features/analytics/presentation/widgets/add_edit_goal_dialog.dart';
import 'package:receipto/features/analytics/presentation/widgets/add_edit_recurring_dialog.dart';
import 'package:receipto/features/analytics/presentation/widgets/add_manual_expense_sheet.dart';
import 'package:receipto/features/analytics/presentation/widgets/analytics_ai_insights_tab.dart';
import 'package:receipto/features/analytics/presentation/widgets/analytics_budgets_tab.dart';
import 'package:receipto/features/analytics/presentation/widgets/analytics_categories_tab.dart';
import 'package:receipto/features/analytics/presentation/widgets/analytics_overview_tab.dart';
import 'package:receipto/features/analytics/presentation/widgets/analytics_transactions_tab.dart';
import 'package:receipto/features/analytics/presentation/widgets/export_report_sheet.dart';
import 'package:receipto/features/analytics/presentation/widgets/spending_calendar_sheet.dart';
import 'package:receipto/features/analytics/presentation/widgets/transaction_details_sheet.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  FinancialPeriod _selectedPeriod = FinancialPeriod.thisMonth;
  DateTimeRange? _customRange;

  // User-scoped persistent items
  List<AppBudget> _budgets = [];
  List<SavingsGoal> _goals = [];
  List<RecurringExpense> _recurring = [];
  List<ReceiptRefund> _refunds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUserFinancialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserFinancialData() async {
    final user = ref.read(firebaseAuthServiceProvider).currentUser;
    if (user == null) {
      return;
    }

    final persistence = ref.read(financialPersistenceServiceProvider);
    final results = await Future.wait([
      persistence.getBudgets(user.uid),
      persistence.getGoals(user.uid),
      persistence.getRecurringExpenses(user.uid),
      persistence.getRefunds(user.uid),
    ]);

    if (mounted) {
      setState(() {
        _budgets = results[0] as List<AppBudget>;
        _goals = results[1] as List<SavingsGoal>;
        _recurring = results[2] as List<RecurringExpense>;
        _refunds = results[3] as List<ReceiptRefund>;
      });
    }
  }

  void _openSpendingCalendar(List<Map<String, dynamic>> receipts) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpendingCalendarSheet(allReceipts: receipts),
    );
  }

  void _openExportReports(List<Map<String, dynamic>> receipts) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportReportSheet(allReceipts: receipts),
    );
  }

  void _openAddManualExpense() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddManualExpenseSheet(),
    );
  }

  void _openTransactionDetails(Map<String, dynamic> receipt) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsSheet(
        receipt: receipt,
        onUpdated: () => _loadUserFinancialData(),
      ),
    );
  }

  void _showAddEditBudgetDialog({AppBudget? existing}) {
    showDialog(
      context: context,
      builder: (_) => AddEditBudgetDialog(
        existingBudget: existing,
        onSave: (budget) async {
          final user = ref.read(firebaseAuthServiceProvider).currentUser;
          if (user != null) {
            await ref.read(financialPersistenceServiceProvider).saveBudget(user.uid, budget);
            _loadUserFinancialData();
          }
        },
      ),
    );
  }

  void _showAddEditGoalDialog({SavingsGoal? existing}) {
    showDialog(
      context: context,
      builder: (_) => AddEditGoalDialog(
        existingGoal: existing,
        onSave: (goal) async {
          final user = ref.read(firebaseAuthServiceProvider).currentUser;
          if (user != null) {
            await ref.read(financialPersistenceServiceProvider).saveGoal(user.uid, goal);
            _loadUserFinancialData();
          }
        },
      ),
    );
  }

  void _showAddEditRecurringDialog({RecurringExpense? existing}) {
    showDialog(
      context: context,
      builder: (_) => AddEditRecurringDialog(
        existingExpense: existing,
        onSave: (expense) async {
          final user = ref.read(firebaseAuthServiceProvider).currentUser;
          if (user != null) {
            await ref.read(financialPersistenceServiceProvider).saveRecurringExpense(user.uid, expense);
            _loadUserFinancialData();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(dbReceiptsListProvider);
    final warrantiesAsync = ref.watch(dbWarrantiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: receiptsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Unable to load financial records: $err',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (receipts) {
            return warrantiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text('Error loading warranties: $err')),
              data: (warranties) {
                // Calculate authoritative financial overview
                final analyticsService = ref.read(financialAnalyticsServiceProvider);
                final overviewData = analyticsService.calculateOverview(
                  allReceipts: receipts,
                  allWarranties: warranties,
                  userBudgets: _budgets,
                  refunds: _refunds,
                  period: _selectedPeriod,
                  customRange: _customRange,
                );

                return Column(
                  children: [
                    // Header Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
                      child: _buildHeader(receipts),
                    ),

                    // Navigation Tab Bar (Overview, Categories, Transactions, Budgets, AI Insights)
                    _buildSegmentedTabBar(),

                    // Tab View Contents
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 1. OVERVIEW
                          AnalyticsOverviewTab(
                            data: overviewData,
                            selectedPeriod: _selectedPeriod,
                            onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
                            onOpenCalendar: () => _openSpendingCalendar(receipts),
                            onOpenExport: () => _openExportReports(receipts),
                            onEditBudget: () => _showAddEditBudgetDialog(
                              existing: _budgets.where((b) => b.isOverall).fold<AppBudget?>(null, (_, b) => b),
                            ),
                            goals: _goals,
                            recurring: _recurring,
                            onOpenGoals: () => _tabController.animateTo(3),
                            onOpenRecurring: () => _tabController.animateTo(3),
                          ),

                          // 2. CATEGORIES
                          AnalyticsCategoriesTab(
                            data: overviewData,
                            onReceiptTap: _openTransactionDetails,
                          ),

                          // 3. TRANSACTIONS
                          AnalyticsTransactionsTab(
                            data: overviewData,
                            onReceiptTap: _openTransactionDetails,
                            onAddManualExpense: _openAddManualExpense,
                          ),

                          // 4. BUDGETS & GOALS
                          AnalyticsBudgetsTab(
                            data: overviewData,
                            budgets: _budgets,
                            goals: _goals,
                            recurring: _recurring,
                            onAddBudget: () => _showAddEditBudgetDialog(),
                            onEditBudget: (b) => _showAddEditBudgetDialog(existing: b),
                            onDeleteBudget: (id) async {
                              final user = ref.read(firebaseAuthServiceProvider).currentUser;
                              if (user != null) {
                                await ref.read(financialPersistenceServiceProvider).deleteBudget(user.uid, id);
                                _loadUserFinancialData();
                              }
                            },
                            onAddGoal: () => _showAddEditGoalDialog(),
                            onEditGoal: (g) => _showAddEditGoalDialog(existing: g),
                            onDeleteGoal: (id) async {
                              final user = ref.read(firebaseAuthServiceProvider).currentUser;
                              if (user != null) {
                                await ref.read(financialPersistenceServiceProvider).deleteGoal(user.uid, id);
                                _loadUserFinancialData();
                              }
                            },
                            onAddRecurring: () => _showAddEditRecurringDialog(),
                            onToggleRecurring: (r) async {
                              final user = ref.read(firebaseAuthServiceProvider).currentUser;
                              if (user != null) {
                                await ref.read(financialPersistenceServiceProvider).saveRecurringExpense(user.uid, r);
                                _loadUserFinancialData();
                              }
                            },
                            onDeleteRecurring: (id) async {
                              final user = ref.read(firebaseAuthServiceProvider).currentUser;
                              if (user != null) {
                                await ref.read(financialPersistenceServiceProvider).deleteRecurringExpense(user.uid, id);
                                _loadUserFinancialData();
                              }
                            },
                          ),

                          // 5. AI INSIGHTS
                          AnalyticsAiInsightsTab(data: overviewData),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader(List<Map<String, dynamic>> receipts) {
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
                try {
                  StatefulNavigationShell.of(context).goBranch(4);
                } catch (_) {
                  context.push('/profile');
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Analytics',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Intelligence & expenditure control',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined, color: Colors.white70, size: 20),
              tooltip: 'Spending Calendar',
              onPressed: () => _openSpendingCalendar(receipts),
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined, color: Colors.white70, size: 20),
              tooltip: 'Export Financial Reports',
              onPressed: () => _openExportReports(receipts),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentedTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(
            icon: Icon(Icons.dashboard_outlined, size: 16),
            text: 'Overview',
          ),
          Tab(
            icon: Icon(Icons.pie_chart_outline, size: 16),
            text: 'Categories',
          ),
          Tab(
            icon: Icon(Icons.receipt_long_outlined, size: 16),
            text: 'Transactions',
          ),
          Tab(
            icon: Icon(Icons.savings_outlined, size: 16),
            text: 'Budgets & Goals',
          ),
          Tab(
            icon: Icon(Icons.auto_awesome, size: 16),
            text: 'AI Insights',
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'Log Expense',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: _openAddManualExpense,
      ),
    );
  }
}
