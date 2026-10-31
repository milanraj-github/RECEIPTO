enum AIQueryIntentType {
  searchProducts,
  searchReceipts,
  productHistory,
  productDetails,
  warrantySearch,
  spendingSummary,
  categoryBreakdown,
  merchantPurchases,
  repeatPurchases,
  openReceipt,
  general,
}

enum AISortField {
  price,
  date,
  name,
  count,
}

enum AISortOrder {
  asc,
  desc,
}

enum AIWarrantyFilter {
  any,
  active,
  expiringSoon,
  expired,
  lifetime,
  missing,
}

/// Strongly-typed filter parameters for controlled AI queries.
class AISearchQuery {
  final AIQueryIntentType intent;
  final String targetType; // 'product', 'receipt', 'warranty', 'summary', 'category', 'action'
  final String? productName;
  final String? category;
  final String? merchant;
  final String? brand;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? dateLabel;
  final int? year;
  final int? month;
  final int? days;
  final AIWarrantyFilter warrantyFilter;
  final AISortField sortBy;
  final AISortOrder sortOrder;
  final int limit;
  final bool isFollowUp;
  final String? targetReceiptId;

  const AISearchQuery({
    this.intent = AIQueryIntentType.general,
    this.targetType = 'summary',
    this.productName,
    this.category,
    this.merchant,
    this.brand,
    this.minPrice,
    this.maxPrice,
    this.startDate,
    this.endDate,
    this.dateLabel,
    this.year,
    this.month,
    this.days,
    this.warrantyFilter = AIWarrantyFilter.any,
    this.sortBy = AISortField.date,
    this.sortOrder = AISortOrder.desc,
    this.limit = 20,
    this.isFollowUp = false,
    this.targetReceiptId,
  });

  AISearchQuery copyWith({
    AIQueryIntentType? intent,
    String? targetType,
    String? productName,
    String? category,
    String? merchant,
    String? brand,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
    String? dateLabel,
    int? year,
    int? month,
    int? days,
    AIWarrantyFilter? warrantyFilter,
    AISortField? sortBy,
    AISortOrder? sortOrder,
    int? limit,
    bool? isFollowUp,
    String? targetReceiptId,
  }) {
    return AISearchQuery(
      intent: intent ?? this.intent,
      targetType: targetType ?? this.targetType,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      brand: brand ?? this.brand,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dateLabel: dateLabel ?? this.dateLabel,
      year: year ?? this.year,
      month: month ?? this.month,
      days: days ?? this.days,
      warrantyFilter: warrantyFilter ?? this.warrantyFilter,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      limit: limit ?? this.limit,
      isFollowUp: isFollowUp ?? this.isFollowUp,
      targetReceiptId: targetReceiptId ?? this.targetReceiptId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': intent.name,
      'targetType': targetType,
      'productName': productName,
      'category': category,
      'merchant': merchant,
      'brand': brand,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'dateLabel': dateLabel,
      'year': year,
      'month': month,
      'days': days,
      'warrantyFilter': warrantyFilter.name,
      'sortBy': sortBy.name,
      'sortOrder': sortOrder.name,
      'limit': limit,
      'isFollowUp': isFollowUp,
      'targetReceiptId': targetReceiptId,
    };
  }
}

/// Stores conversation state across consecutive user turns.
class AIConversationContext {
  final AISearchQuery? lastQuery;
  final List<dynamic> lastResults; // List of AIProductItem or AIReceiptItem
  final dynamic lastFocusedItem; // Single item if asked "which is the most expensive"
  final String? lastUserQuestion;

  const AIConversationContext({
    this.lastQuery,
    this.lastResults = const [],
    this.lastFocusedItem,
    this.lastUserQuestion,
  });

  AIConversationContext copyWith({
    AISearchQuery? lastQuery,
    List<dynamic>? lastResults,
    dynamic lastFocusedItem,
    String? lastUserQuestion,
  }) {
    return AIConversationContext(
      lastQuery: lastQuery ?? this.lastQuery,
      lastResults: lastResults ?? this.lastResults,
      lastFocusedItem: lastFocusedItem ?? this.lastFocusedItem,
      lastUserQuestion: lastUserQuestion ?? this.lastUserQuestion,
    );
  }
}
