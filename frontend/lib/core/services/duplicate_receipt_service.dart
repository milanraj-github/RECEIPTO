import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';

final duplicateReceiptServiceProvider = Provider<DuplicateReceiptService>((ref) {
  return DuplicateReceiptService(Supabase.instance.client);
});

class DuplicateResult {
  final bool isDuplicate;
  final Map<String, dynamic>? existingReceipt;
  final String? matchReason;

  DuplicateResult({
    required this.isDuplicate,
    this.existingReceipt,
    this.matchReason,
  });
}

class DuplicateReceiptService {
  final SupabaseClient _client;

  DuplicateReceiptService(this._client);

  /// Priority-based duplicate receipt detection:
  /// Priority 1: Compare receipt_hash.
  /// Priority 2: If receipt_hash cannot be generated, compare invoice_number, merchant_name, purchase_date, grand_total.
  /// Priority 3: If invoice number is unavailable, fallback to filename, file_size, OCR text similarity (Jaccard > 80%).
  Future<DuplicateResult> checkDuplicate({
    required ReceiptModel receipt,
    required String userId,
    required String? fileName,
    int? fileSize,
    String? rawText,
  }) async {
    // Priority 1: Generate receipt_hash fingerprint
    final cleanMerchant = (receipt.merchantName ?? '').trim().toLowerCase();
    final cleanInvoice = (receipt.invoiceNumber ?? '').trim().toLowerCase();
    final cleanDate = (receipt.date ?? '').trim().toLowerCase();
    final double totalVal = receipt.total ?? 0.0;
    final cleanTotal = totalVal.toStringAsFixed(2);
    
    String? incomingHash;
    if (cleanMerchant.isNotEmpty || cleanInvoice.isNotEmpty || cleanDate.isNotEmpty || totalVal > 0) {
      final hashInput = '$cleanMerchant|$cleanInvoice|$cleanDate|$cleanTotal';
      incomingHash = sha256.convert(utf8.encode(hashInput)).toString();
    }

    List<Map<String, dynamic>> existingReceipts = [];
    try {
      final response = await _client
          .from('receipts')
          .select()
          .eq('user_id', userId)
          .or('is_deleted.is.null,is_deleted.eq.false');
      existingReceipts = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) print('Error fetching receipts for duplicate comparison: $e');
      return DuplicateResult(isDuplicate: false);
    }

    if (existingReceipts.isEmpty) {
      return DuplicateResult(isDuplicate: false);
    }

    // Check Priority 1: receipt_hash match
    if (incomingHash != null) {
      for (final row in existingReceipts) {
        String? dbHash = row['receipt_hash'] as String?;
        final dbReceiptNum = row['receipt_number'] as String?;

        // Fallback check for unmigrated rows where receipt_number might contain the hash
        if (dbHash == null && dbReceiptNum != null && dbReceiptNum.length == 64 && RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(dbReceiptNum)) {
          dbHash = dbReceiptNum;
        }

        if (dbHash != null && dbHash.toLowerCase() == incomingHash.toLowerCase()) {
          if (kDebugMode) print('Duplicate found by Priority 1 (receipt_hash): $incomingHash');
          return DuplicateResult(
            isDuplicate: true,
            existingReceipt: row,
            matchReason: 'A receipt with the exact same fingerprint (receipt_hash) already exists.',
          );
        }
      }
    }

    // Priority 2: If receipt_hash cannot be generated or matched, compare invoice_number, merchant_name, purchase_date, grand_total
    if (cleanInvoice.isNotEmpty && cleanMerchant.isNotEmpty && cleanDate.isNotEmpty && totalVal > 0) {
      for (final row in existingReceipts) {
        final dbInvoice = (row['invoice_number'] as String? ?? '').trim().toLowerCase();
        final dbMerchant = (row['merchant_name'] as String? ?? '').trim().toLowerCase();
        final dbDate = (row['date'] as String? ?? '').trim().toLowerCase();
        final dbTotal = (ReceiptModel.parseDouble(row['grand_total']) ?? ReceiptModel.parseDouble(row['total']) ?? 0.0).toStringAsFixed(2);

        if (dbInvoice == cleanInvoice && dbMerchant == cleanMerchant && dbDate == cleanDate && dbTotal == cleanTotal) {
          if (kDebugMode) print('Duplicate found by Priority 2 (all 4 fields match)');
          return DuplicateResult(
            isDuplicate: true,
            existingReceipt: row,
            matchReason: 'Priority 2 match: invoice_number, merchant_name, purchase_date, and grand_total all match.',
          );
        }
      }
    }

    // Priority 3: If invoice_number is missing/unavailable -> Fallback to filename + file_size + OCR text similarity (>80%)
    final bool isInvoiceUnavailable = cleanInvoice.isEmpty;
    if (isInvoiceUnavailable) {
      final String incomingRawText = rawText ?? receipt.rawText ?? '';

      for (final row in existingReceipts) {
        final String? dbFileName = row['original_file_name'] as String?;
        
        // Read file_size from file_size column, with fallback to legacy confidence_score if stashed size
        dynamic rawSize = row['file_size'];
        int? dbFileSize = rawSize != null ? int.tryParse(rawSize.toString()) : null;
        if (dbFileSize == null && row['confidence_score'] != null) {
          final double? stashedSize = double.tryParse(row['confidence_score'].toString());
          if (stashedSize != null && stashedSize > 100) {
            dbFileSize = stashedSize.round();
          }
        }

        final String dbRawText = row['raw_text'] as String? ?? '';

        final double similarity = _calculateJaccardSimilarity(incomingRawText, dbRawText);

        bool isMatch = false;
        // Priority 3 checks: filename + file_size + OCR similarity (>80%)
        if (fileName != null && dbFileName != null && fileName.trim().toLowerCase() == dbFileName.trim().toLowerCase() && fileSize == dbFileSize && fileSize != null) {
          isMatch = true;
        } else if (fileSize != null && dbFileSize != null && fileSize == dbFileSize && similarity > 0.80) {
          isMatch = true;
        } else if (fileName != null && dbFileName != null && fileName.trim().toLowerCase() == dbFileName.trim().toLowerCase() && similarity > 0.80) {
          isMatch = true;
        }

        if (isMatch) {
          if (kDebugMode) print('Duplicate found by Priority 3 (filename, size, OCR similarity: $similarity)');
          return DuplicateResult(
            isDuplicate: true,
            existingReceipt: row,
            matchReason: 'Priority 3 match: filename, file_size, or OCR text similarity (>80%) matches closely.',
          );
        }
      }
    }

    return DuplicateResult(isDuplicate: false);
  }

  /// Calculates the Jaccard similarity index based on word token overlap
  double _calculateJaccardSimilarity(String text1, String text2) {
    final t1 = text1.toLowerCase().trim();
    final t2 = text2.toLowerCase().trim();
    if (t1.isEmpty && t2.isEmpty) return 1.0;
    if (t1.isEmpty || t2.isEmpty) return 0.0;

    final words1 = t1.split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toSet();
    final words2 = t2.split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toSet();
    
    if (words1.isEmpty && words2.isEmpty) return 1.0;
    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    return intersection.length / union.length;
  }
}
