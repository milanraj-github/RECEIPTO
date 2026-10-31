import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';

class SpendingCalendarSheet extends StatefulWidget {
  final List<Map<String, dynamic>> allReceipts;

  const SpendingCalendarSheet({
    super.key,
    required this.allReceipts,
  });

  @override
  State<SpendingCalendarSheet> createState() => _SpendingCalendarSheetState();
}

class _SpendingCalendarSheetState extends State<SpendingCalendarSheet> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  DateTime? _parseDate(Map<String, dynamic> r) {
    final rawDate = r['date']?.toString().trim();
    if (rawDate != null && rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) return parsed;
    }
    final rawCreated = r['created_at']?.toString().trim();
    if (rawCreated != null && rawCreated.isNotEmpty) {
      return DateTime.tryParse(rawCreated);
    }
    return null;
  }

  Map<int, double> _getDailySpendingForMonth(DateTime month) {
    final Map<int, double> map = {};
    for (final r in widget.allReceipts) {
      final d = _parseDate(r);
      if (d != null && d.year == month.year && d.month == month.month) {
        final amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
        map[d.day] = (map[d.day] ?? 0.0) + amt;
      }
    }
    return map;
  }

  List<Map<String, dynamic>> _getReceiptsForDate(DateTime date) {
    return widget.allReceipts.where((r) {
      final d = _parseDate(r);
      return d != null && d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dailyMap = _getDailySpendingForMonth(_currentMonth);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1=Mon, 7=Sun

    final selectedReceipts = _selectedDate != null ? _getReceiptsForDate(_selectedDate!) : <Map<String, dynamic>>[];
    final selectedDayTotal = _selectedDate != null ? (dailyMap[_selectedDate!.day] ?? 0.0) : 0.0;

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending Calendar',
                      style: GoogleFonts.hankenGrotesk(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Daily expense activity breakdown',
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Month selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                      _selectedDate = null;
                    });
                  },
                ),
                Text(
                  '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: GoogleFonts.hankenGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                      _selectedDate = null;
                    });
                  },
                ),
              ],
            ),
          ),

          // Days of week header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                return SizedBox(
                  width: 38,
                  child: Center(
                    child: Text(
                      day,
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42, // 6 weeks
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - (firstWeekday - 2);
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final thisDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == thisDate.year &&
                    _selectedDate!.month == thisDate.month &&
                    _selectedDate!.day == thisDate.day;
                final spend = dailyMap[dayNumber] ?? 0.0;
                final hasSpending = spend > 0;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = thisDate;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : hasSpending
                              ? AppColors.cardSurface
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : hasSpending
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            fontSize: 13,
                            fontWeight: isSelected || hasSpending ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (hasSpending) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),

          // Selected date transactions preview
          Expanded(
            child: _selectedDate == null
                ? Center(
                    child: Text(
                      'Tap a date above to view purchases',
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                    ),
                  )
                : selectedReceipts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_busy, color: AppColors.onSurfaceVariant, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'No purchases on ${_selectedDate!.day} ${monthNames[_selectedDate!.month - 1]}',
                              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: selectedReceipts.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          if (idx == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_selectedDate!.day} ${monthNames[_selectedDate!.month - 1]} Purchases',
                                    style: GoogleFonts.hankenGrotesk(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(selectedDayTotal),
                                    style: GoogleFonts.hankenGrotesk(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final r = selectedReceipts[idx - 1];
                          final merchant = r['merchant_name'] as String? ?? 'Merchant';
                          final category = r['category'] as String? ?? 'Other';
                          final amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;

                          return GlassCard(
                            borderRadius: AppRadius.md,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                  child: const Icon(Icons.receipt_outlined, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        merchant,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        category,
                                        style: GoogleFonts.inter(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(amt),
                                  style: GoogleFonts.hankenGrotesk(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  );
  }
}
