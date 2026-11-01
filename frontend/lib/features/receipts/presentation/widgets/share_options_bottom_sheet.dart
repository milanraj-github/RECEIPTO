import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/services/pdf_invoice_service.dart';
import 'package:receipto/core/services/receipt_export_service.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/receipts/presentation/models/receipt_detail_view_model.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

class ShareOptionsBottomSheet extends StatefulWidget {
  final ReceiptDetailViewModel detail;
  final List<WarrantyModel>? warranties;
  final File? cachedPdfFile;

  const ShareOptionsBottomSheet({
    super.key,
    required this.detail,
    this.warranties,
    this.cachedPdfFile,
  });

  static Future<void> show(
    BuildContext context, {
    required ReceiptDetailViewModel detail,
    List<WarrantyModel>? warranties,
    File? cachedPdfFile,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareOptionsBottomSheet(
        detail: detail,
        warranties: warranties,
        cachedPdfFile: cachedPdfFile,
      ),
    );
  }

  @override
  State<ShareOptionsBottomSheet> createState() => _ShareOptionsBottomSheetState();
}

class _ShareOptionsBottomSheetState extends State<ShareOptionsBottomSheet> {
  bool _isLoading = false;
  String _loadingMessage = '';

  Future<File> _getOrGeneratePdf() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Generating PDF Invoice...';
    });
    final pdf = await PdfInvoiceService.generateInvoicePdf(
      detail: widget.detail,
      warranties: widget.warranties,
    );
    setState(() => _isLoading = false);
    return pdf;
  }

  Future<File?> _getImageFile() async {
    if (widget.detail.receiptImageUrl.isEmpty) return null;
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Preparing image...';
    });
    try {
      if (widget.detail.receiptImageUrl.startsWith('http')) {
        final res = await http.get(Uri.parse(widget.detail.receiptImageUrl));
        if (res.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/receipt_${widget.detail.id}.jpg');
          await file.writeAsBytes(res.bodyBytes);
          setState(() => _isLoading = false);
          return file;
        }
      } else {
        final file = File(widget.detail.receiptImageUrl);
        if (await file.exists()) {
          setState(() => _isLoading = false);
          return file;
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
    return null;
  }

  Future<void> _shareImage() async {
    final file = await _getImageFile();
    if (!mounted) return;
    if (file != null) {
      Navigator.of(context).pop();
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Receipt from ${widget.detail.merchant}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt image is not available.')),
      );
    }
  }

  Future<void> _sharePdf() async {
    final pdf = await _getOrGeneratePdf();
    if (!mounted) return;
    Navigator.of(context).pop();
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(pdf.path)], text: 'PDF Invoice from ${widget.detail.merchant}');
  }

  Future<void> _shareTextSummary() async {
    final StringBuffer summary = StringBuffer();
    summary.writeln('🧾 RECEIPT SUMMARY - ${widget.detail.merchant}');
    if (widget.detail.invoiceNumber != null) {
      summary.writeln('Invoice #: ${widget.detail.invoiceNumber}');
    }
    summary.writeln('Date: ${widget.detail.purchaseDate}');
    summary.writeln('Amount: ${CurrencyFormatter.format(widget.detail.amount, currency: widget.detail.currency)}');
    if (widget.detail.paymentMethod.isNotEmpty) {
      summary.writeln('Payment: ${widget.detail.paymentMethod}');
    }
    if (widget.detail.items.isNotEmpty) {
      summary.writeln('\nItems:');
      for (final item in widget.detail.items) {
        summary.writeln('• ${item.name} (${item.qty}x) - ${CurrencyFormatter.format(item.price, currency: widget.detail.currency)}');
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    // ignore: deprecated_member_use
    await Share.share(summary.toString());
  }

  Future<void> _sharePdfAndImage() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Preparing files for sharing...';
    });
    final pdf = await _getOrGeneratePdf();
    final img = await _getImageFile();
    setState(() => _isLoading = false);

    final List<XFile> filesToShare = [XFile(pdf.path)];
    if (img != null) {
      filesToShare.add(XFile(img.path));
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    // ignore: deprecated_member_use
    await Share.shareXFiles(filesToShare, text: 'Invoice & Receipt scan for ${widget.detail.merchant}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.base),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Text(
              'Share Receipt',
              style: GoogleFonts.hankenGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      _loadingMessage,
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              )
            else ...[
              _buildOptionTile(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: Colors.redAccent,
                title: 'Share Generated PDF',
                subtitle: 'Export & share digital invoice PDF',
                onTap: _sharePdf,
              ),
              const SizedBox(height: 10),
              _buildOptionTile(
                icon: Icons.image_rounded,
                iconColor: Colors.blueAccent,
                title: 'Share Original Receipt Image',
                subtitle: 'Share high-res scanned image',
                onTap: _shareImage,
              ),
              const SizedBox(height: 10),
              _buildOptionTile(
                icon: Icons.collections_rounded,
                iconColor: AppColors.primary,
                title: 'Share PDF + Image',
                subtitle: 'Share invoice PDF together with scan image',
                onTap: _sharePdfAndImage,
              ),
              const SizedBox(height: 10),
              _buildOptionTile(
                icon: Icons.table_chart_rounded,
                iconColor: Colors.greenAccent,
                title: 'Export as CSV Spreadsheet',
                subtitle: 'Tabular receipt and product data for Excel/Sheets',
                onTap: () async {
                  Navigator.of(context).pop();
                  final exportService = ReceiptExportService();
                  await exportService.exportSingleReceipt(
                    detail: widget.detail,
                    warranties: widget.warranties,
                    format: ExportFormat.csv,
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildOptionTile(
                icon: Icons.code_rounded,
                iconColor: Colors.amberAccent,
                title: 'Export as JSON',
                subtitle: 'Structured machine-readable receipt data',
                onTap: () async {
                  Navigator.of(context).pop();
                  final exportService = ReceiptExportService();
                  await exportService.exportSingleReceipt(
                    detail: widget.detail,
                    warranties: widget.warranties,
                    format: ExportFormat.json,
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildOptionTile(
                icon: Icons.text_snippet_rounded,
                iconColor: Colors.orangeAccent,
                title: 'Share Receipt Summary (Text)',
                subtitle: 'Share merchant, total & item details as text',
                onTap: _shareTextSummary,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: GlassCard(
          borderRadius: AppRadius.md,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
