import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipto/features/analytics/domain/models/budget_model.dart';
import 'package:receipto/features/analytics/domain/models/savings_goal_model.dart';
import 'package:receipto/features/analytics/domain/models/recurring_expense_model.dart';
import 'package:receipto/features/analytics/domain/models/refund_model.dart';

final financialPersistenceServiceProvider = Provider<FinancialPersistenceService>((ref) {
  return FinancialPersistenceService();
});

class FinancialPersistenceService {
  // Key generators scoped by user UID for multi-user security
  String _budgetKey(String userId) => 'financial_budgets_$userId';
  String _goalKey(String userId) => 'financial_goals_$userId';
  String _recurringKey(String userId) => 'financial_recurring_$userId';
  String _refundKey(String userId) => 'financial_refunds_$userId';

  // ===================== BUDGETS =====================
  Future<List<AppBudget>> getBudgets(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_budgetKey(userId));
    if (raw == null || raw.isEmpty) {
      // Check legacy 'monthly_budget' key for backwards compatibility
      final legacy = prefs.getDouble('monthly_budget');
      if (legacy != null && legacy > 0) {
        final legacyBudget = AppBudget(
          id: 'overall_legacy',
          category: 'Overall',
          limitAmount: legacy,
          createdAt: DateTime.now(),
        );
        await saveBudget(userId, legacyBudget);
        return [legacyBudget];
      }
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => AppBudget.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBudget(String userId, AppBudget budget) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getBudgets(userId);
    final index = existing.indexWhere((b) => b.id == budget.id || (b.category.toLowerCase() == budget.category.toLowerCase()));
    if (index >= 0) {
      existing[index] = budget;
    } else {
      existing.add(budget);
    }
    final raw = jsonEncode(existing.map((b) => b.toJson()).toList());
    await prefs.setString(_budgetKey(userId), raw);

    // Keep legacy key synced if overall
    if (budget.isOverall) {
      await prefs.setDouble('monthly_budget', budget.limitAmount);
    }
  }

  Future<void> deleteBudget(String userId, String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getBudgets(userId);
    final target = existing.firstWhere((b) => b.id == budgetId, orElse: () => existing.first);
    existing.removeWhere((b) => b.id == budgetId);
    final raw = jsonEncode(existing.map((b) => b.toJson()).toList());
    await prefs.setString(_budgetKey(userId), raw);

    if (target.isOverall) {
      await prefs.remove('monthly_budget');
    }
  }

  // ===================== SAVINGS GOALS =====================
  Future<List<SavingsGoal>> getGoals(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_goalKey(userId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => SavingsGoal.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGoal(String userId, SavingsGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getGoals(userId);
    final index = existing.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      existing[index] = goal;
    } else {
      existing.add(goal);
    }
    final raw = jsonEncode(existing.map((g) => g.toJson()).toList());
    await prefs.setString(_goalKey(userId), raw);
  }

  Future<void> deleteGoal(String userId, String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getGoals(userId);
    existing.removeWhere((g) => g.id == goalId);
    final raw = jsonEncode(existing.map((g) => g.toJson()).toList());
    await prefs.setString(_goalKey(userId), raw);
  }

  // ===================== RECURRING EXPENSES =====================
  Future<List<RecurringExpense>> getRecurringExpenses(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recurringKey(userId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => RecurringExpense.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecurringExpense(String userId, RecurringExpense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getRecurringExpenses(userId);
    final index = existing.indexWhere((r) => r.id == expense.id);
    if (index >= 0) {
      existing[index] = expense;
    } else {
      existing.add(expense);
    }
    final raw = jsonEncode(existing.map((r) => r.toJson()).toList());
    await prefs.setString(_recurringKey(userId), raw);
  }

  Future<void> deleteRecurringExpense(String userId, String expenseId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getRecurringExpenses(userId);
    existing.removeWhere((r) => r.id == expenseId);
    final raw = jsonEncode(existing.map((r) => r.toJson()).toList());
    await prefs.setString(_recurringKey(userId), raw);
  }

  // ===================== REFUNDS =====================
  Future<List<ReceiptRefund>> getRefunds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_refundKey(userId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => ReceiptRefund.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRefund(String userId, ReceiptRefund refund) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getRefunds(userId);
    final index = existing.indexWhere((r) => r.id == refund.id);
    if (index >= 0) {
      existing[index] = refund;
    } else {
      existing.add(refund);
    }
    final raw = jsonEncode(existing.map((r) => r.toJson()).toList());
    await prefs.setString(_refundKey(userId), raw);
  }

  Future<void> deleteRefund(String userId, String refundId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getRefunds(userId);
    existing.removeWhere((r) => r.id == refundId);
    final raw = jsonEncode(existing.map((r) => r.toJson()).toList());
    await prefs.setString(_refundKey(userId), raw);
  }
}
