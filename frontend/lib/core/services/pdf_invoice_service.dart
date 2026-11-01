import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/services/pdf_font_helper.dart';
import 'package:receipto/features/receipts/presentation/models/receipt_detail_view_model.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

class PdfInvoiceService {
  /// Generates a professional invoice PDF file from receipt detail data and optional warranty models.
  static Future<File> generateInvoicePdf({
    required ReceiptDetailViewModel detail,
    List<WarrantyModel>? warranties,
  }) async {
    final pdfTheme = await PdfFontHelper.getReceiptoPdfTheme();
    final pdf = pw.Document(theme: pdfTheme);

    // Page 1: Invoice Content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header & Branding
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RECEIPTO INVOICE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        detail.merchant.isNotEmpty ? detail.merchant : 'Merchant Invoice',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      if (detail.invoiceNumber != null && detail.invoiceNumber!.isNotEmpty)
                        pw.Text(
                          '# ${detail.invoiceNumber}',
                          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Metadata Grid
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (detail.purchaseDate.isNotEmpty)
                        pw.Text('Date: ${detail.purchaseDate}', style: const pw.TextStyle(fontSize: 10)),
                      if (detail.paymentMethod.isNotEmpty)
                        pw.Text('Payment: ${detail.paymentMethod}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (detail.gstNumber != null && detail.gstNumber!.isNotEmpty)
                        pw.Text('GST / Tax ID: ${detail.gstNumber}', style: const pw.TextStyle(fontSize: 10)),
                      if (detail.category.isNotEmpty)
                        pw.Text('Category: ${detail.category}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Text('Purchased Items', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Item Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Unit Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  // Table Rows
                  if (detail.items.isEmpty)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Total Purchase', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('1', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(CurrencyFormatter.format(detail.amount, currency: detail.currency), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(CurrencyFormatter.format(detail.amount, currency: detail.currency), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    )
                  else
                    ...detail.items.map((prod) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(prod.name, style: const pw.TextStyle(fontSize: 10)),
                                if (prod.warrantyExpiry != null && prod.warrantyExpiry!.isNotEmpty)
                                  pw.Text('Expiry: ${prod.warrantyExpiry}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('${prod.qty}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(CurrencyFormatter.format(prod.unitPrice, currency: detail.currency), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(CurrencyFormatter.format(prod.price, currency: detail.currency), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                          ),
                        ],
                      );
                    }),
                ],
              ),
              pw.SizedBox(height: 16),

              // Summary Breakdown
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        if (detail.subtotal != null)
                          _buildSummaryPdfRow('Subtotal', CurrencyFormatter.format(detail.subtotal!, currency: detail.currency)),
                        if (detail.tax != null)
                          _buildSummaryPdfRow('Tax / GST', CurrencyFormatter.format(detail.tax!, currency: detail.currency)),
                        if (detail.discount != null)
                          _buildSummaryPdfRow('Discount', '-${CurrencyFormatter.format(detail.discount!, currency: detail.currency)}'),
                        pw.Divider(color: PdfColors.grey400),
                        _buildSummaryPdfRow(
                          'Grand Total',
                          CurrencyFormatter.format(detail.amount, currency: detail.currency),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Warranty Details Section (if present)
              if (warranties != null && warranties.isNotEmpty) ...[
                pw.Text('Warranty Protection Summary', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                pw.SizedBox(height: 6),
                ...warranties.map((w) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.teal300, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      color: PdfColors.teal50,
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${w.productName} (${w.warrantyPeriod} ${w.warrantyUnit})', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Status: ${w.status} | Expires: ${w.expiryDate}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  );
                }),
              ],

              pw.Spacer(),
              // Footer Note
              pw.Center(
                child: pw.Text(
                  'Generated automatically by Receipto AI Expense Tracker',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Page 2: Embedded Image (if available)
    if (detail.receiptImageUrl.isNotEmpty) {
      try {
        Uint8List? imageBytes;
        if (detail.receiptImageUrl.startsWith('http')) {
          final response = await http.get(Uri.parse(detail.receiptImageUrl));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          }
        } else {
          final file = File(detail.receiptImageUrl);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
          }
        }

        if (imageBytes != null && imageBytes.isNotEmpty) {
          final pdfImage = pw.MemoryImage(imageBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(24),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ORIGINAL SCANNED RECEIPT',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Expanded(
                      child: pw.Center(
                        child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) print('Failed to attach receipt image to PDF: $e');
      }
    }

    // Save to file
    final outputDir = await getTemporaryDirectory();
    final sanitizeInvoice = (detail.invoiceNumber ?? 'receipt_${detail.id}').replaceAll(RegExp(r'[^\w\.-]'), '_');
    final filePath = '${outputDir.path}/Invoice_$sanitizeInvoice.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryPdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
