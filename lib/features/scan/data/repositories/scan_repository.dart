// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receipto/features/scan/data/services/image_picker_service.dart';
import 'package:receipto/features/scan/data/services/file_processor_service.dart';
import 'package:receipto/core/services/storage_service.dart';
import 'package:receipto/core/services/gemini_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/features/notifications/data/services/notification_scheduler.dart';
import 'package:receipto/core/services/ai_categorizer_service.dart';
import 'package:receipto/features/warranty/presentation/widgets/manual_warranty_modal.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  final imagePickerService = ref.watch(imagePickerServiceProvider);
  final fileProcessorService = ref.watch(fileProcessorServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final geminiService = ref.watch(geminiServiceProvider);
  final receiptDatabaseService = ref.watch(receiptDatabaseServiceProvider);
  final warrantyDatabaseService = ref.watch(warrantyDatabaseServiceProvider);
  final notificationScheduler = ref.watch(notificationSchedulerProvider);
  final aiCategorizerService = ref.watch(aiCategorizerServiceProvider);
  return ScanRepository(
    imagePickerService,
    fileProcessorService,
    storageService,
    geminiService,
    receiptDatabaseService,
    warrantyDatabaseService,
    notificationScheduler,
    aiCategorizerService,
  );
});

class ScanRepository {
  final ImagePickerService _imagePickerService;
  final FileProcessorService _fileProcessorService;
  final StorageService _storageService;
  final GeminiService _geminiService;
  final ReceiptDatabaseService _receiptDatabaseService;
  final WarrantyDatabaseService _warrantyDatabaseService;
  final NotificationScheduler _notificationScheduler;
  final AICategorizerService _aiCategorizerService;

  ScanRepository(
    this._imagePickerService,
    this._fileProcessorService,
    this._storageService,
    this._geminiService,
    this._receiptDatabaseService,
    this._warrantyDatabaseService,
    this._notificationScheduler,
    this._aiCategorizerService,
  );

  /// Capture image using camera, perform permissions checks, compression, and return the compressed File.
  Future<File?> scanFromCamera() async {
    return await _imagePickerService.pickFromCamera();
  }

  /// Select image using gallery, perform permissions checks, compression, and return the compressed File.
  Future<File?> scanFromGallery() async {
    return await _imagePickerService.pickFromGallery();
  }

  /// Compress an existing image file using picker compression.
  Future<File> compressImage(File file) async {
    return await _imagePickerService.compressImage(file);
  }

  /// Select file using system file picker
  Future<File?> selectReceiptFile() async {
    return await _fileProcessorService.pickReceiptFile();
  }

  /// Process the selected file (Images, PDFs, Word, Excel, CSV, Text) and extract contents
  Future<Map<String, dynamic>> processReceiptFile(File file) async {
    return await _fileProcessorService.processFile(file);
  }

  /// Upload receipt file to public Supabase bucket
  Future<String> uploadReceipt({
    required File image,
    required String userId,
  }) async {
    return await _storageService.uploadReceipt(image: image, userId: userId);
  }

  /// Save extracted receipt details to Supabase database
  Future<String> saveReceipt(
    ReceiptModel receipt, {
    required String userId,
    String? imageUrl,
    String? originalFileName,
  }) async {
    return await _receiptDatabaseService.saveReceipt(
      receipt,
      userId: userId,
      imageUrl: imageUrl,
      originalFileName: originalFileName,
    );
  }

  /// Save extracted receipt item details to Supabase database
  Future<void> saveReceiptItems(
    String receiptId,
    List<ReceiptItemModel> items,
  ) async {
    await _receiptDatabaseService.saveReceiptItems(receiptId, items);
  }

  /// Executes the complete universal scanned document pipeline:
  /// Detect format -> Upload raw file -> Extract & Analyze via Gemini -> Save Receipt metadata & Items.
  Future<Map<String, dynamic>> processAndSaveReceiptFlow({
    required File imageFile,
    required String userId,
    int? fileSize,
  }) async {
    final result = await extractReceiptAndUpload(imageFile: imageFile, userId: userId);
    final ReceiptModel receipt = result['receipt'] as ReceiptModel;
    final String publicUrl = result['imageUrl'] as String;
    final String originalFileName = imageFile.path.split('/').last.split('\\').last;

    final categorizedReceipt = await _aiCategorizerService.categorize(receipt);

    final String dbId = await saveExtractedReceiptFlow(
      categorizedReceipt,
      publicUrl,
      userId,
      originalFileName: originalFileName,
      fileSize: fileSize,
    );

    return {
      'receipt': categorizedReceipt,
      'id': dbId,
      'imageUrl': publicUrl,
    };
  }

  /// Extracts the ReceiptModel from the file and uploads it to storage in parallel for maximum speed.
  Future<Map<String, dynamic>> extractReceiptAndUpload({
    required File imageFile,
    required String userId,
  }) async {
    final String extension = p.extension(imageFile.path).toLowerCase().replaceAll('.', '');
    String publicUrl = '';
    ReceiptModel receipt;

    if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension)) {
      // 1. Read bytes directly from local file
      final bytes = await imageFile.readAsBytes();
      final mimeType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      // 2. Parallel execution: Storage Upload + Gemini AI Vision
      final uploadFuture = _storageService.uploadReceiptFile(
        file: imageFile,
        userId: userId,
      );

      final analyzeFuture = _geminiService.analyzeReceiptBytes(
        imageBytes: bytes,
        mimeType: mimeType,
      );

      final results = await Future.wait([uploadFuture, analyzeFuture]);
      publicUrl = results[0] as String;
      receipt = results[1] as ReceiptModel;
    } else if (extension == 'pdf') {
      // PDF: Launch upload and parallel page rendering/analysis
      final uploadFuture = _storageService.uploadReceiptFile(
        file: imageFile,
        userId: userId,
      );

      final List<File> pageImages = await _fileProcessorService.convertPdfToImages(imageFile);
      if (pageImages.isEmpty) {
        throw Exception('Failed to render pages from PDF file.');
      }

      final pageAnalyzeFutures = pageImages.map((img) async {
        final bytes = await img.readAsBytes();
        final pageReceipt = await _geminiService.analyzeReceiptBytes(
          imageBytes: bytes,
          mimeType: 'image/jpeg',
        );
        try {
          await img.delete();
        } catch (_) {}
        return pageReceipt;
      }).toList();

      final results = await Future.wait([uploadFuture, Future.wait(pageAnalyzeFutures)]);
      publicUrl = results[0] as String;
      final List<ReceiptModel> pageReceipts = results[1] as List<ReceiptModel>;
      receipt = _mergeReceiptModels(pageReceipts);
    } else if (['doc', 'docx', 'xls', 'xlsx', 'txt', 'csv'].contains(extension)) {
      // Documents: Process text and upload in parallel
      final uploadFuture = _storageService.uploadReceiptFile(
        file: imageFile,
        userId: userId,
      );

      final Map<String, dynamic> result = await _fileProcessorService.processFile(imageFile);
      final String extractedText = result['extractedText'] as String? ?? '';
      if (extractedText.trim().isEmpty) {
        throw Exception('Failed to extract text contents from $extension document.');
      }
      if (extractedText == 'This document format is not supported') {
        throw Exception('This document format is not supported');
      }

      final analyzeFuture = _geminiService.analyzeReceiptText(text: extractedText);
      final results = await Future.wait([uploadFuture, analyzeFuture]);
      publicUrl = results[0] as String;
      receipt = results[1] as ReceiptModel;
    } else {
      throw Exception('Unsupported file format: .$extension');
    }

    // Validation checks
    if (receipt.merchantName == null || receipt.merchantName!.trim().isEmpty) {
      throw Exception('Gemini extraction failed: Merchant name was not identified.');
    }
    if (receipt.total != null && receipt.total! <= 0.0) {
      throw Exception('Gemini extraction failed: Total amount must be greater than zero.');
    }

    return {
      'receipt': receipt,
      'imageUrl': publicUrl,
    };
  }

  /// Saves receipt details and schedules automatic warranties.
  Future<String> saveExtractedReceiptFlow(
    ReceiptModel receipt,
    String publicUrl,
    String userId, {
    String? originalFileName,
    int? fileSize,
  }) async {
    // 1. Save receipt meta to receipts table
    final String dbId = await _receiptDatabaseService.saveReceipt(
      receipt,
      userId: userId,
      imageUrl: publicUrl,
      originalFileName: originalFileName,
      fileSize: fileSize,
    );

    // 2. Save individual items
    await _receiptDatabaseService.saveReceiptItems(dbId, receipt.items);

    // 3. Automatic Warranty processing
    for (final item in receipt.items) {
      final hasExplicitExpiry = item.warrantyExpiry != null && item.warrantyExpiry!.trim().isNotEmpty;
      final hasWarrantyPeriod = item.warrantyPeriod != null && item.warrantyPeriod! > 0;
      final isWarrantyAvailable = item.warrantyAvailable == true || hasExplicitExpiry || hasWarrantyPeriod;

      if (isWarrantyAvailable) {
        final productName = item.name;
        final merchantName = receipt.merchantName ?? 'Unknown Merchant';
        final purchaseDate = receipt.date ?? DateTime.now().toString().split(' ').first;
        
        int warrantyPeriod = item.warrantyPeriod ?? 0;
        String warrantyUnit = item.warrantyUnit ?? 'months';
        String expiryDate;
        String reason = '';

        if (hasExplicitExpiry) {
          // Priority 1: Explicit printed expiry
          expiryDate = item.warrantyExpiry!;
          reason = 'Printed expiry date detected. Using printed expiry. Ignoring calculated warranty.';
        } else if (hasWarrantyPeriod) {
          // Priority 2: Calculate from duration
          expiryDate = WarrantyUtils.calculateExpiryDate(purchaseDate, warrantyPeriod, warrantyUnit);
          reason = 'No printed expiry date. Calculated from warranty period: $warrantyPeriod $warrantyUnit.';
        } else {
          // Priority 3: Unknown
          expiryDate = 'Warranty Unknown';
          reason = 'Neither printed expiry date nor warranty period exists. Storing Warranty Unknown.';
        }

        // Cross-validation check for conflicts
        if (hasExplicitExpiry && hasWarrantyPeriod) {
          final calculated = WarrantyUtils.calculateExpiryDate(purchaseDate, warrantyPeriod, warrantyUnit);
          if (calculated != expiryDate) {
            debugPrint('[Warranty Conflict] Product: $productName. Purchase: $purchaseDate, Period: $warrantyPeriod $warrantyUnit -> Calculated: $calculated VS Printed Expiry: $expiryDate. Preference: Always prefer Printed Expiry Date.');
          }
        }

        // Debug logging as required
        debugPrint('Detected Purchase Date: $purchaseDate');
        debugPrint('Detected Warranty Duration: ${warrantyPeriod > 0 ? "$warrantyPeriod $warrantyUnit" : "None"}');
        debugPrint('Detected Printed Expiry: ${item.warrantyExpiry ?? "None"}');
        debugPrint('Calculated Expiry: ${hasWarrantyPeriod ? WarrantyUtils.calculateExpiryDate(purchaseDate, warrantyPeriod, warrantyUnit) : "None"}');
        debugPrint('Selected Final Expiry: $expiryDate');
        debugPrint('Reason: $reason');

        final status = expiryDate == 'Warranty Unknown' ? 'ACTIVE' : WarrantyUtils.calculateStatus(expiryDate);

        final warranty = WarrantyModel(
          userId: userId,
          receiptId: dbId,
          productName: productName,
          merchantName: merchantName,
          invoiceNumber: receipt.invoiceNumber,
          purchaseDate: purchaseDate,
          warrantyPeriod: warrantyPeriod,
          warrantyUnit: warrantyUnit,
          expiryDate: expiryDate,
          imageUrl: publicUrl,
          status: status,
          brand: item.brand,
          model: item.model,
          serialNumber: item.serialNumber,
        );

        if (kDebugMode) {
          print('=== Warranty expiry selected ===');
          print('Expiry: $expiryDate, Status: $status');
        }

        final warrantyId = await _warrantyDatabaseService.saveWarranty(warranty);

        if (kDebugMode) print('=== Warranty inserted: $warrantyId ===');
        
        // Automatically schedule notifications for the newly created warranty
        debugPrint('Scheduling warranty notifications for product: $productName');
        await _notificationScheduler.rescheduleWarranty(warranty.copyWith(id: warrantyId));
      }
    }

    return dbId;
  }

  /// Saves manually specified warranties for eligible products.
  Future<void> saveManualWarranties({
    required String receiptId,
    required String userId,
    required String merchantName,
    required String? invoiceNumber,
    required String purchaseDate,
    required String imageUrl,
    required List<ManualWarrantySelection> selections,
  }) async {
    for (final selection in selections) {
      if (!selection.isEnabled || selection.period <= 0) continue;

      final status = WarrantyUtils.calculateStatus(selection.expiryDate);

      final warranty = WarrantyModel(
        userId: userId,
        receiptId: receiptId,
        productName: selection.item.name,
        merchantName: merchantName,
        invoiceNumber: invoiceNumber,
        purchaseDate: purchaseDate,
        warrantyPeriod: selection.period,
        warrantyUnit: selection.unit,
        expiryDate: selection.expiryDate,
        imageUrl: imageUrl,
        status: status,
        brand: selection.item.brand,
        model: selection.item.model,
        serialNumber: selection.item.serialNumber,
        isManual: true,
      );

      final warrantyId = await _warrantyDatabaseService.saveWarranty(warranty);
      if (kDebugMode) print('=== Manual warranty inserted: $warrantyId for ${selection.item.name} ===');
      await _notificationScheduler.rescheduleWarranty(warranty.copyWith(id: warrantyId));
    }
  }

  /// Deletes a receipt and all cascaded child relations (items, warranties, notifications, files).
  Future<void> deleteReceiptCascade({
    required String receiptId,
    required String userId,
    required String? imageUrl,
  }) async {
    if (kDebugMode) print('Replacing receipt - Deleting old record: $receiptId');
    final client = Supabase.instance.client;
    final intId = int.tryParse(receiptId) ?? receiptId;

    // Verify receipt ownership
    final check = await client.from('receipts').select('id').eq('id', intId).eq('user_id', userId).maybeSingle();
    if (check == null) return;

    // 1. Delete storage file if URL exists
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await _storageService.deleteReceiptFileByUrl(imageUrl);
    }

    // 2. Delete warranties linked to this receipt
    try {
      await client.from('warranties').delete().eq('receipt_id', intId).eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) print('Error deleting warranties linked to receipt: $e');
    }

    // 4. Delete items linked to this receipt
    try {
      await client.from('receipt_items').delete().eq('receipt_id', intId);
    } catch (e) {
      if (kDebugMode) print('Error deleting items linked to receipt: $e');
    }

    // 5. Delete receipt record itself
    try {
      await client.from('receipts').delete().eq('id', intId).eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) print('Error deleting receipt record: $e');
    }
  }

  ReceiptModel _mergeReceiptModels(List<ReceiptModel> receipts) {
    if (receipts.isEmpty) {
      return ReceiptModel(items: []);
    }
    if (receipts.length == 1) return receipts.first;

    String? merchantName;
    String? invoiceNumber;
    String? date;
    String? time;
    String? gstNumber;
    String? currency;
    double subtotal = 0.0;
    double tax = 0.0;
    double discount = 0.0;
    double total = 0.0;
    String? paymentMethod;
    String? category;
    String? merchantAddress;
    String? merchantPhone;
    final List<ReceiptItemModel> items = [];

    for (final r in receipts) {
      merchantName ??= r.merchantName;
      invoiceNumber ??= r.invoiceNumber;
      date ??= r.date;
      time ??= r.time;
      gstNumber ??= r.gstNumber;
      currency ??= r.currency;
      paymentMethod ??= r.paymentMethod;
      category ??= r.category;
      merchantAddress ??= r.merchantAddress;
      merchantPhone ??= r.merchantPhone;
      
      items.addAll(r.items);
      subtotal += r.subtotal ?? 0.0;
      tax += r.tax ?? 0.0;
      discount += r.discount ?? 0.0;
      if ((r.total ?? 0.0) > total) {
        total = r.total!;
      }
    }

    if (total == 0.0) {
      total = subtotal + tax - discount;
    }

    return ReceiptModel(
      merchantName: merchantName,
      invoiceNumber: invoiceNumber,
      date: date,
      time: time,
      gstNumber: gstNumber,
      currency: currency,
      subtotal: subtotal > 0 ? subtotal : null,
      tax: tax > 0 ? tax : null,
      discount: discount > 0 ? discount : null,
      total: total > 0 ? total : null,
      paymentMethod: paymentMethod,
      category: category,
      merchantAddress: merchantAddress,
      merchantPhone: merchantPhone,
      items: items,
    );
  }

  /// Soft deletes a receipt record by updating is_deleted to true and deleted_at to current timestamp.
  Future<void> softDeleteReceipt(String receiptId, {required String userId}) async {
    debugPrint('Receipt deleted: $receiptId. Cancelling pending notifications...');
    await _receiptDatabaseService.softDeleteReceipt(receiptId, userId: userId);
    
    // Fetch and cancel notifications for all warranties associated with this receipt
    try {
      final client = Supabase.instance.client;
      final intId = int.tryParse(receiptId) ?? receiptId;
      final warrantiesData = await client.from('warranties').select('id').eq('receipt_id', intId).eq('user_id', userId);
      for (final w in warrantiesData) {
        final wId = w['id']?.toString();
        if (wId != null) {
          await _notificationScheduler.cancelWarrantyNotifications(wId);
        }
      }
    } catch (e) {
      debugPrint('Error cancelling notifications on soft delete: $e');
    }
  }

  /// Restores a soft-deleted receipt record by setting is_deleted to false and deleted_at to null.
  Future<void> restoreReceipt(String receiptId, {required String userId}) async {
    debugPrint('Receipt restored: $receiptId. Rescheduling notifications...');
    await _receiptDatabaseService.restoreReceipt(receiptId, userId: userId);
    
    // Fetch and reschedule notifications for all warranties associated with this receipt
    try {
      final client = Supabase.instance.client;
      final intId = int.tryParse(receiptId) ?? receiptId;
      final warrantiesData = await client.from('warranties').select().eq('receipt_id', intId).eq('user_id', userId);
      for (final w in warrantiesData) {
        final warranty = WarrantyModel.fromJson(w);
        await _notificationScheduler.rescheduleWarranty(warranty);
      }
    } catch (e) {
      debugPrint('Error rescheduling notifications on restore: $e');
    }
  }

  /// Permanently deletes a receipt and all related data (items, warranties, files, local reminders).
  /// Performs transactional rollback in case database deletes fail.
  Future<void> permanentDeleteReceipt({
    required String receiptId,
    required String userId,
    required String? imageUrl,
  }) async {
    final client = Supabase.instance.client;
    final intId = int.tryParse(receiptId) ?? receiptId;

    // 1. Fetch all existing records to support rollback
    Map<String, dynamic>? receiptData;
    List<dynamic> itemsData = [];
    List<dynamic> warrantiesData = [];

    try {
      receiptData = await client.from('receipts').select().eq('id', intId).eq('user_id', userId).maybeSingle();
      if (receiptData == null) {
        throw Exception('Access denied: Receipt not found or does not belong to current user.');
      }
      itemsData = await client.from('receipt_items').select().eq('receipt_id', intId);
      warrantiesData = await client.from('warranties').select().eq('receipt_id', intId).eq('user_id', userId);
    } catch (e, stackTrace) {
      print('=== Deletion Backup Fetch Failed ===');
      print('Receipt ID: $receiptId');
      print('Exception: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Backup fetch failed: $e');
    }

    // 2. Attempt deletion
    try {
      // 1. Cancel scheduled local notifications
      for (final w in warrantiesData) {
        final wId = w['id'];
        if (wId != null) {
          await _notificationScheduler.cancelWarrantyNotifications(wId.toString());
        }
      }

      // 2. Delete warranty rows
      print('Deleting warranties...');
      if (warrantiesData.isNotEmpty) {
        try {
          await client.from('warranties').delete().eq('receipt_id', intId).eq('user_id', userId);
        } catch (e, stackTrace) {
          print('=== Deletion Failed at warranties ===');
          print('Receipt ID: $receiptId');
          print('Table: warranties');
          print('Exception: $e');
          print('StackTrace: $stackTrace');
          throw Exception('Table: warranties. Error: $e');
        }
      }

      // 3. Delete receipt items
      print('Deleting receipt_items...');
      if (itemsData.isNotEmpty) {
        try {
          await client.from('receipt_items').delete().eq('receipt_id', intId);
        } catch (e, stackTrace) {
          print('=== Deletion Failed at receipt_items ===');
          print('Receipt ID: $receiptId');
          print('Table: receipt_items');
          print('Exception: $e');
          print('StackTrace: $stackTrace');
          throw Exception('Table: receipt_items. Error: $e');
        }
      }

      // 4. Delete receipt image from Supabase Storage
      print('Deleting storage image...');
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storageService.deleteReceiptFileByUrl(imageUrl);
        } catch (e, stackTrace) {
          print('=== Deletion Failed at storage ===');
          print('Receipt ID: $receiptId');
          print('Operation: storage image deletion');
          print('Exception: $e');
          print('StackTrace: $stackTrace');
          throw Exception('Operation: storage image deletion. Error: $e');
        }
      }

      // 5. Delete receipt row
      print('Deleting receipt...');
      if (receiptData != null) {
        try {
          await client.from('receipts').delete().eq('id', intId).eq('user_id', userId);
        } catch (e, stackTrace) {
          print('=== Deletion Failed at receipts ===');
          print('Receipt ID: $receiptId');
          print('Table: receipts');
          print('Exception: $e');
          print('StackTrace: $stackTrace');
          throw Exception('Table: receipts. Error: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Deletion failed, attempting rollback: $e');
      // Rollback: Re-insert in reverse order
      try {
        if (receiptData != null) {
          await client.from('receipts').insert(receiptData);
        }
        if (itemsData.isNotEmpty) {
          await client.from('receipt_items').insert(itemsData);
        }
        if (warrantiesData.isNotEmpty) {
          await client.from('warranties').insert(warrantiesData);
        }
      } catch (rollbackErr) {
        if (kDebugMode) print('Rollback failed: $rollbackErr');
      }
      rethrow;
    }

    // 6. Clean up temporary/cached local image files if any
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      for (final file in files) {
        if (file is File && (file.path.contains(receiptId) || file.path.contains('storage_compressed'))) {
          await file.delete();
        }
      }
    } catch (_) {}
  }
}
