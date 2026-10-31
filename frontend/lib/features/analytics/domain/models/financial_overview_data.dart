import 'package:flutter/material.dart';
import 'package:receipto/features/analytics/domain/models/financial_filter.dart';

class MerchantStat {
  final String name;
  final double totalSpending;
  final int purchaseCount;
  final double averageSpend;

  const MerchantStat({
    required this.name,
    required this.totalSpending,
    required this.purchaseCount,
    required this.averageSpend,
  });
}

class ProductStat {
  final String name;
  final double totalSpending;
  final int purchaseCount;
  final double averagePrice;
  final String category;

  const ProductStat({
    required this.name,
    required this.totalSpending,
    required this.purchaseCount,
    required this.averagePrice,
    required this.category,
  });
}

class MonthlyTrendPoint {
  final String monthLabel;
  final double amount;
  final DateTime monthDate;

  const MonthlyTrendPoint({
    required this.monthLabel,
    required this.amount,
    required this.monthDate,
  });
}

class FinancialOverviewData {
  final FinancialPeriod selectedPeriod;
  final DateTimeRange effectiveRange;

  // Primary Accounting Totals
  final double totalSpending;
  final double totalSaved;
  final double totalRefunds;
  final double netSpending;
  final int transactionCount;
  final double avgDailySpend;
  final double avgTransactionValue;

  // Budget Metrics
  final double? overallBudget;
  final double budgetRemaining;
  final double budgetUsedPercentage;

  // Comparison Metrics
  final double? comparisonPercentageChange;
  final String comparisonPeriodLabel;

  // Categorization
  final String topCategory;
  final double topCategorySpend;
  final Map<String, double> categoryTotals;
  final Map<String, int> categoryTransactionCounts;
  final double essentialSpending;
  final double discretionarySpending;

  // Merchant Intelligence
  final String topMerchant;
  final double topMerchantSpend;
  final List<MerchantStat> topMerchants;

  // Product Intelligence
  final List<ProductStat> topProducts;

  // Trends
  final List<double> weeklyDayTotals; // 7 days Mon-Sun
  final List<MonthlyTrendPoint> monthlyTrends; // 6 months

  // Payment Methods
  final Map<String, double> paymentMethodTotals;

  // Forecasting
  final double projectedMonthEndSpend;
  final double? projectedBudgetOverrun;
  final int daysElapsedInMonth;
  final int totalDaysInMonth;
  final String forecastExplanation;

  // Duplicate Transactions
  final List<Map<String, dynamic>> possibleDuplicates;

  // Filtered Source Transactions
  final List<Map<String, dynamic>> filteredReceipts;

  // Warranty Highlights
  final int protectedProductsCount;
  final int activeWarrantiesCount;
  final int expiringSoonCount;

  const FinancialOverviewData({
    required this.selectedPeriod,
    required this.effectiveRange,
    required this.totalSpending,
    required this.totalSaved,
    required this.totalRefunds,
    required this.netSpending,
    required this.transactionCount,
    required this.avgDailySpend,
    required this.avgTransactionValue,
    this.overallBudget,
    required this.budgetRemaining,
    required this.budgetUsedPercentage,
    this.comparisonPercentageChange,
    required this.comparisonPeriodLabel,
    required this.topCategory,
    required this.topCategorySpend,
    required this.categoryTotals,
    required this.categoryTransactionCounts,
    required this.essentialSpending,
    required this.discretionarySpending,
    required this.topMerchant,
    required this.topMerchantSpend,
    required this.topMerchants,
    required this.topProducts,
    required this.weeklyDayTotals,
    required this.monthlyTrends,
    required this.paymentMethodTotals,
    required this.projectedMonthEndSpend,
    this.projectedBudgetOverrun,
    required this.daysElapsedInMonth,
    required this.totalDaysInMonth,
    required this.forecastExplanation,
    required this.possibleDuplicates,
    required this.filteredReceipts,
    required this.protectedProductsCount,
    required this.activeWarrantiesCount,
    required this.expiringSoonCount,
  });
}
