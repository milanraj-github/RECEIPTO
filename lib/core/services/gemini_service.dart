import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/services/gemini_exception_handler.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  late final String _apiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const String _prompt = '''
You are an expert AI receipt scanner.
Analyze the provided receipt image/content and extract the receipt details.

CRITICAL RULES FOR CURRENCY RESOLUTION:
- Assume all receipts are Indian by default unless another country's address, currency symbol, or tax format clearly proves otherwise.
- For all Indian receipts/merchants (including DMart, Reliance, Smart Bazaar, More, Vishal Mart, Big Bazaar, Apollo, MedPlus, Croma, Vijay Sales, JioMart, Indian petrol pumps, Indian restaurants, etc.), the currency MUST be "₹".
- Never return "\$" for Indian receipts. Never infer USD.
- Return INR ("₹") for all Indian merchants.
- Only return "\$", "€", "£", etc. when the receipt explicitly belongs to another country (e.g., US, Europe, UK).

CRITICAL RULES FOR WARRANTY & RETURN EXTRACTION:
- Distinguish Return/Replacement Windows (e.g., 7 days return, 10 days replacement) from Warranty Periods. Do not confuse them.
- Never hardcode or assume warranty durations based on merchant names (e.g., do NOT assume Croma, Amazon, Reliance, or Flipkart always implies a 12-month warranty).
- Receipts can contain multiple products. Extract warranty, brand, return details, category, and serial numbers independently for every product. Do NOT copy one product's warranty terms to other items.
- Extracted dates (purchase date and expiry dates) must be normalized to standard ISO format (YYYY-MM-DD). Support formats like "19-Jul-2026", "19 July 2026", "19/07/2026", "19 Jul 26", "July 19 2026", etc.

WARRANTY RESOLUTION PRIORITIES:
- PRIORITY 1: If the receipt explicitly contains a printed expiry/validity date (using labels like: Warranty Expiry, Warranty End, Warranty Valid Till, Warranty Ends, Return / Warranty Expiry Date, Return Expiry, Replacement Until, Return Valid Until, Warranty Until, Valid Until, Expires On, Expiry Date, Expiration Date, End Date), use THAT exact date in "warranty_expiry". Do not calculate, estimate, or infer another date.
- PRIORITY 2: Only if no expiry date is printed anywhere on the receipt, search for warranty duration keywords (e.g. 12 Months, 24 Months, 6 Months, 2 Years, 1 Year, etc.). Populate "warranty_period" (e.g., 12) and "warranty_unit" (e.g., "months").
- PRIORITY 3: If neither an explicit printed expiry date nor a warranty period exists on the receipt for an item, set "warranty_available" to false, and set "warranty_period", "warranty_unit", "warranty_expiry", and "return_window" to null. Never assume 12 months, and never invent values.

CONFIDENCE SCORE RULES:
For key fields ("date", "merchant_name", "payment_method", "invoice_number", and inside each item: "name", "warranty_period", "warranty_expiry"), you must output an AI extraction confidence score between 0.0 and 1.0 (float) based on OCR legibility and textual certainty.

You must return ONLY a single, valid JSON object matching this structure:
{
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
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in environment variables (.env file).');
    }
  }

  /// Sends raw in-memory image bytes directly to Gemini Vision API (fastest, zero download latency).
  Future<ReceiptModel> analyzeReceiptBytes({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    return _analyzeReceiptBytesWithRetry(
      imageBytes: imageBytes,
      mimeType: mimeType,
      retryCount: 1,
    );
  }

  Future<ReceiptModel> _analyzeReceiptBytesWithRetry({
    required Uint8List imageBytes,
    required String mimeType,
    required int retryCount,
  }) async {
    try {
      final String base64Image = base64.encode(imageBytes);

      final Map<String, dynamic> requestPayload = {
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
      };

      final String requestBody = jsonEncode(requestPayload);

      final http.Response response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode != 200) {
        final geminiExc = GeminiExceptionHandler.handleResponse(response);
        final bool isRetriable = [429, 500, 503].contains(response.statusCode);
        if (isRetriable && retryCount > 0) {
          final waitSec = geminiExc.retryAfterSeconds ?? 4;
          await Future.delayed(Duration(seconds: waitSec));
          return _analyzeReceiptBytesWithRetry(
            imageBytes: imageBytes,
            mimeType: mimeType,
            retryCount: retryCount - 1,
          );
        }
        throw geminiExc;
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }
      final candidate = candidates.first as Map<String, dynamic>;
      final contentMap = candidate['content'] as Map<String, dynamic>?;
      if (contentMap == null) {
        throw GeminiException("Unexpected error occurred.");
      }
      final parts = contentMap['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }
      final part = parts.first as Map<String, dynamic>;
      final rawText = part['text'] as String?;

      if (rawText == null || rawText.trim().isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }

      final cleanedJson = _cleanJsonResponse(rawText);
      final Map<String, dynamic> jsonMap = jsonDecode(cleanedJson) as Map<String, dynamic>;
      return ReceiptModel.fromJson(jsonMap);
    } catch (e) {
      final mappedExc = GeminiExceptionHandler.handleException(e);
      final bool isNetworkErr = e is SocketException || e is TimeoutException;
      if (isNetworkErr && retryCount > 0) {
        await Future.delayed(const Duration(seconds: 4));
        return _analyzeReceiptBytesWithRetry(
          imageBytes: imageBytes,
          mimeType: mimeType,
          retryCount: retryCount - 1,
        );
      }
      throw mappedExc;
    }
  }

  /// Sends the receipt image URL to Gemini Vision REST API for scanning and data extraction (fallback).
  Future<ReceiptModel> analyzeReceipt({
    required String imageUrl,
  }) async {
    return _analyzeReceiptWithRetry(imageUrl: imageUrl, retryCount: 1);
  }

  Future<ReceiptModel> _analyzeReceiptWithRetry({
    required String imageUrl,
    required int retryCount,
  }) async {
    try {
      final http.Response downloadRes = await http.get(Uri.parse(imageUrl));
      if (downloadRes.statusCode != 200) {
        throw GeminiException(
          'Failed to download image from storage bucket.',
          statusCode: downloadRes.statusCode,
        );
      }
      final bytes = downloadRes.bodyBytes;
      return await analyzeReceiptBytes(
        imageBytes: bytes,
        mimeType: 'image/jpeg',
      );
    } catch (e) {
      final mappedExc = GeminiExceptionHandler.handleException(e);
      final bool isNetworkErr = e is SocketException || e is TimeoutException;
      if (isNetworkErr && retryCount > 0) {
        await Future.delayed(const Duration(seconds: 4));
        return _analyzeReceiptWithRetry(imageUrl: imageUrl, retryCount: retryCount - 1);
      }
      throw mappedExc;
    }
  }

  /// Sends the receipt plain text contents to Gemini REST API for scanning and data extraction.
  Future<ReceiptModel> analyzeReceiptText({
    required String text,
  }) async {
    return _analyzeReceiptTextWithRetry(text: text, retryCount: 1);
  }

  Future<ReceiptModel> _analyzeReceiptTextWithRetry({
    required String text,
    required int retryCount,
  }) async {
    try {
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

      final http.Response response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode != 200) {
        final geminiExc = GeminiExceptionHandler.handleResponse(response);
        final bool isRetriable = [429, 500, 503].contains(response.statusCode);
        if (isRetriable && retryCount > 0) {
          final waitSec = geminiExc.retryAfterSeconds ?? 4;
          await Future.delayed(Duration(seconds: waitSec));
          return _analyzeReceiptTextWithRetry(text: text, retryCount: retryCount - 1);
        }
        throw geminiExc;
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }
      final candidate = candidates.first as Map<String, dynamic>;
      final contentMap = candidate['content'] as Map<String, dynamic>?;
      if (contentMap == null) {
        throw GeminiException("Unexpected error occurred.");
      }
      final parts = contentMap['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }
      final part = parts.first as Map<String, dynamic>;
      final rawText = part['text'] as String?;

      if (rawText == null || rawText.trim().isEmpty) {
        throw GeminiException("Unexpected error occurred.");
      }

      final cleanedJson = _cleanJsonResponse(rawText);
      final Map<String, dynamic> jsonMap = jsonDecode(cleanedJson) as Map<String, dynamic>;
      return ReceiptModel.fromJson(jsonMap);
    } catch (e) {
      final mappedExc = GeminiExceptionHandler.handleException(e);
      final bool isNetworkErr = e is SocketException || e is TimeoutException;
      if (isNetworkErr && retryCount > 0) {
        await Future.delayed(const Duration(seconds: 4));
        return _analyzeReceiptTextWithRetry(text: text, retryCount: retryCount - 1);
      }
      throw mappedExc;
    }
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
