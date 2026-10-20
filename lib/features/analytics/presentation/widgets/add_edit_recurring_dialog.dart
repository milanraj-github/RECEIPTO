import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/features/analytics/domain/models/recurring_expense_model.dart';

class AddEditRecurringDialog extends StatefulWidget {
  final RecurringExpense? existingExpense;
  final Function(RecurringExpense expense) onSave;

  const AddEditRecurringDialog({
    super.key,
    this.existingExpense,
    required this.onSave,
  });

  @override
  State<AddEditRecurringDialog> createState() => _AddEditRecurringDialogState();
}

class _AddEditRecurringDialogState extends State<AddEditRecurringDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late String _frequency;
  late String _category;
  late DateTime _nextDueDate;
  late bool _reminderEnabled;

  final List<String> _frequencies = ['monthly', 'weekly', 'yearly'];
  final List<String> _categories = ['Subscription', 'Utilities', 'Entertainment', 'Healthcare', 'Insurance', 'Rent', 'Others'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingExpense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.existingExpense != null ? widget.existingExpense!.amount.toInt().toString() : '',
    );
    _merchantController = TextEditingController(text: widget.existingExpense?.merchant ?? '');
    _frequency = widget.existingExpense?.frequency ?? 'monthly';
    _category = widget.existingExpense?.category ?? 'Subscription';
    _nextDueDate = widget.existingExpense?.nextDueDate ?? DateTime.now().add(const Duration(days: 30));
    _reminderEnabled = widget.existingExpense?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final amt = double.tryParse(_amountController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expense name.')),
      );
      return;
    }

    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final recurring = RecurringExpense(
      id: widget.existingExpense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      amount: amt,
      category: _category,
      frequency: _frequency,
      nextDueDate: _nextDueDate,
      merchant: _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : null,
      reminderEnabled: _reminderEnabled,
      isActive: widget.existingExpense?.isActive ?? true,
      createdAt: widget.existingExpense?.createdAt ?? DateTime.now(),
    );

    widget.onSave(recurring);
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
        widget.existingExpense == null ? 'New Recurring Expense' : 'Edit Recurring Expense',
        style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name
            TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Expense Name',
                hintText: 'e.g. Netflix, Broadband, Gym, Rent',
                labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                labelText: 'Amount (₹)',
                hintText: '649',
                labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Category Dropdown
            Text('Category', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _categories.contains(_category) ? _category : 'Subscription',
                  dropdownColor: AppColors.cardSurface,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Frequency
            Text('Billing Frequency', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: _frequencies.map((f) {
                final isSel = _frequency == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.toUpperCase(), style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11)),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    onSelected: (_) => setState(() => _frequency = f),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Next Due Date
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextDueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          surface: AppColors.cardSurface,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _nextDueDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Next Due Date', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13)),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_nextDueDate.day}/${_nextDueDate.month}/${_nextDueDate.year}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Reminder Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Due Date Notification Reminder', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
              value: _reminderEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _reminderEnabled = val),
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
          child: const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
