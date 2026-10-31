import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:receipto/features/scan/domain/models/receipt_model.dart';

final aiCategorizerServiceProvider = Provider<AICategorizerService>((ref) {
  return AICategorizerService();
});

class AICategorizerService {
  final List<String> supportedCategories = [
    'Electronics',
    'Groceries',
    'Food & Dining',
    'Fuel',
    'Shopping',
    'Fashion',
    'Furniture',
    'Home Appliances',
    'Healthcare',
    'Beauty & Personal Care',
    'Travel',
    'Entertainment',
    'Education',
    'Utilities',
    'Office Supplies',
    'Sports',
    'Automotive',
    'Accessories',
    'Books',
    'Mobile & Gadgets',
    'Computers',
    'Subscription',
    'Others'
  ];

  /// Categorizes and normalizes the receipt and each of its line items.
  Future<ReceiptModel> categorize(ReceiptModel receipt) async {
    final merchant = receipt.merchantName ?? '';
    final itemsList = receipt.items.map((e) => e.name).toList();

    String resolvedCategory = 'Others';
    double confidence = 85.0;

    // 1. If Gemini Vision already provided a high-quality category, normalize it
    if (receipt.category != null &&
        receipt.category!.trim().isNotEmpty &&
        receipt.category!.trim().toLowerCase() != 'others' &&
        receipt.category!.trim().toLowerCase() != 'other') {
      resolvedCategory = resolveSupportedCategory(receipt.category);
      confidence = receipt.confidenceScore ?? 90.0;
    } else {
      // 2. Perform intelligent local keyword categorization
      final localResult = localKeywordCategorize(merchant, itemsList);
      if (localResult['category'] != 'Others' || localResult['confidence'] > 60.0) {
        resolvedCategory = resolveSupportedCategory(localResult['category']);
        confidence = localResult['confidence'] as double;
      } else {
        // 3. Ultra-fast Groq AI Categorizer (with multi-key failover and Gemini fallback)
        bool categorized = false;
        final groqKeysRaw = dotenv.env['GROQ_API_KEYS'] ?? dotenv.env['GROQ_API_KEY'] ?? '';
        final groqKeys = groqKeysRaw.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();

        for (final groqKey in groqKeys) {
          try {
            final result = await _callGroqCategorizer(
              merchant: merchant,
              items: itemsList,
              apiKey: groqKey,
            );
            resolvedCategory = resolveSupportedCategory(result['category']);
            confidence = (result['confidence'] as num?)?.toDouble() ?? 85.0;
            categorized = true;
            break;
          } catch (e) {
            if (kDebugMode) print('[AI Categorization] Groq key error: $e, trying next key...');
            continue;
          }
        }

        // If all Groq keys fail or none configured, fallback to Gemini
        if (!categorized) {
          try {
            final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
            if (geminiKey.isNotEmpty) {
              final result = await _callGeminiCategorizer(
                merchant: merchant,
                items: itemsList,
                apiKey: geminiKey,
              );
              resolvedCategory = resolveSupportedCategory(result['category']);
              confidence = (result['confidence'] as num?)?.toDouble() ?? 80.0;
            } else {
              resolvedCategory = resolveSupportedCategory(localResult['category']);
            }
          } catch (e) {
            if (kDebugMode) print('[AI Categorization] Gemini fallback error: $e');
            resolvedCategory = resolveSupportedCategory(localResult['category']);
          }
        }
      }
    }

    if (kDebugMode) {
      print('[AI Categorization] Final Resolved Receipt Category: $resolvedCategory (Confidence: $confidence%)');
    }

    // 4. Normalize and categorize every item individually
    final normalizedItems = receipt.items.map((item) {
      final itemCat = inferItemCategory(
        item.name,
        existingCategory: item.category,
        receiptCategory: resolvedCategory,
      );
      return item.copyWith(category: itemCat);
    }).toList();

    final double normalizedConfidence = confidence > 1.0
        ? double.parse((confidence / 100.0).toStringAsFixed(2))
        : confidence;

    return receipt.copyWith(
      category: resolvedCategory,
      confidenceScore: normalizedConfidence,
      items: normalizedItems,
    );
  }

  /// Resolve and standardize any category string to one of our official categories
  String resolveSupportedCategory(dynamic input) {
    if (input == null || input is! String) return 'Others';
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'Others';
    final lower = trimmed.toLowerCase();

    // Exact matches
    for (final cat in supportedCategories) {
      if (cat.toLowerCase() == lower) {
        return cat;
      }
    }

    // Common synonyms and variations mapping
    if (lower == 'grocery' || lower.contains('supermarket') || lower.contains('hypermarket') || lower.contains('provisions') || lower.contains('kirana') || lower.contains('mart')) {
      return 'Groceries';
    }
    if (lower == 'food' || lower.contains('dining') || lower.contains('restaurant') || lower.contains('cafe') || lower.contains('fast food') || lower.contains('bakery')) {
      return 'Food & Dining';
    }
    if (lower.contains('electronic') || lower.contains('audio') || lower.contains('sound') || lower.contains('speaker') || lower.contains('headphone') || lower.contains('earbud') || lower.contains('tws') || lower.contains('camera')) {
      return 'Electronics';
    }
    if (lower.contains('mobile') || lower.contains('phone') || lower.contains('smartphone') || lower.contains('smartwatch') || lower.contains('tablet') || lower.contains('ipad') || lower.contains('gadget') || lower.contains('powerbank') || lower.contains('charger')) {
      return 'Mobile & Gadgets';
    }
    if (lower.contains('laptop') || lower.contains('desktop') || lower.contains('computer') || lower.contains('macbook') || lower.contains('pc') || lower.contains('monitor') || lower.contains('hardware')) {
      return 'Computers';
    }
    if (lower.contains('appliance') || lower.contains('fridge') || lower.contains('refrigerator') || lower.contains('microwave') || lower.contains('oven') || lower.contains('washer')) {
      return 'Home Appliances';
    }
    if (lower.contains('medical') || lower.contains('pharmacy') || lower.contains('health') || lower.contains('hospital') || lower.contains('chemist') || lower.contains('clinic')) {
      return 'Healthcare';
    }
    if (lower.contains('fashion') || lower.contains('cloth') || lower.contains('apparel') || lower.contains('garment') || lower.contains('shoe') || lower.contains('wear')) {
      return 'Fashion';
    }
    if (lower.contains('beauty') || lower.contains('cosmetic') || lower.contains('personal care') || lower.contains('skincare') || lower.contains('salon')) {
      return 'Beauty & Personal Care';
    }
    if (lower.contains('fuel') || lower.contains('petrol') || lower.contains('diesel') || lower.contains('cng') || lower.contains('gas')) {
      return 'Fuel';
    }
    if (lower.contains('furniture') || lower.contains('decor') || lower.contains('chair') || lower.contains('table') || lower.contains('sofa')) {
      return 'Furniture';
    }
    if (lower.contains('utility') || lower.contains('utilities') || lower.contains('bill') || lower.contains('electricity') || lower.contains('broadband')) {
      return 'Utilities';
    }
    if (lower.contains('stationery') || lower.contains('office')) {
      return 'Office Supplies';
    }
    if (lower.contains('book')) {
      return 'Books';
    }
    if (lower.contains('travel') || lower.contains('flight') || lower.contains('hotel') || lower.contains('cab')) {
      return 'Travel';
    }
    if (lower.contains('entertainment') || lower.contains('movie') || lower.contains('cinema')) {
      return 'Entertainment';
    }
    if (lower.contains('sport') || lower.contains('fitness') || lower.contains('gym')) {
      return 'Sports';
    }
    if (lower.contains('auto') || lower.contains('car') || lower.contains('bike') || lower.contains('vehicle')) {
      return 'Automotive';
    }
    if (lower.contains('subscription') || lower.contains('saas')) {
      return 'Subscription';
    }

    // Partial contains match against supported categories
    for (final cat in supportedCategories) {
      if (lower.contains(cat.toLowerCase()) || cat.toLowerCase().contains(lower)) {
        return cat;
      }
    }

    return 'Others';
  }

  /// Intelligently infers an item-specific category based on item name and context
  String inferItemCategory(
    String itemName, {
    String? existingCategory,
    String? receiptCategory,
  }) {
    // If existing category is valid and specific, use it
    if (existingCategory != null &&
        existingCategory.trim().isNotEmpty &&
        existingCategory.toLowerCase() != 'others' &&
        existingCategory.toLowerCase() != 'other') {
      final resolved = resolveSupportedCategory(existingCategory);
      if (resolved != 'Others') return resolved;
    }

    final lower = itemName.toLowerCase().trim();

    // 1. Computers & Laptops
    if (lower.contains('laptop') ||
        lower.contains('macbook') ||
        lower.contains('desktop') ||
        lower.contains('computer') ||
        lower.contains('notebook') ||
        lower.contains('pc ') ||
        lower.contains('monitor') ||
        lower.contains('motherboard') ||
        lower.contains('graphics card') ||
        lower.contains('gpu') ||
        lower.contains('cpu ') ||
        lower.contains('processor') ||
        lower.contains('ram ') ||
        lower.contains('ddr') ||
        lower.contains('ssd') ||
        lower.contains('hard disk') ||
        lower.contains('hdd') ||
        lower.contains('keyboard') ||
        lower.contains('mouse') ||
        lower.contains('printer') ||
        lower.contains('scanner')) {
      return 'Computers';
    }

    // 2. Mobile & Gadgets
    if (lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('iphone') ||
        lower.contains('galaxy') ||
        lower.contains('oneplus') ||
        lower.contains('pixel') ||
        lower.contains('redmi') ||
        lower.contains('xiaomi') ||
        lower.contains('realme') ||
        lower.contains('oppo') ||
        lower.contains('vivo') ||
        lower.contains('tablet') ||
        lower.contains('ipad') ||
        lower.contains('smartwatch') ||
        lower.contains('watch') ||
        lower.contains('fitness band') ||
        lower.contains('powerbank') ||
        lower.contains('power bank') ||
        lower.contains('charger') ||
        lower.contains('adapter') ||
        lower.contains('cable') ||
        lower.contains('type-c') ||
        lower.contains('lightning') ||
        lower.contains('tempered glass') ||
        lower.contains('back cover') ||
        lower.contains('case')) {
      return 'Mobile & Gadgets';
    }

    // 3. Audio & Electronics
    if (lower.contains('airdopes') ||
        lower.contains('airpods') ||
        lower.contains('earbud') ||
        lower.contains('earphone') ||
        lower.contains('headphone') ||
        lower.contains('headset') ||
        lower.contains('tws') ||
        lower.contains('speaker') ||
        lower.contains('soundbar') ||
        lower.contains('bluetooth speaker') ||
        lower.contains('tv') ||
        lower.contains('television') ||
        lower.contains('oled') ||
        lower.contains('qled') ||
        lower.contains('smart tv') ||
        lower.contains('camera') ||
        lower.contains('dslr') ||
        lower.contains('lens') ||
        lower.contains('gopro') ||
        lower.contains('playstation') ||
        lower.contains('ps5') ||
        lower.contains('ps4') ||
        lower.contains('xbox') ||
        lower.contains('nintendo') ||
        lower.contains('console') ||
        lower.contains('controller') ||
        lower.contains('drone') ||
        lower.contains('projector')) {
      return 'Electronics';
    }

    // 4. Home Appliances
    if (lower.contains('refrigerator') ||
        lower.contains('fridge') ||
        lower.contains('washing machine') ||
        lower.contains('dryer') ||
        lower.contains('air conditioner') ||
        lower.contains('ac ') ||
        lower.contains('split ac') ||
        lower.contains('inverter') ||
        lower.contains('microwave') ||
        lower.contains('oven') ||
        lower.contains('otg') ||
        lower.contains('purifier') ||
        lower.contains('ro ') ||
        lower.contains('water heater') ||
        lower.contains('geyser') ||
        lower.contains('chimney') ||
        lower.contains('cooktop') ||
        lower.contains('induction') ||
        lower.contains('mixer') ||
        lower.contains('grinder') ||
        lower.contains('blender') ||
        lower.contains('juicer') ||
        lower.contains('air fryer') ||
        lower.contains('kettle') ||
        lower.contains('iron') ||
        lower.contains('vacuum') ||
        lower.contains('fan') ||
        lower.contains('cooler') ||
        lower.contains('stabilizer')) {
      return 'Home Appliances';
    }

    // 5. Healthcare & Pharmacy
    if (lower.contains('tablet') && (lower.contains('mg') || lower.contains('strip') || lower.contains('capsule')) ||
        lower.contains('syrup') ||
        lower.contains('capsule') ||
        lower.contains('ointment') ||
        lower.contains('drops') ||
        lower.contains('injection') ||
        lower.contains('bandage') ||
        lower.contains('paracetamol') ||
        lower.contains('dolo') ||
        lower.contains('crocin') ||
        lower.contains('vitamin') ||
        lower.contains('calcium') ||
        lower.contains('protein powder') ||
        lower.contains('thermometer') ||
        lower.contains('bp monitor') ||
        lower.contains('oximeter')) {
      return 'Healthcare';
    }

    // 6. Groceries
    if (lower.contains('milk') ||
        lower.contains('bread') ||
        lower.contains('egg') ||
        lower.contains('butter') ||
        lower.contains('cheese') ||
        lower.contains('paneer') ||
        lower.contains('curd') ||
        lower.contains('atta') ||
        lower.contains('flour') ||
        lower.contains('rice') ||
        lower.contains('dal') ||
        lower.contains('oil') ||
        lower.contains('ghee') ||
        lower.contains('sugar') ||
        lower.contains('salt') ||
        lower.contains('masala') ||
        lower.contains('spice') ||
        lower.contains('biscuit') ||
        lower.contains('cookie') ||
        lower.contains('chip') ||
        lower.contains('snack') ||
        lower.contains('chocolate') ||
        lower.contains('tea') ||
        lower.contains('coffee') ||
        lower.contains('juice') ||
        lower.contains('vegetable') ||
        lower.contains('fruit')) {
      return 'Groceries';
    }

    // 7. Fashion & Apparel
    if (lower.contains('shirt') ||
        lower.contains('t-shirt') ||
        lower.contains('pant') ||
        lower.contains('jeans') ||
        lower.contains('trouser') ||
        lower.contains('dress') ||
        lower.contains('kurta') ||
        lower.contains('saree') ||
        lower.contains('jacket') ||
        lower.contains('sweater') ||
        lower.contains('hoodie') ||
        lower.contains('shoe') ||
        lower.contains('sneaker') ||
        lower.contains('sandal') ||
        lower.contains('slipper') ||
        lower.contains('socks') ||
        lower.contains('belt') ||
        lower.contains('wallet') ||
        lower.contains('handbag')) {
      return 'Fashion';
    }

    // 8. Beauty & Personal Care
    if (lower.contains('soap') ||
        lower.contains('shampoo') ||
        lower.contains('conditioner') ||
        lower.contains('lotion') ||
        lower.contains('cream') ||
        lower.contains('face wash') ||
        lower.contains('perfume') ||
        lower.contains('deodorant') ||
        lower.contains('toothpaste') ||
        lower.contains('brush') ||
        lower.contains('sunscreen') ||
        lower.contains('serum') ||
        lower.contains('trimmer') ||
        lower.contains('shaver') ||
        lower.contains('hair dryer')) {
      return 'Beauty & Personal Care';
    }

    // 9. If no specific item keywords matched, inherit the normalized receipt category
    if (receiptCategory != null && receiptCategory.isNotEmpty && receiptCategory != 'Others') {
      return resolveSupportedCategory(receiptCategory);
    }

    return 'Others';
  }

  /// Queries the Groq API for ultra-fast receipt categorization
  Future<Map<String, dynamic>> _callGroqCategorizer({
    required String merchant,
    required List<String> items,
    required String apiKey,
  }) async {
    final systemPrompt = '''
You are an expert AI categorization system for purchase receipts.
Determine the single best category for the given receipt based on the merchant name and items list.

List of supported categories:
${supportedCategories.join('\n')}

Rules:
1. You must return a single JSON object.
2. The JSON object must contain "category" (String) and "confidence" (int, 0 to 100).
3. The category value must exactly match one of the supported categories listed above.
4. If you cannot determine the category, return "Others" with a confidence of 50.
5. Do NOT include markdown code blocks or backticks.

Input Details:
Merchant Name: $merchant
Items Purchased: ${items.join(', ')}
''';

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "openai/gpt-oss-120b",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": "Categorize this receipt:\nMerchant: $merchant\nItems: ${items.join(', ')}"}
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0.1
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Groq categorizer HTTP status ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final String content = data['choices'][0]['message']['content'];
    return jsonDecode(content.trim()) as Map<String, dynamic>;
  }

  /// Queries the Gemini API to categorize the receipt details
  Future<Map<String, dynamic>> _callGeminiCategorizer({
    required String merchant,
    required List<String> items,
    required String apiKey,
  }) async {
    final systemPrompt = '''
You are an expert AI categorization system for purchase receipts.
Determine the single best category for the given receipt based on the merchant name and items list.

List of supported categories:
${supportedCategories.join('\n')}

Rules:
1. You must return a single JSON object.
2. The JSON object must contain "category" (String) and "confidence" (int, 0 to 100).
3. The category value must exactly match one of the supported categories listed above.
4. If you cannot determine the category, return "Others" with a confidence of 50.
5. Do NOT include markdown code blocks or backticks.

Input Details:
Merchant Name: $merchant
Items Purchased: ${items.join(', ')}
''';

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": systemPrompt}
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
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gemini categorizer HTTP status ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final String textOutput = data['candidates'][0]['content']['parts'][0]['text'];
    return jsonDecode(textOutput.trim()) as Map<String, dynamic>;
  }

  /// High-accuracy local keyword categorization fallback
  Map<String, dynamic> localKeywordCategorize(String merchant, List<String> items) {
    final mLower = merchant.toLowerCase().trim();

    // 1. Electronics & Gadgets merchants
    if (mLower.contains('croma') ||
        mLower.contains('vijay sales') ||
        mLower.contains('reliance digital') ||
        mLower.contains('apple') ||
        mLower.contains('samsung') ||
        mLower.contains('boat') ||
        mLower.contains('sony') ||
        mLower.contains('noise') ||
        mLower.contains('oneplus') ||
        mLower.contains('xiaomi') ||
        mLower.contains('poorvika') ||
        mLower.contains('sangeetha')) {
      return {'category': 'Electronics', 'confidence': 95.0};
    }

    // 2. Groceries merchants
    if (mLower.contains('dmart') ||
        mLower.contains('reliance fresh') ||
        mLower.contains('reliance smart') ||
        mLower.contains('more supermarket') ||
        mLower.contains('more retail') ||
        mLower.contains('big bazaar') ||
        mLower.contains('smart bazaar') ||
        mLower.contains('nature basket') ||
        mLower.contains('blinkit') ||
        mLower.contains('zepto') ||
        mLower.contains('instamart') ||
        mLower.contains('jiomart') ||
        mLower.contains('supermarket') ||
        mLower.contains('hypermarket') ||
        mLower.contains('grocery') ||
        mLower.contains('kirana') ||
        mLower.contains('provisions')) {
      return {'category': 'Groceries', 'confidence': 95.0};
    }

    // 3. Food & Dining
    if (mLower.contains("mcdonald's") ||
        mLower.contains('mcdonalds') ||
        mLower.contains('kfc') ||
        mLower.contains('burger king') ||
        mLower.contains("domino's") ||
        mLower.contains('dominos') ||
        mLower.contains('pizza hut') ||
        mLower.contains('subway') ||
        mLower.contains('starbucks') ||
        mLower.contains('swiggy') ||
        mLower.contains('zomato') ||
        mLower.contains('restaurant') ||
        mLower.contains('cafe') ||
        mLower.contains('dhaba') ||
        mLower.contains('bakery') ||
        mLower.contains('bistro') ||
        mLower.contains('biryani') ||
        mLower.contains('dining') ||
        mLower.contains('sweets')) {
      return {'category': 'Food & Dining', 'confidence': 95.0};
    }

    // 4. Fuel
    if (mLower.contains('indian oil') ||
        mLower.contains('hp petrol') ||
        mLower.contains('hindustan petroleum') ||
        mLower.contains('bharat petroleum') ||
        mLower.contains('bpcl') ||
        mLower.contains('ioc') ||
        mLower.contains('shell') ||
        mLower.contains('petrol') ||
        mLower.contains('fuel') ||
        mLower.contains('gas station')) {
      return {'category': 'Fuel', 'confidence': 95.0};
    }

    // 5. Healthcare
    if (mLower.contains('apollo pharmacy') ||
        mLower.contains('apollo') ||
        mLower.contains('medplus') ||
        mLower.contains('pharmacy') ||
        mLower.contains('chemist') ||
        mLower.contains('druggist') ||
        mLower.contains('hospital') ||
        mLower.contains('clinic') ||
        mLower.contains('diagnostics') ||
        mLower.contains('pathology') ||
        mLower.contains('medical') ||
        mLower.contains('pharma') ||
        mLower.contains('healthcare') ||
        mLower.contains('netmeds') ||
        mLower.contains('1mg') ||
        mLower.contains('pharmeasy')) {
      return {'category': 'Healthcare', 'confidence': 95.0};
    }

    // 6. Fashion
    if (mLower.contains('zara') ||
        mLower.contains('h&m') ||
        mLower.contains('myntra') ||
        mLower.contains('trends') ||
        mLower.contains('westside') ||
        mLower.contains('pantaloons') ||
        mLower.contains('max fashion') ||
        mLower.contains('lifestyle') ||
        mLower.contains('shoppers stop') ||
        mLower.contains('fabindia') ||
        mLower.contains('decathlon') ||
        mLower.contains('bata') ||
        mLower.contains('nike') ||
        mLower.contains('adidas') ||
        mLower.contains('puma') ||
        mLower.contains('apparel') ||
        mLower.contains('clothing') ||
        mLower.contains('textile') ||
        mLower.contains('garment')) {
      return {'category': 'Fashion', 'confidence': 95.0};
    }

    // 7. Furniture
    if (mLower.contains('ikea') ||
        mLower.contains('pepperfry') ||
        mLower.contains('urban ladder') ||
        mLower.contains('furniture') ||
        mLower.contains('home centre') ||
        mLower.contains('sleepwell')) {
      return {'category': 'Furniture', 'confidence': 95.0};
    }

    // 8. Scan item descriptions for strong category indicators
    for (final item in items) {
      final iLower = item.toLowerCase();
      if (iLower.contains('laptop') || iLower.contains('macbook') || iLower.contains('computer') || iLower.contains('desktop') || iLower.contains('monitor')) {
        return {'category': 'Computers', 'confidence': 90.0};
      }
      if (iLower.contains('phone') || iLower.contains('mobile') || iLower.contains('iphone') || iLower.contains('smartwatch') || iLower.contains('powerbank') || iLower.contains('charger')) {
        return {'category': 'Mobile & Gadgets', 'confidence': 90.0};
      }
      if (iLower.contains('airdopes') || iLower.contains('earbud') || iLower.contains('headphone') || iLower.contains('speaker') || iLower.contains('tv') || iLower.contains('television')) {
        return {'category': 'Electronics', 'confidence': 90.0};
      }
      if (iLower.contains('fridge') || iLower.contains('washing machine') || iLower.contains('microwave') || iLower.contains('geyser') || iLower.contains('purifier') || iLower.contains('air conditioner')) {
        return {'category': 'Home Appliances', 'confidence': 90.0};
      }
      if (iLower.contains('milk') || iLower.contains('bread') || iLower.contains('rice') || iLower.contains('atta') || iLower.contains('vegetable') || iLower.contains('biscuit')) {
        return {'category': 'Groceries', 'confidence': 90.0};
      }
      if (iLower.contains('shirt') || iLower.contains('pant') || iLower.contains('jeans') || iLower.contains('t-shirt') || iLower.contains('dress') || iLower.contains('shoes')) {
        return {'category': 'Fashion', 'confidence': 90.0};
      }
      if (iLower.contains('tablet') && (iLower.contains('mg') || iLower.contains('strip')) || iLower.contains('syrup') || iLower.contains('capsule') || iLower.contains('ointment')) {
        return {'category': 'Healthcare', 'confidence': 90.0};
      }
    }

    return {'category': 'Others', 'confidence': 50.0};
  }
}
