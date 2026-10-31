import 'package:flutter/foundation.dart';

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentSaved;
  final DateTime targetDate;
  final String category;
  final bool isCompleted;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentSaved = 0.0,
    required this.targetDate,
    this.category = 'General',
    this.isCompleted = false,
    required this.createdAt,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentSaved / targetAmount).clamp(0.0, 1.0);
  }

  double get remainingAmount => (targetAmount - currentSaved).clamp(0.0, double.infinity);

  int get daysRemaining {
    final now = DateTime.now();
    final diff = targetDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff < 0 ? 0 : diff;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'target_amount': targetAmount,
    'current_saved': currentSaved,
    'target_date': targetDate.toIso8601String(),
    'category': category,
    'is_completed': isCompleted,
    'created_at': createdAt.toIso8601String(),
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String? ?? UniqueKey().toString(),
      name: json['name'] as String? ?? 'Savings Goal',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentSaved: (json['current_saved'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['target_date'] != null
          ? DateTime.tryParse(json['target_date'].toString()) ?? DateTime.now().add(const Duration(days: 90))
          : DateTime.now().add(const Duration(days: 90)),
      category: json['category'] as String? ?? 'General',
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentSaved,
    DateTime? targetDate,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentSaved: currentSaved ?? this.currentSaved,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
