import 'package:flutter/foundation.dart';

class RecurringExpense {
  final String id;
  final String name;
  final double amount;
  final String currency;
  final String category;
  final String frequency; // 'weekly', 'monthly', 'yearly'
  final DateTime nextDueDate;
  final String? merchant;
  final bool isActive;
  final bool reminderEnabled;
  final DateTime createdAt;

  const RecurringExpense({
    required this.id,
    required this.name,
    required this.amount,
    this.currency = '₹',
    this.category = 'Subscription',
    this.frequency = 'monthly',
    required this.nextDueDate,
    this.merchant,
    this.isActive = true,
    this.reminderEnabled = true,
    required this.createdAt,
  });

  /// Computes estimated monthly normalized cost
  double get monthlyNormalizedAmount {
    if (!isActive) return 0.0;
    switch (frequency.toLowerCase()) {
      case 'weekly':
        return amount * 4.333;
      case 'yearly':
        return amount / 12.0;
      case 'monthly':
      default:
        return amount;
    }
  }

  int get daysUntilDue {
    final now = DateTime.now();
    return nextDueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'currency': currency,
    'category': category,
    'frequency': frequency,
    'next_due_date': nextDueDate.toIso8601String(),
    'merchant': merchant,
    'is_active': isActive,
    'reminder_enabled': reminderEnabled,
    'created_at': createdAt.toIso8601String(),
  };

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'] as String? ?? UniqueKey().toString(),
      name: json['name'] as String? ?? 'Subscription',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '₹',
      category: json['category'] as String? ?? 'Subscription',
      frequency: json['frequency'] as String? ?? 'monthly',
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'].toString()) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      merchant: json['merchant'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  RecurringExpense copyWith({
    String? id,
    String? name,
    double? amount,
    String? currency,
    String? category,
    String? frequency,
    DateTime? nextDueDate,
    String? merchant,
    bool? isActive,
    bool? reminderEnabled,
    DateTime? createdAt,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      merchant: merchant ?? this.merchant,
      isActive: isActive ?? this.isActive,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
