import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/features/analytics/domain/models/budget_model.dart';

class AddEditBudgetDialog extends StatefulWidget {
  final AppBudget? existingBudget;
  final Function(AppBudget budget) onSave;

  const AddEditBudgetDialog({
    super.key,
    this.existingBudget,
    required this.onSave,
  });

  @override
  State<AddEditBudgetDialog> createState() => _AddEditBudgetDialogState();
}

class _AddEditBudgetDialogState extends State<AddEditBudgetDialog> {
  late final TextEditingController _amountController;
  late String _category;
  late double _alertThreshold;

  final List<String> _categories = [
    'Overall',
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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.existingBudget != null ? widget.existingBudget!.limitAmount.toInt().toString() : '',
    );
    _category = widget.existingBudget?.category ?? 'Overall';
    _alertThreshold = widget.existingBudget?.alertThreshold ?? 0.8;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive budget amount.')),
      );
      return;
    }

    final budget = AppBudget(
      id: widget.existingBudget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      category: _category,
      limitAmount: amt,
      alertThreshold: _alertThreshold,
      createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
    );

    widget.onSave(budget);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Text(
        widget.existingBudget == null ? 'Set New Budget' : 'Edit Budget',
        style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Dropdown
            Text('Scope', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _categories.contains(_category) ? _category : 'Overall',
                  dropdownColor: AppColors.cardSurface,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Limit Amount
            Text('Monthly Limit (₹)', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                hintText: 'e.g. 25000',
                hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Alert Threshold
            Text('Alert Threshold', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [0.5, 0.8, 1.0].map((t) {
                final isSel = _alertThreshold == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${(t * 100).toInt()}%', style: TextStyle(color: isSel ? Colors.black : Colors.white70)),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    onSelected: (_) => setState(() => _alertThreshold = t),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submit,
          child: const Text('Save Budget', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
