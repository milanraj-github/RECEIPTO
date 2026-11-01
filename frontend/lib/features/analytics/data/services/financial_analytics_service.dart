import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/core/services/ai_categorizer_service.dart';
import 'package:receipto/core/services/currency_converter_service.dart';
import 'package:receipto/features/analytics/domain/models/financial_filter.dart';
import 'package:receipto/features/analytics/domain/models/financial_overview_data.dart';
import 'package:receipto/features/analytics/domain/models/budget_model.dart';
import 'package:receipto/features/analytics/domain/models/refund_model.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

final financialAnalyticsServiceProvider = Provider<FinancialAnalyticsService>((ref) {
  final categorizer = ref.read(aiCategorizerServiceProvider);
  return FinancialAnalyticsService(categorizer);
});

class FinancialAnalyticsService {
  final AICategorizerService _categorizer;

  FinancialAnalyticsService(this._categorizer);

  /// Robust date parser for receipts
  DateTime? parseReceiptDate(Map<String, dynamic> r) {
    final rawDate = r['date']?.toString().trim();
    if (rawDate != null && rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) return parsed;

      // Handle DD/MM/YYYY or DD-MM-YYYY
      final parts = rawDate.split(RegExp(r'[/.-]'));
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) return DateTime(y, m, d);
        } else if (parts[2].length == 4) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            if (m > 12 && d <= 12) return DateTime(y, d, m);
            return DateTime(y, m, d);
          }
        }
      }
    }

    final rawCreated = r['created_at']?.toString().trim();
    if (rawCreated != null && rawCreated.isNotEmpty) {
      final parsed = DateTime.tryParse(rawCreated);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Categorize an item as Essential vs Discretionary
  bool isEssentialCategory(String category) {
    final lower = category.trim().toLowerCase();
    return lower == 'groceries' ||
        lower == 'grocery' ||
        lower == 'healthcare' ||
        lower == 'medical' ||
        lower == 'pharmacy' ||
        lower == 'utilities' ||
        lower == 'fuel' ||
        lower == 'education';
  }

  /// Calculates authoritative financial overview data for a given period
  FinancialOverviewData calculateOverview({
    required List<Map<String, dynamic>> allReceipts,
    required List<WarrantyModel> allWarranties,
    required List<AppBudget> userBudgets,
    required List<ReceiptRefund> refunds,
    required FinancialPeriod period,
    DateTimeRange? customRange,
  }) {
    final now = DateTime.now();
    final effectiveRange = period.getDateRange(now, customRange: customRange);

    // 1. Overall budget resolution
    final overallBudgetModel = userBudgets.where((b) => b.isOverall).fold<AppBudget?>(
          null,
          (prev, curr) => curr,
        );
    final double? overallBudget = overallBudgetModel?.limitAmount;

    // 2. Filter receipts strictly inside effectiveRange
    final List<Map<String, dynamic>> filteredReceipts = [];
    final List<Map<String, dynamic>> previousPeriodReceipts = [];

    // Calculate equivalent comparison range (same duration immediately preceding)
    final Duration rangeDuration = effectiveRange.end.difference(effectiveRange.start);
    final DateTime compStart = effectiveRange.start.subtract(rangeDuration);
    final DateTime compEnd = effectiveRange.start.subtract(const Duration(milliseconds: 1));

    for (final r in allReceipts) {
      final rDate = parseReceiptDate(r);
      if (rDate == null) continue;

      if (!rDate.isBefore(effectiveRange.start) && !rDate.isAfter(effectiveRange.end)) {
        filteredReceipts.add(r);
      } else if (!rDate.isBefore(compStart) && !rDate.isAfter(compEnd)) {
        previousPeriodReceipts.add(r);
      }
    }

    // 3. Primary Accounting Aggregations
    double grossSpending = 0.0;
    double totalSaved = 0.0;
    final Map<String, double> categorySpendMap = {};
    final Map<String, int> categoryCountMap = {};
    final Map<String, double> merchantSpendMap = {};
    final Map<String, int> merchantCountMap = {};
    final Map<String, double> paymentMethodMap = {};
    final Map<String, _ProductAccumulator> productMap = {};

    double essentialSpending = 0.0;
    double discretionarySpending = 0.0;

    for (final r in filteredReceipts) {
      final String cur = (r['currency'] as String?) ?? '₹';
      final double rawAmt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
      final double amt = CurrencyConverterService.convertToInr(rawAmt, currency: cur);
      final double rawDisc = ReceiptModel.parseDouble(r['discount']) ?? 0.0;
      final double disc = CurrencyConverterService.convertToInr(rawDisc, currency: cur);

      // Primary accounting: Each receipt contributes to gross spending exactly once
      grossSpending += amt;
      totalSaved += disc;

      // Merchant
      final String merchant = (r['merchant_name'] as String?)?.trim() ?? 'Unknown Merchant';
      merchantSpendMap[merchant] = (merchantSpendMap[merchant] ?? 0.0) + amt;
      merchantCountMap[merchant] = (merchantCountMap[merchant] ?? 0) + 1;

      // Payment Method
      final String rawPay = (r['payment_method'] as String?)?.trim() ?? 'Other';
      final String paymentMethod = _normalizePaymentMethod(rawPay);
      paymentMethodMap[paymentMethod] = (paymentMethodMap[paymentMethod] ?? 0.0) + amt;

      // Category handling (Accounting Rule: line-items if reliable, otherwise receipt category)
      final rawCategory = (r['category'] as String?)?.trim() ?? 'Others';
      final category = _categorizer.resolveSupportedCategory(rawCategory);

      final lineItems = (r['receipt_items'] as List<dynamic>?) ?? [];
      if (lineItems.isNotEmpty) {
        // Line items available: accumulate product intelligence
        for (final item in lineItems) {
          final String pName = (item['name'] as String?)?.trim() ?? 'Item';
          final double rawPrice = ReceiptModel.parseDouble(item['total_price']) ??
              ReceiptModel.parseDouble(item['price']) ??
              0.0;
          final double pPrice = CurrencyConverterService.convertToInr(rawPrice, currency: cur);
          final int pQty = (item['quantity'] as num?)?.toInt() ?? 1;

          if (pName.isNotEmpty && pPrice > 0) {
            final key = pName.toLowerCase();
            final acc = productMap[key] ??
                _ProductAccumulator(
                  name: pName,
                  totalPrice: 0.0,
                  totalCount: 0,
                  category: category,
                );
            acc.totalPrice += pPrice;
            acc.totalCount += pQty;
            productMap[key] = acc;
          }
        }
      }

      // Aggregate category totals
      categorySpendMap[category] = (categorySpendMap[category] ?? 0.0) + amt;
      categoryCountMap[category] = (categoryCountMap[category] ?? 0) + 1;

      if (isEssentialCategory(category)) {
        essentialSpending += amt;
      } else {
        discretionarySpending += amt;
      }
    }

    // 4. Refunds in this period
    double totalRefunds = 0.0;
    for (final ref in refunds) {
      if (!ref.refundDate.isBefore(effectiveRange.start) && !ref.refundDate.isAfter(effectiveRange.end)) {
        totalRefunds += ref.refundAmount;
      }
    }
    final double netSpending = (grossSpending - totalRefunds).clamp(0.0, double.infinity);

    // 5. Comparison period calculation
    double previousPeriodSpend = 0.0;
    for (final r in previousPeriodReceipts) {
      final String cur = (r['currency'] as String?) ?? '₹';
      final double rawAmt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
      previousPeriodSpend += CurrencyConverterService.convertToInr(rawAmt, currency: cur);
    }

    double? comparisonPercentageChange;
    if (previousPeriodSpend > 0.0) {
      comparisonPercentageChange = ((grossSpending - previousPeriodSpend) / previousPeriodSpend) * 100;
    }

    final String comparisonPeriodLabel = period == FinancialPeriod.thisMonth
        ? 'vs Last Month'
        : period == FinancialPeriod.thisWeek
            ? 'vs Last Week'
            : 'vs Prior Equivalent Period';

    // 6. Top Category & Top Merchant
    String topCategory = 'None';
    double topCategorySpend = 0.0;
    if (categorySpendMap.isNotEmpty) {
      final sortedCats = categorySpendMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sortedCats.first.key;
      topCategorySpend = sortedCats.first.value;
    }

    String topMerchant = 'None';
    double topMerchantSpend = 0.0;
    final List<MerchantStat> topMerchants = [];
    merchantSpendMap.forEach((mName, mSpend) {
      final count = merchantCountMap[mName] ?? 1;
      topMerchants.add(MerchantStat(
        name: mName,
        totalSpending: mSpend,
        purchaseCount: count,
        averageSpend: count > 0 ? mSpend / count : mSpend,
      ));
    });
    topMerchants.sort((a, b) => b.totalSpending.compareTo(a.totalSpending));
    if (topMerchants.isNotEmpty) {
      topMerchant = topMerchants.first.name;
      topMerchantSpend = topMerchants.first.totalSpending;
    }

    // 7. Top Products
    final List<ProductStat> topProducts = productMap.values.map((acc) {
      return ProductStat(
        name: acc.name,
        totalSpending: acc.totalPrice,
        purchaseCount: acc.totalCount,
        averagePrice: acc.totalCount > 0 ? acc.totalPrice / acc.totalCount : acc.totalPrice,
        category: acc.category,
      );
    }).toList();
    topProducts.sort((a, b) => b.totalSpending.compareTo(a.totalSpending));

    // 8. Weekly Day Totals (Mon-Sun for current calendar week)
    final List<double> weeklyDayTotals = List.filled(7, 0.0);
    final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(mondayThisWeek.year, mondayThisWeek.month, mondayThisWeek.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    for (final r in allReceipts) {
      final rDate = parseReceiptDate(r);
      if (rDate != null && !rDate.isBefore(startOfWeek) && rDate.isBefore(endOfWeek)) {
        final double amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
        final int dayIdx = rDate.weekday - 1; // 0 = Mon, 6 = Sun
        if (dayIdx >= 0 && dayIdx < 7) {
          weeklyDayTotals[dayIdx] += amt;
        }
      }
    }

    // 9. Monthly Trends (Last 6 Calendar Months)
    final List<MonthlyTrendPoint> monthlyTrends = [];
    final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (int i = 5; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      double mTotal = 0.0;
      for (final r in allReceipts) {
        final rDate = parseReceiptDate(r);
        if (rDate != null && !rDate.isBefore(targetMonth) && rDate.isBefore(nextMonth)) {
          mTotal += ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
        }
      }
      monthlyTrends.add(MonthlyTrendPoint(
        monthLabel: monthNames[targetMonth.month - 1],
        amount: mTotal,
        monthDate: targetMonth,
      ));
    }

    // 10. Month-End Forecasting
    final daysElapsed = now.day;
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final double currentMonthSpend = monthlyTrends.isNotEmpty ? monthlyTrends.last.amount : 0.0;
    final double dailyAverageSpend = daysElapsed > 0 ? currentMonthSpend / daysElapsed : currentMonthSpend;
    final double projectedMonthEndSpend = dailyAverageSpend * totalDaysInMonth;

    double? projectedBudgetOverrun;
    String forecastExplanation = 'Based on $daysElapsed days of observed daily spending (${dailyAverageSpend.toStringAsFixed(0)}/day) across $totalDaysInMonth total calendar days.';
    if (overallBudget != null && overallBudget > 0) {
      if (projectedMonthEndSpend > overallBudget) {
        projectedBudgetOverrun = projectedMonthEndSpend - overallBudget;
        forecastExplanation += ' Projected to exceed monthly budget limit by ${projectedBudgetOverrun.toStringAsFixed(0)}.';
      } else {
        forecastExplanation += ' On track to remain within your budget limit.';
      }
    }

    // 11. Budget Consumption
    final double budgetRemaining = overallBudget != null
        ? (overallBudget - currentMonthSpend).clamp(0.0, double.infinity)
        : 0.0;
    final double budgetUsedPercentage = overallBudget != null && overallBudget > 0
        ? ((currentMonthSpend / overallBudget) * 100).clamp(0.0, 100.0)
        : 0.0;

    // 12. Duplicate Detection (same merchant, same date, same amount)
    final List<Map<String, dynamic>> possibleDuplicates = [];
    final Map<String, List<Map<String, dynamic>>> dupGroups = {};
    for (final r in filteredReceipts) {
      final merchant = (r['merchant_name'] as String?)?.trim().toLowerCase() ?? '';
      final date = (r['date'] as String?)?.trim() ?? '';
      final amt = (ReceiptModel.parseDouble(r['grand_total']) ?? 0.0).toStringAsFixed(2);
      if (merchant.isNotEmpty && date.isNotEmpty && amt != '0.00') {
        final key = '$merchant|$date|$amt';
        dupGroups[key] = (dupGroups[key] ?? [])..add(r);
      }
    }
    dupGroups.forEach((key, list) {
      if (list.length > 1) {
        possibleDuplicates.addAll(list);
      }
    });

    // 13. Warranties metrics
    final protectedProductsCount = allWarranties.length;
    final activeWarrantiesCount = allWarranties.where((w) => w.status == 'ACTIVE').length;
    final expiringSoonCount = allWarranties.where((w) => w.status == 'EXPIRING SOON').length;

    // Averages
    final int count = filteredReceipts.length;
    final int elapsedRangeDays = math.max(1, effectiveRange.end.difference(effectiveRange.start).inDays + 1);
    final double avgDailySpend = netSpending / elapsedRangeDays;
    final double avgTransactionValue = count > 0 ? netSpending / count : 0.0;

    return FinancialOverviewData(
      selectedPeriod: period,
      effectiveRange: effectiveRange,
      totalSpending: grossSpending,
      totalSaved: totalSaved,
      totalRefunds: totalRefunds,
      netSpending: netSpending,
      transactionCount: count,
      avgDailySpend: avgDailySpend,
      avgTransactionValue: avgTransactionValue,
      overallBudget: overallBudget,
      budgetRemaining: budgetRemaining,
      budgetUsedPercentage: budgetUsedPercentage,
      comparisonPercentageChange: comparisonPercentageChange,
      comparisonPeriodLabel: comparisonPeriodLabel,
      topCategory: topCategory,
      topCategorySpend: topCategorySpend,
      categoryTotals: categorySpendMap,
      categoryTransactionCounts: categoryCountMap,
      essentialSpending: essentialSpending,
      discretionarySpending: discretionarySpending,
      topMerchant: topMerchant,
      topMerchantSpend: topMerchantSpend,
      topMerchants: topMerchants,
      topProducts: topProducts,
      weeklyDayTotals: weeklyDayTotals,
      monthlyTrends: monthlyTrends,
      paymentMethodTotals: paymentMethodMap,
      projectedMonthEndSpend: projectedMonthEndSpend,
      projectedBudgetOverrun: projectedBudgetOverrun,
      daysElapsedInMonth: daysElapsed,
      totalDaysInMonth: totalDaysInMonth,
      forecastExplanation: forecastExplanation,
      possibleDuplicates: possibleDuplicates,
      filteredReceipts: filteredReceipts,
      protectedProductsCount: protectedProductsCount,
      activeWarrantiesCount: activeWarrantiesCount,
      expiringSoonCount: expiringSoonCount,
    );
  }

  String _normalizePaymentMethod(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('upi') || lower.contains('gpay') || lower.contains('phonepe') || lower.contains('paytm')) {
      return 'UPI';
    }
    if (lower.contains('credit') || lower.contains('mastercard') || lower.contains('visa')) {
      return 'Credit Card';
    }
    if (lower.contains('debit')) {
      return 'Debit Card';
    }
    if (lower.contains('cash')) {
      return 'Cash';
    }
    if (lower.contains('net') || lower.contains('bank')) {
      return 'Net Banking';
    }
    if (lower.contains('wallet')) {
      return 'Wallet';
    }
    return 'Other';
  }
}

class _ProductAccumulator {
  final String name;
  double totalPrice;
  int totalCount;
  final String category;

  _ProductAccumulator({
    required this.name,
    required this.totalPrice,
    required this.totalCount,
    required this.category,
  });
}
