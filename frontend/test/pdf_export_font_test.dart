import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:receipto/core/services/currency_converter_service.dart';
import 'package:receipto/core/utils/currency_formatter.dart';

void main() {
  test('PDF generates with Roboto font and Rupee symbol', () async {
    final regularBytes = await File('assets/fonts/Roboto-Regular.ttf').readAsBytes();
    final boldBytes = await File('assets/fonts/Roboto-Bold.ttf').readAsBytes();

    final ttfRegular = pw.Font.ttf(regularBytes.buffer.asByteData());
    final ttfBold = pw.Font.ttf(boldBytes.buffer.asByteData());

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttfRegular,
        bold: ttfBold,
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('RECEIPTO SUMMARY REPORT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
              pw.Text('TOTAL EXPENSE: ₹8,709.82'),
              pw.Text('Total: ₹ 22.00'),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    expect(bytes.isNotEmpty, true);
    print('Generated PDF with length: ${bytes.length}');
  });

  test('formatPdf produces clean ASCII currency representation without broken glyphs', () {
    expect(CurrencyFormatter.formatPdf(8246.54, currency: '₹'), 'INR 8,246.54');
    expect(CurrencyFormatter.formatPdf(8246.54, currency: 'INR'), 'INR 8,246.54');
    expect(CurrencyFormatter.formatPdf(86.76, currency: r'$'), r'$86.76');
    expect(CurrencyFormatter.formatPdf(120.00, currency: 'USD'), 'USD 120.00');

    // Converted PDF format
    final converted = CurrencyConverterService.formatConvertedForPdf(86.76, currency: r'$');
    expect(converted.startsWith('INR '), isTrue);
    expect(converted.contains('≈'), isFalse);
    expect(converted.contains('₹'), isFalse);
  });
}
