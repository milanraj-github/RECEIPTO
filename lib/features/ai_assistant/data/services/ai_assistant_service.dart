import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:receipto/core/services/ai_categorizer_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/features/ai_assistant/domain/models/ai_search_query.dart';
import 'package:receipto/features/ai_assistant/domain/models/ai_structured_response.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

final aiAssistantServiceProvider = Provider<AIAssistantService>((ref) {
  final receiptDb = ref.watch(receiptDatabaseServiceProvider);
  final warrantyDb = ref.watch(warrantyDatabaseServiceProvider);
  final categorizer = ref.watch(aiCategorizerServiceProvider);
  return AIAssistantService(receiptDb, warrantyDb, categorizer);
});

class AIAssistantService {
  final ReceiptDatabaseService _receiptDb;
  final WarrantyDatabaseService _warrantyDb;
  final AICategorizerService _categorizer;

  final Map<String, String> _cache = {};
  AIConversationContext _context = const AIConversationContext();

  AIAssistantService(this._receiptDb, this._warrantyDb, this._categorizer);

  String _getGeminiApiKey() => dotenv.env['GEMINI_API_KEY'] ?? '';

  List<String> _getGroqApiKeys() {
    final raw = dotenv.env['GROQ_API_KEYS'] ?? dotenv.env['GROQ_API_KEY'] ?? '';
    return raw
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
  }

  void clearCache() {
    _cache.clear();
    _context = const AIConversationContext();
  }

  void resetContext() {
    _context = const AIConversationContext();
  }

  AIConversationContext get context => _context;

  /// Legacy interface for plain text responses
  Future<String> ask(String question, {String? overrideUserId}) async {
    final structured = await askStructured(question, overrideUserId: overrideUserId);
    return structured.text;
  }

  /// Full interactive query engine returning structured Flutter cards & actions
  Future<AIStructuredResponse> askStructured(String question, {String? overrideUserId}) async {
    String? userId = overrideUserId;
    if (userId == null) {
      try {
        userId = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {
        userId = null;
      }
    }
    if (userId == null) {
      return const AIStructuredResponse(
        text: "You must be logged in to ask the Receipto AI Assistant.",
        type: AIStructuredResponseType.error,
      );
    }

    try {
      // 1. Fetch real, authentic user records (isolated by userId)
      final rawReceipts = await _receiptDb.fetchAllReceipts(userId: userId);
      final rawWarranties = await _warrantyDb.fetchAllWarranties(userId);

      // 2. Extract line items, receipts, and warranties into unified strongly-typed structures
      final allProducts = _extractAllProducts(rawReceipts, rawWarranties);
      final allReceipts = _extractAllReceipts(rawReceipts);
      final allWarranties = _extractAllWarranties(rawWarranties);

      // 3. Parse intent into an AISearchQuery (via LLM or local rule engine with context merging)
      final parsedQuery = await _parseQuery(question, _context);

      // 4. Execute deterministic query against real user data
      final response = _executeQuery(
        question: question,
        query: parsedQuery,
        allProducts: allProducts,
        allReceipts: allReceipts,
        allWarranties: allWarranties,
        rawReceipts: rawReceipts,
      );

      // 5. Update conversation context for consecutive follow-ups
      _context = _context.copyWith(
        lastQuery: parsedQuery,
        lastResults: response.products.isNotEmpty
            ? response.products
            : (response.receipts.isNotEmpty ? response.receipts : response.warranties),
        lastFocusedItem: response.products.isNotEmpty
            ? response.products.first
            : (response.receipts.isNotEmpty ? response.receipts.first : null),
        lastUserQuestion: question,
      );

      return response;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[AI Assistant] Error: $e\n$stack');
      }
      return _generateOfflineFallback(question);
    }
  }

  // =========================================================================
  // DATA EXTRACTION & CORRELATION
  // =========================================================================

  List<AIProductItem> _extractAllProducts(
    List<Map<String, dynamic>> rawReceipts,
    List<WarrantyModel> warranties,
  ) {
    final List<AIProductItem> products = [];

    for (final r in rawReceipts) {
      final receiptId = r['id']?.toString() ?? '';
      final merchantName = (r['merchant_name'] as String?)?.trim() ?? 'Unknown Merchant';
      final receiptCategory = (r['category'] as String?)?.trim() ?? 'Others';
      final receiptDateStr = r['date']?.toString().trim();
      final purchaseDate = receiptDateStr != null ? DateTime.tryParse(receiptDateStr) : null;
      final currency = (r['currency'] as String?)?.trim().isNotEmpty == true ? r['currency'] as String : '₹';
      final imageUrl = r['image_url'] as String? ?? r['file_url'] as String?;
      final receiptTotal = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']);

      final rawItems = (r['receipt_items'] as List<dynamic>?) ?? (r['items'] as List<dynamic>?) ?? [];
      final List<String> allItemNames = rawItems
          .map((i) => (i['name'] as String?)?.trim() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      for (final item in rawItems) {
        final name = (item['name'] as String?)?.trim() ?? 'Unknown Item';
        final int qty = (item['quantity'] as num?)?.toInt() ?? 1;

        // Deterministic price extraction: line item price != receipt total
        final double? rawTotal = ReceiptModel.parseDouble(item['total_price']) ?? ReceiptModel.parseDouble(item['price']);
        final double? rawUnit = ReceiptModel.parseDouble(item['unit_price']);

        double? price;
        double? unitPrice;

        if (rawTotal != null && rawTotal > 0) {
          price = rawTotal;
          unitPrice = rawUnit ?? (qty > 0 ? rawTotal / qty : rawTotal);
        } else if (rawUnit != null && rawUnit > 0) {
          unitPrice = rawUnit;
          price = rawUnit * qty;
        }

        // Category resolution
        String itemCategory = (item['category'] as String?)?.trim() ?? '';
        if (itemCategory.isEmpty) {
          itemCategory = _categorizer.inferItemCategory(name, receiptCategory: receiptCategory);
        }
        final resolvedCat = _categorizer.resolveSupportedCategory(itemCategory);

        // Warranty correlation
        String? warrantyStatus;
        String? warrantyExpiry;
        int? daysRemaining;

        // 1. Try matching with warranty records
        final matchedWarr = _matchWarranty(warranties, receiptId, name);
        if (matchedWarr != null) {
          warrantyStatus = matchedWarr.status;
          warrantyExpiry = matchedWarr.expiryDate;
          daysRemaining = WarrantyUtils.calculateDaysRemaining(matchedWarr.expiryDate);
        } else if (item['warranty_expiry'] != null) {
          warrantyExpiry = item['warranty_expiry']?.toString();
          if (warrantyExpiry != null && warrantyExpiry.isNotEmpty) {
            daysRemaining = WarrantyUtils.calculateDaysRemaining(warrantyExpiry);
            warrantyStatus = daysRemaining >= 0
                ? (daysRemaining <= 30 ? 'EXPIRING SOON' : 'ACTIVE')
                : 'EXPIRED';
          }
        }

        final otherItems = allItemNames.where((n) => n.toLowerCase() != name.toLowerCase()).toList();

        products.add(AIProductItem(
          name: name,
          price: price,
          unitPrice: unitPrice,
          quantity: qty,
          category: resolvedCat,
          purchaseDate: purchaseDate,
          purchaseDateStr: receiptDateStr,
          merchantName: merchantName,
          receiptId: receiptId,
          receiptTotal: receiptTotal,
          warrantyStatus: warrantyStatus,
          warrantyExpiryDate: warrantyExpiry,
          daysRemaining: daysRemaining,
          imageUrl: imageUrl,
          otherItemsInReceipt: otherItems,
          currency: currency,
        ));
      }
    }

    return products;
  }

  WarrantyModel? _matchWarranty(
    List<WarrantyModel> warranties,
    String receiptId,
    String productName,
  ) {
    if (warranties.isEmpty) return null;
    final lowerName = productName.toLowerCase();

    // 1. Exact receiptId and matching product name
    for (final w in warranties) {
      if (w.receiptId == receiptId) {
        final wName = w.productName.toLowerCase();
        if (wName.contains(lowerName) || lowerName.contains(wName)) {
          return w;
        }
      }
    }

    // 2. Exact receiptId if product name has matching word overlap
    final byReceipt = warranties.where((w) => w.receiptId == receiptId).toList();
    for (final w in byReceipt) {
      final wWords = w.productName.toLowerCase().split(' ').where((word) => word.length >= 3);
      for (final word in wWords) {
        if (lowerName.contains(word)) {
          return w;
        }
      }
    }

    // 3. Fuzzy name match across all user warranties
    for (final w in warranties) {
      final wName = w.productName.toLowerCase();
      if (wName.isNotEmpty && (wName.contains(lowerName) || lowerName.contains(wName))) {
        return w;
      }
    }

    return null;
  }

  List<AIReceiptItem> _extractAllReceipts(List<Map<String, dynamic>> rawReceipts) {
    final List<AIReceiptItem> receipts = [];

    for (final r in rawReceipts) {
      final id = r['id']?.toString() ?? '';
      final merchant = (r['merchant_name'] as String?)?.trim() ?? 'Unknown Merchant';
      final total = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
      final currency = (r['currency'] as String?)?.trim().isNotEmpty == true ? r['currency'] as String : '₹';
      final dateStr = r['date']?.toString().trim();
      final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
      final rawCat = (r['category'] as String?)?.trim() ?? 'Others';
      final category = _categorizer.resolveSupportedCategory(rawCat);
      final payMethod = r['payment_method'] as String?;
      final imageUrl = r['image_url'] as String? ?? r['file_url'] as String?;

      final rawItems = (r['receipt_items'] as List<dynamic>?) ?? (r['items'] as List<dynamic>?) ?? [];
      final itemNames = rawItems
          .map((i) => (i['name'] as String?)?.trim() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      receipts.add(AIReceiptItem(
        receiptId: id,
        merchantName: merchant,
        total: total,
        currency: currency,
        purchaseDate: date,
        purchaseDateStr: dateStr,
        category: category,
        itemCount: itemNames.length,
        itemNames: itemNames,
        imageUrl: imageUrl,
        paymentMethod: payMethod,
      ));
    }

    return receipts;
  }

  List<AIWarrantyItem> _extractAllWarranties(List<WarrantyModel> rawWarranties) {
    return rawWarranties.map((w) {
      final days = WarrantyUtils.calculateDaysRemaining(w.expiryDate);
      return AIWarrantyItem(
        warrantyId: w.id,
        receiptId: w.receiptId,
        productName: w.productName,
        merchantName: w.merchantName,
        purchaseDate: w.purchaseDate,
        expiryDate: w.expiryDate,
        status: w.status,
        daysRemaining: days,
        imageUrl: w.imageUrl,
      );
    }).toList();
  }

  // =========================================================================
  // NATURAL LANGUAGE INTENT & QUERY PARSING (GROQ / GEMINI / LOCAL RULE ENGINE)
  // =========================================================================

  Future<AISearchQuery> _parseQuery(String question, AIConversationContext context) async {
    final clean = question.trim().toLowerCase();

    // Check for explicit contextual follow-ups first
    if (_isFollowUpQuery(clean, context)) {
      return _buildFollowUpQuery(clean, context);
    }

    // Try LLM parsing with JSON schema
    try {
      final llmResult = await _detectIntentWithLLM(question);
      if (llmResult != null) {
        return _convertJsonToQuery(llmResult);
      }
    } catch (e) {
      if (kDebugMode) print('[AI Assistant] LLM parsing failed: $e, using deterministic local parser.');
    }

    // Fallback to high-precision local rule parser
    return _parseQueryLocally(question, context);
  }

  bool _isFollowUpQuery(String clean, AIConversationContext context) {
    if (context.lastQuery == null) return false;

    // Follow up patterns
    if (clean.startsWith('only ') ||
        clean.startsWith('just ') ||
        clean.startsWith('filter by ') ||
        clean.contains('sort by') ||
        clean.contains('sort them') ||
        clean.contains('which is the most') ||
        clean.contains('which is the cheapest') ||
        clean.contains('which is most') ||
        clean.contains('open its receipt') ||
        clean.contains('open the receipt') ||
        clean.contains('open that receipt') ||
        clean.contains('open receipt') ||
        clean.contains('show its receipt') ||
        clean.contains('what else was bought') ||
        clean.contains('what other items') ||
        clean.contains('have i bought this before') ||
        clean.contains('purchase history')) {
      return true;
    }

    return false;
  }

  AISearchQuery _buildFollowUpQuery(String clean, AIConversationContext context) {
    final base = context.lastQuery!;

    // 1. "Open its receipt" or "Open receipt"
    if (clean.contains('open') && clean.contains('receipt')) {
      String? targetId;
      if (context.lastFocusedItem != null) {
        if (context.lastFocusedItem is AIProductItem) {
          targetId = (context.lastFocusedItem as AIProductItem).receiptId;
        } else if (context.lastFocusedItem is AIReceiptItem) {
          targetId = (context.lastFocusedItem as AIReceiptItem).receiptId;
        } else if (context.lastFocusedItem is AIWarrantyItem) {
          targetId = (context.lastFocusedItem as AIWarrantyItem).receiptId;
        }
      } else if (context.lastResults.isNotEmpty) {
        final first = context.lastResults.first;
        if (first is AIProductItem) targetId = first.receiptId;
        if (first is AIReceiptItem) targetId = first.receiptId;
        if (first is AIWarrantyItem) targetId = first.receiptId;
      }

      return base.copyWith(
        intent: AIQueryIntentType.openReceipt,
        targetType: 'action',
        targetReceiptId: targetId,
        isFollowUp: true,
      );
    }

    // 2. "Which is the most expensive?"
    if (clean.contains('most expensive') || clean.contains('highest price')) {
      return base.copyWith(
        sortBy: AISortField.price,
        sortOrder: AISortOrder.desc,
        limit: 1,
        isFollowUp: true,
      );
    }

    // 3. "Which is the cheapest?"
    if (clean.contains('cheapest') || clean.contains('lowest price')) {
      return base.copyWith(
        sortBy: AISortField.price,
        sortOrder: AISortOrder.asc,
        limit: 1,
        isFollowUp: true,
      );
    }

    // 4. "Sort them by price"
    if (clean.contains('sort') && clean.contains('price')) {
      final isAsc = clean.contains('low to high') || clean.contains('ascending');
      return base.copyWith(
        sortBy: AISortField.price,
        sortOrder: isAsc ? AISortOrder.asc : AISortOrder.desc,
        isFollowUp: true,
      );
    }

    // 5. "Sort them by date"
    if (clean.contains('sort') && clean.contains('date')) {
      final isAsc = clean.contains('oldest') || clean.contains('ascending');
      return base.copyWith(
        sortBy: AISortField.date,
        sortOrder: isAsc ? AISortOrder.asc : AISortOrder.desc,
        isFollowUp: true,
      );
    }

    // 6. "Only electronics" or "only groceries"
    for (final cat in _categorizer.supportedCategories) {
      if (clean.contains(cat.toLowerCase())) {
        return base.copyWith(
          category: cat,
          isFollowUp: true,
        );
      }
    }

    // 7. "What other items were purchased with it?"
    if (clean.contains('other items') || clean.contains('what else')) {
      return base.copyWith(
        intent: AIQueryIntentType.productDetails,
        targetType: 'product_details',
        isFollowUp: true,
      );
    }

    // 8. "Purchase history"
    if (clean.contains('purchase history') || clean.contains('bought before') || clean.contains('all purchases')) {
      return base.copyWith(
        intent: AIQueryIntentType.productHistory,
        targetType: 'history',
        isFollowUp: true,
      );
    }

    return base.copyWith(isFollowUp: true);
  }

  Future<Map<String, dynamic>?> _detectIntentWithLLM(String question) async {
    final systemPrompt = '''
You are the natural language query parser for Receipto financial assistant.
Parse the user's question into typed query parameters. Output ONLY raw JSON.

Output JSON structure:
{
  "intent": "searchProducts | searchReceipts | productHistory | productDetails | warrantySearch | spendingSummary | categoryBreakdown | merchantPurchases | repeatPurchases | openReceipt | general",
  "target_type": "product | receipt | warranty | summary | category | action",
  "product_name": "string or null",
  "category": "Electronics | Groceries | Food & Dining | Fuel | Shopping | Fashion | Furniture | Home Appliances | Healthcare | Travel | Utilities | Others | null",
  "merchant": "string or null",
  "brand": "string or null",
  "min_price": number or null,
  "max_price": number or null,
  "date_label": "this_month | last_month | this_year | last_year | last_30_days | last_6_months | null",
  "warranty_filter": "active | expiring_soon | expired | lifetime | missing | any",
  "days": integer or null,
  "sort_by": "price | date | name | count",
  "sort_order": "asc | desc",
  "limit": integer (default 20)
}
''';

    // 1. Try Groq API
    final groqKeys = _getGroqApiKeys();
    for (final groqKey in groqKeys) {
      try {
        final response = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $groqKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": "openai/gpt-oss-120b",
            "messages": [
              {"role": "system", "content": systemPrompt},
              {"role": "user", "content": "Query: $question"}
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.0
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices'][0]['message']['content'];
          return jsonDecode(text.trim()) as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    // 2. Try Gemini
    final geminiKey = _getGeminiApiKey();
    if (geminiKey.isNotEmpty) {
      try {
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiKey';
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": systemPrompt},
                  {"text": "Query: $question"}
                ]
              }
            ],
            "generationConfig": {"responseMimeType": "application/json"}
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return jsonDecode(text.trim()) as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    return null;
  }

  AISearchQuery _convertJsonToQuery(Map<String, dynamic> json) {
    final intentStr = json['intent']?.toString() ?? 'general';
    AIQueryIntentType intent = AIQueryIntentType.general;
    for (final val in AIQueryIntentType.values) {
      if (val.name.toLowerCase() == intentStr.toLowerCase()) {
        intent = val;
        break;
      }
    }

    final targetType = json['target_type']?.toString() ?? 'product';

    final sortFieldStr = json['sort_by']?.toString() ?? 'date';
    AISortField sortField = AISortField.date;
    if (sortFieldStr == 'price') sortField = AISortField.price;
    if (sortFieldStr == 'name') sortField = AISortField.name;
    if (sortFieldStr == 'count') sortField = AISortField.count;

    final sortOrderStr = json['sort_order']?.toString() ?? 'desc';
    final sortOrder = sortOrderStr == 'asc' ? AISortOrder.asc : AISortOrder.desc;

    final wFilterStr = json['warranty_filter']?.toString() ?? 'any';
    AIWarrantyFilter wFilter = AIWarrantyFilter.any;
    if (wFilterStr.contains('expiring')) wFilter = AIWarrantyFilter.expiringSoon;
    if (wFilterStr.contains('expired')) wFilter = AIWarrantyFilter.expired;
    if (wFilterStr.contains('active')) wFilter = AIWarrantyFilter.active;
    if (wFilterStr.contains('lifetime')) wFilter = AIWarrantyFilter.lifetime;
    if (wFilterStr.contains('missing') || wFilterStr.contains('no_warranty')) wFilter = AIWarrantyFilter.missing;

    // Date range resolution
    final dateLabel = json['date_label']?.toString();
    final dateRange = _resolveDateLabel(dateLabel);

    return AISearchQuery(
      intent: intent,
      targetType: targetType,
      productName: json['product_name']?.toString(),
      category: json['category'] != null ? _categorizer.resolveSupportedCategory(json['category'].toString()) : null,
      merchant: json['merchant']?.toString(),
      brand: json['brand']?.toString(),
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      startDate: dateRange?['start'],
      endDate: dateRange?['end'],
      dateLabel: dateLabel,
      warrantyFilter: wFilter,
      days: (json['days'] as num?)?.toInt(),
      sortBy: sortField,
      sortOrder: sortOrder,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }

  Map<String, DateTime>? _resolveDateLabel(String? label) {
    if (label == null) return null;
    final now = DateTime.now();
    final lower = label.toLowerCase();

    if (lower.contains('this_month') || lower == 'this month') {
      return {
        'start': DateTime(now.year, now.month, 1),
        'end': DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      };
    }
    if (lower.contains('last_month') || lower == 'last month') {
      return {
        'start': DateTime(now.year, now.month - 1, 1),
        'end': DateTime(now.year, now.month, 0, 23, 59, 59),
      };
    }
    if (lower.contains('this_year') || lower == 'this year') {
      return {
        'start': DateTime(now.year, 1, 1),
        'end': DateTime(now.year, 12, 31, 23, 59, 59),
      };
    }
    if (lower.contains('last_year') || lower == 'last year') {
      return {
        'start': DateTime(now.year - 1, 1, 1),
        'end': DateTime(now.year - 1, 12, 31, 23, 59, 59),
      };
    }
    if (lower.contains('last_30_days') || lower.contains('30 days')) {
      return {
        'start': now.subtract(const Duration(days: 30)),
        'end': now,
      };
    }
    if (lower.contains('last_6_months') || lower.contains('6 months')) {
      return {
        'start': DateTime(now.year, now.month - 6, now.day),
        'end': now,
      };
    }
    return null;
  }

  /// High-precision deterministic rule parser for offline / instant query handling
  AISearchQuery _parseQueryLocally(String question, AIConversationContext context) {
    final lower = question.toLowerCase();

    // 1. Target Type Detection: receipt vs product vs warranty vs summary
    final bool isReceiptQuery = lower.contains('receipt') || lower.contains('invoice') || lower.contains('bill');
    final bool isWarrantyQuery = lower.contains('warranty') || lower.contains('warranties') || lower.contains('guarantee');
    final bool isSpendingQuery = lower.contains('how much did i spend') || lower.contains('total spend') || lower.contains('total expense');
    final bool isCategoryQuery = lower.contains('category') || lower.contains('categories');
    final bool isRepeatQuery = lower.contains('multiple times') || lower.contains('bought before') || lower.contains('frequent');

    String targetType = 'product';
    AIQueryIntentType intent = AIQueryIntentType.searchProducts;

    if (isReceiptQuery && !lower.contains('product') && !lower.contains('item')) {
      targetType = 'receipt';
      intent = AIQueryIntentType.searchReceipts;
    } else if (isWarrantyQuery && !lower.contains('product') && !lower.contains('price')) {
      targetType = 'warranty';
      intent = AIQueryIntentType.warrantySearch;
    } else if (isSpendingQuery) {
      targetType = 'summary';
      intent = AIQueryIntentType.spendingSummary;
    } else if (isCategoryQuery) {
      targetType = 'category';
      intent = AIQueryIntentType.categoryBreakdown;
    } else if (isRepeatQuery) {
      targetType = 'product';
      intent = AIQueryIntentType.repeatPurchases;
    }

    // 2. Extract numeric price constraints (above, below, between)
    double? minPrice;
    double? maxPrice;

    // Pattern: between X and Y
    final betweenMatch = RegExp(r'between\s+(?:₹|rs\.?|inr)?\s*([\d,]+)\s+and\s+(?:₹|rs\.?|inr)?\s*([\d,]+)').firstMatch(lower);
    if (betweenMatch != null) {
      minPrice = double.tryParse(betweenMatch.group(1)!.replaceAll(',', ''));
      maxPrice = double.tryParse(betweenMatch.group(2)!.replaceAll(',', ''));
    } else {
      // Pattern: above / more than / greater than / >
      final aboveMatch = RegExp(r'(?:above|more than|greater than|>|over)\s+(?:₹|rs\.?|inr)?\s*([\d,]+)').firstMatch(lower);
      if (aboveMatch != null) {
        minPrice = double.tryParse(aboveMatch.group(1)!.replaceAll(',', ''));
      }

      // Pattern: below / less than / under / <
      final belowMatch = RegExp(r'(?:below|less than|under|<)\s+(?:₹|rs\.?|inr)?\s*([\d,]+)').firstMatch(lower);
      if (belowMatch != null) {
        maxPrice = double.tryParse(belowMatch.group(1)!.replaceAll(',', ''));
      }
    }

    // 3. Extract Category
    String? category;
    for (final cat in _categorizer.supportedCategories) {
      if (lower.contains(cat.toLowerCase())) {
        category = cat;
        break;
      }
    }

    // 4. Extract Date range
    Map<String, DateTime>? dateRange;
    String? dateLabel;

    if (lower.contains('this month')) {
      dateLabel = 'this_month';
      dateRange = _resolveDateLabel(dateLabel);
    } else if (lower.contains('last month')) {
      dateLabel = 'last_month';
      dateRange = _resolveDateLabel(dateLabel);
    } else if (lower.contains('this year')) {
      dateLabel = 'this_year';
      dateRange = _resolveDateLabel(dateLabel);
    } else if (lower.contains('last year')) {
      dateLabel = 'last_year';
      dateRange = _resolveDateLabel(dateLabel);
    } else if (lower.contains('last 6 months')) {
      dateLabel = 'last_6_months';
      dateRange = _resolveDateLabel(dateLabel);
    } else if (lower.contains('last 30 days')) {
      dateLabel = 'last_30_days';
      dateRange = _resolveDateLabel(dateLabel);
    }

    // 5. Extract Warranty Filter
    AIWarrantyFilter wFilter = AIWarrantyFilter.any;
    if (lower.contains('expiring soon') || lower.contains('expiring this month') || lower.contains('expires soon')) {
      wFilter = AIWarrantyFilter.expiringSoon;
    } else if (lower.contains('expired')) {
      wFilter = AIWarrantyFilter.expired;
    } else if (lower.contains('under warranty') || lower.contains('active warranty')) {
      wFilter = AIWarrantyFilter.active;
    } else if (lower.contains('lifetime')) {
      wFilter = AIWarrantyFilter.lifetime;
    } else if (lower.contains('no warranty') || lower.contains('without warranty') || lower.contains('missing warranty')) {
      wFilter = AIWarrantyFilter.missing;
    }

    // 6. Extract Sorting & Limits
    AISortField sortBy = AISortField.date;
    AISortOrder sortOrder = AISortOrder.desc;
    int limit = 20;

    if (lower.contains('most expensive') || lower.contains('highest price') || lower.contains('top priced')) {
      sortBy = AISortField.price;
      sortOrder = AISortOrder.desc;
      if (lower.contains('top 5') || lower.contains('five most expensive')) limit = 5;
      if (lower.contains('top 10') || lower.contains('ten most expensive')) limit = 10;
      if (lower.contains('the most expensive') || lower.contains('what is my most expensive')) limit = 1;
    } else if (lower.contains('cheapest') || lower.contains('lowest price') || lower.contains('least expensive')) {
      sortBy = AISortField.price;
      sortOrder = AISortOrder.asc;
      if (lower.contains('top 5') || lower.contains('five cheapest')) limit = 5;
      if (lower.contains('the cheapest') || lower.contains('what is my cheapest')) limit = 1;
    } else if (lower.contains('sort by price')) {
      sortBy = AISortField.price;
      sortOrder = lower.contains('asc') ? AISortOrder.asc : AISortOrder.desc;
    } else if (lower.contains('sort by date') || lower.contains('sort by purchase date')) {
      sortBy = AISortField.date;
      sortOrder = lower.contains('asc') ? AISortOrder.asc : AISortOrder.desc;
    } else if (lower.contains('latest') || lower.contains('newest')) {
      sortBy = AISortField.date;
      sortOrder = AISortOrder.desc;
      if (lower.contains('the latest') || lower.contains('latest receipt') || lower.contains('latest product')) limit = 1;
    } else if (lower.contains('oldest')) {
      sortBy = AISortField.date;
      sortOrder = AISortOrder.asc;
      if (lower.contains('the oldest') || lower.contains('oldest receipt')) limit = 1;
    }

    // 7. Extract Merchant / Brand keywords
    String? merchant;
    final merchantMatch = RegExp(r'\b(?:from|at)\b\s+([a-zA-Z0-9\s&]+?)(?:\s+receipts|\s+products|\s+store|\s+shop|$|\.|\?)').firstMatch(question);
    if (merchantMatch != null) {
      final cand = merchantMatch.group(1)!.trim();
      if (!cand.toLowerCase().contains('last') &&
          !cand.toLowerCase().contains('this') &&
          !cand.toLowerCase().contains('my') &&
          cand.length > 2) {
        merchant = cand;
      }
    }

    return AISearchQuery(
      intent: intent,
      targetType: targetType,
      minPrice: minPrice,
      maxPrice: maxPrice,
      category: category,
      merchant: merchant,
      startDate: dateRange?['start'],
      endDate: dateRange?['end'],
      dateLabel: dateLabel,
      warrantyFilter: wFilter,
      sortBy: sortBy,
      sortOrder: sortOrder,
      limit: limit,
    );
  }

  // =========================================================================
  // DETERMINISTIC QUERY EXECUTION
  // =========================================================================

  AIStructuredResponse _executeQuery({
    required String question,
    required AISearchQuery query,
    required List<AIProductItem> allProducts,
    required List<AIReceiptItem> allReceipts,
    required List<AIWarrantyItem> allWarranties,
    required List<Map<String, dynamic>> rawReceipts,
  }) {
    // 1. Action Trigger (e.g. Open Receipt)
    if (query.intent == AIQueryIntentType.openReceipt && query.targetReceiptId != null) {
      return AIStructuredResponse(
        text: "Opening Receipt #${query.targetReceiptId}...",
        type: AIStructuredResponseType.actionTriggered,
        action: AIAction(
          actionType: 'openReceipt',
          targetReceiptId: query.targetReceiptId,
          label: 'View Receipt Details',
        ),
        originalQuery: query,
      );
    }

    // 2. Product Search
    if (query.targetType == 'product' || query.intent == AIQueryIntentType.searchProducts) {
      return _executeProductQuery(question, query, allProducts);
    }

    // 3. Product History / Repeat Purchases
    if (query.intent == AIQueryIntentType.productHistory || query.intent == AIQueryIntentType.repeatPurchases) {
      return _executeRepeatAndHistoryQuery(question, query, allProducts);
    }

    // 4. Receipt Search
    if (query.targetType == 'receipt' || query.intent == AIQueryIntentType.searchReceipts) {
      return _executeReceiptQuery(question, query, allReceipts);
    }

    // 5. Warranty Search
    if (query.targetType == 'warranty' || query.intent == AIQueryIntentType.warrantySearch) {
      return _executeWarrantyQuery(question, query, allWarranties);
    }

    // 6. Category Breakdown
    if (query.targetType == 'category' || query.intent == AIQueryIntentType.categoryBreakdown) {
      return _executeCategoryQuery(question, query, allReceipts);
    }

    // 7. Spending Summary
    return _executeSummaryQuery(question, query, allReceipts, allProducts);
  }

  AIStructuredResponse _executeProductQuery(
    String question,
    AISearchQuery query,
    List<AIProductItem> allProducts,
  ) {
    var matches = allProducts.where((p) {
      // 1. Min Price
      if (query.minPrice != null) {
        if (p.price == null || p.price! < query.minPrice!) return false;
      }

      // 2. Max Price
      if (query.maxPrice != null) {
        if (p.price == null || p.price! > query.maxPrice!) return false;
      }

      // 3. Category
      if (query.category != null) {
        if (p.category.toLowerCase() != query.category!.toLowerCase()) return false;
      }

      // 4. Merchant
      if (query.merchant != null) {
        if (!p.merchantName.toLowerCase().contains(query.merchant!.toLowerCase())) return false;
      }

      // 5. Product Name
      if (query.productName != null) {
        if (!p.name.toLowerCase().contains(query.productName!.toLowerCase())) return false;
      }

      // 6. Date Range
      if (query.startDate != null) {
        if (p.purchaseDate == null || p.purchaseDate!.isBefore(query.startDate!)) return false;
      }
      if (query.endDate != null) {
        if (p.purchaseDate == null || p.purchaseDate!.isAfter(query.endDate!)) return false;
      }

      // 7. Warranty Filter
      if (query.warrantyFilter != AIWarrantyFilter.any) {
        switch (query.warrantyFilter) {
          case AIWarrantyFilter.active:
            if (p.warrantyStatus != 'ACTIVE' && p.warrantyStatus != 'EXPIRING SOON' && p.warrantyStatus != 'LIFETIME') {
              return false;
            }
            break;
          case AIWarrantyFilter.expiringSoon:
            if (p.warrantyStatus != 'EXPIRING SOON' &&
                (p.daysRemaining == null || p.daysRemaining! < 0 || p.daysRemaining! > (query.days ?? 30))) {
              return false;
            }
            break;
          case AIWarrantyFilter.expired:
            if (p.warrantyStatus != 'EXPIRED' && (p.daysRemaining == null || p.daysRemaining! >= 0)) {
              return false;
            }
            break;
          case AIWarrantyFilter.lifetime:
            if (p.warrantyStatus != 'LIFETIME') return false;
            break;
          case AIWarrantyFilter.missing:
            if (p.warrantyStatus != null && p.warrantyStatus != 'NO WARRANTY') return false;
            break;
          case AIWarrantyFilter.any:
            break;
        }
      }

      return true;
    }).toList();

    // Sorting
    if (query.sortBy == AISortField.price) {
      matches.sort((a, b) {
        if (query.sortOrder == AISortOrder.asc) {
          final pa = a.price ?? double.infinity;
          final pb = b.price ?? double.infinity;
          return pa.compareTo(pb);
        } else {
          final pa = a.price ?? -1.0;
          final pb = b.price ?? -1.0;
          return pb.compareTo(pa);
        }
      });
    } else if (query.sortBy == AISortField.date) {
      matches.sort((a, b) {
        final da = a.purchaseDate ?? DateTime(1970);
        final db = b.purchaseDate ?? DateTime(1970);
        return query.sortOrder == AISortOrder.asc ? da.compareTo(db) : db.compareTo(da);
      });
    } else if (query.sortBy == AISortField.name) {
      matches.sort((a, b) => a.name.compareTo(b.name));
    }

    final int totalMatches = matches.length;
    final limited = matches.take(query.limit).toList();

    if (limited.isEmpty) {
      return AIStructuredResponse(
        text: _buildProductEmptyText(query),
        type: AIStructuredResponseType.empty,
        matchedCount: 0,
        totalChecked: allProducts.length,
        suggestedFollowUps: const [
          'Show all products',
          'Show products above ₹1,000',
          'Show electronics receipts',
        ],
        originalQuery: query,
      );
    }

    final explanation = _buildProductExplanation(query, limited, totalMatches);
    final followUps = _generateProductFollowUps(query, limited);

    return AIStructuredResponse(
      text: explanation,
      type: AIStructuredResponseType.products,
      products: limited,
      matchedCount: totalMatches,
      totalChecked: allProducts.length,
      suggestedFollowUps: followUps,
      originalQuery: query,
    );
  }

  String _buildProductExplanation(AISearchQuery q, List<AIProductItem> items, int total) {
    final first = items.first;
    if (q.limit == 1) {
      if (q.sortBy == AISortField.price && q.sortOrder == AISortOrder.desc) {
        return "Your most expensive recorded product is **${first.name}** at **₹${first.price?.toStringAsFixed(0) ?? 'N/A'}** from ${first.merchantName}.";
      }
      if (q.sortBy == AISortField.price && q.sortOrder == AISortOrder.asc) {
        return "Your cheapest recorded product is **${first.name}** at **₹${first.price?.toStringAsFixed(0) ?? 'N/A'}** from ${first.merchantName}.";
      }
    }

    final StringBuffer buf = StringBuffer();
    buf.write("Found **$total product${total > 1 ? 's' : ''}**");

    if (q.category != null) {
      buf.write(" in **${q.category}**");
    }
    if (q.minPrice != null && q.maxPrice != null) {
      buf.write(" between **₹${q.minPrice!.toStringAsFixed(0)}** and **₹${q.maxPrice!.toStringAsFixed(0)}**");
    } else if (q.minPrice != null) {
      buf.write(" above **₹${q.minPrice!.toStringAsFixed(0)}**");
    } else if (q.maxPrice != null) {
      buf.write(" below **₹${q.maxPrice!.toStringAsFixed(0)}**");
    }
    if (q.dateLabel != null) {
      buf.write(" purchased **${q.dateLabel!.replaceAll('_', ' ')}**");
    }
    if (q.merchant != null) {
      buf.write(" from **${q.merchant}**");
    }
    if (q.warrantyFilter == AIWarrantyFilter.active) {
      buf.write(" that are currently **under warranty**");
    } else if (q.warrantyFilter == AIWarrantyFilter.expiringSoon) {
      buf.write(" with warranties **expiring soon**");
    }
    buf.write(":");

    return buf.toString();
  }

  String _buildProductEmptyText(AISearchQuery q) {
    final List<String> conditions = [];
    if (q.category != null) conditions.add("in category '${q.category}'");
    if (q.minPrice != null) conditions.add("above ₹${q.minPrice!.toStringAsFixed(0)}");
    if (q.maxPrice != null) conditions.add("below ₹${q.maxPrice!.toStringAsFixed(0)}");
    if (q.dateLabel != null) conditions.add("from ${q.dateLabel!.replaceAll('_', ' ')}");
    if (q.merchant != null) conditions.add("from merchant '${q.merchant}'");
    if (q.warrantyFilter != AIWarrantyFilter.any) conditions.add("matching warranty filter");

    if (conditions.isEmpty) {
      return "No product line items were found in your receipts yet.";
    }
    return "No products found matching ${conditions.join(', ')}. Try adjusting your search or filters.";
  }

  List<String> _generateProductFollowUps(AISearchQuery q, List<AIProductItem> items) {
    final List<String> chips = [];
    if (items.isNotEmpty && q.limit > 1) {
      chips.add("Which is the most expensive?");
      chips.add("Sort them by price");
    }
    if (q.category == null) {
      chips.add("Only electronics");
    }
    if (items.isNotEmpty) {
      chips.add("Open its receipt");
    }
    return chips;
  }

  AIStructuredResponse _executeRepeatAndHistoryQuery(
    String question,
    AISearchQuery query,
    List<AIProductItem> allProducts,
  ) {
    // 1. Repeat purchases across multiple receipts
    final Map<String, List<AIProductItem>> grouped = {};
    for (final p in allProducts) {
      final key = p.name.trim().toLowerCase();
      if (key.length >= 2) {
        grouped.putIfAbsent(key, () => []).add(p);
      }
    }

    final repeatGroups = grouped.entries.where((e) => e.value.length >= 2).toList();

    if (query.intent == AIQueryIntentType.repeatPurchases || question.contains('multiple times')) {
      if (repeatGroups.isEmpty) {
        return const AIStructuredResponse(
          text: "No products have been purchased multiple times across your recorded receipts.",
          type: AIStructuredResponseType.empty,
          suggestedFollowUps: ['Show most expensive products', 'Show all receipts'],
        );
      }

      final List<AIProductItem> topRepeats = [];
      for (final g in repeatGroups) {
        topRepeats.addAll(g.value);
      }

      return AIStructuredResponse(
        text: "You have purchased **${repeatGroups.length} distinct item${repeatGroups.length > 1 ? 's' : ''}** multiple times:",
        type: AIStructuredResponseType.products,
        products: topRepeats.take(15).toList(),
        matchedCount: topRepeats.length,
        suggestedFollowUps: const ['Sort by purchase date', 'Show spending summary'],
        originalQuery: query,
      );
    }

    // 2. Specific product history
    final candName = query.productName ?? question.split(' ').last;
    final matches = allProducts.where((p) => p.name.toLowerCase().contains(candName.toLowerCase())).toList();
    matches.sort((a, b) => (b.purchaseDate ?? DateTime(1970)).compareTo(a.purchaseDate ?? DateTime(1970)));

    if (matches.isEmpty) {
      return AIStructuredResponse(
        text: "No purchase history found for product '$candName'.",
        type: AIStructuredResponseType.empty,
      );
    }

    return AIStructuredResponse(
      text: "Found **${matches.length} purchase${matches.length > 1 ? 's' : ''}** of **${matches.first.name}**:",
      type: AIStructuredResponseType.products,
      products: matches,
      matchedCount: matches.length,
      suggestedFollowUps: const ['Which is the most expensive?', 'Open its receipt'],
      originalQuery: query,
    );
  }

  AIStructuredResponse _executeReceiptQuery(
    String question,
    AISearchQuery query,
    List<AIReceiptItem> allReceipts,
  ) {
    var matches = allReceipts.where((r) {
      if (query.minPrice != null && r.total < query.minPrice!) return false;
      if (query.maxPrice != null && r.total > query.maxPrice!) return false;
      if (query.category != null && r.category.toLowerCase() != query.category!.toLowerCase()) return false;
      if (query.merchant != null && !r.merchantName.toLowerCase().contains(query.merchant!.toLowerCase())) return false;
      if (query.startDate != null && (r.purchaseDate == null || r.purchaseDate!.isBefore(query.startDate!))) return false;
      if (query.endDate != null && (r.purchaseDate == null || r.purchaseDate!.isAfter(query.endDate!))) return false;
      if (query.productName != null) {
        final pName = query.productName!.toLowerCase();
        if (!r.itemNames.any((n) => n.toLowerCase().contains(pName))) return false;
      }
      return true;
    }).toList();

    // Sort
    if (query.sortBy == AISortField.price) {
      matches.sort((a, b) => query.sortOrder == AISortOrder.asc ? a.total.compareTo(b.total) : b.total.compareTo(a.total));
    } else {
      matches.sort((a, b) {
        final da = a.purchaseDate ?? DateTime(1970);
        final db = b.purchaseDate ?? DateTime(1970);
        return query.sortOrder == AISortOrder.asc ? da.compareTo(db) : db.compareTo(da);
      });
    }

    final int totalMatches = matches.length;
    final limited = matches.take(query.limit).toList();

    if (limited.isEmpty) {
      return AIStructuredResponse(
        text: "No receipts match the specified filters. Try expanding your search criteria.",
        type: AIStructuredResponseType.empty,
        suggestedFollowUps: const ['Show all receipts', 'Show receipts from last month'],
        originalQuery: query,
      );
    }

    String explanation = "Found **$totalMatches receipt${totalMatches > 1 ? 's' : ''}**";
    if (query.minPrice != null && query.maxPrice != null) {
      explanation += " between **₹${query.minPrice!.toStringAsFixed(0)}** and **₹${query.maxPrice!.toStringAsFixed(0)}**";
    } else if (query.minPrice != null) {
      explanation += " above **₹${query.minPrice!.toStringAsFixed(0)}**";
    } else if (query.maxPrice != null) {
      explanation += " below **₹${query.maxPrice!.toStringAsFixed(0)}**";
    }
    if (query.merchant != null) {
      explanation += " from **${query.merchant}**";
    }
    explanation += ":";

    return AIStructuredResponse(
      text: explanation,
      type: AIStructuredResponseType.receipts,
      receipts: limited,
      matchedCount: totalMatches,
      totalChecked: allReceipts.length,
      suggestedFollowUps: const [
        'Show products in the largest receipt',
        'Show category breakdown',
        'Show receipts from last month',
      ],
      originalQuery: query,
    );
  }

  AIStructuredResponse _executeWarrantyQuery(
    String question,
    AISearchQuery query,
    List<AIWarrantyItem> allWarranties,
  ) {
    var matches = allWarranties.where((w) {
      if (query.warrantyFilter == AIWarrantyFilter.active) {
        if (w.status != 'ACTIVE' && w.status != 'EXPIRING SOON' && w.status != 'LIFETIME') return false;
      } else if (query.warrantyFilter == AIWarrantyFilter.expiringSoon) {
        final limit = query.days ?? 30;
        if (w.daysRemaining < 0 || w.daysRemaining > limit) return false;
      } else if (query.warrantyFilter == AIWarrantyFilter.expired) {
        if (w.status != 'EXPIRED' && w.daysRemaining >= 0) return false;
      } else if (query.warrantyFilter == AIWarrantyFilter.lifetime) {
        if (w.status != 'LIFETIME') return false;
      }

      if (query.productName != null && !w.productName.toLowerCase().contains(query.productName!.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    matches.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

    if (matches.isEmpty) {
      return const AIStructuredResponse(
        text: "No warranties found matching the requested status.",
        type: AIStructuredResponseType.empty,
        suggestedFollowUps: ['Show all warranties', 'Show active warranties'],
      );
    }

    return AIStructuredResponse(
      text: "Found **${matches.length} warrant${matches.length > 1 ? 'ies' : 'y'}** in your vault:",
      type: AIStructuredResponseType.warranties,
      warranties: matches,
      matchedCount: matches.length,
      suggestedFollowUps: const [
        'Which warranty expires next?',
        'Show products without warranty',
      ],
      originalQuery: query,
    );
  }

  AIStructuredResponse _executeCategoryQuery(
    String question,
    AISearchQuery query,
    List<AIReceiptItem> allReceipts,
  ) {
    double totalSpend = 0.0;
    final Map<String, double> catSpend = {};
    final Map<String, int> catCount = {};

    for (final r in allReceipts) {
      totalSpend += r.total;
      catSpend[r.category] = (catSpend[r.category] ?? 0.0) + r.total;
      catCount[r.category] = (catCount[r.category] ?? 0) + 1;
    }

    final List<AICategoryItem> categories = [];
    catSpend.forEach((cat, spend) {
      final pct = totalSpend > 0 ? (spend / totalSpend) * 100 : 0.0;
      categories.add(AICategoryItem(
        category: cat,
        amount: spend,
        percentage: pct,
        count: catCount[cat] ?? 1,
      ));
    });

    categories.sort((a, b) => b.amount.compareTo(a.amount));

    return AIStructuredResponse(
      text: "Here is your expenditure breakdown across **${categories.length} categories** (Total: **₹${totalSpend.toStringAsFixed(0)}**):",
      type: AIStructuredResponseType.categories,
      categories: categories,
      matchedCount: categories.length,
      suggestedFollowUps: const [
        'Show electronics products',
        'Show my most expensive purchase',
        'How much did I spend this month?',
      ],
      originalQuery: query,
    );
  }

  AIStructuredResponse _executeSummaryQuery(
    String question,
    AISearchQuery query,
    List<AIReceiptItem> allReceipts,
    List<AIProductItem> allProducts,
  ) {
    double totalSpend = 0.0;
    final Map<String, double> catSpend = {};
    final Map<String, double> merchantSpend = {};

    for (final r in allReceipts) {
      totalSpend += r.total;
      catSpend[r.category] = (catSpend[r.category] ?? 0.0) + r.total;
      merchantSpend[r.merchantName] = (merchantSpend[r.merchantName] ?? 0.0) + r.total;
    }

    String topCat = 'None';
    if (catSpend.isNotEmpty) {
      final sorted = catSpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCat = sorted.first.key;
    }

    String topMerchant = 'None';
    if (merchantSpend.isNotEmpty) {
      final sorted = merchantSpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topMerchant = sorted.first.key;
    }

    final summary = AISummaryItem(
      totalSpending: totalSpend,
      transactionCount: allReceipts.length,
      topCategory: topCat,
      topMerchant: topMerchant,
      periodLabel: query.dateLabel?.replaceAll('_', ' ') ?? 'All Time',
    );

    return AIStructuredResponse(
      text: "Your total recorded expenditure is **₹${totalSpend.toStringAsFixed(0)}** across **${allReceipts.length} receipts**.\nHighest spending category: **$topCat**.\nTop merchant: **$topMerchant**.",
      type: AIStructuredResponseType.summary,
      summary: summary,
      suggestedFollowUps: const [
        'Show category breakdown',
        'Show products above ₹2,000',
        'Which is my most expensive product?',
      ],
      originalQuery: query,
    );
  }

  AIStructuredResponse _generateOfflineFallback(String question) {
    return AIStructuredResponse(
      text: "I encountered an issue connecting to the AI services, but your local receipt records are safe. Please verify your connection or try a simpler question like 'Show products above ₹2,000'.",
      type: AIStructuredResponseType.error,
      suggestedFollowUps: const [
        'Show products above ₹2,000',
        'Show all receipts',
      ],
    );
  }
}
