import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';

class AddManualExpenseSheet extends ConsumerStatefulWidget {
  const AddManualExpenseSheet({super.key});

  @override
  ConsumerState<AddManualExpenseSheet> createState() => _AddManualExpenseSheetState();
}

class _AddManualExpenseSheetState extends ConsumerState<AddManualExpenseSheet> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food & Dining';
  String _selectedPaymentMethod = 'UPI';
  bool _isSaving = false;

  final List<String> _categories = [
    'Food & Dining',
    'Groceries',
    'Shopping',
    'Electronics',
    'Fuel',
    'Healthcare',
    'Fashion',
    'Entertainment',
    'Utilities',
    'Travel',
    'Others',
  ];

  final List<String> _paymentMethods = [
    'UPI',
    'Cash',
    'Credit Card',
    'Debit Card',
    'Net Banking',
    'Wallet',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amountText = _amountController.text.trim();
    final merchant = _merchantController.text.trim();

    if (amountText.isEmpty || double.tryParse(amountText) == null || double.parse(amountText) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount.')),
      );
      return;
    }

    if (merchant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a merchant or store name.')),
      );
      return;
    }

    final user = ref.read(firebaseAuthServiceProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double amt = double.parse(amountText);
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final receipt = ReceiptModel(
        merchantName: merchant,
        total: amt,
        subtotal: amt,
        date: dateStr,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        currency: '₹',
        rawText: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : 'Manual Expense',
        items: [
          ReceiptItemModel(
            name: merchant,
            quantity: 1,
            unitPrice: amt,
            totalPrice: amt,
            category: _selectedCategory,
          ),
        ],
      );

      final dbService = ref.read(receiptDatabaseServiceProvider);
      await dbService.saveReceipt(
        receipt,
        userId: user.uid,
        originalFileName: 'Manual Expense',
      );

      ref.invalidate(dbReceiptsListProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manual expense recorded successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + (bottomPadding > 0 ? bottomPadding : 12),
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Record Manual Expense',
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

              // Amount
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.hankenGrotesk(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                  hintText: '0.00',
                  hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                  labelText: 'Amount Spent',
                  labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Merchant
              TextField(
                controller: _merchantController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Merchant / Description',
                  hintText: 'e.g. Starbucks, Grocery Store, Metro Ride',
                  labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Date & Category in Row
              Row(
                children: [
                  // Date Picker Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.black,
                                  surface: AppColors.cardSurface,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          dropdownColor: AppColors.cardSurface,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: _categories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Payment Method Chips
              Text(
                'Payment Method',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _paymentMethods.map((pm) {
                  final isSel = _selectedPaymentMethod == pm;
                  return ChoiceChip(
                    label: Text(pm, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 12)),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.cardSurface,
                    onSelected: (val) => setState(() => _selectedPaymentMethod = pm),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Notes (optional)
              TextField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. Lunch with team, monthly top-up',
                  labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text(
                        'Save Expense',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
