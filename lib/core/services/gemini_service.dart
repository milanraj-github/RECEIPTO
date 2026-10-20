import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/services/gemini_exception_handler.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  late final List<String> _apiKeys;
  int _currentKeyIndex = 0;
  final http.Client _client = http.Client();
  final Map<String, DateTime> _keyCooldowns = {};

  // High-performance models with active quota and verified multimodal vision support
  static const List<String> _models = [
    'gemini-3.5-flash', // Primary: ultra-fast (~5s), verified multimodal active quota
    'gemini-3.6-flash', // Secondary fallback
    'gemini-3.8-flash', // Tertiary fallback
  ];

  static const Duration _requestTimeout = Duration(seconds: 12);

  static const String _prompt = '''
You are an expert AI receipt scanner.
Analyze the provided receipt image/content and extract all details in structured JSON.

VALIDITY RULES:
- Set "is_valid_receipt": true if the image is an authentic shopping receipt, store invoice, retail bill, restaurant check, or valid purchase record.
- Set "is_valid_receipt": false if the image is NOT a receipt (e.g., photo of a person/selfie, face, pet, animal, food dish without bill, nature/landscape, screenshot of a chat/social media, blank or completely unreadable image). If false, describe the reason in "invalid_reason".

CRITICAL RULES FOR CURRENCY RESOLUTION:
- Assume all receipts are Indian by default unless another country's address, currency symbol, or tax format clearly proves otherwise.
- For all Indian receipts/merchants (including DMart, Reliance, Smart Bazaar, More, Vishal Mart, Big Bazaar, Apollo, MedPlus, Croma, Vijay Sales, JioMart, Indian petrol pumps, Indian restaurants, etc.), the currency MUST be "₹".
- Never return "\$" for Indian receipts. Never infer USD.
- Return INR ("₹") for all Indian merchants.
- Only return "\$", "€", "£", etc. when the receipt explicitly belongs to another country (e.g., US, Europe, UK).

CRITICAL RULES FOR EXPIRY DATE & WARRANTY EXTRACTION:
- Extract ANY printed expiry, expiration, best before, use by, valid till, or warranty date for each line item!
- For grocery, dairy, food, beverages, medicines, cosmetics, and packaged items: receipts frequently print "Expiry : DD-MM-YYYY", "Exp:", "Use By:", or "Best Before:" (e.g., "Expiry : 21-10-2026 (TOMORROW)").
- YOU MUST extract this printed date as the item's expiration date into "warranty_expiry" (normalized to standard ISO YYYY-MM-DD). If an expiry date is printed, set "warranty_available": true!
- Example: "Amul Fresh Milk (500 ml) Expiry : 21-10-2026 (TOMORROW)" -> name: "Amul Fresh Milk (500 ml)", warranty_expiry: "2026-10-21", warranty_available: true.
- Do NOT ignore food/dairy/medicine expiration dates! Treat all product expiry, validity, and warranty end dates as "warranty_expiry".
- Distinguish Return/Replacement Windows (e.g., 7 days return, 10 days replacement) from Warranty/Expiry Periods. Do not confuse them.
- Never hardcode or assume warranty durations based on merchant names.
- Receipts can contain multiple products. Extract warranty/expiry, brand, return details, category, and serial numbers independently for every product. Do NOT copy one product's warranty/expiry terms to other items.
- Extracted dates (purchase date and expiry dates) must be normalized to standard ISO format (YYYY-MM-DD).

WARRANTY & EXPIRY RESOLUTION PRIORITIES:
- PRIORITY 1: If the receipt explicitly contains a printed expiry/validity date, use THAT exact date in "warranty_expiry" and set "warranty_available": true.
- PRIORITY 2: Only if no expiry date is printed, search for warranty duration keywords (e.g. 12 Months, 24 Months, 2 Years). Populate "warranty_period" (e.g., 12), "warranty_unit" (e.g., "months"), and set "warranty_available": true.
- PRIORITY 3: If neither exists, set "warranty_available": false, and set "warranty_period", "warranty_unit", "warranty_expiry", and "return_window" to null.

CRITICAL RULES FOR CATEGORIZATION:
- You MUST categorize both the overall receipt ("category") and every individual line item ("category") using EXACTLY one of these supported categories:
  ["Electronics", "Groceries", "Food & Dining", "Fuel", "Shopping", "Fashion", "Furniture", "Home Appliances", "Healthcare", "Beauty & Personal Care", "Travel", "Entertainment", "Education", "Utilities", "Office Supplies", "Sports", "Automotive", "Accessories", "Books", "Mobile & Gadgets", "Computers", "Subscription", "Others"]

CONFIDENCE SCORE RULES:
For key fields ("date", "merchant_name", "payment_method", "invoice_number", and inside each item: "name", "warranty_period", "warranty_expiry"), output an extraction confidence score between 0.0 and 1.0.

Return ONLY a single, valid JSON object matching this structure:
{
  "is_valid_receipt": boolean,
  "invalid_reason": String or null,
  "merchant_name": String or null,
  "invoice_number": String or null,
  "date": String (YYYY-MM-DD format) or null,
  "time": String (HH:MM or HH:MM:SS format) or null,
  "gst_number": String or null,
  "currency": String ("₹" or other currency symbol) or null,
  "subtotal": double or null,
  "tax": double or null,
  "discount": double or null,
  "total": double or null,
  "payment_method": String or null,
  "category": String or null,
  "merchant_address": String or null,
  "merchant_phone": String or null,
  "confidence_scores": {
    "merchant_name": float,
    "invoice_number": float,
    "date": float,
    "payment_method": float
  },
  "items": [
    {
      "name": String,
      "quantity": int or null,
      "unit_price": double or null,
      "total_price": double or null,
      "brand": String or null,
      "model": String or null,
      "serial_number": String or null,
      "category": String or null,
      "warranty_available": bool,
      "warranty_period": int or null,
      "warranty_unit": String or null,
      "warranty_expiry": String (YYYY-MM-DD format) or null,
      "return_window": int or null,
      "confidence_scores": {
        "name": float,
        "warranty_period": float,
        "warranty_expiry": float
      }
    }
  ]
}
''';

  GeminiService() {
    final rawKeys = dotenv.env['GEMINI_API_KEYS'] ?? dotenv.env['GEMINI_API_KEY'] ?? '';
    _apiKeys = rawKeys
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    if (_apiKeys.isEmpty) {
      throw Exception('Missing GEMINI_API_KEYS / GEMINI_API_KEY in environment variables (.env file).');
    }
  }

  /// Returns API keys ordered by starting position, filtering out temporarily cooled-down keys.
  List<String> _getRotatedKeys() {
    if (_apiKeys.isEmpty) return [];
    final now = DateTime.now();
    // Exclude keys currently in cooldown (e.g. rate-limited 429 or timed out)
    final active = _apiKeys.where((k) {
      final cd = _keyCooldowns[k];
      return cd == null || now.isAfter(cd);
    }).toList();

    final pool = active.isNotEmpty ? active : _apiKeys;
    final startIndex = _currentKeyIndex % pool.length;

    final List<String> rotated = [];
    for (int i = 0; i < pool.length; i++) {
      rotated.add(pool[(startIndex + i) % pool.length]);
    }
    return rotated;
  }

  /// Sends raw in-memory image bytes directly to Gemini Vision API (fastest, zero download latency).
  Future<ReceiptModel> analyzeReceiptBytes({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    return _analyzeWithModelFailover(
      buildRequestPayload: (base64Image) => {
        "contents": [
          {
            "parts": [
              {
                "text": _prompt
              },
              {
                "inlineData": {
                  "mimeType": mimeType,
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.1,
          "responseMimeType": "application/json"
        }
      },
      imageBytes: imageBytes,
    );
  }

  Future<ReceiptModel> _analyzeWithModelFailover({
    required Map<String, dynamic> Function(String base64Image) buildRequestPayload,
    required Uint8List imageBytes,
  }) async {
    final String base64Image = base64.encode(imageBytes);
    final payload = buildRequestPayload(base64Image);
    final String requestBody = jsonEncode(payload);

    Exception? lastException;

    for (final model in _models) {
      final keys = _getRotatedKeys();

      for (final apiKey in keys) {
        final keyPrefix = apiKey.length > 12 ? apiKey.substring(0, 12) : apiKey;
        try {
          final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
          final response = await _client.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          ).timeout(_requestTimeout);

          if (response.statusCode == 200) {
            final Map<String, dynamic> jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = jsonResponse['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final candidate = candidates.first as Map<String, dynamic>;
              final contentMap = candidate['content'] as Map<String, dynamic>?;
              final parts = contentMap?['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                final part = parts.first as Map<String, dynamic>;
                final rawText = part['text'] as String?;
                if (rawText != null && rawText.trim().isNotEmpty) {
                  final cleanedJson = _cleanJsonResponse(rawText);
                  final Map<String, dynamic> jsonMap = jsonDecode(cleanedJson) as Map<String, dynamic>;

                  // Lock in successful key for instant next scan
                  final successIdx = _apiKeys.indexOf(apiKey);
                  if (successIdx != -1) {
                    _currentKeyIndex = successIdx;
                    _keyCooldowns.remove(apiKey);
                  }

                  if (kDebugMode) {
                    print('[GeminiService] Extracted successfully using $model with key $keyPrefix...');
                  }
                  return ReceiptModel.fromJson(jsonMap);
                }
              }
            }
          } else if (response.statusCode == 429) {
            if (kDebugMode) {
              print('[GeminiService] Key $keyPrefix... quota exhausted (429). Switching to next key immediately...');
            }
            _keyCooldowns[apiKey] = DateTime.now().add(const Duration(minutes: 3));
            lastException = GeminiExceptionHandler.handleResponse(response);
            continue; // Switch to the next key in the pool immediately!
          } else if (response.statusCode == 404 || response.statusCode == 503) {
            if (kDebugMode) {
              print('[GeminiService] Model $model status ${response.statusCode}, trying next key/model...');
            }
            lastException = GeminiExceptionHandler.handleResponse(response);
            continue; // Try next key
          } else {
            throw GeminiExceptionHandler.handleResponse(response);
          }
        } on TimeoutException {
          if (kDebugMode) {
            print('[GeminiService] Model $model timed out with key $keyPrefix (>${_requestTimeout.inSeconds}s). Switching to next key...');
          }
          _keyCooldowns[apiKey] = DateTime.now().add(const Duration(minutes: 1));
          continue; // Switch to next key immediately
        } catch (e) {
          if (kDebugMode) {
            print('[GeminiService] Model $model with key $keyPrefix... error: $e');
          }
          lastException = e is Exception ? e : Exception(e.toString());
          continue;
        }
      }
    }

    throw lastException ?? Exception('All Gemini vision models and API keys failed to process receipt.');
  }

  /// Sends the receipt image URL to Gemini Vision REST API for scanning (fallback).
  Future<ReceiptModel> analyzeReceipt({
    required String imageUrl,
  }) async {
    final http.Response downloadRes = await _client.get(Uri.parse(imageUrl));
    if (downloadRes.statusCode != 200) {
      throw GeminiException(
        'Failed to download image from storage bucket.',
        statusCode: downloadRes.statusCode,
      );
    }
    return analyzeReceiptBytes(
      imageBytes: downloadRes.bodyBytes,
      mimeType: 'image/jpeg',
    );
  }

  /// Sends the receipt plain text contents to Gemini REST API for scanning and data extraction.
  Future<ReceiptModel> analyzeReceiptText({
    required String text,
  }) async {
    final Map<String, dynamic> requestPayload = {
      "contents": [
        {
          "parts": [
            {
              "text": '$_prompt\n\nRECEIPT TEXT:\n$text'
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.1,
        "responseMimeType": "application/json"
      }
    };

    final String requestBody = jsonEncode(requestPayload);

    for (final model in _models) {
      final keys = _getRotatedKeys();
      for (final apiKey in keys) {
        try {
          final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
          final response = await _client.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          ).timeout(_requestTimeout);

          if (response.statusCode == 200) {
            final Map<String, dynamic> jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = jsonResponse['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final candidate = candidates.first as Map<String, dynamic>;
              final contentMap = candidate['content'] as Map<String, dynamic>?;
              final parts = contentMap?['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                final part = parts.first as Map<String, dynamic>;
                final rawText = part['text'] as String?;
                if (rawText != null && rawText.trim().isNotEmpty) {
                  final cleanedJson = _cleanJsonResponse(rawText);
                  final Map<String, dynamic> jsonMap = jsonDecode(cleanedJson) as Map<String, dynamic>;

                  final successIdx = _apiKeys.indexOf(apiKey);
                  if (successIdx != -1) {
                    _currentKeyIndex = successIdx;
                    _keyCooldowns.remove(apiKey);
                  }
                  return ReceiptModel.fromJson(jsonMap);
                }
              }
            }
          } else if (response.statusCode == 429) {
            _keyCooldowns[apiKey] = DateTime.now().add(const Duration(minutes: 3));
            continue; // Switch to next key
          } else if (response.statusCode == 404 || response.statusCode == 503) {
            continue; // Try next key
          }
        } on TimeoutException {
          _keyCooldowns[apiKey] = DateTime.now().add(const Duration(minutes: 1));
          continue;
        } catch (_) {
          continue;
        }
      }
    }

    throw Exception('Gemini text extraction failed across all models.');
  }

  String _cleanJsonResponse(String response) {
    String cleaned = response.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'^```[a-zA-Z]*\n'), '');
      cleaned = cleaned.replaceAll(RegExp(r'\n```$'), '');
      cleaned = cleaned.trim();
    }
    return cleaned;
  }
}
