import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:receipto/core/services/pdf_invoice_service.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/features/receipts/presentation/models/receipt_detail_view_model.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

final receiptExportServiceProvider = Provider<ReceiptExportService>((ref) {
  return ReceiptExportService();
});

enum ExportFormat { pdf, csv, json }

class ReceiptExportService {
  /// Exports a single receipt to PDF, CSV, or JSON and triggers the system share sheet.
  Future<File> exportSingleReceipt({
    required ReceiptDetailViewModel detail,
    List<WarrantyModel>? warranties,
    required ExportFormat format,
    bool autoShare = true,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanMerchant = detail.merchant.replaceAll(RegExp(r'[^\w\s-]'), '_').trim();
    final fileName = 'Receipto_${cleanMerchant}_$timestamp';

    File exportedFile;

    switch (format) {
      case ExportFormat.pdf:
        exportedFile = await PdfInvoiceService.generateInvoicePdf(
          detail: detail,
          warranties: warranties,
        );
        break;

      case ExportFormat.csv:
        final csvContent = _generateSingleReceiptCsv(detail, warranties);
        final filePath = '${tempDir.path}/$fileName.csv';
        exportedFile = File(filePath);
        await exportedFile.writeAsString(csvContent);
        break;

      case ExportFormat.json:
        final jsonMap = _generateSingleReceiptJson(detail, warranties);
        final filePath = '${tempDir.path}/$fileName.json';
        exportedFile = File(filePath);
        await exportedFile.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonMap));
        break;
    }

    if (autoShare) {
      await Share.shareXFiles(
        [XFile(exportedFile.path)],
        subject: 'Receipto Export - ${detail.merchant}',
        text: 'Receipt export for ${detail.merchant} (${detail.purchaseDate})',
      );
    }

    return exportedFile;
  }

  /// Exports multiple receipts into a consolidated PDF, CSV, or JSON and triggers share sheet.
  Future<File> exportMultipleReceipts({
    required List<Map<String, dynamic>> receipts,
    List<WarrantyModel>? warranties,
    required ExportFormat format,
    bool autoShare = true,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Receipto_Export_Summary_$timestamp';

    File exportedFile;

    switch (format) {
      case ExportFormat.pdf:
        exportedFile = await _generateMultiReceiptsPdf(receipts, warranties);
        break;

      case ExportFormat.csv:
        final csvContent = _generateMultiReceiptsCsv(receipts, warranties);
        final filePath = '${tempDir.path}/$fileName.csv';
        exportedFile = File(filePath);
        await exportedFile.writeAsString(csvContent);
        break;

      case ExportFormat.json:
        final jsonList = _generateMultiReceiptsJson(receipts, warranties);
        final filePath = '${tempDir.path}/$fileName.json';
        exportedFile = File(filePath);
        await exportedFile.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonList));
        break;
    }

    if (autoShare) {
      await Share.shareXFiles(
        [XFile(exportedFile.path)],
        subject: 'Receipto Multi-Receipts Export',
        text: 'Exported ${receipts.length} receipts from Receipto.',
      );
    }

    return exportedFile;
  }

  String _generateSingleReceiptCsv(ReceiptDetailViewModel detail, List<WarrantyModel>? warranties) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln('Receipto Receipt Export');
    buffer.writeln('Receipt ID,${_escapeCsv(detail.id)}');
    buffer.writeln('Merchant,${_escapeCsv(detail.merchant)}');
    buffer.writeln('Invoice Number,${_escapeCsv(detail.invoiceNumber ?? '')}');
    buffer.writeln('Purchase Date,${_escapeCsv(detail.purchaseDate)}');
    buffer.writeln('Category,${_escapeCsv(detail.category)}');
    buffer.writeln('Payment Method,${_escapeCsv(detail.paymentMethod)}');
    buffer.writeln('Currency,${_escapeCsv(detail.currency)}');
    buffer.writeln('Total Amount,${detail.amount.toStringAsFixed(2)}');
    buffer.writeln('GST Number,${_escapeCsv(detail.gstNumber ?? '')}');
    buffer.writeln('');

    // Products table
    buffer.writeln('Products');
    buffer.writeln('Product Name,Quantity,Unit Price,Total Price,Warranty Period,Warranty Unit');
    for (final item in detail.items) {
      buffer.writeln(
        '${_escapeCsv(item.name)},${item.qty},${item.unitPrice.toStringAsFixed(2)},${item.price.toStringAsFixed(2)},${item.warrantyPeriod ?? ''},${_escapeCsv(item.warrantyUnit ?? '')}',
      );
    }

    if (warranties != null && warranties.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Warranties');
      buffer.writeln('Product,Warranty Period,Purchase Date,Expiry Date,Status');
      for (final w in warranties) {
        buffer.writeln(
          '${_escapeCsv(w.productName)},${w.warrantyPeriod} ${w.warrantyUnit},${_escapeCsv(w.purchaseDate)},${_escapeCsv(w.expiryDate)},${_escapeCsv(w.status)}',
        );
      }
    }

    return buffer.toString();
  }

  Map<String, dynamic> _generateSingleReceiptJson(ReceiptDetailViewModel detail, List<WarrantyModel>? warranties) {
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'receipt': {
        'id': detail.id,
        'merchant': detail.merchant,
        'invoice_number': detail.invoiceNumber,
        'purchase_date': detail.purchaseDate,
        'category': detail.category,
        'payment_method': detail.paymentMethod,
        'currency': detail.currency,
        'amount': detail.amount,
        'subtotal': detail.subtotal,
        'tax': detail.tax,
        'discount': detail.discount,
        'gst_number': detail.gstNumber,
        'image_url': detail.receiptImageUrl,
        'products': detail.items.map((item) => {
          'name': item.name,
          'quantity': item.qty,
          'unit_price': item.unitPrice,
          'total_price': item.price,
          'warranty_period': item.warrantyPeriod,
          'warranty_unit': item.warrantyUnit,
        }).toList(),
      },
      'warranties': warranties?.map((w) => w.toJson()).toList() ?? [],
    };
  }

  String _generateMultiReceiptsCsv(List<Map<String, dynamic>> receipts, List<WarrantyModel>? warranties) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Merchant,Date,Category,Total,Currency,Payment Method,Invoice Number,Warranties');
    for (final r in receipts) {
      final idStr = r['id']?.toString() ?? '';
      final matchingWarranties = warranties?.where((w) => w.receiptId == idStr).map((w) => '${w.productName} (${w.status})').join('; ') ?? '';
      final total = r['grand_total'] ?? r['total'] ?? 0.0;
      buffer.writeln(
        '${_escapeCsv(idStr)},${_escapeCsv(r['merchant_name']?.toString() ?? '')},${_escapeCsv(r['date']?.toString() ?? '')},${_escapeCsv(r['category']?.toString() ?? '')},${total.toString()},${_escapeCsv(r['currency']?.toString() ?? '₹')},${_escapeCsv(r['payment_method']?.toString() ?? '')},${_escapeCsv(r['invoice_number']?.toString() ?? '')},${_escapeCsv(matchingWarranties)}',
      );
    }
    return buffer.toString();
  }

  List<Map<String, dynamic>> _generateMultiReceiptsJson(List<Map<String, dynamic>> receipts, List<WarrantyModel>? warranties) {
    return receipts.map((r) {
      final idStr = r['id']?.toString() ?? '';
      final matchingWarranties = warranties?.where((w) => w.receiptId == idStr).map((w) => w.toJson()).toList() ?? [];
      return {
        'receipt': r,
        'warranties': matchingWarranties,
      };
    }).toList();
  }

  Future<File> _generateMultiReceiptsPdf(List<Map<String, dynamic>> receipts, List<WarrantyModel>? warranties) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          double grandSum = 0;
          for (final r in receipts) {
            grandSum += (r['grand_total'] as num?)?.toDouble() ?? (r['total'] as num?)?.toDouble() ?? 0.0;
          }

          return [
            // Title Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RECEIPTO SUMMARY REPORT',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Total Receipts: ${receipts.length} | Generated: ${DateTime.now().toString().split(' ').first}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TOTAL EXPENSE', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text(
                      CurrencyFormatter.format(grandSum),
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            // Receipts Table
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Merchant', 'Category', 'Invoice #', 'Total'],
              data: receipts.map((r) {
                final amt = (r['grand_total'] as num?)?.toDouble() ?? (r['total'] as num?)?.toDouble() ?? 0.0;
                final cur = r['currency']?.toString() ?? '₹';
                return [
                  r['date']?.toString() ?? '-',
                  r['merchant_name']?.toString() ?? 'Unknown',
                  r['category']?.toString() ?? 'Other',
                  r['invoice_number']?.toString() ?? '-',
                  '$cur ${amt.toStringAsFixed(2)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            ),
          ];
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Receipto_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
