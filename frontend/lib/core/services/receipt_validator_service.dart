import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:receipto/core/services/gemini_exception_handler.dart';

final receiptValidatorServiceProvider = Provider<ReceiptValidatorService>((ref) {
  return ReceiptValidatorService();
});

class ValidationResult {
  final bool isValid;
  final double confidence;
  final String reason;

  ValidationResult({
    required this.isValid,
    required this.confidence,
    required this.reason,
  });
}

class ReceiptValidatorService {
  late final String _apiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent';

  ReceiptValidatorService() {
    final raw = dotenv.env['GEMINI_API_KEYS'] ?? dotenv.env['GEMINI_API_KEY'] ?? '';
    _apiKey = raw.split(',').firstWhere((k) => k.trim().isNotEmpty, orElse: () => '').trim();
  }

  /// Analyzes an image file to validate whether it is a genuine purchase receipt before OCR extraction.
  Future<ValidationResult> validateImage(File imageFile) async {
    if (_apiKey.isEmpty) {
      // Fall back to valid if API key is missing to prevent unexpected blocking
      return ValidationResult(isValid: true, confidence: 1.0, reason: 'API key missing, skipping validation');
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final String base64Image = base64.encode(bytes);

      const systemPrompt = '''
You are an expert AI receipt validation classifier.
Your task is to analyze the provided image and determine with high precision whether it is a valid shopping receipt, retail invoice, store bill, restaurant check, or valid purchase voucher.

VALID RECEIPT CHARACTERISTICS (Must possess most of these):
- Merchant/Store Name or Business Logo
- Transaction Date or Time
- Itemized Product List with Prices and Quantities
- Subtotal, Total Amount, Tax/GST/VAT, or Payment Method
- Bill / Invoice / Receipt Number

REJECT AND CLASSIFY AS INVALID (is_valid_receipt = false):
- Handwritten bills, notes, notebook paper, homework, classroom notes, random scribbles.
- Identity documents (Aadhaar card, PAN card, Passport, Driving license, Voter ID).
- Selfies, human portraits, photos of people or faces.
- Landscapes, nature, animals, food dishes, product photos without receipts.
- Mobile screenshots, WhatsApp chat screenshots, social media feeds, home screens.
- Unrelated documents (tickets, letters, certificates, resumes, contracts).
- Blank images, completely dark images, heavily blurred or unreadable images.

Return ONLY a single valid JSON object with NO markdown formatting:
{
  "is_valid_receipt": boolean,
  "confidence": float (0.0 to 1.0),
  "reason": string
}
''';

      final requestBody = json.encode({
        'contents': [
          {
            'parts': [
              {'text': systemPrompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 200,
          'responseMimeType': 'application/json',
        }
      });

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String textResponse = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        
        final cleanJson = textResponse.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> jsonMap = json.decode(cleanJson);

        final bool isValid = jsonMap['is_valid_receipt'] == true;
        final double confidence = (jsonMap['confidence'] as num?)?.toDouble() ?? (isValid ? 0.95 : 0.1);
        final String reason = jsonMap['reason'] as String? ?? '';

        if (kDebugMode) {
          print('[ReceiptValidator] Validation Result: isValid=$isValid, confidence=$confidence, reason=$reason');
        }

        // Apply confidence threshold >= 0.70 (70%)
        if (isValid && confidence >= 0.70) {
          return ValidationResult(isValid: true, confidence: confidence, reason: reason);
        } else {
          return ValidationResult(isValid: false, confidence: confidence, reason: reason);
        }
      } else if (response.statusCode == 429) {
        throw GeminiException('API rate limit reached.', statusCode: 429);
      } else {
        // Fallback to valid if server error occurs to avoid blocking legitimate receipts
        return ValidationResult(isValid: true, confidence: 0.8, reason: 'Validation service fallback');
      }
    } catch (e) {
      if (e is GeminiException && e.statusCode == 429) {
        rethrow;
      }
      if (kDebugMode) print('[ReceiptValidator] Validation exception: $e');
      // On network failure or non-critical exception, fall back to valid
      return ValidationResult(isValid: true, confidence: 0.8, reason: 'Fallback on error');
    }
  }
}
