import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/features/analytics/domain/models/savings_goal_model.dart';

class AddEditGoalDialog extends StatefulWidget {
  final SavingsGoal? existingGoal;
  final Function(SavingsGoal goal) onSave;

  const AddEditGoalDialog({
    super.key,
    this.existingGoal,
    required this.onSave,
  });

  @override
  State<AddEditGoalDialog> createState() => _AddEditGoalDialogState();
}

class _AddEditGoalDialogState extends State<AddEditGoalDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _currentSavedController;
  late DateTime _targetDate;
  late String _category;

  final List<String> _categories = ['General', 'Electronics', 'Travel', 'Emergency', 'Vehicle', 'Home'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingGoal?.name ?? '');
    _targetAmountController = TextEditingController(
      text: widget.existingGoal != null ? widget.existingGoal!.targetAmount.toInt().toString() : '',
    );
    _currentSavedController = TextEditingController(
      text: widget.existingGoal != null ? widget.existingGoal!.currentSaved.toInt().toString() : '0',
    );
    _targetDate = widget.existingGoal?.targetDate ?? DateTime.now().add(const Duration(days: 90));
    _category = widget.existingGoal?.category ?? 'General';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentSavedController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final targetAmt = double.tryParse(_targetAmountController.text.trim());
    final currentSaved = double.tryParse(_currentSavedController.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal name.')),
      );
      return;
    }

    if (targetAmt == null || targetAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount.')),
      );
      return;
    }

    final goal = SavingsGoal(
      id: widget.existingGoal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      targetAmount: targetAmt,
      currentSaved: currentSaved,
      targetDate: _targetDate,
      category: _category,
      isCompleted: currentSaved >= targetAmt,
      createdAt: widget.existingGoal?.createdAt ?? DateTime.now(),
    );

    widget.onSave(goal);
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
        widget.existingGoal == null ? 'New Savings Goal' : 'Edit Savings Goal',
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
                labelText: 'Goal Name',
                hintText: 'e.g. New Laptop, Vacation, Emergency Fund',
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
                  value: _categories.contains(_category) ? _category : 'General',
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

            // Target Amount
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                labelText: 'Target Amount (₹)',
                hintText: '50000',
                labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Current Saved Amount
            TextField(
              controller: _currentSavedController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.tertiary),
                labelText: 'Already Saved Amount (₹)',
                hintText: '0',
                labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Target Date picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime.now(),
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
                  setState(() => _targetDate = picked);
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
                    Text('Target Date', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13)),
                    Row(
                      children: [
                        const Icon(Icons.event_outlined, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
          child: const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

