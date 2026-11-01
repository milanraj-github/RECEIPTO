import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
}
