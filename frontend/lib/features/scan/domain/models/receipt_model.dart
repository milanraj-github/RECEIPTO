import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:flutter/foundation.dart';

class ReceiptModel {
  final String? merchantName;
  final String? invoiceNumber;
  final String? date;
  final String? time;
  final String? gstNumber;
  final String? currency;
  final double? subtotal;
  final double? tax;
  final double? discount;
  final double? total;
  final String? paymentMethod;
  final String? category;
  final String? merchantAddress;
  final String? merchantPhone;
  final List<ReceiptItemModel> items;
  final String? receiptHash;
  final int? fileSize;
  final double? confidenceScore;
  final String? rawText;
  final bool isValidReceipt;
  final String? invalidReason;

  ReceiptModel({
    this.merchantName,
    this.invoiceNumber,
    this.date,
    this.time,
    this.gstNumber,
    this.currency,
    this.subtotal,
    this.tax,
    this.discount,
    this.total,
    this.paymentMethod,
    this.category,
    this.merchantAddress,
    this.merchantPhone,
    required this.items,
    this.receiptHash,
    this.fileSize,
    this.confidenceScore,
    this.rawText,
    this.isValidReceipt = true,
    this.invalidReason,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    // Resolve currency
    String? resolvedCurrency = json['currency'] as String?;
    if (resolvedCurrency == null || resolvedCurrency.trim().isEmpty) {
      resolvedCurrency = '₹';
    } else {
      final curLower = resolvedCurrency.toLowerCase();
      if (curLower.contains('usd') || resolvedCurrency == '\$') {
        resolvedCurrency = '\$';
      } else if (curLower.contains('inr') || resolvedCurrency == '₹' || curLower.contains('rupee')) {
        resolvedCurrency = '₹';
      }
    }

    // 1. Extract root confidence scores
    final dynamic rawConfScores = json['confidence_scores'];
    Map<String, dynamic> confScores = {};
    if (rawConfScores is Map<String, dynamic>) {
      confScores = rawConfScores;
    }

    final double merchantConf = parseDouble(confScores['merchant_name']) ?? 1.0;
    final double invoiceConf = parseDouble(confScores['invoice_number']) ?? 1.0;
    final double dateConf = parseDouble(confScores['date']) ?? 1.0;
    final double payConf = parseDouble(confScores['payment_method']) ?? 1.0;

    String? parsedMerchant = json['merchant_name'] as String?;
    if (parsedMerchant != null && parsedMerchant.isNotEmpty && merchantConf < 0.8) {
      parsedMerchant = '$parsedMerchant (Low Confidence)';
    }

    String? parsedInvoice = json['invoice_number'] as String?;
    if (parsedInvoice != null && parsedInvoice.isNotEmpty && invoiceConf < 0.8) {
      parsedInvoice = '$parsedInvoice (Low Confidence)';
    }

    String? parsedPayment = json['payment_method'] as String?;
    if (parsedPayment != null && parsedPayment.isNotEmpty && payConf < 0.8) {
      parsedPayment = '$parsedPayment (Low Confidence)';
    }

    String? parsedDateStr = json['date'] as String?;
    final String? normalizedDate = WarrantyUtils.parseAndNormalizeDate(parsedDateStr);
    if (parsedDateStr != null && dateConf < 0.8) {
      debugPrint('[Confidence Warning] Purchase Date "$parsedDateStr" has low confidence: $dateConf');
    }

    return ReceiptModel(
      merchantName: parsedMerchant,
      invoiceNumber: parsedInvoice,
      date: normalizedDate ?? parsedDateStr,
      time: json['time'] as String?,
      gstNumber: json['gst_number'] as String?,
      currency: resolvedCurrency,
      subtotal: parseDouble(json['subtotal']),
      tax: parseDouble(json['tax']),
      discount: parseDouble(json['discount']),
      total: parseDouble(json['total']),
      paymentMethod: parsedPayment,
      category: json['category'] as String?,
      merchantAddress: json['merchant_address'] as String?,
      merchantPhone: json['merchant_phone'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ReceiptItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      receiptHash: json['receipt_hash'] as String?,
      fileSize: parseInt(json['file_size']),
      confidenceScore: parseDouble(json['confidence_score']),
      rawText: json['raw_text'] as String?,
      isValidReceipt: json['is_valid_receipt'] is bool ? json['is_valid_receipt'] as bool : true,
      invalidReason: json['invalid_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_name': merchantName,
      'invoice_number': invoiceNumber,
      'date': date,
      'time': time,
      'gst_number': gstNumber,
      'currency': currency,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'category': category,
      'merchant_address': merchantAddress,
      'merchant_phone': merchantPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'receipt_hash': receiptHash,
      'file_size': fileSize,
      'confidence_score': confidenceScore,
      'raw_text': rawText,
    };
  }

  static double? parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^\d\.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  static int? parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleaned);
    }
    return null;
  }

  ReceiptModel copyWith({
    String? merchantName,
    String? invoiceNumber,
    String? date,
    String? time,
    String? gstNumber,
    String? currency,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? paymentMethod,
    String? category,
    String? merchantAddress,
    String? merchantPhone,
    List<ReceiptItemModel>? items,
    String? receiptHash,
    int? fileSize,
    double? confidenceScore,
    String? rawText,
    bool? isValidReceipt,
    String? invalidReason,
  }) {
    return ReceiptModel(
      merchantName: merchantName ?? this.merchantName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      time: time ?? this.time,
      gstNumber: gstNumber ?? this.gstNumber,
      currency: currency ?? this.currency,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      category: category ?? this.category,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      items: items ?? this.items,
      receiptHash: receiptHash ?? this.receiptHash,
      fileSize: fileSize ?? this.fileSize,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      rawText: rawText ?? this.rawText,
      isValidReceipt: isValidReceipt ?? this.isValidReceipt,
      invalidReason: invalidReason ?? this.invalidReason,
    );
  }
}

class ReceiptItemModel {
  final String name;
  final int? quantity;
  final double? unitPrice;
  final double? totalPrice;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final bool? warrantyAvailable;
  final int? warrantyPeriod;
  final String? warrantyUnit;
  final String? category;
  final String? warrantyExpiry;
  final int? returnWindow;

  ReceiptItemModel({
    required this.name,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.brand,
    this.model,
    this.serialNumber,
    this.warrantyAvailable,
    this.warrantyPeriod,
    this.warrantyUnit,
    this.category,
    this.warrantyExpiry,
    this.returnWindow,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    // 1. Extract item confidence scores
    final dynamic rawConfScores = json['confidence_scores'];
    Map<String, dynamic> confScores = {};
    if (rawConfScores is Map<String, dynamic>) {
      confScores = rawConfScores;
    }

    final double nameConf = parseDouble(confScores['name']) ?? 1.0;
    final double periodConf = parseDouble(confScores['warranty_period']) ?? 1.0;
    final double expiryConf = parseDouble(confScores['warranty_expiry']) ?? 1.0;

    String parsedName = (json['name'] as String?) ?? 'Unknown Item';
    if (nameConf < 0.8) {
      parsedName = '$parsedName (Low Confidence)';
    }

    String? parsedUnit = json['warranty_unit'] as String?;
    if (parsedUnit != null && parsedUnit.isNotEmpty && periodConf < 0.8) {
      parsedUnit = '$parsedUnit (Low Confidence)';
    }

    String? parsedExpiry = json['warranty_expiry'] as String?;
    final String? normalizedExpiry = WarrantyUtils.parseAndNormalizeDate(parsedExpiry);
    if (parsedExpiry != null && expiryConf < 0.8) {
      debugPrint('[Confidence Warning] Warranty Expiry Date "$parsedExpiry" has low confidence: $expiryConf');
    }

    return ReceiptItemModel(
      name: parsedName,
      quantity: parseInt(json['quantity']),
      unitPrice: parseDouble(json['unit_price']),
      totalPrice: parseDouble(json['total_price']),
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serial_number'] as String?,
      warrantyAvailable: json['warranty_available'] as bool?,
      warrantyPeriod: parseInt(json['warranty_period']),
      warrantyUnit: parsedUnit,
      category: json['category'] as String?,
      warrantyExpiry: normalizedExpiry ?? parsedExpiry,
      returnWindow: parseInt(json['return_window']),
    );
  }

  ReceiptItemModel copyWith({
    String? name,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? brand,
    String? model,
    String? serialNumber,
    bool? warrantyAvailable,
    int? warrantyPeriod,
    String? warrantyUnit,
    String? category,
    String? warrantyExpiry,
    int? returnWindow,
  }) {
    return ReceiptItemModel(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      warrantyAvailable: warrantyAvailable ?? this.warrantyAvailable,
      warrantyPeriod: warrantyPeriod ?? this.warrantyPeriod,
      warrantyUnit: warrantyUnit ?? this.warrantyUnit,
      category: category ?? this.category,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      returnWindow: returnWindow ?? this.returnWindow,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'warranty_available': warrantyAvailable,
      'warranty_period': warrantyPeriod,
      'warranty_unit': warrantyUnit,
      'category': category,
      'warranty_expiry': warrantyExpiry,
      'return_window': returnWindow,
    };
  }

  static double? parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^\d\.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  static int? parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleaned);
    }
    return null;
  }
}
