import 'package:receipto/features/ai_assistant/domain/models/ai_search_query.dart';

enum AIStructuredResponseType {
  products,
  receipts,
  warranties,
  summary,
  categories,
  productHistory,
  empty,
  error,
  textOnly,
  actionTriggered,
}

/// A product line item retrieved from real receipt records.
class AIProductItem {
  final String name;
  final double? price; // Unit price or total item price (distinguished from receipt total)
  final double? unitPrice;
  final int quantity;
  final String category;
  final DateTime? purchaseDate;
  final String? purchaseDateStr;
  final String merchantName;
  final String receiptId;
  final double? receiptTotal;
  final String? warrantyStatus; // 'ACTIVE', 'EXPIRING SOON', 'EXPIRED', 'LIFETIME', 'NO WARRANTY', 'UNKNOWN'
  final String? warrantyExpiryDate;
  final int? daysRemaining;
  final String? imageUrl;
  final List<String> otherItemsInReceipt;
  final String currency;

  const AIProductItem({
    required this.name,
    this.price,
    this.unitPrice,
    this.quantity = 1,
    required this.category,
    this.purchaseDate,
    this.purchaseDateStr,
    required this.merchantName,
    required this.receiptId,
    this.receiptTotal,
    this.warrantyStatus,
    this.warrantyExpiryDate,
    this.daysRemaining,
    this.imageUrl,
    this.otherItemsInReceipt = const [],
    this.currency = '₹',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'unit_price': unitPrice,
      'quantity': quantity,
      'category': category,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_date_str': purchaseDateStr,
      'merchant_name': merchantName,
      'receipt_id': receiptId,
      'receipt_total': receiptTotal,
      'warranty_status': warrantyStatus,
      'warranty_expiry_date': warrantyExpiryDate,
      'days_remaining': daysRemaining,
      'image_url': imageUrl,
      'other_items_in_receipt': otherItemsInReceipt,
      'currency': currency,
    };
  }
}

/// A complete receipt record retrieved from the database.
class AIReceiptItem {
  final String receiptId;
  final String merchantName;
  final double total;
  final String currency;
  final DateTime? purchaseDate;
  final String? purchaseDateStr;
  final String category;
  final int itemCount;
  final List<String> itemNames;
  final String? imageUrl;
  final String? paymentMethod;

  const AIReceiptItem({
    required this.receiptId,
    required this.merchantName,
    required this.total,
    this.currency = '₹',
    this.purchaseDate,
    this.purchaseDateStr,
    required this.category,
    this.itemCount = 0,
    this.itemNames = const [],
    this.imageUrl,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'receipt_id': receiptId,
      'merchant_name': merchantName,
      'total': total,
      'currency': currency,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_date_str': purchaseDateStr,
      'category': category,
      'item_count': itemCount,
      'item_names': itemNames,
      'image_url': imageUrl,
      'payment_method': paymentMethod,
    };
  }
}

/// A warranty record retrieved from the database.
class AIWarrantyItem {
  final String? warrantyId;
  final String? receiptId;
  final String productName;
  final String merchantName;
  final String purchaseDate;
  final String expiryDate;
  final String status;
  final int daysRemaining;
  final String? imageUrl;

  const AIWarrantyItem({
    this.warrantyId,
    this.receiptId,
    required this.productName,
    required this.merchantName,
    required this.purchaseDate,
    required this.expiryDate,
    required this.status,
    required this.daysRemaining,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'warranty_id': warrantyId,
      'receipt_id': receiptId,
      'product_name': productName,
      'merchant_name': merchantName,
      'purchase_date': purchaseDate,
      'expiry_date': expiryDate,
      'status': status,
      'days_remaining': daysRemaining,
      'image_url': imageUrl,
    };
  }
}

/// High-level financial overview metrics.
class AISummaryItem {
  final double totalSpending;
  final int transactionCount;
  final String topCategory;
  final String topMerchant;
  final String periodLabel;
  final String currency;

  const AISummaryItem({
    required this.totalSpending,
    required this.transactionCount,
    required this.topCategory,
    required this.topMerchant,
    required this.periodLabel,
    this.currency = '₹',
  });
}

/// Category spending statistics.
class AICategoryItem {
  final String category;
  final double amount;
  final double percentage;
  final int count;

  const AICategoryItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.count,
  });
}

/// Optional action command triggered by AI (e.g. open specific receipt).
class AIAction {
  final String actionType; // 'openReceipt', 'none'
  final String? targetReceiptId;
  final String? label;

  const AIAction({
    required this.actionType,
    this.targetReceiptId,
    this.label,
  });
}

/// Complete response object returned by the controlled AI Assistant.
class AIStructuredResponse {
  final String text;
  final AIStructuredResponseType type;
  final List<AIProductItem> products;
  final List<AIReceiptItem> receipts;
  final List<AIWarrantyItem> warranties;
  final AISummaryItem? summary;
  final List<AICategoryItem> categories;
  final List<String> suggestedFollowUps;
  final AIAction? action;
  final int matchedCount;
  final int totalChecked;
  final String? missingDataNotice;
  final AISearchQuery? originalQuery;

  const AIStructuredResponse({
    required this.text,
    this.type = AIStructuredResponseType.textOnly,
    this.products = const [],
    this.receipts = const [],
    this.warranties = const [],
    this.summary,
    this.categories = const [],
    this.suggestedFollowUps = const [],
    this.action,
    this.matchedCount = 0,
    this.totalChecked = 0,
    this.missingDataNotice,
    this.originalQuery,
  });

  bool get hasProducts => products.isNotEmpty;
  bool get hasReceipts => receipts.isNotEmpty;
  bool get hasWarranties => warranties.isNotEmpty;
  bool get hasSummary => summary != null;
  bool get hasCategories => categories.isNotEmpty;
}
