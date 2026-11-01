import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/services/pdf_invoice_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/services/currency_converter_service.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/widgets/gradient_button.dart';
import 'package:receipto/core/widgets/nebula_background.dart';
import 'package:receipto/features/receipts/presentation/models/receipt_detail_view_model.dart';
import 'package:receipto/features/receipts/presentation/widgets/animated_warranty_card.dart';
import 'package:receipto/features/receipts/presentation/widgets/document_viewer_dialog.dart';
import 'package:receipto/features/receipts/presentation/widgets/pdf_viewer_dialog.dart';
import 'package:receipto/features/receipts/presentation/widgets/share_options_bottom_sheet.dart';
import 'package:receipto/core/services/receipt_export_service.dart';
import 'package:receipto/features/scan/data/repositories/scan_repository.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/features/scan/presentation/providers/scan_provider.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/features/warranty/presentation/widgets/manual_warranty_modal.dart';

final receiptDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dbService = ref.watch(receiptDatabaseServiceProvider);
  final authService = ref.watch(firebaseAuthServiceProvider);
  final userId = authService.currentUser?.uid;
  if (userId == null || userId.isEmpty) {
    throw Exception('Unauthorized: No active user session.');
  }
  return await dbService.fetchReceipt(id, userId: userId);
});

class ReceiptDetailsScreen extends ConsumerStatefulWidget {
  final String receiptId;

  const ReceiptDetailsScreen({
    super.key,
    required this.receiptId,
  });

  @override
  ConsumerState<ReceiptDetailsScreen> createState() => _ReceiptDetailsScreenState();
}

class _ReceiptDetailsScreenState extends ConsumerState<ReceiptDetailsScreen> {
  bool _isGeneratingPdf = false;
  File? _cachedPdfFile;

  ReceiptDetailViewModel _mapReceiptToDetail(
    ReceiptModel receipt,
    String id,
    String? imageUrl,
    int? matchScore,
  ) {
    String dateStr = '';
    if (receipt.date != null && receipt.date!.isNotEmpty) {
      dateStr = receipt.date!;
      if (receipt.time != null && receipt.time!.isNotEmpty) {
        dateStr += ' • ${receipt.time}';
      }
    }

    return ReceiptDetailViewModel(
      id: id,
      invoiceNumber: receipt.invoiceNumber,
      merchant: receipt.merchantName ?? '',
      category: receipt.category ?? '',
      amount: receipt.total ?? 0.0,
      purchaseDate: dateStr,
      paymentMethod: receipt.paymentMethod ?? '',
      matchScore: matchScore,
      receiptImageUrl: imageUrl ?? '',
      currency: receipt.currency ?? '₹',
      gstNumber: receipt.gstNumber,
      subtotal: receipt.subtotal,
      tax: receipt.tax,
      discount: receipt.discount,
      items: receipt.items.map((item) => ProductItemViewModel(
        name: item.name,
        price: item.totalPrice ?? (item.unitPrice != null && item.quantity != null ? item.unitPrice! * item.quantity! : 0.0),
        qty: item.quantity ?? 1,
        unitPrice: item.unitPrice ?? 0.0,
        warrantyAvailable: item.warrantyAvailable,
        warrantyPeriod: item.warrantyPeriod,
        warrantyUnit: item.warrantyUnit,
        warrantyExpiry: item.warrantyExpiry,
      )).toList(),
    );
  }

  Future<void> _generateAndDownloadPdf(ReceiptDetailViewModel detail, List<WarrantyModel>? warranties) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfFile = await PdfInvoiceService.generateInvoicePdf(
        detail: detail,
        warranties: warranties,
      );
      _cachedPdfFile = pdfFile;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invoice PDF saved successfully.'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () {
              OpenFilex.open(pdfFile.path);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: Text('PDF Generation Failed', style: GoogleFonts.hankenGrotesk(color: Colors.white)),
          content: Text('$e', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    if (kDebugMode) print('=== Image URL loaded in Details screen: ${scanState.uploadedUrl ?? "None"} ===');

    // 1. Check local scanner state first for instant transition
    final isLocalMatch = scanState.savedReceiptId != null && widget.receiptId == scanState.savedReceiptId;
    
    if (isLocalMatch && scanState.extractedReceipt != null) {
      final receipt = scanState.extractedReceipt!;
      final detail = _mapReceiptToDetail(
        receipt,
        scanState.savedReceiptId!,
        scanState.uploadedUrl,
        100,
      );
      return _buildDetailsContent(context, detail);
    }

    // 2. Fetch from Supabase database asynchronously
    final dbAsync = ref.watch(receiptDetailsProvider(widget.receiptId));

    return dbAsync.when(
      data: (dbData) {
        try {
          final receiptMap = Map<String, dynamic>.from(dbData['receipt'] as Map);
          final itemsList = dbData['items'] as List<dynamic>? ?? [];

          final imageUrl = receiptMap['image_url'] as String?;
          final userUid = receiptMap['user_id'] as String?;
          final rawText = receiptMap['raw_text'] as String?;

          if (kDebugMode) {
            print('=== [ReceiptDetailsScreen Loaded] ===');
            print('Receipt ID: ${receiptMap['id']}');
            print('User UID: $userUid');
            print('Merchant Name: ${receiptMap['merchant_name']}');
            print('Storage Image URL: ${imageUrl ?? "None"}');
            print('OCR Text Status: ${rawText != null && rawText.isNotEmpty ? "Saved (${rawText.length} chars)" : "None"}');
            print('Products Loaded: ${itemsList.length}');
          }

          final parsedTotal = ReceiptModel.parseDouble(receiptMap['grand_total']) ?? 
                              ReceiptModel.parseDouble(receiptMap['total']);

          final receipt = ReceiptModel(
            merchantName: receiptMap['merchant_name'] as String?,
            invoiceNumber: (receiptMap['invoice_number'] ?? receiptMap['receipt_number']) as String?,
            date: receiptMap['date'] as String?,
            time: receiptMap['time'] as String?,
            gstNumber: receiptMap['gst_number'] as String?,
            currency: receiptMap['currency'] as String?,
            subtotal: ReceiptModel.parseDouble(receiptMap['subtotal']),
            tax: ReceiptModel.parseDouble(receiptMap['tax']),
            discount: ReceiptModel.parseDouble(receiptMap['discount']),
            total: parsedTotal,
            paymentMethod: receiptMap['payment_method'] as String?,
            category: receiptMap['category'] as String?,
            merchantAddress: receiptMap['merchant_address'] as String?,
            merchantPhone: receiptMap['merchant_phone'] as String?,
            rawText: rawText,
            confidenceScore: ReceiptModel.parseDouble(receiptMap['confidence_score']),
            items: itemsList.map((itemMap) {
              final m = Map<String, dynamic>.from(itemMap as Map);
              return ReceiptItemModel(
                name: m['name'] as String? ?? 'Unknown Item',
                quantity: ReceiptItemModel.parseInt(m['quantity']),
                unitPrice: ReceiptItemModel.parseDouble(m['unit_price']),
                totalPrice: ReceiptItemModel.parseDouble(m['total_price'] ?? m['price']),
              );
            }).toList(),
          );

          final resolvedId = receiptMap['id']?.toString() ?? widget.receiptId;
          final detailModel = _mapReceiptToDetail(receipt, resolvedId, imageUrl, null);

          return _buildDetailsContent(context, detailModel);
        } catch (e, stack) {
          if (kDebugMode) {
            print('=== [ReceiptDetailsScreen Parse Exception] ===');
            print('Receipt ID: ${widget.receiptId}');
            print('Error: $e');
            print('StackTrace: $stack');
          }
          return _buildErrorScreen(context, 'Failed to parse database receipt: $e');
        }
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      ),
      error: (err, stack) {
        if (kDebugMode) {
          print('=== [ReceiptDetailsScreen Async Error] ===');
          print('Receipt ID: ${widget.receiptId}');
          print('Error: $err');
          print('StackTrace: $stack');
        }
        return _buildErrorScreen(context, err.toString().replaceAll('Exception: ', ''));
      },
    );
  }

  Widget _buildDetailsContent(BuildContext context, ReceiptDetailViewModel detail) {
    final warrantiesAsync = ref.watch(warrantiesByReceiptProvider(detail.id));
    final List<WarrantyModel> warrantiesList = warrantiesAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Nebula animation
          const Positioned.fill(
            child: AnimatedNebulaBackground(opacity: 0.5),
          ),
          
          // Vignette overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.4),
                    AppColors.background.withValues(alpha: 0.8),
                  ],
                  stops: const [0.6, 0.85, 1.0],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Custom Header with Share Button
                _buildHeader(context, detail, warrantiesList),
                
                // Details Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Receipt Scan Image Preview
                        _buildReceiptImagePreview(context, detail.receiptImageUrl),
                        const SizedBox(height: 24),

                        // Merchant & Value Core Details
                        _buildMerchantCoreDetails(context, ref, detail),
                        const SizedBox(height: 20),

                        // Extracted Metadata Info Table Card
                        if (detail.purchaseDate.isNotEmpty || detail.paymentMethod.isNotEmpty || detail.gstNumber != null || detail.invoiceNumber != null)
                          _buildExtractedMetadataTable(context, detail),
                        const SizedBox(height: 20),

                        // Warranty Information Card Section (if available)
                        _buildWarrantySection(context, ref, detail),
                        const SizedBox(height: 20),

                        // Line items purchase summary
                        _buildPurchasedItemsList(context, detail, warrantiesList),
                        const SizedBox(height: 32),

                        // Premium PDF Export Button
                        GradientButton(
                          text: _isGeneratingPdf ? 'Generating PDF...' : '📄 Export Invoice PDF',
                          icon: _isGeneratingPdf ? null : Icons.file_download_outlined,
                          isLoading: _isGeneratingPdf,
                          onPressed: _isGeneratingPdf
                              ? null
                              : () => _generateAndDownloadPdf(detail, warrantiesList),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AnimatedNebulaBackground(opacity: 0.5),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, null, null),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Unable to Load Receipt',
                            style: GoogleFonts.hankenGrotesk(
                              color: AppColors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Back Nav custom Header bar with active Share and Export buttons
  Widget _buildHeader(
    BuildContext context,
    ReceiptDetailViewModel? detail,
    List<WarrantyModel>? warranties,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.onSurface,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          
          Text(
            'Receipt details',
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          Row(
            children: [
              // Export Action Menu (PDF, CSV, JSON)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                ),
                child: PopupMenuButton<ExportFormat>(
                  icon: const Icon(
                    Icons.file_download_outlined,
                    color: AppColors.onSurface,
                    size: 20,
                  ),
                  tooltip: 'Export receipt',
                  color: AppColors.cardSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  onSelected: (format) async {
                    if (detail == null) return;
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Exporting ${format.name.toUpperCase()}...'),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      await ref.read(receiptExportServiceProvider).exportSingleReceipt(
                        detail: detail,
                        warranties: warranties,
                        format: format,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Export failed: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: ExportFormat.pdf,
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 10),
                          Text('Export PDF', style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ExportFormat.csv,
                      child: Row(
                        children: [
                          const Icon(Icons.table_chart_outlined, color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 10),
                          Text('Export CSV', style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ExportFormat.json,
                      child: Row(
                        children: [
                          const Icon(Icons.code_outlined, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 10),
                          Text('Export JSON', style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Share Action Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.share_rounded,
                    color: AppColors.onSurface,
                    size: 20,
                  ),
                  onPressed: detail == null
                      ? null
                      : () {
                          ShareOptionsBottomSheet.show(
                            context,
                            detail: detail,
                            warranties: warranties,
                            cachedPdfFile: _cachedPdfFile,
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptImagePreview(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          color: AppColors.surfaceVariant,
        ),
        child: const Center(
          child: Icon(Icons.receipt_long_outlined, color: AppColors.onSurfaceVariant, size: 48),
        ),
      );
    }

    // Support multi-page batch scanned receipts
    if (imageUrl.contains(',')) {
      final urls = imageUrl.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
      if (urls.length > 1) {
        return _MultiPageReceiptCarousel(urls: urls);
      }
    }

    final Uri? parsedUri = Uri.tryParse(imageUrl);
    final String pathPart = parsedUri?.path ?? imageUrl;
    final String rawFilename = pathPart.split('/').last.split('?').first.toLowerCase();
    final String extension = rawFilename.contains('.') ? rawFilename.split('.').last : '';
    
    final bool isImage = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension);
    final bool isPdf = extension == 'pdf';
    final bool isDoc = !isImage && !isPdf;

    return GestureDetector(
      onTap: () {
        if (isImage) {
          _showFullScreenImage(context, imageUrl);
        } else if (isPdf) {
          _showPdfViewer(context, imageUrl);
        } else {
          _openOriginalDocument(context, imageUrl);
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 20,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.lg,
          child: Stack(
            children: [
              Positioned.fill(
                child: isImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.surfaceVariant,
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_off_rounded, color: AppColors.onSurfaceVariant, size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image unavailable offline',
                                    style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : isPdf
                        ? _RemotePdfThumbnail(pdfUrl: imageUrl)
                        : _buildDocumentPreviewCard(extension: extension),
              ),
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: isDoc ? 0.35 : 0.6),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: isDoc ? 0.5 : 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              // Action Pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.85),
                    borderRadius: AppRadius.full,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isImage
                            ? Icons.fullscreen
                            : isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.open_in_new_rounded,
                        color: isPdf ? const Color(0xFFFF6174) : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isImage
                            ? 'View Original Scan'
                            : isPdf
                                ? 'Open PDF Viewer'
                                : 'Open Original Document',
                        style: GoogleFonts.inter(
                          color: isPdf ? const Color(0xFFFF6174) : AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreviewCard({required String extension}) {
    final isWord = ['doc', 'docx'].contains(extension);
    final isExcel = ['xls', 'xlsx', 'csv'].contains(extension);
    final accentColor = isWord
        ? const Color(0xFF2B579A)
        : isExcel
            ? const Color(0xFF217346)
            : AppColors.secondary;
    final iconData = isWord
        ? Icons.description_rounded
        : isExcel
            ? Icons.table_chart_rounded
            : Icons.article_rounded;
    final typeLabel = isWord
        ? 'WORD INVOICE DOCUMENT'
        : isExcel
            ? 'EXCEL / SPREADSHEET'
            : (extension.isNotEmpty ? '${extension.toUpperCase()} DOCUMENT' : 'DOCUMENT');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.28),
            const Color(0xFF131522),
            const Color(0xFF0C0E17),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.18),
                border: Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(iconData, color: accentColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              typeLabel,
              style: GoogleFonts.inter(
                color: accentColor,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap to open original document file',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOriginalDocument(BuildContext context, String fileUrl) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: AppRadius.md,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Text(
                  'Opening original document...',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    File? localFile;
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        final filename = fileUrl.split('/').last.split('?').first;
        final tempDir = await getTemporaryDirectory();
        localFile = File('${tempDir.path}/$filename');
        await localFile.writeAsBytes(response.bodyBytes);
      }
    } catch (e) {
      if (kDebugMode) print('Error downloading original document: $e');
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
    }

    if (localFile != null && await localFile.exists()) {
      try {
        final openResult = await OpenFilex.open(localFile.path);
        if (openResult.type != ResultType.done && context.mounted) {
          _showDocumentViewer(context, fileUrl, localFile: localFile);
        }
      } catch (e) {
        if (context.mounted) {
          _showDocumentViewer(context, fileUrl, localFile: localFile);
        }
      }
    } else {
      if (context.mounted) {
        _showDocumentViewer(context, fileUrl);
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                borderRadius: AppRadius.lg,
                color: Colors.black.withValues(alpha: 0.9),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.lg,
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfViewer(BuildContext context, String pdfUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: PdfViewerDialog(pdfUrl: pdfUrl),
      ),
    );
  }

  void _showDocumentViewer(BuildContext context, String fileUrl, {File? localFile}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: DocumentViewerDialog(
          fileUrl: fileUrl,
          preloadedFile: localFile,
        ),
      ),
    );
  }

  Widget _buildMerchantCoreDetails(BuildContext context, WidgetRef ref, ReceiptDetailViewModel detail) {
    final textTheme = Theme.of(context).textTheme;
    final warrantiesAsync = ref.watch(warrantiesByReceiptProvider(detail.id));

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.merchant.isNotEmpty)
                  Text(
                    detail.merchant,
                    style: GoogleFonts.hankenGrotesk(
                      color: AppColors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 6),
                
                if (detail.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: AppRadius.full,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      detail.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                
                Text(
                  CurrencyFormatter.format(detail.amount, currency: detail.currency),
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (CurrencyConverterService.isForeign(detail.currency)) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.sm,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: Text(
                      CurrencyConverterService.formatConvertedInr(detail.amount, currency: detail.currency),
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          warrantiesAsync.when(
            data: (warranties) {
              if (warranties.isEmpty) return const SizedBox.shrink();
              
              final isMulti = warranties.length > 1;
              final w = warranties.first;
              final statusColor = w.isActive 
                  ? Colors.greenAccent 
                  : (w.isExpiringSoon ? Colors.orangeAccent : Colors.redAccent);

              return Container(
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.2),
                  borderRadius: AppRadius.md,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          isMulti ? '${warranties.length} Products' : 'Warranty',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (!isMulti) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${w.warrantyPeriod} ${w.warrantyUnit}',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expires:',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        w.expiryDate,
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Protected',
                        style: GoogleFonts.inter(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedMetadataTable(BuildContext context, ReceiptDetailViewModel detail) {
    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (detail.purchaseDate.isNotEmpty)
            _buildMetadataRow('Purchase Date', detail.purchaseDate),
          if (detail.paymentMethod.isNotEmpty)
            _buildMetadataRow('Payment Method', detail.paymentMethod),
          if (detail.gstNumber != null && detail.gstNumber!.isNotEmpty)
            _buildMetadataRow('GST/Tax ID', detail.gstNumber!),
          if (detail.invoiceNumber != null && detail.invoiceNumber!.isNotEmpty)
            _buildMetadataRow('Invoice / Receipt #', detail.invoiceNumber!),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedItemsList(
    BuildContext context,
    ReceiptDetailViewModel detail, [
    List<WarrantyModel> warranties = const [],
  ]) {
    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Purchased Items',
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (detail.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No line items parsed.',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detail.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final prod = detail.items[index];

                // Match with warranties table if item doesn't have local expiry
                final matchedWarranty = warranties.cast<WarrantyModel?>().firstWhere(
                  (w) => w != null && (w.productName.trim().toLowerCase() == prod.name.trim().toLowerCase() ||
                         prod.name.trim().toLowerCase().contains(w.productName.trim().toLowerCase()) ||
                         w.productName.trim().toLowerCase().contains(prod.name.trim().toLowerCase())),
                  orElse: () => null,
                );

                final String? expiryDate = prod.warrantyExpiry ?? (matchedWarranty?.expiryDate != 'Warranty Unknown' ? matchedWarranty?.expiryDate : null);
                final bool hasWarranty = (prod.warrantyPeriod != null && prod.warrantyPeriod! > 0) || (matchedWarranty != null && matchedWarranty.warrantyPeriod > 0);
                final int warrantyPeriod = prod.warrantyPeriod ?? matchedWarranty?.warrantyPeriod ?? 0;
                final String warrantyUnit = prod.warrantyUnit ?? matchedWarranty?.warrantyUnit ?? 'months';

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.name,
                            style: GoogleFonts.inter(
                              color: AppColors.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: ${prod.qty} × ${CurrencyFormatter.format(prod.unitPrice, currency: detail.currency)}',
                            style: GoogleFonts.inter(
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          if (expiryDate != null && expiryDate.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.event_available_rounded, color: Colors.amberAccent, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  'Expiry: $expiryDate',
                                  style: GoogleFonts.inter(
                                    color: Colors.amberAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (hasWarranty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Active Warranty: $warrantyPeriod $warrantyUnit',
                                  style: GoogleFonts.inter(
                                    color: Colors.greenAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(prod.price, currency: detail.currency),
                          style: GoogleFonts.inter(
                            color: AppColors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (CurrencyConverterService.isForeign(detail.currency))
                          Text(
                            CurrencyConverterService.formatConvertedInr(prod.price, currency: detail.currency),
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),

          if (detail.subtotal != null)
            _buildBreakdownRow('Subtotal', CurrencyFormatter.format(detail.subtotal!, currency: detail.currency), rawAmount: detail.subtotal, currency: detail.currency),
          if (detail.tax != null)
            _buildBreakdownRow('Tax / GST', CurrencyFormatter.format(detail.tax!, currency: detail.currency), rawAmount: detail.tax, currency: detail.currency),
          if (detail.discount != null)
            _buildBreakdownRow('Discount', '-${CurrencyFormatter.format(detail.discount!, currency: detail.currency)}', isDiscount: true, rawAmount: detail.discount, currency: detail.currency),
          
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: GoogleFonts.inter(
                  color: AppColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.format(detail.amount, currency: detail.currency),
                    style: GoogleFonts.inter(
                      color: AppColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (CurrencyConverterService.isForeign(detail.currency))
                    Text(
                      CurrencyConverterService.formatConvertedInr(detail.amount, currency: detail.currency),
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value, {
    bool isDiscount = false,
    double? rawAmount,
    String? currency,
  }) {
    final hasConversion = rawAmount != null && CurrencyConverterService.isForeign(currency);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
              fontSize: 13.5,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasConversion) ...[
                Text(
                  '${CurrencyConverterService.formatConvertedInr(rawAmount, currency: currency)} ',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              Text(
                value,
                style: GoogleFonts.inter(
                  color: isDiscount ? AppColors.tertiary : AppColors.onSurface,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantySection(BuildContext context, WidgetRef ref, ReceiptDetailViewModel detail) {
    final warrantiesAsync = ref.watch(warrantiesByReceiptProvider(detail.id));

    return warrantiesAsync.when(
      data: (warranties) {
        // ── Has warranties: show existing warranty cards as before ──
        if (warranties.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Protected Products',
                  style: GoogleFonts.hankenGrotesk(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...warranties.map((w) => AnimatedWarrantyCard(warranty: w)),
            ],
          );
        }

        // ── No warranties: show "Add Warranty" banner ──
        // Only show if the receipt has items (nothing to warrant on empty receipt)
        if (detail.items.isEmpty) return const SizedBox.shrink();

        return _buildAddWarrantyBanner(context, ref, detail);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Banner shown when a receipt has no warranties — lets the user add them manually.
  Widget _buildAddWarrantyBanner(BuildContext context, WidgetRef ref, ReceiptDetailViewModel detail) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.07),
            AppColors.cardSurface.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.lg,
        child: InkWell(
          borderRadius: AppRadius.lg,
          onTap: () => _showAddWarrantyModal(context, ref, detail),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.accentCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Warranty Detected',
                        style: GoogleFonts.hankenGrotesk(
                          color: AppColors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to add warranty for this receipt or individual products.',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryBlueViolet,
                    borderRadius: AppRadius.full,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Add',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the ManualWarrantyModal bottom sheet for the given receipt.
  void _showAddWarrantyModal(BuildContext context, WidgetRef ref, ReceiptDetailViewModel detail) {
    // Build ReceiptItemModel list from the detail view model items
    final items = detail.items.map((p) => ReceiptItemModel(
      name: p.name,
      quantity: p.qty,
      unitPrice: p.unitPrice,
      totalPrice: p.price,
    )).toList();

    // Extract purchase date — strip time portion if present
    final purchaseDate = detail.purchaseDate.split(' • ').first.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualWarrantyModal(
        eligibleItems: items,
        purchaseDate: purchaseDate.isNotEmpty ? purchaseDate : DateTime.now().toIso8601String().split('T').first,
        merchantName: detail.merchant,
        onSave: (selections) async {
          Navigator.of(context).pop();
          if (selections.isEmpty) return;

          final user = ref.read(firebaseAuthServiceProvider).currentUser;
          if (user == null) return;

          try {
            final repo = ref.read(scanRepositoryProvider);
            await repo.saveManualWarranties(
              receiptId: detail.id,
              userId: user.uid,
              merchantName: detail.merchant,
              invoiceNumber: detail.invoiceNumber,
              purchaseDate: purchaseDate.isNotEmpty ? purchaseDate : DateTime.now().toIso8601String().split('T').first,
              imageUrl: detail.receiptImageUrl,
              selections: selections,
            );

            // Refresh warranties to show the newly added ones
            ref.invalidate(dbWarrantiesProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${selections.length} warrant${selections.length == 1 ? 'y' : 'ies'} added successfully!',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: Colors.greenAccent.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save warranty: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        onSkip: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _RemotePdfThumbnail extends StatefulWidget {
  final String pdfUrl;
  const _RemotePdfThumbnail({required this.pdfUrl});

  @override
  State<_RemotePdfThumbnail> createState() => _RemotePdfThumbnailState();
}

class _RemotePdfThumbnailState extends State<_RemotePdfThumbnail> {
  Uint8List? _thumbnailBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filename = 'thumb_${widget.pdfUrl.hashCode}.pdf';
        final tempFile = File('${tempDir.path}/$filename');
        await tempFile.writeAsBytes(response.bodyBytes);

        final doc = await PdfDocument.openFile(tempFile.path);
        final page = await doc.getPage(1);
        final pageImage = await page.render(
          width: page.width * 1.5,
          height: page.height * 1.5,
          format: PdfPageImageFormat.jpeg,
        );
        await doc.close();
        if (mounted && pageImage?.bytes != null) {
          setState(() {
            _thumbnailBytes = pageImage!.bytes;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ReceiptDetails] RemotePdfPreview error: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailBytes != null) {
      return Image.memory(
        _thumbnailBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 2)
            else
              const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFF6174), size: 48),
            const SizedBox(height: 8),
            Text(
              _isLoading ? 'Loading PDF preview...' : 'Original PDF Document',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swipeable preview carousel for multi-page batch scanned receipts
class _MultiPageReceiptCarousel extends StatefulWidget {
  final List<String> urls;

  const _MultiPageReceiptCarousel({required this.urls});

  @override
  State<_MultiPageReceiptCarousel> createState() => _MultiPageReceiptCarouselState();
}

class _MultiPageReceiptCarouselState extends State<_MultiPageReceiptCarousel> {
  late PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: Stack(
          children: [
            // PageView of receipt images
            PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, idx) {
                final url = widget.urls[idx];
                return GestureDetector(
                  onTap: () => _showFullScreenBatchCarousel(context, widget.urls, initialIndex: idx),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 36),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Top Gradient & Page Count Pill
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_motion_rounded, color: AppColors.secondary, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Page ${_currentIndex + 1} of ${widget.urls.length}',
                            style: GoogleFonts.inter(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Multi-Page Bill',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center Tap-to-Expand Pill
            Center(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.82),
                    borderRadius: AppRadius.full,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fullscreen, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'View Fullscreen',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Dots Indicator
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.urls.length, (i) {
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isActive ? AppColors.secondary : Colors.white38,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen zoomable carousel modal for multi-page batch receipts
void _showFullScreenBatchCarousel(BuildContext context, List<String> urls, {int initialIndex = 0}) {
  showDialog(
    context: context,
    builder: (context) {
      int active = initialIndex;
      final PageController ctrl = PageController(initialPage: initialIndex);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.78,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.lg,
                    color: Colors.black.withValues(alpha: 0.95),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.lg,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: ctrl,
                          itemCount: urls.length,
                          onPageChanged: (i) => setDialogState(() => active = i),
                          itemBuilder: (context, idx) {
                            return InteractiveViewer(
                              maxScale: 4.5,
                              minScale: 1.0,
                              child: Center(
                                child: Image.network(
                                  urls[idx],
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, lp) =>
                                      lp == null ? child : const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                                  errorBuilder: (context, err, st) => const Center(
                                    child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Page indicator badge
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Page ${active + 1} of ${urls.length}',
                              style: GoogleFonts.inter(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        // Dots at bottom
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(urls.length, (i) {
                              final isActive = i == active;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isActive ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: isActive ? AppColors.secondary : Colors.white38,
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black87,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
