import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

class EditSingleWarrantyModal extends StatefulWidget {
  final WarrantyModel warranty;
  final Function(bool isRemoved, int newPeriod, String newUnit, String newExpiryDate) onSave;

  const EditSingleWarrantyModal({
    super.key,
    required this.warranty,
    required this.onSave,
  });

  @override
  State<EditSingleWarrantyModal> createState() => _EditSingleWarrantyModalState();
}

class _EditSingleWarrantyModalState extends State<EditSingleWarrantyModal> {
  late String _selectedChip;
  late String _customUnit;
  late TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    final p = widget.warranty.warrantyPeriod;
    final u = widget.warranty.warrantyUnit.toLowerCase();

    if (p == 0) {
      _selectedChip = 'No Warranty';
    } else if (p == 6 && u.contains('month')) {
      _selectedChip = '6 Months';
    } else if ((p == 1 && u.contains('year')) || (p == 12 && u.contains('month'))) {
      _selectedChip = '1 Year';
    } else if ((p == 2 && u.contains('year')) || (p == 24 && u.contains('month'))) {
      _selectedChip = '2 Years';
    } else if ((p == 3 && u.contains('year')) || (p == 36 && u.contains('month'))) {
      _selectedChip = '3 Years';
    } else if ((p == 5 && u.contains('year')) || (p == 60 && u.contains('month'))) {
      _selectedChip = '5 Years';
    } else {
      _selectedChip = 'Custom';
    }

    _customUnit = u.contains('year') ? 'years' : 'months';
    _customController = TextEditingController(text: p > 0 ? p.toString() : '12');
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  (int, String) _getDurationAndUnit() {
    switch (_selectedChip) {
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
        final p = int.tryParse(_customController.text.trim()) ?? 12;
        return (p > 0 ? p : 1, _customUnit);
      case 'No Warranty':
      default:
        return (0, 'months');
    }
  }

  String _calculateExpiry() {
    if (_selectedChip == 'No Warranty') {
      return 'No Warranty';
    }
    final (period, unit) = _getDurationAndUnit();
    if (period <= 0) return 'No Warranty';
    return WarrantyUtils.calculateExpiryDate(widget.warranty.purchaseDate, period, unit);
  }

  void _handleConfirm() {
    if (_selectedChip == 'No Warranty') {
      widget.onSave(true, 0, 'months', '');
    } else {
      final (period, unit) = _getDurationAndUnit();
      final expiry = _calculateExpiry();
      widget.onSave(false, period, unit, expiry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 20;
    final expiryPreview = _calculateExpiry();

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
                    Icons.edit_note_rounded,
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
                        'Edit Manual Warranty',
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Update warranty duration for ${widget.warranty.productName}',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

          // Body
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product details card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.6),
                    borderRadius: AppRadius.md,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.warranty.productName,
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purchase Date: ${widget.warranty.purchaseDate}',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Select Warranty Duration',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                // Choice Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'No Warranty',
                    '6 Months',
                    '1 Year',
                    '2 Years',
                    '3 Years',
                    '5 Years',
                    'Custom',
                  ].map((chip) {
                    final isSelected = _selectedChip == chip;
                    return ChoiceChip(
                      label: Text(
                        chip,
                        style: AppFonts.geist(
                          color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedChip = chip;
                          });
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.cardSurface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    );
                  }).toList(),
                ),

                if (_selectedChip == 'Custom') ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 42,
                        child: TextField(
                          controller: _customController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          onChanged: (val) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      const SizedBox(width: 14),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'months', label: Text('Months')),
                          ButtonSegment(value: 'years', label: Text('Years')),
                        ],
                        selected: {_customUnit},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() {
                            _customUnit = selection.first;
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

                const SizedBox(height: 16),

                // Calculated Expiry Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedChip == 'No Warranty'
                        ? Colors.redAccent.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.sm,
                    border: Border.all(
                      color: _selectedChip == 'No Warranty'
                          ? Colors.redAccent.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedChip == 'No Warranty' ? Icons.delete_outline_rounded : Icons.calendar_today_rounded,
                        color: _selectedChip == 'No Warranty' ? Colors.redAccent : AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedChip == 'No Warranty'
                              ? 'Warranty will be removed. Receipt remains untouched.'
                              : 'Calculated Expiry: $expiryPreview',
                          style: GoogleFonts.inter(
                            color: _selectedChip == 'No Warranty' ? Colors.redAccent : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
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
                      backgroundColor: _selectedChip == 'No Warranty' ? Colors.redAccent : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.md,
                      ),
                    ),
                    onPressed: _handleConfirm,
                    child: Text(
                      _selectedChip == 'No Warranty' ? 'Remove Warranty' : 'Save Changes',
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
        ],
      ),
    );
  }
}
