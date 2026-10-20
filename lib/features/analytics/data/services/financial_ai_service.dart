import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/features/analytics/domain/models/financial_overview_data.dart';

final financialAiServiceProvider = Provider<FinancialAiService>((ref) {
  return FinancialAiService();
});

class FinancialInsightItem {
  final String title;
  final String description;
  final String type; // 'fact', 'alert', 'recommendation', 'forecast'
  final String? metric;

  const FinancialInsightItem({
    required this.title,
    required this.description,
    required this.type,
    this.metric,
  });
}

class FinancialAiService {
  // Simple in-memory cache to prevent repeated API calls on widget rebuilds
  final Map<String, List<FinancialInsightItem>> _insightsCache = {};

  String _getGeminiApiKey() {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Generates dynamic insights using verified financial overview data
  Future<List<FinancialInsightItem>> generateInsights(
    FinancialOverviewData data, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${data.selectedPeriod.name}_${data.netSpending}_${data.transactionCount}';
    if (!forceRefresh && _insightsCache.containsKey(cacheKey)) {
      return _insightsCache[cacheKey]!;
    }

    // 1. Generate verified deterministic core insights
    final List<FinancialInsightItem> coreInsights = _generateDeterministicInsights(data);

    // 2. Attempt to enrich with Gemini if key is available
    final apiKey = _getGeminiApiKey();
    if (apiKey.isEmpty || data.transactionCount == 0) {
      _insightsCache[cacheKey] = coreInsights;
      return coreInsights;
    }

    try {
      final geminiInsights = await _fetchGeminiInsights(data, apiKey);
      if (geminiInsights.isNotEmpty) {
        final combined = [...coreInsights, ...geminiInsights];
        _insightsCache[cacheKey] = combined;
        return combined;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FinancialAiService] Gemini insight enrichment error: $e. Falling back to deterministic rules.');
      }
    }

    _insightsCache[cacheKey] = coreInsights;
    return coreInsights;
  }

  /// Authoritative deterministic insights based on verified facts
  List<FinancialInsightItem> _generateDeterministicInsights(FinancialOverviewData data) {
    final List<FinancialInsightItem> list = [];

    // Fact 1: Category concentration
    if (data.netSpending > 0 && data.topCategory != 'None') {
      final double pct = (data.topCategorySpend / data.netSpending) * 100;
      list.add(FinancialInsightItem(
        title: 'Spending Concentration',
        description: 'You spent ${pct.toStringAsFixed(0)}% of your total expenditures on ${data.topCategory} (${CurrencyFormatter.format(data.topCategorySpend)}).',
        type: 'fact',
        metric: '${pct.toStringAsFixed(0)}%',
      ));
    }

    // Fact 2: Essential vs Discretionary
    if (data.netSpending > 0) {
      final double essPct = (data.essentialSpending / data.netSpending) * 100;
      final double discPct = (data.discretionarySpending / data.netSpending) * 100;
      list.add(FinancialInsightItem(
        title: 'Essential vs Discretionary',
        description: 'Needs (Groceries, Utilities, Health, Fuel) represent ${essPct.toStringAsFixed(0)}% of your spend, while discretionary purchases represent ${discPct.toStringAsFixed(0)}%.',
        type: 'fact',
        metric: '${essPct.toStringAsFixed(0)}% Essential',
      ));
    }

    // Alert 3: Budget Overrun or Healthy Status
    if (data.overallBudget != null && data.overallBudget! > 0) {
      if (data.projectedBudgetOverrun != null && data.projectedBudgetOverrun! > 0) {
        list.add(FinancialInsightItem(
          title: 'Budget Overrun Risk (Estimate)',
          description: 'At your current spending rate of ${CurrencyFormatter.format(data.avgDailySpend)}/day, you are projected to exceed your monthly budget by ${CurrencyFormatter.format(data.projectedBudgetOverrun!)}.',
          type: 'alert',
          metric: '+${CurrencyFormatter.format(data.projectedBudgetOverrun!)}',
        ));
      } else {
        list.add(FinancialInsightItem(
          title: 'Budget On Track',
          description: 'You have consumed ${data.budgetUsedPercentage.toStringAsFixed(1)}% of your monthly budget. Remaining allowance is ${CurrencyFormatter.format(data.budgetRemaining)}.',
          type: 'recommendation',
          metric: '${data.budgetUsedPercentage.toStringAsFixed(0)}% Used',
        ));
      }
    }

    // Recommendation 4: Savings / Discounts
    if (data.totalSaved > 0) {
      list.add(FinancialInsightItem(
        title: 'Discount Savings',
        description: 'You captured ${CurrencyFormatter.format(data.totalSaved)} in coupons and discounts across your purchases for this period.',
        type: 'recommendation',
        metric: CurrencyFormatter.format(data.totalSaved),
      ));
    }

    // Recommendation 5: Warranty Protection
    if (data.expiringSoonCount > 0) {
      list.add(FinancialInsightItem(
        title: 'Warranty Expiry Alert',
        description: 'You have ${data.expiringSoonCount} warranty protection plans expiring within the next 30 days. Check your invoices for eligibility.',
        type: 'alert',
        metric: '${data.expiringSoonCount} Expiring',
      ));
    }

    if (list.isEmpty) {
      list.add(const FinancialInsightItem(
        title: 'Start Tracking',
        description: 'Scan receipts or log manual expenses to generate personalized AI spending insights.',
        type: 'recommendation',
      ));
    }

    return list;
  }

  /// Calls Gemini using verified financial summary JSON payload
  Future<List<FinancialInsightItem>> _fetchGeminiInsights(
    FinancialOverviewData data,
    String apiKey,
  ) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final promptData = {
      "period": data.selectedPeriod.name,
      "total_spending": data.netSpending,
      "transaction_count": data.transactionCount,
      "daily_average": data.avgDailySpend,
      "top_category": data.topCategory,
      "top_category_spend": data.topCategorySpend,
      "top_merchant": data.topMerchant,
      "essential_spend": data.essentialSpending,
      "discretionary_spend": data.discretionarySpending,
      "monthly_budget": data.overallBudget,
      "projected_spend": data.projectedMonthEndSpend,
    };

    final systemInstruction = '''
You are an expert AI financial advisor for Receipto.
Analyze this verified user spending data and return 2 concise, intelligent, actionable financial recommendations.
CRITICAL RULES:
- Never fabricate numbers or merchants. Use only the provided figures.
- Label any future projections clearly as estimates.
- Keep each recommendation under 2 sentences.
- Return ONLY valid JSON matching this schema:
[
  {
    "title": "Short title",
    "description": "Insight text referencing actual figures",
    "type": "recommendation"
  }
]
''';

    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": systemInstruction},
            {"text": "Financial Data: ${jsonEncode(promptData)}"}
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
      return [];
    }

    final respJson = jsonDecode(response.body);
    final String textOutput = respJson['candidates'][0]['content']['parts'][0]['text'];
    final List<dynamic> decoded = jsonDecode(textOutput.trim());

    return decoded.map((item) {
      return FinancialInsightItem(
        title: item['title'] as String? ?? 'AI Recommendation',
        description: item['description'] as String? ?? '',
        type: item['type'] as String? ?? 'recommendation',
      );
    }).toList();
  }
}
