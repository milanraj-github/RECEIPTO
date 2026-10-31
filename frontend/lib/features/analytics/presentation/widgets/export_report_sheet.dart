import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/services/receipt_export_service.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';

class ExportReportSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> allReceipts;

  const ExportReportSheet({
    super.key,
    required this.allReceipts,
  });

  @override
  ConsumerState<ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends ConsumerState<ExportReportSheet> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  String _selectedCategory = 'All';
  String _selectedPeriod = 'All Time';
  bool _isExporting = false;

  List<String> get _categories {
    final Set<String> set = {'All'};
    for (final r in widget.allReceipts) {
      final c = (r['category'] as String?)?.trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    return set.toList();
  }

  List<Map<String, dynamic>> get _filteredReceipts {
    final now = DateTime.now();
    return widget.allReceipts.where((r) {
      // Category filter
      if (_selectedCategory != 'All') {
        final cat = (r['category'] as String?)?.trim() ?? '';
        if (cat.toLowerCase() != _selectedCategory.toLowerCase()) return false;
      }

      // Period filter
      if (_selectedPeriod != 'All Time') {
        final rawDate = r['date']?.toString().trim();
        final dt = rawDate != null ? DateTime.tryParse(rawDate) : null;
        if (dt == null) return false;

        if (_selectedPeriod == 'This Month') {
          return dt.year == now.year && dt.month == now.month;
        } else if (_selectedPeriod == 'Last 3 Months') {
          final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
          return !dt.isBefore(threeMonthsAgo);
        } else if (_selectedPeriod == 'This Year') {
          return dt.year == now.year;
        }
      }
      return true;
    }).toList();
  }

  double get _filteredTotal {
    return _filteredReceipts.fold(0.0, (sum, r) {
      final amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
      return sum + amt;
    });
  }

  Future<void> _handleExport() async {
    final filtered = _filteredReceipts;
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipts found matching selected criteria.')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final warranties = ref.read(dbWarrantiesProvider).value ?? [];
      final exportService = ref.read(receiptExportServiceProvider);

      await exportService.exportMultipleReceipts(
        receipts: filtered,
        warranties: warranties,
        format: _selectedFormat,
        autoShare: true,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${filtered.length} receipts successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: 24 + bottomInset + (bottomPadding > 0 ? bottomPadding : 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Export Financial Report',
                    style: GoogleFonts.hankenGrotesk(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Format selection
              Text(
                'Export Format',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFormatOption('PDF Document', ExportFormat.pdf, Icons.picture_as_pdf_outlined),
                  const SizedBox(width: 10),
                  _buildFormatOption('CSV / Excel', ExportFormat.csv, Icons.table_chart_outlined),
                  const SizedBox(width: 10),
                  _buildFormatOption('JSON Data', ExportFormat.json, Icons.data_object),
                ],
              ),
              const SizedBox(height: 18),

              // Period selection
              Text(
                'Timeframe',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All Time', 'This Month', 'Last 3 Months', 'This Year'].map((p) {
                  final isSel = _selectedPeriod == p;
                  return ChoiceChip(
                    label: Text(p, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 12)),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.cardSurface,
                    onSelected: (val) => setState(() => _selectedPeriod = p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              Text(
                'Category Filter',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    dropdownColor: AppColors.cardSurface,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Summary of selection
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matching Receipts',
                          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_filteredReceipts.length} transactions',
                          style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(_filteredTotal),
                          style: GoogleFonts.hankenGrotesk(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Export button
              ElevatedButton(
                onPressed: _isExporting ? null : _handleExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isExporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Generate & Share Export',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatOption(String title, ExportFormat format, IconData icon) {
    final isSelected = _selectedFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFormat = format),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white10,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.white70, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.primary : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
