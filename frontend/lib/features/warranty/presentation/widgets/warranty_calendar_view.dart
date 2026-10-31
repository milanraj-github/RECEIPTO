import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

class WarrantyCalendarView extends StatefulWidget {
  final List<WarrantyModel> warranties;

  const WarrantyCalendarView({
    super.key,
    required this.warranties,
  });

  @override
  State<WarrantyCalendarView> createState() => _WarrantyCalendarViewState();
}

class _WarrantyCalendarViewState extends State<WarrantyCalendarView> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  List<WarrantyModel> _getWarrantiesForDate(DateTime date) {
    final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return widget.warranties.where((w) {
      final exp = w.expiryDate.split('T').first.trim();
      return exp == dateStr;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.greenAccent;
      case 'EXPIRING SOON':
      case 'EXPIRING_SOON':
        return Colors.orangeAccent;
      case 'EXPIRED':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // 1 (Monday) .. 7 (Sunday)
    final firstWeekday = _focusedMonth.weekday;
    final totalGridCells = (daysInMonth + firstWeekday - 1);
    final rowCount = (totalGridCells / 7).ceil();

    final selectedDateWarranties = _getWarrantiesForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Month Navigation Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: GlassCard(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  onPressed: _previousMonth,
                  tooltip: 'Previous Month',
                ),
                GestureDetector(
                  onTap: _jumpToToday,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Today',
                          style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  onPressed: _nextMonth,
                  tooltip: 'Next Month',
                ),
              ],
            ),
          ),
        ),

        // 2. Weekday Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays.map((d) {
              return SizedBox(
                width: 38,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // 3. Monthly Days Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GlassCard(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.95,
              ),
              itemCount: rowCount * 7,
              itemBuilder: (context, index) {
                final dayOffset = index - (firstWeekday - 1);
                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                  return const SizedBox.shrink();
                }

                final dayNumber = dayOffset + 1;
                final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                final isSelected = cellDate.year == _selectedDate.year &&
                    cellDate.month == _selectedDate.month &&
                    cellDate.day == _selectedDate.day;

                final now = DateTime.now();
                final isToday = cellDate.year == now.year &&
                    cellDate.month == now.month &&
                    cellDate.day == now.day;

                final dayWarranties = _getWarrantiesForDate(cellDate);
                final hasWarranties = dayWarranties.isNotEmpty;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : isToday
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : isToday
                                ? AppColors.secondary.withValues(alpha: 0.6)
                                : Colors.transparent,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.secondary
                                    : Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (hasWarranties)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayWarranties.take(3).map((w) {
                              final color = _getStatusColor(w.status);
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              );
                            }).toList(),
                          )
                        else
                          const SizedBox(height: 5),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Selected Date Details Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
                style: GoogleFonts.hankenGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedDateWarranties.isNotEmpty
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedDateWarranties.length} ${selectedDateWarranties.length == 1 ? 'Expiry' : 'Expirations'}',
                  style: GoogleFonts.inter(
                    color: selectedDateWarranties.isNotEmpty ? AppColors.primary : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 5. Warranties list for selected date
        if (selectedDateWarranties.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GlassCard(
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_outlined, color: Colors.white.withValues(alpha: 0.4), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'No warranties expiring on this date',
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
            itemCount: selectedDateWarranties.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final item = selectedDateWarranties[idx];
              final statusColor = _getStatusColor(item.status);
              final daysRemaining = WarrantyUtils.calculateDaysRemaining(item.expiryDate);

              return InkWell(
                onTap: () {
                  if (item.id != null && item.id!.isNotEmpty) {
                    context.push('/receipts/warranty/${item.id}');
                  } else if (item.receiptId != null && item.receiptId!.isNotEmpty) {
                    context.push('/receipts/details/${item.receiptId}');
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: GlassCard(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.verified_user_outlined, color: statusColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: GoogleFonts.hankenGrotesk(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.merchantName} • ${item.warrantyPeriod} ${item.warrantyUnit}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              item.status,
                              style: GoogleFonts.inter(
                                color: statusColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.status == 'EXPIRED'
                                ? 'Expired'
                                : '$daysRemaining days left',
                            style: GoogleFonts.inter(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
