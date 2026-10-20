import 'package:flutter/material.dart';

enum FinancialPeriod {
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  thisYear,
  custom,
}

extension FinancialPeriodExtension on FinancialPeriod {
  String get label {
    switch (this) {
      case FinancialPeriod.thisWeek:
        return 'This Week';
      case FinancialPeriod.thisMonth:
        return 'This Month';
      case FinancialPeriod.lastMonth:
        return 'Last Month';
      case FinancialPeriod.last3Months:
        return 'Last 3M';
      case FinancialPeriod.last6Months:
        return 'Last 6M';
      case FinancialPeriod.thisYear:
        return 'This Year';
      case FinancialPeriod.custom:
        return 'Custom';
    }
  }

  DateTimeRange getDateRange(DateTime now, {DateTimeRange? customRange}) {
    if (this == FinancialPeriod.custom && customRange != null) {
      return customRange;
    }

    switch (this) {
      case FinancialPeriod.thisWeek:
        final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
        final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));
        final end = DateTime(start.year, start.month, start.day).add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);

      case FinancialPeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);

      case FinancialPeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);

      case FinancialPeriod.last3Months:
        final start = DateTime(now.year, now.month - 2, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);

      case FinancialPeriod.last6Months:
        final start = DateTime(now.year, now.month - 5, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);

      case FinancialPeriod.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year + 1, 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);

      case FinancialPeriod.custom:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
    }
  }
}
