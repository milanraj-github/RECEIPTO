import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/date_formatter.dart';

class CustomDateRangeSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange> onApply;

  const CustomDateRangeSheet({
    super.key,
    this.initialRange,
    required this.onApply,
  });

  @override
  State<CustomDateRangeSheet> createState() => _CustomDateRangeSheetState();
}

class _CustomDateRangeSheetState extends State<CustomDateRangeSheet> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.initialRange != null) {
      _startDate = widget.initialRange!.start;
      _endDate = widget.initialRange!.end;
    } else {
      // Default to past 1 year
      _startDate = DateTime(now.year - 1, now.month, now.day);
      _endDate = now;
      _selectedPreset = 'Past 1 Year';
    }
  }

  void _applyPreset(String label, DateTime start, DateTime end) {
    setState(() {
      _selectedPreset = label;
      _startDate = start;
      _endDate = end;
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isAfter(_endDate) ? _endDate : _startDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: _endDate,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT START (FROM) DATE',
      confirmText: 'SET START',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
            dialogTheme: const DialogThemeData(backgroundColor: AppColors.cardSurface),
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.cardSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _selectedPreset = null;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT END (TO) DATE',
      confirmText: 'SET END',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
            dialogTheme: const DialogThemeData(backgroundColor: AppColors.cardSurface),
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.cardSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _selectedPreset = null;
      });
    }
  }

  String _formatDuration(DateTime start, DateTime end) {
    final days = end.difference(start).inDays.abs() + 1;
    if (days >= 365) {
      final years = (days / 365.25).floor();
      final remainingDays = days - (years * 365.25).floor();
      final months = (remainingDays / 30.4).floor();
      if (months > 0) {
        return '$years year${years > 1 ? "s" : ""}, $months month${months > 1 ? "s" : ""}';
      }
      return '$years year${years > 1 ? "s" : ""}';
    } else if (days >= 30) {
      final months = (days / 30.4).floor();
      return '$months month${months > 1 ? "s" : ""}';
    } else {
      return '$days day${days > 1 ? "s" : ""}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentYear = now.year;

    final presets = <Map<String, dynamic>>[
      {
        'label': 'Past 1 Year',
        'start': DateTime(now.year - 1, now.month, now.day),
        'end': now,
      },
      {
        'label': 'Past 3 Years',
        'start': DateTime(now.year - 3, now.month, now.day),
        'end': now,
      },
      {
        'label': 'Past 5 Years',
        'start': DateTime(now.year - 5, now.month, now.day),
        'end': now,
      },
      {
        'label': 'Past 10 Years',
        'start': DateTime(now.year - 10, now.month, now.day),
        'end': now,
      },
      {
        'label': '$currentYear (This Year)',
        'start': DateTime(currentYear, 1, 1),
        'end': DateTime(currentYear, 12, 31),
      },
      {
        'label': '${currentYear - 1}',
        'start': DateTime(currentYear - 1, 1, 1),
        'end': DateTime(currentYear - 1, 12, 31),
      },
      {
        'label': '${currentYear - 2}',
        'start': DateTime(currentYear - 2, 1, 1),
        'end': DateTime(currentYear - 2, 12, 31),
      },
      {
        'label': '${currentYear - 3}',
        'start': DateTime(currentYear - 3, 1, 1),
        'end': DateTime(currentYear - 3, 12, 31),
      },
      {
        'label': '${currentYear - 4}',
        'start': DateTime(currentYear - 4, 1, 1),
        'end': DateTime(currentYear - 4, 12, 31),
      },
      {
        'label': '${currentYear - 5}',
        'start': DateTime(currentYear - 5, 1, 1),
        'end': DateTime(currentYear - 5, 12, 31),
      },
      {
        'label': 'All Time (2015 - Now)',
        'start': DateTime(2015, 1, 1),
        'end': now,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.date_range_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Date Range',
                            style: GoogleFonts.hankenGrotesk(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tap any date to select past years easily',
                            style: GoogleFonts.inter(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick 1-Tap Presets
              Text(
                'QUICK TIMEFRAME PRESETS',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = presets[index];
                    final label = item['label'] as String;
                    final isSelected = _selectedPreset == label;
                    return ActionChip(
                      label: Text(
                        label,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      backgroundColor: isSelected ? AppColors.primary : AppColors.cardSurface,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      onPressed: () {
                        _applyPreset(label, item['start'] as DateTime, item['end'] as DateTime);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // Date Selection Cards (From & To)
              Text(
                'CUSTOM DATE RANGE',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // FROM DATE CARD
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickStartDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'FROM (START)',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                DateFormatter.formatDate(_startDate),
                                style: GoogleFonts.hankenGrotesk(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to change year/date',
                              style: GoogleFonts.inter(
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 20),
                  ),

                  // TO DATE CARD
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickEndDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_available_outlined, size: 12, color: AppColors.tertiary),
                                const SizedBox(width: 6),
                                Text(
                                  'TO (END)',
                                  style: GoogleFonts.inter(
                                    color: AppColors.tertiary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                DateFormatter.formatDate(_endDate),
                                style: GoogleFonts.hankenGrotesk(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to change year/date',
                              style: GoogleFonts.inter(
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Duration Summary Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timelapse_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Timespan: ${_formatDuration(_startDate, _endDate)} (${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year})',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        final range = DateTimeRange(
                          start: _startDate.isAfter(_endDate) ? _endDate : _startDate,
                          end: _startDate.isAfter(_endDate) ? _startDate : _endDate,
                        );
                        widget.onApply(range);
                      },
                      child: Text(
                        'Apply Date Range',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
