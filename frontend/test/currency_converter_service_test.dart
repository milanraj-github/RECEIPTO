import 'package:flutter_test/flutter_test.dart';
import 'package:receipto/core/services/currency_converter_service.dart';

void main() {
  group('Live & Offline Currency Conversion Tests', () {
    test('1. Currency Normalization maps symbols and codes accurately', () {
      expect(CurrencyConverterService.normalizeCurrency('₹'), equals('INR'));
      expect(CurrencyConverterService.normalizeCurrency('inr'), equals('INR'));
      expect(CurrencyConverterService.normalizeCurrency('Rs.'), equals('INR'));
      expect(CurrencyConverterService.normalizeCurrency(null), equals('INR'));
      expect(CurrencyConverterService.normalizeCurrency(''), equals('INR'));

      expect(CurrencyConverterService.normalizeCurrency(r'$'), equals('USD'));
      expect(CurrencyConverterService.normalizeCurrency('usd'), equals('USD'));
      expect(CurrencyConverterService.normalizeCurrency(r'US$'), equals('USD'));

      expect(CurrencyConverterService.normalizeCurrency('€'), equals('EUR'));
      expect(CurrencyConverterService.normalizeCurrency('eur'), equals('EUR'));

      expect(CurrencyConverterService.normalizeCurrency('£'), equals('GBP'));
      expect(CurrencyConverterService.normalizeCurrency('gbp'), equals('GBP'));

      expect(CurrencyConverterService.normalizeCurrency('AED'), equals('AED'));
      expect(CurrencyConverterService.normalizeCurrency('د.إ'), equals('AED'));

      expect(CurrencyConverterService.normalizeCurrency('CAD'), equals('CAD'));
      expect(CurrencyConverterService.normalizeCurrency('AUD'), equals('AUD'));
      expect(CurrencyConverterService.normalizeCurrency('SGD'), equals('SGD'));
    });

    test('2. isForeign distinguishes domestic from international currencies', () {
      expect(CurrencyConverterService.isForeign('₹'), isFalse);
      expect(CurrencyConverterService.isForeign('INR'), isFalse);
      expect(CurrencyConverterService.isForeign('Rs'), isFalse);
      expect(CurrencyConverterService.isForeign(null), isFalse);

      expect(CurrencyConverterService.isForeign(r'$'), isTrue);
      expect(CurrencyConverterService.isForeign('USD'), isTrue);
      expect(CurrencyConverterService.isForeign('€'), isTrue);
      expect(CurrencyConverterService.isForeign('EUR'), isTrue);
      expect(CurrencyConverterService.isForeign('AED'), isTrue);
    });

    test('3. INR conversion preserves amount 1:1', () {
      expect(CurrencyConverterService.convertToInr(1500.0, currency: '₹'), equals(1500.0));
      expect(CurrencyConverterService.convertToInr(250.75, currency: 'INR'), equals(250.75));
      expect(CurrencyConverterService.convertToInr(100.0, currency: null), equals(100.0));
      expect(CurrencyConverterService.formatConvertedInr(1500.0, currency: '₹'), isEmpty);
    });

    test('4. Foreign currencies convert to INR using realistic exchange rates', () {
      // 50 USD should convert to >= 4000 INR
      final usdInr = CurrencyConverterService.convertToInr(50.0, currency: r'$');
      expect(usdInr, greaterThan(4000.0));
      expect(usdInr, lessThan(5000.0));

      // 100 EUR should convert to >= 8500 INR
      final eurInr = CurrencyConverterService.convertToInr(100.0, currency: '€');
      expect(eurInr, greaterThan(8500.0));

      // 100 AED should convert to >= 2000 INR
      final aedInr = CurrencyConverterService.convertToInr(100.0, currency: 'AED');
      expect(aedInr, greaterThan(2000.0));
    });

    test('5. Formatted converted text displays clean compact Rupee presentation', () {
      final formatted = CurrencyConverterService.formatConvertedInr(50.0, currency: r'$');
      expect(formatted, startsWith('≈ ₹'));
      expect(formatted, contains(',')); // e.g. ≈ ₹4,275
    });

    test('6. Zero or negative amounts return 0.0 safely', () {
      expect(CurrencyConverterService.convertToInr(0.0, currency: r'$'), equals(0.0));
      expect(CurrencyConverterService.convertToInr(-50.0, currency: r'$'), equals(0.0));
    });
  });
}
