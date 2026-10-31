import 'package:flutter/foundation.dart';

class AppBudget {
  final String id;
  final String category; // 'Overall' or specific category name
  final double limitAmount;
  final String period; // 'monthly', 'weekly'
  final double alertThreshold; // 0.8 = 80%, 1.0 = 100%
  final DateTime createdAt;

  const AppBudget({
    required this.id,
    required this.category,
    required this.limitAmount,
    this.period = 'monthly',
    this.alertThreshold = 0.8,
    required this.createdAt,
  });

  bool get isOverall => category.trim().toLowerCase() == 'overall' || category.trim().isEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'limit_amount': limitAmount,
    'period': period,
    'alert_threshold': alertThreshold,
    'created_at': createdAt.toIso8601String(),
  };

  factory AppBudget.fromJson(Map<String, dynamic> json) {
    return AppBudget(
      id: json['id'] as String? ?? UniqueKey().toString(),
      category: json['category'] as String? ?? 'Overall',
      limitAmount: (json['limit_amount'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] as String? ?? 'monthly',
      alertThreshold: (json['alert_threshold'] as num?)?.toDouble() ?? 0.8,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AppBudget copyWith({
    String? id,
    String? category,
    double? limitAmount,
    String? period,
    double? alertThreshold,
    DateTime? createdAt,
  }) {
    return AppBudget(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      period: period ?? this.period,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
