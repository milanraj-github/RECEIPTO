import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipto/core/services/ai_categorizer_service.dart';
import 'package:receipto/features/analytics/data/services/financial_analytics_service.dart';
import 'package:receipto/features/analytics/domain/models/budget_model.dart';
import 'package:receipto/features/analytics/domain/models/financial_filter.dart';
import 'package:receipto/features/analytics/domain/models/refund_model.dart';

void main() {
  late FinancialAnalyticsService analyticsService;
  late AICategorizerService categorizerService;

  setUp(() {
    categorizerService = AICategorizerService();
    analyticsService = FinancialAnalyticsService(categorizerService);
  });

  group('Financial Analytics Accounting & Aggregation Rules', () {
    test('Calculates gross spending, discounts, and net spending correctly with refunds', () {
      final sampleReceipts = [
        {
          'id': '101',
          'merchant_name': 'Supermarket A',
          'date': '2026-10-15',
          'grand_total': '2500.00',
          'discount': '150.00',
          'category': 'Groceries',
          'payment_method': 'UPI',
        },
        {
          'id': '102',
          'merchant_name': 'Electronics Store',
          'date': '2026-10-18',
          'grand_total': '15000.00',
          'discount': '0.00',
          'category': 'Electronics',
          'payment_method': 'Credit Card',
        },
      ];

      final sampleRefunds = [
        ReceiptRefund(
          id: 'ref_1',
          receiptId: '101',
          merchant: 'Supermarket A',
          originalAmount: 2500.00,
          refundAmount: 500.00,
          refundDate: DateTime(2026, 10, 16),
          createdAt: DateTime(2026, 10, 16),
        ),
      ];

      final result = analyticsService.calculateOverview(
        allReceipts: sampleReceipts,
        allWarranties: [],
        userBudgets: [],
        refunds: sampleRefunds,
        period: FinancialPeriod.custom,
        customRange: DateTimeRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 31, 23, 59, 59),
        ),
      );

      // Gross total: 2500 + 15000 = 17500
      expect(result.totalSpending, 17500.00);
      // Discounts: 150
      expect(result.totalSaved, 150.00);
      // Refunds: 500
      expect(result.totalRefunds, 500.00);
      // Net spend: 17500 - 500 = 17000
      expect(result.netSpending, 17000.00);
      // Transaction count: 2
      expect(result.transactionCount, 2);
    });

    test('Identifies essential vs discretionary categories accurately', () {
      expect(analyticsService.isEssentialCategory('Groceries'), isTrue);
      expect(analyticsService.isEssentialCategory('Healthcare'), isTrue);
      expect(analyticsService.isEssentialCategory('Utilities'), isTrue);
      expect(analyticsService.isEssentialCategory('Fuel'), isTrue);
      expect(analyticsService.isEssentialCategory('Electronics'), isFalse);
      expect(analyticsService.isEssentialCategory('Entertainment'), isFalse);
      expect(analyticsService.isEssentialCategory('Shopping'), isFalse);
    });

    test('Forecasting correctly extrapolates daily average across full calendar month', () {
      final sampleReceipts = [
        {
          'id': '201',
          'merchant_name': 'Cafe',
          'date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-02',
          'grand_total': '1000.00',
          'category': 'Food & Dining',
        },
      ];

      final result = analyticsService.calculateOverview(
        allReceipts: sampleReceipts,
        allWarranties: [],
        userBudgets: [
          AppBudget(
            id: 'b1',
            category: 'Overall',
            limitAmount: 5000.00,
            createdAt: DateTime.now(),
          ),
        ],
        refunds: [],
        period: FinancialPeriod.thisMonth,
      );

      final now = DateTime.now();
      final totalDays = DateTime(now.year, now.month + 1, 0).day;
      final expectedDailyAvg = 1000.0 / now.day;
      final expectedProjected = expectedDailyAvg * totalDays;

      expect(result.projectedMonthEndSpend, closeTo(expectedProjected, 0.01));
    });

    test('Detects duplicate candidates with identical merchant, date, and amount', () {
      final sampleReceipts = [
        {
          'id': '301',
          'merchant_name': 'Starbucks',
          'date': '2026-10-10',
          'grand_total': '450.00',
          'category': 'Food & Dining',
        },
        {
          'id': '302',
          'merchant_name': 'Starbucks',
          'date': '2026-10-10',
          'grand_total': '450.00',
          'category': 'Food & Dining',
        },
        {
          'id': '303',
          'merchant_name': 'Bookstore',
          'date': '2026-10-10',
          'grand_total': '900.00',
          'category': 'Shopping',
        },
      ];

      final result = analyticsService.calculateOverview(
        allReceipts: sampleReceipts,
        allWarranties: [],
        userBudgets: [],
        refunds: [],
        period: FinancialPeriod.custom,
        customRange: DateTimeRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 31),
        ),
      );

      // Receipts 301 and 302 should be detected as possible duplicates
      expect(result.possibleDuplicates.length, 2);
      expect(result.possibleDuplicates.any((r) => r['id'] == '301'), isTrue);
      expect(result.possibleDuplicates.any((r) => r['id'] == '302'), isTrue);
      expect(result.possibleDuplicates.any((r) => r['id'] == '303'), isFalse);
    });
  });
}
