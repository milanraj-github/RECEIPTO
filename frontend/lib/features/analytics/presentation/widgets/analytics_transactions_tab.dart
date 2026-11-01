import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/analytics/domain/models/financial_overview_data.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';

class AnalyticsTransactionsTab extends StatefulWidget {
  final FinancialOverviewData data;
  final Function(Map<String, dynamic> receipt) onReceiptTap;
  final VoidCallback onAddManualExpense;

  const AnalyticsTransactionsTab({
    super.key,
    required this.data,
    required this.onReceiptTap,
    required this.onAddManualExpense,
  });

  @override
  State<AnalyticsTransactionsTab> createState() => _AnalyticsTransactionsTabState();
}

class _AnalyticsTransactionsTabState extends State<AnalyticsTransactionsTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _paymentFilter = 'All';
  String _sortOption = 'Newest'; // 'Newest', 'Oldest', 'Highest Amount', 'Lowest Amount'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final Set<String> set = {'All'};
    for (final r in widget.data.filteredReceipts) {
      final c = (r['category'] as String?)?.trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    return set.toList();
  }

  List<String> get _paymentMethods => ['All', 'UPI', 'Cash', 'Credit Card', 'Debit Card', 'Other'];

  List<Map<String, dynamic>> get _processedTransactions {
    final list = widget.data.filteredReceipts.where((r) {
      final merchant = (r['merchant_name'] as String?)?.toLowerCase() ?? '';
      final category = (r['category'] as String?)?.toLowerCase() ?? '';
      final payment = (r['payment_method'] as String?)?.toLowerCase() ?? '';
      final invoice = (r['invoice_number'] as String?)?.toLowerCase() ?? '';
      final notes = (r['raw_text'] as String?)?.toLowerCase() ?? '';

      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesMerchant = merchant.contains(q);
        final matchesCat = category.contains(q);
        final matchesInvoice = invoice.contains(q);
        final matchesNotes = notes.contains(q);

        // Also search line items
        final items = (r['receipt_items'] as List<dynamic>?) ?? [];
        final matchesItem = items.any((it) => (it['name'] as String?)?.toLowerCase().contains(q) ?? false);

        if (!matchesMerchant && !matchesCat && !matchesInvoice && !matchesNotes && !matchesItem) {
          return false;
        }
      }

      // Category filter
      if (_categoryFilter != 'All' && category != _categoryFilter.toLowerCase()) {
        return false;
      }

      // Payment filter
      if (_paymentFilter != 'All' && !payment.contains(_paymentFilter.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    list.sort((a, b) {
      final double amtA = ReceiptModel.parseDouble(a['grand_total']) ?? ReceiptModel.parseDouble(a['total']) ?? 0.0;
      final double amtB = ReceiptModel.parseDouble(b['grand_total']) ?? ReceiptModel.parseDouble(b['total']) ?? 0.0;
      final String dateA = a['date'] as String? ?? a['created_at'] as String? ?? '';
      final String dateB = b['date'] as String? ?? b['created_at'] as String? ?? '';

      switch (_sortOption) {
        case 'Highest Amount':
          return amtB.compareTo(amtA);
        case 'Lowest Amount':
          return amtA.compareTo(amtB);
        case 'Oldest':
          return dateA.compareTo(dateB);
        case 'Newest':
        default:
          return dateB.compareTo(dateA);
      }
    });

    return list;
  }

  bool _isDuplicateCandidate(Map<String, dynamic> r) {
    return widget.data.possibleDuplicates.any((d) => d['id'] == r['id']);
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _processedTransactions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Filter Header
          _buildSearchAndFilters(),
          const SizedBox(height: 14),

          // Total Results count & Add Manual Expense shortcut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${transactions.length} Transactions Found',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: widget.onAddManualExpense,
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Add Expense',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (transactions.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 48, color: AppColors.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'No matching transactions',
                      style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try resetting filters or searching another keyword.',
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final r = transactions[idx];
                final merchant = r['merchant_name'] as String? ?? 'Merchant';
                final date = r['date'] as String? ?? 'Unknown date';
                final category = r['category'] as String? ?? 'Other';
                final payment = r['payment_method'] as String? ?? 'Other';
                final amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
                final isDup = _isDuplicateCandidate(r);
                final isManual = (r['original_file_name'] == 'Manual Expense') ||
                    (r['image_url'] == null || r['image_url'].toString().isEmpty);

                return GestureDetector(
                  onTap: () => widget.onReceiptTap(r),
                  child: GlassCard(
                    borderRadius: AppRadius.md,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isManual
                              ? Colors.orangeAccent.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.12),
                          child: Icon(
                            isManual ? Icons.edit_note : Icons.receipt_outlined,
                            color: isManual ? Colors.orangeAccent : AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      merchant,
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isDup) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'POSSIBLE DUPLICATE',
                                        style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$date • $category • $payment',
                                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(amt),
                          style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search merchant, product, or description...',
            hintStyle: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white60, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.cardSurface,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        const SizedBox(height: 10),

        // Filter Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Category filter dropdown pill
              _buildFilterDropdown(
                label: 'Category: $_categoryFilter',
                items: _categories,
                currentVal: _categoryFilter,
                onChanged: (val) => setState(() => _categoryFilter = val),
              ),
              const SizedBox(width: 8),

              // Payment filter dropdown pill
              _buildFilterDropdown(
                label: 'Payment: $_paymentFilter',
                items: _paymentMethods,
                currentVal: _paymentFilter,
                onChanged: (val) => setState(() => _paymentFilter = val),
              ),
              const SizedBox(width: 8),

              // Sort pill
              _buildFilterDropdown(
                label: 'Sort: $_sortOption',
                items: const ['Newest', 'Oldest', 'Highest Amount', 'Lowest Amount'],
                currentVal: _sortOption,
                onChanged: (val) => setState(() => _sortOption = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required List<String> items,
    required String currentVal,
    required Function(String val) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentVal) ? currentVal : items.first,
          dropdownColor: AppColors.cardSurface,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 18),
          items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
