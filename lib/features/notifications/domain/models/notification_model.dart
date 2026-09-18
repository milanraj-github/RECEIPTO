class NotificationModel {
  final String? id;
  final String userId;
  final String? warrantyId;
  final String? receiptId;
  final String title;
  final String message;
  final String type; // 'WARRANTY', 'EMAIL', 'SYSTEM'
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    this.warrantyId,
    this.receiptId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString(),
      userId: json['user_id'] as String? ?? '',
      warrantyId: json['warranty_id']?.toString(),
      receiptId: json['receipt_id']?.toString(),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'SYSTEM',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      'user_id': userId,
      if (warrantyId != null) 'warranty_id': warrantyId,
      if (receiptId != null) 'receipt_id': receiptId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? warrantyId,
    String? receiptId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      warrantyId: warrantyId ?? this.warrantyId,
      receiptId: receiptId ?? this.receiptId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
