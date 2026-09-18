import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/utils/warranty_utils.dart';

final aiAssistantServiceProvider = Provider<AIAssistantService>((ref) {
  final receiptDb = ref.watch(receiptDatabaseServiceProvider);
  final warrantyDb = ref.watch(warrantyDatabaseServiceProvider);
  return AIAssistantService(receiptDb, warrantyDb);
});

class AIAssistantService {
  final ReceiptDatabaseService _receiptDb;
  final WarrantyDatabaseService _warrantyDb;
  final Map<String, String> _cache = {};

  AIAssistantService(this._receiptDb, this._warrantyDb);

  String _getApiKey() {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Clears in-memory AI response cache.
  void clearCache() {
    _cache.clear();
  }

  /// Entry point for handling user question, running intent detection,
  /// executing structured local query, and producing human friendly answers.
  Future<String> ask(String question) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return "You must be logged in to ask the AI Warranty Assistant.";
    }
    final userId = currentUser.uid;
    final cleanQuestion = question.trim().toLowerCase();
    final cacheKey = '$userId|$cleanQuestion';

    if (_cache.containsKey(cacheKey)) {
      if (kDebugMode) print('[AI Assistant] Cache Hit for: $question');
      return _cache[cacheKey]!;
    }

    try {
      // 1. Detect Intent
      final intentJson = await _detectIntent(question);
      if (kDebugMode) print('[AI Assistant] Detected Intent JSON: $intentJson');

      // 2. Load Local Data
      final warranties = await _warrantyDb.fetchAllWarranties(userId);
      final receipts = await _receiptDb.fetchAllReceipts(userId: userId);

      // 3. Run Local Query Engine
      final queryResult = _runLocalQuery(intentJson, warranties, receipts);
      if (kDebugMode) print('[AI Assistant] Local Query Result: $queryResult');

      // 4. Generate Final Response
      final answer = await _generateAnswer(question, queryResult);
      
      // Cache response with user-isolated key
      if (answer.isNotEmpty) {
        _cache[cacheKey] = answer;
      }
      
      return answer;
    } catch (e) {
      if (kDebugMode) print('[AI Assistant] Error: $e');
      // Graceful offline/error search fallback
      return await _offlineSearchFallback(question);
    }
  }

  Future<Map<String, dynamic>> _detectIntent(String question) async {
    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in environment variables.');
    }

    const systemPrompt = '''
You are the natural language intent parser for Receipto.
Your task is to parse the user's natural language question and output ONLY a structured JSON document representing the user's query intent.

Supported Intent types:
- CHECK_WARRANTY: Looking for warranty status/expiration of a specific product name.
- EXPIRING_PRODUCTS: Looking for products expiring within a certain timeframe.
- CHECK_LIFETIME: Checking for items with lifetime warranties.
- TOTAL_SPENDING: Checking total expense, optionally filtered by brand, category, month, or year.
- MERCHANT_PURCHASES: Inquiries about purchases made at a specific merchant.
- BRAND_PURCHASES: Inquiries about purchases from a specific brand.
- LARGEST_PURCHASE: Finding the highest priced receipt or item.
- EXPENSIVE_RECEIPT: Finding the most expensive receipt.
- PURCHASES_IN_YEAR: Listing items bought in a specific year.
- PURCHASES_BY_AMOUNT: Filtering purchases above or below a certain price value.
- NO_WARRANTY: Checking items that have no active warranty.
- ACTIVE_WARRANTIES_COUNT: Inquiries about total count of active warranties.
- TOP_BRANDS: Inquiries about favorite/most bought brands.
- TOP_CATEGORIES: Inquiries about highest spending categories.
- SUMMARIZE_PURCHASES: General purchase dashboard summary.
- SUMMARIZE_WARRANTIES: General warranty dashboard summary.
- GENERAL: Generic questions or friendly greetings.

Output JSON Format:
{
  "intent": "INTENT_TYPE",
  "product": "Product name or null",
  "category": "Electronics | Fashion | Groceries | Furniture | Travel | Utilities | Food | bills | shopping | fuel | medical | null",
  "brand": "Brand name or null",
  "merchant": "Merchant/Shop name or null",
  "year": integer_year or null,
  "month": integer_month_1_to_12 or null,
  "days": integer_days or null,
  "amount": double_amount or null,
  "comparison": "GT | LT | EQ | null",
  "warranty_status": "EXPIRED | ACTIVE | EXPIRING_SOON | LIFETIME | null"
}

Do NOT output any markdown tags (like ```json), explanations, or surrounding text. Output only raw JSON.
''';

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": systemPrompt},
            {"text": "User Query: $question"}
          ]
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json"
      }
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini intent detection API returned status code ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final String textOutput = data['candidates'][0]['content']['parts'][0]['text'];
    return jsonDecode(textOutput.trim()) as Map<String, dynamic>;
  }

  Map<String, dynamic> _runLocalQuery(
    Map<String, dynamic> intent,
    List<WarrantyModel> warranties,
    List<Map<String, dynamic>> receipts,
  ) {
    final String intentType = intent['intent'] ?? 'GENERAL';
    final String? product = intent['product'];
    final String? category = intent['category'];
    final String? brand = intent['brand'];
    final String? merchant = intent['merchant'];
    final int? year = intent['year'];
    final int? month = intent['month'];
    final int? days = intent['days'];
    final double? amount = intent['amount']?.toDouble();
    final String? comparison = intent['comparison'];

    final now = DateTime.now();

    switch (intentType) {
      case 'CHECK_WARRANTY':
        if (product == null || product.isEmpty) {
          return {"status": "ERROR", "message": "Product name not supplied."};
        }
        final match = warranties.where((w) =>
            w.productName.toLowerCase().contains(product.toLowerCase())).toList();
        if (match.isEmpty) {
          return {"status": "NOT_FOUND", "type": "warranty", "product": product};
        }
        return {
          "status": "FOUND",
          "warranties": match.map((w) => {
            "product_name": w.productName,
            "merchant_name": w.merchantName,
            "expiry_date": w.expiryDate,
            "days_remaining": WarrantyUtils.calculateDaysRemaining(w.expiryDate),
            "status": w.status,
          }).toList()
        };

      case 'EXPIRING_PRODUCTS':
        final limitDays = days ?? 30;
        final match = warranties.where((w) {
          final rem = WarrantyUtils.calculateDaysRemaining(w.expiryDate);
          return rem >= 0 && rem <= limitDays;
        }).toList();
        return {
          "status": "FOUND",
          "warranties": match.map((w) => {
            "product_name": w.productName,
            "expiry_date": w.expiryDate,
            "days_remaining": WarrantyUtils.calculateDaysRemaining(w.expiryDate),
          }).toList(),
          "timeframe_days": limitDays
        };

      case 'CHECK_LIFETIME':
        final match = warranties.where((w) =>
            w.warrantyPeriod >= 99).toList();
        return {
          "status": "FOUND",
          "warranties": match.map((w) => {
            "product_name": w.productName,
            "expiry_date": w.expiryDate,
          }).toList()
        };

      case 'TOTAL_SPENDING':
        double total = 0.0;
        int count = 0;
        
        for (final r in receipts) {
          final rDateStr = r['date'] as String? ?? '';
          final rDate = DateTime.tryParse(rDateStr);
          
          if (year != null && rDate?.year != year) continue;
          if (month != null && rDate?.month != month) continue;
          
          final rCategory = r['category'] as String? ?? '';
          if (category != null && rCategory.toLowerCase() != category.toLowerCase()) continue;
          
          final rMerchant = r['merchant_name'] as String? ?? '';
          if (merchant != null && !rMerchant.toLowerCase().contains(merchant.toLowerCase())) continue;

          final double val = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
          total += val;
          count++;
        }
        return {
          "status": "FOUND",
          "total_spending": total,
          "receipt_count": count,
          "category": category,
          "year": year,
          "month": month,
          "currency": receipts.isNotEmpty ? (receipts.first['currency'] ?? '₹') : '₹'
        };

      case 'MERCHANT_PURCHASES':
        if (merchant == null || merchant.isEmpty) {
          return {"status": "ERROR", "message": "Merchant name not supplied."};
        }
        final match = receipts.where((r) =>
            (r['merchant_name'] as String? ?? '').toLowerCase().contains(merchant.toLowerCase())).toList();
        return {
          "status": "FOUND",
          "merchant": merchant,
          "purchases": match.map((r) => {
            "merchant_name": r['merchant_name'],
            "date": r['date'],
            "total": r['grand_total'] ?? r['total'],
            "category": r['category'],
            "currency": r['currency'] ?? '₹'
          }).toList()
        };

      case 'BRAND_PURCHASES':
        if (brand == null || brand.isEmpty) {
          return {"status": "ERROR", "message": "Brand name not supplied."};
        }
        final matchWarr = warranties.where((w) =>
            w.productName.toLowerCase().contains(brand.toLowerCase())).toList();
        return {
          "status": "FOUND",
          "brand": brand,
          "products": matchWarr.map((w) => {
            "product_name": w.productName,
            "expiry_date": w.expiryDate,
            "status": w.status
          }).toList()
        };

      case 'LARGEST_PURCHASE':
      case 'EXPENSIVE_RECEIPT':
        if (receipts.isEmpty) {
          return {"status": "NOT_FOUND", "type": "purchases"};
        }
        var maxVal = -1.0;
        Map<String, dynamic>? largest;
        for (final r in receipts) {
          final double val = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
          if (val > maxVal) {
            maxVal = val;
            largest = r;
          }
        }
        if (largest == null) return {"status": "NOT_FOUND"};
        return {
          "status": "FOUND",
          "merchant_name": largest['merchant_name'],
          "date": largest['date'],
          "total": maxVal,
          "category": largest['category'],
          "currency": largest['currency'] ?? '₹'
        };

      case 'PURCHASES_IN_YEAR':
        final targetYear = year ?? now.year;
        final match = receipts.where((r) {
          final date = DateTime.tryParse(r['date'] as String? ?? '');
          return date?.year == targetYear;
        }).toList();
        return {
          "status": "FOUND",
          "year": targetYear,
          "purchases": match.map((r) => {
            "merchant_name": r['merchant_name'],
            "date": r['date'],
            "total": r['grand_total'] ?? r['total'],
            "currency": r['currency'] ?? '₹'
          }).toList()
        };

      case 'PURCHASES_BY_AMOUNT':
        if (amount == null) {
          return {"status": "ERROR", "message": "Amount filter not specified."};
        }
        final comp = comparison ?? 'GT';
        final match = receipts.where((r) {
          final double val = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
          if (comp == 'GT') return val > amount;
          if (comp == 'LT') return val < amount;
          return val == amount;
        }).toList();
        return {
          "status": "FOUND",
          "amount": amount,
          "comparison": comp,
          "purchases": match.map((r) => {
            "merchant_name": r['merchant_name'],
            "date": r['date'],
            "total": r['grand_total'] ?? r['total'],
            "currency": r['currency'] ?? '₹'
          }).toList()
        };

      case 'ACTIVE_WARRANTIES_COUNT':
        final count = warranties.where((w) => w.status == 'ACTIVE').length;
        return {
          "status": "FOUND",
          "active_warranties_count": count
        };

      case 'TOP_BRANDS':
        final Map<String, int> counts = {};
        for (final w in warranties) {
          final parts = w.productName.trim().split(' ');
          if (parts.isNotEmpty) {
            final brandName = parts.first;
            counts[brandName] = (counts[brandName] ?? 0) + 1;
          }
        }
        final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return {
          "status": "FOUND",
          "top_brands": sorted.take(3).map((e) => {"brand": e.key, "count": e.value}).toList()
        };

      case 'TOP_CATEGORIES':
        final Map<String, double> spends = {};
        for (final r in receipts) {
          final cat = r['category'] as String? ?? 'Other';
          final double val = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
          spends[cat] = (spends[cat] ?? 0.0) + val;
        }
        final sorted = spends.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return {
          "status": "FOUND",
          "top_categories": sorted.take(3).map((e) => {"category": e.key, "total_spend": e.value}).toList(),
          "currency": receipts.isNotEmpty ? (receipts.first['currency'] ?? '₹') : '₹'
        };

      case 'SUMMARIZE_PURCHASES':
        return {
          "status": "FOUND",
          "total_receipts": receipts.length,
          "latest_purchases": receipts.take(3).map((r) => {
            "merchant_name": r['merchant_name'],
            "date": r['date'],
            "total": r['grand_total'] ?? r['total'],
            "currency": r['currency'] ?? '₹'
          }).toList()
        };

      case 'SUMMARIZE_WARRANTIES':
        return {
          "status": "FOUND",
          "total_warranties": warranties.length,
          "active_warranties": warranties.where((w) => w.status == 'ACTIVE').length,
          "expiring_warranties": warranties.where((w) => w.status == 'EXPIRING SOON').length,
          "expired_warranties": warranties.where((w) => w.status == 'EXPIRED').length,
        };

      default:
        return {
          "status": "GENERAL_QUERY",
          "warranties_summary": {
            "total": warranties.length,
            "active": warranties.where((w) => w.status == 'ACTIVE').length
          },
          "spending_summary": {
            "total_receipts": receipts.length,
            "latest_receipt_merchant": receipts.isNotEmpty ? receipts.first['merchant_name'] : 'N/A'
          }
        };
    }
  }

  Future<String> _generateAnswer(String question, Map<String, dynamic> queryResult) async {
    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      return "Missing API key in environment config.";
    }

    final systemPrompt = '''
You are the AI Warranty Assistant for the Receipto application.
Your goal is to answer the user's natural language question based on the provided local query results.

Guidelines:
- Produce a helpful, professional, friendly, and extremely clear response.
- Keep the response relatively short and focused.
- Format details beautifully using bold text, bullet points, or simple markdown tables where appropriate.
- Always use the Indian Rupee symbol "₹" when referring to currency, unless the query results specify another currency symbol.
- Avoid exposing any database field names or raw system IDs. Just speak naturally.
- If the results indicate nothing was found (status "NOT_FOUND" or empty lists), respond politely, stating that no records match the criteria.
''';

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": systemPrompt},
            {"text": "User Question: $question"},
            {"text": "Query Results Data:\n${jsonEncode(queryResult)}"}
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini response generation API returned status code ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final String answer = data['candidates'][0]['content']['parts'][0]['text'];
    return answer.trim();
  }

  Future<String> _offlineSearchFallback(String question) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return "Offline Mode: Authentication unavailable.";
      }
      final warranties = await _warrantyDb.fetchAllWarranties(currentUser.uid);

      final words = question.toLowerCase().split(' ');
      final List<String> matches = [];

      for (final w in warranties) {
        for (final word in words) {
          if (word.length >= 3 && w.productName.toLowerCase().contains(word)) {
            final days = WarrantyUtils.calculateDaysRemaining(w.expiryDate);
            matches.add(
              "* **${w.productName}**: Expires on ${w.expiryDate} (${days >= 0 ? '$days days remaining' : 'Expired'})."
            );
            break;
          }
        }
      }

      if (matches.isNotEmpty) {
        return "Offline Fallback Results:\nI couldn't reach the AI service, but found these matching warranties in your local cache:\n\n${matches.join('\n')}";
      }
    } catch (_) {}

    return "AI Assistant is currently unavailable. Please verify your network connection and try again.";
  }
}
