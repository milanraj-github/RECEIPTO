import 'package:flutter/foundation.dart';

class ReceiptRefund {
  final String id;
  final String receiptId;
  final String merchant;
  final double originalAmount;
  final double refundAmount;
  final DateTime refundDate;
  final String reason;
  final String status; // 'Completed', 'Processing'
  final DateTime createdAt;

  const ReceiptRefund({
    required this.id,
    required this.receiptId,
    required this.merchant,
    required this.originalAmount,
    required this.refundAmount,
    required this.refundDate,
    this.reason = 'Returned item',
    this.status = 'Completed',
    required this.createdAt,
  });

  double get netAmount => (originalAmount - refundAmount).clamp(0.0, double.infinity);

  Map<String, dynamic> toJson() => {
    'id': id,
    'receipt_id': receiptId,
    'merchant': merchant,
    'original_amount': originalAmount,
    'refund_amount': refundAmount,
    'refund_date': refundDate.toIso8601String(),
    'reason': reason,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };

  factory ReceiptRefund.fromJson(Map<String, dynamic> json) {
    return ReceiptRefund(
      id: json['id'] as String? ?? UniqueKey().toString(),
      receiptId: json['receipt_id'] as String? ?? '',
      merchant: json['merchant'] as String? ?? 'Merchant',
      originalAmount: (json['original_amount'] as num?)?.toDouble() ?? 0.0,
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0.0,
      refundDate: json['refund_date'] != null
          ? DateTime.tryParse(json['refund_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reason: json['reason'] as String? ?? 'Returned item',
      status: json['status'] as String? ?? 'Completed',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
