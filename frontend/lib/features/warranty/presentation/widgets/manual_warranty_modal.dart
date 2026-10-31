import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';

class ManualWarrantySelection {
  final ReceiptItemModel item;
  final bool isEnabled;
  final int period;
  final String unit;
  final String expiryDate;

  ManualWarrantySelection({
    required this.item,
    required this.isEnabled,
    required this.period,
    required this.unit,
    required this.expiryDate,
  });
}

class ManualWarrantyModal extends StatefulWidget {
  final List<ReceiptItemModel> eligibleItems;
  final String purchaseDate;
  final String merchantName;
  final Function(List<ManualWarrantySelection> selections) onSave;
  final VoidCallback onSkip;

  const ManualWarrantyModal({
    super.key,
    required this.eligibleItems,
    required this.purchaseDate,
    required this.merchantName,
    required this.onSave,
    required this.onSkip,
  });

  @override
  State<ManualWarrantyModal> createState() => _ManualWarrantyModalState();
}

class _ManualWarrantyModalState extends State<ManualWarrantyModal> {
  // Store selected option per item index
  // Options: 'No Warranty', '6 Months', '1 Year', '2 Years', '3 Years', '5 Years', 'Custom'
  late List<String> _selectedChips;
  late List<String> _customUnits;
  late List<TextEditingController> _customControllers;

  @override
  void initState() {
    super.initState();
    _selectedChips = List.generate(widget.eligibleItems.length, (_) => 'No Warranty');
    _customUnits = List.generate(widget.eligibleItems.length, (_) => 'months');
    _customControllers = List.generate(
      widget.eligibleItems.length,
      (_) => TextEditingController(text: '12'),
    );
  }

  @override
  void dispose() {
    for (final controller in _customControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  (int, String) _getDurationAndUnit(int index) {
    final chip = _selectedChips[index];
    switch (chip) {
      case '6 Months':
        return (6, 'months');
      case '1 Year':
        return (1, 'years');
      case '2 Years':
        return (2, 'years');
      case '3 Years':
        return (3, 'years');
      case '5 Years':
        return (5, 'years');
      case 'Custom':
        final p = int.tryParse(_customControllers[index].text.trim()) ?? 12;
        return (p > 0 ? p : 1, _customUnits[index]);
      case 'No Warranty':
      default:
        return (0, 'months');
    }
  }

  String _calculateExpiry(int index) {
    final chip = _selectedChips[index];
    if (chip == 'No Warranty') {
      return 'No Warranty';
    }
    final (period, unit) = _getDurationAndUnit(index);
    if (period <= 0) return 'No Warranty';
    return WarrantyUtils.calculateExpiryDate(widget.purchaseDate, period, unit);
  }

  void _handleConfirm() {
    final List<ManualWarrantySelection> results = [];
    for (int i = 0; i < widget.eligibleItems.length; i++) {
      final item = widget.eligibleItems[i];
      final chip = _selectedChips[i];
      if (chip != 'No Warranty') {
        final (period, unit) = _getDurationAndUnit(i);
        final expiry = _calculateExpiry(i);
        results.add(
          ManualWarrantySelection(
            item: item,
            isEnabled: true,
            period: period,
            unit: unit,
            expiryDate: expiry,
          ),
        );
      }
    }
    widget.onSave(results);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 20;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: AppRadius.full,
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Warranty Entry',
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No warranty detected on receipt. Set warranty for eligible products below.',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

          // Eligible products list
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: bottomPadding,
              ),
              shrinkWrap: true,
              itemCount: widget.eligibleItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = widget.eligibleItems[index];
                final currentChip = _selectedChips[index];
                final expiryPreview = _calculateExpiry(index);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.6),
                    borderRadius: AppRadius.md,
                    border: Border.all(
                      color: currentChip != 'No Warranty'
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title & Purchase Date Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.hankenGrotesk(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: AppRadius.sm,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Text(
                              'Bought: ${widget.purchaseDate}',
                              style: GoogleFonts.inter(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Warranty Option Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          'No Warranty',
                          '6 Months',
                          '1 Year',
                          '2 Years',
                          '3 Years',
                          '5 Years',
                          'Custom',
                        ].map((chip) {
                          final isSelected = currentChip == chip;
                          return ChoiceChip(
                            label: Text(
                              chip,
                              style: AppFonts.geist(
                                color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                height: 1.0,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedChips[index] = chip;
                                });
                              }
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.cardSurface,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          );
                        }).toList(),
                      ),

                      // Custom Duration Input (if Custom selected)
                      if (currentChip == 'Custom') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 40,
                              child: TextField(
                                controller: _customControllers[index],
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                onChanged: (val) {
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: AppColors.cardSurface,
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadius.sm,
                                    borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.sm,
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.sm,
                                    borderSide: const BorderSide(color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'months', label: Text('Months')),
                                ButtonSegment(value: 'years', label: Text('Years')),
                              ],
                              selected: {_customUnits[index]},
                              onSelectionChanged: (Set<String> selection) {
                                setState(() {
                                  _customUnits[index] = selection.first;
                                });
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                textStyle: WidgetStateProperty.all(
                                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Calculated Expiry Preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: currentChip == 'No Warranty'
                              ? Colors.white.withValues(alpha: 0.04)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.sm,
                          border: Border.all(
                            color: currentChip == 'No Warranty'
                                ? Colors.transparent
                                : AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              currentChip == 'No Warranty' ? Icons.block : Icons.calendar_today_rounded,
                              color: currentChip == 'No Warranty' ? AppColors.onSurfaceVariant : AppColors.primary,
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentChip == 'No Warranty'
                                  ? 'No warranty will be created'
                                  : 'Calculated Expiry: $expiryPreview',
                              style: GoogleFonts.inter(
                                color: currentChip == 'No Warranty' ? AppColors.onSurfaceVariant : Colors.white,
                                fontSize: 13,
                                fontWeight: currentChip == 'No Warranty' ? FontWeight.w400 : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Fixed Sticky Bottom Action Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md,
                        ),
                      ),
                      onPressed: _handleConfirm,
                      child: Text(
                        'Save',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
