import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipto/core/utils/currency_formatter.dart';

class CurrencyConverterService {
  static const String _prefsKeyRates = 'cached_currency_rates_to_inr';
  static const String _prefsKeyLastSync = 'cached_currency_rates_last_sync';

  // Fallback exchange rates to INR (1 foreign unit = X INR)
  static final Map<String, double> _ratesToInr = {
    'INR': 1.0,
    'USD': 85.50,
    'EUR': 92.80,
    'GBP': 111.20,
    'AED': 23.28,
    'CAD': 62.10,
    'AUD': 56.40,
    'SGD': 64.90,
    'JPY': 0.57,
    'CNY': 11.80,
    'CHF': 98.40,
    'THB': 2.45,
    'MYR': 19.30,
    'SAR': 22.80,
    'QAR': 23.45,
    'KWD': 278.50,
    'NZD': 51.20,
  };

  static bool _initialized = false;
  static DateTime? _lastSyncTime;

  /// Normalizes currency symbols, prefixes, and ISO codes to standard 3-letter codes
  static String normalizeCurrency(String? raw) {
    if (raw == null) return 'INR';
    final s = raw.trim().toUpperCase();
    if (s.isEmpty || s == '₹' || s == 'INR' || s == 'RS' || s == 'RS.' || s == 'RUPEES') {
      return 'INR';
    }
    if (s == r'$' || s == 'USD' || s == r'US$' || s == r'$US') return 'USD';
    if (s == '€' || s == 'EUR') return 'EUR';
    if (s == '£' || s == 'GBP') return 'GBP';
    if (s == 'AED' || s == 'د.إ' || s == 'DHS') return 'AED';
    if (s == 'CAD' || s == r'C$' || s == r'CA$') return 'CAD';
    if (s == 'AUD' || s == r'A$' || s == r'AU$') return 'AUD';
    if (s == 'SGD' || s == r'S$' || s == r'SG$') return 'SGD';
    if (s == 'JPY' || s == '¥' || s == 'YEN') return 'JPY';
    if (s == 'CNY' || s == 'RMB') return 'CNY';
    if (s == 'CHF') return 'CHF';
    if (s == 'THB' || s == '฿') return 'THB';
    if (s == 'MYR' || s == 'RM') return 'MYR';
    if (s == 'SAR') return 'SAR';
    if (s == 'QAR') return 'QAR';
    if (s == 'KWD') return 'KWD';
    if (s == 'NZD' || s == r'NZ$') return 'NZD';

    return s;
  }

  /// Whether a currency represents a foreign non-INR currency
  static bool isForeign(String? raw) {
    return normalizeCurrency(raw) != 'INR';
  }

  /// Initializes cached rates from local storage and initiates a background sync if stale
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt(_prefsKeyLastSync);
      if (lastSyncMs != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      }

      final cachedJson = prefs.getString(_prefsKeyRates);
      if (cachedJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        for (final entry in decoded.entries) {
          if (entry.value is num) {
            _ratesToInr[entry.key] = (entry.value as num).toDouble();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[CurrencyConverter] Cache load error: $e');
    }

    // Refresh if rates haven't been updated in 24 hours
    final shouldSync = _lastSyncTime == null ||
        DateTime.now().difference(_lastSyncTime!).inHours >= 24;
    if (shouldSync) {
      // Fire-and-forget background sync
      syncLiveRates();
    }
  }

  /// Fetches latest real-time rates from live open exchange API
  static Future<bool> syncLiveRates() async {
    try {
      final url = Uri.parse('https://open.er-api.com/v6/latest/USD');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>?;
          if (rates != null && rates.containsKey('INR')) {
            final double inrPerUsd = (rates['INR'] as num).toDouble();

            // Calculate rate to INR for each supported foreign currency
            for (final code in _ratesToInr.keys) {
              if (code == 'INR') continue;
              if (code == 'USD') {
                _ratesToInr['USD'] = inrPerUsd;
              } else if (rates.containsKey(code)) {
                final double codePerUsd = (rates[code] as num).toDouble();
                if (codePerUsd > 0) {
                  _ratesToInr[code] = inrPerUsd / codePerUsd;
                }
              }
            }

            _lastSyncTime = DateTime.now();

            // Persist to SharedPreferences
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_prefsKeyRates, jsonEncode(_ratesToInr));
              await prefs.setInt(_prefsKeyLastSync, _lastSyncTime!.millisecondsSinceEpoch);
            } catch (_) {}

            if (kDebugMode) {
              print('[CurrencyConverter] Live rates synced successfully: USD = ₹${_ratesToInr['USD']?.toStringAsFixed(2)}');
            }
            return true;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[CurrencyConverter] Live rate sync failed, using fallback/cached rates: $e');
    }
    return false;
  }

  /// Converts any foreign or local amount to Indian Rupees (INR)
  static double convertToInr(double amount, {String? currency}) {
    if (amount <= 0) return 0.0;
    final code = normalizeCurrency(currency);
    if (code == 'INR') return amount;

    final rate = _ratesToInr[code] ?? _ratesToInr['USD'] ?? 85.50;
    return amount * rate;
  }

  /// Gets the exchange rate of a currency against INR (e.g. 1 USD = 85.50 INR)
  static double getRateToInr(String? currency) {
    final code = normalizeCurrency(currency);
    return _ratesToInr[code] ?? 1.0;
  }

  /// Formats the converted INR equivalent string (e.g., "≈ ₹4,250")
  /// Returns empty string if the currency is already INR
  static String formatConvertedInr(double amount, {String? currency}) {
    if (!isForeign(currency)) return '';
    final converted = convertToInr(amount, currency: currency);
    return '≈ ${CurrencyFormatter.formatCompact(converted, currency: '₹')}';
  }

  /// Formats the converted INR equivalent cleanly for PDF export without math symbols
  static String formatConvertedForPdf(double amount, {String? currency}) {
    if (!isForeign(currency)) return '';
    final converted = convertToInr(amount, currency: currency);
    final parts = converted.abs().toStringAsFixed(2).split('.');
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = parts[0].replaceAllMapped(reg, (Match m) => '${m[1]},');
    return 'INR $formattedInteger.${parts[1]}';
  }
}
