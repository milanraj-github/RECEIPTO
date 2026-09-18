import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/offline_cache_service.dart';

final receiptDatabaseServiceProvider = Provider<ReceiptDatabaseService>((ref) {
  return ReceiptDatabaseService(Supabase.instance.client, OfflineCacheService());
});

class ReceiptDatabaseService {
  final SupabaseClient _supabase;
  final OfflineCacheService? _cache;
  OfflineCacheService get _offlineCacheService => _cache ?? OfflineCacheService.instance;

  ReceiptDatabaseService([
    SupabaseClient? supabase,
    OfflineCacheService? offlineCacheService,
  ])  : _supabase = supabase ?? Supabase.instance.client,
        _cache = offlineCacheService ?? OfflineCacheService.instance;

  /// Inserts a new receipt record into the "receipts" table and returns the generated database ID.
  /// Generates a SHA-256 fingerprint hash of merchant_name, invoice_number, purchase_date, grand_total
  /// and stores it ONLY in the "receipt_hash" column.
  /// "receipt_number" holds the original invoice number.
  /// "file_size" holds the uploaded file size.
  /// "confidence_score" holds ONLY AI/OCR extraction confidence score (or null).
  Future<String> saveReceipt(
    ReceiptModel receipt, {
    required String userId,
    String? imageUrl,
    String? originalFileName,
    int? fileSize,
  }) async {
    try {
      // Calculate SHA-256 fingerprint hash
      final cleanMerchant = (receipt.merchantName ?? '').trim().toLowerCase();
      final cleanInvoice = (receipt.invoiceNumber ?? '').trim().toLowerCase();
      final cleanDate = (receipt.date ?? '').trim().toLowerCase();
      final double totalVal = receipt.total ?? 0.0;
      final cleanTotal = totalVal.toStringAsFixed(2);
      
      final hashInput = '$cleanMerchant|$cleanInvoice|$cleanDate|$cleanTotal';
      final hashBytes = utf8.encode(hashInput);
      final String hash = sha256.convert(hashBytes).toString();

      final Map<String, dynamic> insertData = {
        'user_id': userId,
        'merchant_name': receipt.merchantName,
        'date': receipt.date,
        'time': receipt.time,
        'receipt_number': receipt.invoiceNumber,
        'invoice_number': receipt.invoiceNumber,
        'receipt_hash': hash,
        'file_size': fileSize,
        'confidence_score': receipt.confidenceScore,
        'gst_number': receipt.gstNumber,
        'payment_method': receipt.paymentMethod,
        'currency': receipt.currency ?? '₹',
        'grand_total': totalVal,
        'total': totalVal,
        'tax': receipt.tax,
        'discount': receipt.discount,
        'subtotal': receipt.subtotal,
        'category': receipt.category,
        'image_url': imageUrl,
        'merchant_address': receipt.merchantAddress,
        'merchant_phone': receipt.merchantPhone,
        'original_file_name': originalFileName,
        'raw_text': receipt.rawText,
        'is_deleted': false,
        'deleted_at': null,
      };

      if (kDebugMode) {
        print('=== Supabase insert payload with receipt_hash and file_size ===');
        print(insertData);
      }

      final response = await _supabase
          .from('receipts')
          .insert(insertData)
          .select('id')
          .single();

      final String receiptId = response['id'].toString();
      if (kDebugMode) print('=== Receipt ID: $receiptId ===');

      return receiptId;
    } catch (e) {
      throw Exception('Supabase receipts insert failed: $e');
    }
  }

  /// Inserts receipt line items linked to the generated receipt ID.
  Future<void> saveReceiptItems(
    String receiptId,
    List<ReceiptItemModel> items,
  ) async {
    try {
      if (items.isEmpty) return;
      
      final payload = items.map((item) {
        final double qty = (item.quantity ?? 1).toDouble();
        final double up = item.unitPrice ?? 0.0;
        final double tp = item.totalPrice ?? (up * qty);
        return {
          'receipt_id': int.parse(receiptId),
          'name': item.name,
          'quantity': item.quantity ?? 1,
          'price': tp,
          'unit_price': up,
          'total_price': tp,
        };
      }).toList();

      if (kDebugMode) {
        print('=== Receipt Items payload ===');
        print(payload);
      }

      await _supabase.from('receipt_items').insert(payload);
    } catch (e) {
      throw Exception('Supabase receipt_items insert failed: $e');
    }
  }

  /// Fetches a receipt record and its items from Supabase by ID for a specific user, with offline cache support.
  Future<Map<String, dynamic>> fetchReceipt(String receiptId, {required String userId}) async {
    try {
      final intId = int.tryParse(receiptId) ?? receiptId;
      
      final receiptData = await _supabase
          .from('receipts')
          .select()
          .eq('id', intId)
          .eq('user_id', userId)
          .maybeSingle();

      if (receiptData == null) {
        // Diagnostic fallback to identify exact missing/mismatched record
        final checkAny = await _supabase
            .from('receipts')
            .select()
            .eq('id', intId)
            .maybeSingle();

        if (checkAny == null) {
          // Check local offline cache before throwing
          final cached = await _offlineCacheService.getCachedReceiptDetails(userId, receiptId);
          if (cached != null) return cached;
          throw Exception('Receipt record ID "$receiptId" does not exist in database.');
        } else if (checkAny['user_id'] != userId && checkAny['user_id'] != 'guest') {
          throw Exception('Access denied: Receipt owner (${checkAny['user_id']}) does not match current user ($userId).');
        } else {
          final result = await _fetchReceiptWithData(checkAny, intId);
          await _offlineCacheService.cacheReceiptDetails(userId, receiptId, result);
          return result;
        }
      }

      final result = await _fetchReceiptWithData(receiptData, intId);
      await _offlineCacheService.cacheReceiptDetails(userId, receiptId, result);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[FetchReceipt Error] Receipt ID: $receiptId | User UID: $userId | Exception: $e. Checking offline cache...');
      }
      final cached = await _offlineCacheService.getCachedReceiptDetails(userId, receiptId);
      if (cached != null) {
        return cached;
      }
      throw Exception('Database fetch failed: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchReceiptWithData(Map<String, dynamic> receiptData, dynamic intId) async {
    final itemsData = await _supabase
        .from('receipt_items')
        .select()
        .eq('receipt_id', intId);

    final migratedReceipt = migrateReceiptDataIfNeeded(receiptData);

    return {
      'receipt': migratedReceipt,
      'items': itemsData,
    };
  }

  /// Fetches all active receipts (where is_deleted is false or null) for a specific user, with offline cache support.
  Future<List<Map<String, dynamic>>> fetchAllReceipts({required String userId}) async {
    try {
      final response = await _supabase
          .from('receipts')
          .select()
          .eq('user_id', userId)
          .or('is_deleted.is.null,is_deleted.eq.false')
          .order('date', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      final migratedList = list.map((r) => migrateReceiptDataIfNeeded(r)).toList();
      
      // Update user-scoped local cache when online
      await _offlineCacheService.cacheReceipts(userId, migratedList);
      return migratedList;
    } catch (e) {
      if (kDebugMode) {
        print('[FetchAllReceipts] Network/database exception ($e). Loading user-scoped offline cache...');
      }
      return await _offlineCacheService.getCachedReceipts(userId);
    }
  }

  /// Fetches all soft-deleted receipts (where is_deleted is true) sorted by deleted_at descending.
  Future<List<Map<String, dynamic>>> fetchDeletedReceipts({required String userId}) async {
    try {
      final response = await _supabase
          .from('receipts')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', true)
          .order('deleted_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      final migratedList = list.map((r) => migrateReceiptDataIfNeeded(r)).toList();

      if (kDebugMode) {
        print('=== fetchDeletedReceipts Debug Logs ===');
        print('Number of deleted receipts fetched: ${migratedList.length}');
        for (final item in migratedList) {
          print('Receipt ID: ${item['id']} | is_deleted: ${item['is_deleted']} | deleted_at: ${item['deleted_at']}');
        }
        print('=======================================');
      }

      return migratedList;
    } catch (e) {
      if (kDebugMode) print('fetchDeletedReceipts error: $e');
      return [];
    }
  }

  /// Soft deletes a receipt record by updating is_deleted to true and deleted_at to current timestamp.
  Future<void> softDeleteReceipt(String receiptId, {required String userId}) async {
    try {
      final intId = int.tryParse(receiptId) ?? receiptId;
      await _supabase
          .from('receipts')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', intId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to soft delete receipt: $e');
    }
  }

  /// Restores a soft-deleted receipt record by setting is_deleted to false and deleted_at to null.
  Future<void> restoreReceipt(String receiptId, {required String userId}) async {
    try {
      final intId = int.tryParse(receiptId) ?? receiptId;
      await _supabase
          .from('receipts')
          .update({
            'is_deleted': false,
            'deleted_at': null,
          })
          .eq('id', intId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to restore receipt: $e');
    }
  }

  /// Fetches receipts deleted more than 30 days ago.
  Future<List<Map<String, dynamic>>> fetchOldDeletedReceipts({required String userId}) async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final response = await _supabase
          .from('receipts')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', true)
          .lt('deleted_at', cutoffDate);

      final list = List<Map<String, dynamic>>.from(response);
      return list.map((r) => migrateReceiptDataIfNeeded(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Ensures receipt_hash, file_size, receipt_number, and confidence_score follow proper design.
  /// Generates hash or populates file_size from metadata if missing.
  Map<String, dynamic> migrateReceiptDataIfNeeded(Map<String, dynamic> row) {
    final Map<String, dynamic> updatedRow = Map<String, dynamic>.from(row);

    final String? currentHash = updatedRow['receipt_hash'] as String?;
    final String? receiptNum = updatedRow['receipt_number'] as String?;
    final String? invoiceNum = updatedRow['invoice_number'] as String?;
    final dynamic rawFileSize = updatedRow['file_size'];
    final dynamic rawConfScore = updatedRow['confidence_score'];

    int? currentFileSize = rawFileSize != null ? int.tryParse(rawFileSize.toString()) : null;
    double? currentConfScore = rawConfScore != null ? double.tryParse(rawConfScore.toString()) : null;

    bool needsDbUpdate = false;
    Map<String, dynamic> dbUpdates = {};

    // Check if receipt_number actually contains a 64-character SHA-256 hash
    bool receiptNumIsHash = receiptNum != null &&
        receiptNum.length == 64 &&
        RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(receiptNum);

    // 1. Populate receipt_hash
    if (currentHash == null || currentHash.isEmpty) {
      if (receiptNumIsHash) {
        updatedRow['receipt_hash'] = receiptNum;
        updatedRow['receipt_number'] = invoiceNum;
        dbUpdates['receipt_hash'] = receiptNum;
        dbUpdates['receipt_number'] = invoiceNum;
        needsDbUpdate = true;
      } else {
        final cleanMerchant = (updatedRow['merchant_name'] as String? ?? '').trim().toLowerCase();
        final cleanInvoice = (invoiceNum ?? '').trim().toLowerCase();
        final cleanDate = (updatedRow['date'] as String? ?? '').trim().toLowerCase();
        final double totalVal = ReceiptModel.parseDouble(updatedRow['grand_total']) ??
            ReceiptModel.parseDouble(updatedRow['total']) ??
            0.0;
        final cleanTotal = totalVal.toStringAsFixed(2);

        final hashInput = '$cleanMerchant|$cleanInvoice|$cleanDate|$cleanTotal';
        final String computedHash = sha256.convert(utf8.encode(hashInput)).toString();

        updatedRow['receipt_hash'] = computedHash;
        dbUpdates['receipt_hash'] = computedHash;
        needsDbUpdate = true;
      }
    } else if (receiptNumIsHash) {
      // Restore receipt_number if it was previously overwritten by a hash
      updatedRow['receipt_number'] = invoiceNum;
      dbUpdates['receipt_number'] = invoiceNum;
      needsDbUpdate = true;
    }

    // 2. Populate file_size if NULL
    if (currentFileSize == null) {
      if (currentConfScore != null && currentConfScore > 100) {
        // High value in confidence_score was the stashed file size
        final int extractedSize = currentConfScore.round();
        updatedRow['file_size'] = extractedSize;
        updatedRow['confidence_score'] = null;
        dbUpdates['file_size'] = extractedSize;
        dbUpdates['confidence_score'] = null;
        needsDbUpdate = true;
      }
    }

    // Background update to persist migrated values to Supabase
    if (needsDbUpdate && updatedRow.containsKey('id')) {
      final id = updatedRow['id'];
      Future.microtask(() async {
        try {
          await _supabase.from('receipts').update(dbUpdates).eq('id', id);
        } catch (e) {
          if (kDebugMode) print('On-the-fly migration update error for receipt $id: $e');
        }
      });
    }

    return updatedRow;
  }
}

final dbReceiptsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authUser = ref.watch(authStateChangesProvider).value;
  final dbService = ref.watch(receiptDatabaseServiceProvider);
  final user = authUser ?? ref.watch(firebaseAuthServiceProvider).currentUser;
  if (user == null) return [];
  return await dbService.fetchAllReceipts(userId: user.uid);
});

final recycleBinProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authUser = ref.watch(authStateChangesProvider).value;
  final dbService = ref.watch(receiptDatabaseServiceProvider);
  final user = authUser ?? ref.watch(firebaseAuthServiceProvider).currentUser;
  if (user == null) return [];
  return await dbService.fetchDeletedReceipts(userId: user.uid);
});
