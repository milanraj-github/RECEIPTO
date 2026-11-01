import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

class PdfFontHelper {
  static pw.ThemeData? _cachedTheme;

  /// Loads Roboto fonts which support the Indian Rupee symbol (₹) and UTF-8 characters.
  static Future<pw.ThemeData> getReceiptoPdfTheme() async {
    if (_cachedTheme != null) return _cachedTheme!;

    try {
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

      _cachedTheme = pw.ThemeData.withFont(
        base: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      );
      return _cachedTheme!;
    } catch (_) {
      // Graceful fallback to default base theme if running in headless environments
      return pw.ThemeData.base();
    }
  }
}
