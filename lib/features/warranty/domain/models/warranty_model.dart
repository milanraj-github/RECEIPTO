class WarrantyModel {
  final String? id;
  final String userId;
  final String? receiptId;
  final String productName;
  final String merchantName;
  final String? invoiceNumber;
  final String purchaseDate;
  final int warrantyPeriod;
  final String warrantyUnit;
  final String expiryDate;
  final String? imageUrl;
  final String status;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final bool notification30Sent;
  final bool notification15Sent;
  final bool notification7Sent;
  final bool notification3Sent;
  final bool notification1Sent;
  final bool notificationTodaySent;
  final bool notificationExpiredSent;
  final bool email30Sent;
  final bool email15Sent;
  final bool email7Sent;
  final bool email3Sent;
  final bool email1Sent;
  final bool emailTodaySent;
  final bool emailExpiredSent;
  final bool isManual;

  WarrantyModel({
    this.id,
    required this.userId,
    this.receiptId,
    required this.productName,
    required this.merchantName,
    this.invoiceNumber,
    required this.purchaseDate,
    required this.warrantyPeriod,
    required this.warrantyUnit,
    required this.expiryDate,
    this.imageUrl,
    required this.status,
    this.brand,
    this.model,
    this.serialNumber,
    this.notification30Sent = false,
    this.notification15Sent = false,
    this.notification7Sent = false,
    this.notification3Sent = false,
    this.notification1Sent = false,
    this.notificationTodaySent = false,
    this.notificationExpiredSent = false,
    this.email30Sent = false,
    this.email15Sent = false,
    this.email7Sent = false,
    this.email3Sent = false,
    this.email1Sent = false,
    this.emailTodaySent = false,
    this.emailExpiredSent = false,
    this.isManual = false,
  });

  factory WarrantyModel.fromJson(Map<String, dynamic> json) {
    return WarrantyModel(
      id: json['id']?.toString(),
      userId: json['user_id'] as String? ?? '',
      receiptId: json['receipt_id']?.toString(),
      productName: json['product_name'] as String? ?? 'Unknown Product',
      merchantName: json['merchant_name'] as String? ?? 'Unknown Merchant',
      invoiceNumber: json['invoice_number'] as String?,
      purchaseDate: json['purchase_date'] as String? ?? '',
      warrantyPeriod: (json['warranty_period'] as num?)?.toInt() ?? 0,
      warrantyUnit: json['warranty_unit'] as String? ?? 'months',
      expiryDate: json['expiry_date'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serial_number'] as String?,
      notification30Sent: json['notification_30_sent'] as bool? ?? false,
      notification15Sent: json['notification_15_sent'] as bool? ?? false,
      notification7Sent: json['notification_7_sent'] as bool? ?? false,
      notification3Sent: json['notification_3_sent'] as bool? ?? false,
      notification1Sent: json['notification_1_sent'] as bool? ?? false,
      notificationTodaySent: json['notification_today_sent'] as bool? ?? false,
      notificationExpiredSent: json['notification_expired_sent'] as bool? ?? false,
      email30Sent: json['email_30_sent'] as bool? ?? false,
      email15Sent: json['email_15_sent'] as bool? ?? false,
      email7Sent: json['email_7_sent'] as bool? ?? false,
      email3Sent: json['email_3_sent'] as bool? ?? false,
      email1Sent: json['email_1_sent'] as bool? ?? false,
      emailTodaySent: json['email_today_sent'] as bool? ?? false,
      emailExpiredSent: json['email_expired_sent'] as bool? ?? false,
      isManual: json['is_manual'] as bool? ?? (json['is_manual_entry'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      'user_id': userId,
      if (receiptId != null) 'receipt_id': int.tryParse(receiptId!) ?? receiptId,
      'product_name': productName,
      'merchant_name': merchantName,
      'invoice_number': invoiceNumber,
      'purchase_date': purchaseDate,
      'warranty_period': warrantyPeriod,
      'warranty_unit': warrantyUnit,
      'expiry_date': expiryDate,
      'image_url': imageUrl,
      'status': status,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'is_manual': isManual,
      'notification_30_sent': notification30Sent,
      'notification_15_sent': notification15Sent,
      'notification_7_sent': notification7Sent,
      'notification_3_sent': notification3Sent,
      'notification_1_sent': notification1Sent,
      'notification_today_sent': notificationTodaySent,
      'notification_expired_sent': notificationExpiredSent,
      'email_30_sent': email30Sent,
      'email_15_sent': email15Sent,
      'email_7_sent': email7Sent,
      'email_3_sent': email3Sent,
      'email_1_sent': email1Sent,
      'email_today_sent': emailTodaySent,
      'email_expired_sent': emailExpiredSent,
    };
  }

  WarrantyModel copyWith({
    String? id,
    String? userId,
    String? receiptId,
    String? productName,
    String? merchantName,
    String? invoiceNumber,
    String? purchaseDate,
    int? warrantyPeriod,
    String? warrantyUnit,
    String? expiryDate,
    String? imageUrl,
    String? status,
    String? brand,
    String? model,
    String? serialNumber,
    bool? notification30Sent,
    bool? notification15Sent,
    bool? notification7Sent,
    bool? notification3Sent,
    bool? notification1Sent,
    bool? notificationTodaySent,
    bool? notificationExpiredSent,
    bool? email30Sent,
    bool? email15Sent,
    bool? email7Sent,
    bool? email3Sent,
    bool? email1Sent,
    bool? emailTodaySent,
    bool? emailExpiredSent,
    bool? isManual,
  }) {
    return WarrantyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      receiptId: receiptId ?? this.receiptId,
      productName: productName ?? this.productName,
      merchantName: merchantName ?? this.merchantName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyPeriod: warrantyPeriod ?? this.warrantyPeriod,
      warrantyUnit: warrantyUnit ?? this.warrantyUnit,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      notification30Sent: notification30Sent ?? this.notification30Sent,
      notification15Sent: notification15Sent ?? this.notification15Sent,
      notification7Sent: notification7Sent ?? this.notification7Sent,
      notification3Sent: notification3Sent ?? this.notification3Sent,
      notification1Sent: notification1Sent ?? this.notification1Sent,
      notificationTodaySent: notificationTodaySent ?? this.notificationTodaySent,
      notificationExpiredSent: notificationExpiredSent ?? this.notificationExpiredSent,
      email30Sent: email30Sent ?? this.email30Sent,
      email15Sent: email15Sent ?? this.email15Sent,
      email7Sent: email7Sent ?? this.email7Sent,
      email3Sent: email3Sent ?? this.email3Sent,
      email1Sent: email1Sent ?? this.email1Sent,
      emailTodaySent: emailTodaySent ?? this.emailTodaySent,
      emailExpiredSent: emailExpiredSent ?? this.emailExpiredSent,
      isManual: isManual ?? this.isManual,
    );
  }
}
