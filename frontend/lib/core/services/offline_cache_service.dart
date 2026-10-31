import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  return OfflineCacheService();
});

class OfflineCacheService {
  static final OfflineCacheService instance = OfflineCacheService();
  static const String _prefix = 'offline_cache_v1_';

  String _userReceiptsKey(String userId) => '${_prefix}user_${userId}_receipts';
  String _userWarrantiesKey(String userId) => '${_prefix}user_${userId}_warranties';
  String _userReceiptDetailKey(String userId, String receiptId) => '${_prefix}user_${userId}_receipt_$receiptId';

  /// Saves the active receipts list scoped to the authenticated user ID.
  Future<void> cacheReceipts(String userId, List<Map<String, dynamic>> receipts) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(receipts);
      await prefs.setString(_userReceiptsKey(userId), jsonStr);
    } catch (e) {
      if (kDebugMode) print('[OfflineCache] Failed to cache receipts: $e');
    }
  }

  /// Retrieves the cached receipts list for the authenticated user ID.
  Future<List<Map<String, dynamic>>> getCachedReceipts(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userReceiptsKey(userId));
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) print('[OfflineCache] Failed to read cached receipts: $e');
      return [];
    }
  }

  /// Saves detailed receipt record + items for offline details viewing.
  Future<void> cacheReceiptDetails(
    String userId,
    String receiptId,
    Map<String, dynamic> data,
  ) async {
    if (userId.isEmpty || receiptId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(data);
      await prefs.setString(_userReceiptDetailKey(userId, receiptId), jsonStr);
    } catch (e) {
      if (kDebugMode) print('[OfflineCache] Failed to cache receipt detail: $e');
    }
  }

  /// Retrieves cached receipt detail record for a specific user and receipt ID.
  Future<Map<String, dynamic>?> getCachedReceiptDetails(String userId, String receiptId) async {
    if (userId.isEmpty || receiptId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userReceiptDetailKey(userId, receiptId));
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final decoded = jsonDecode(jsonStr);
      return Map<String, dynamic>.from(decoded as Map);
    } catch (e) {
      if (kDebugMode) print('[OfflineCache] Failed to read cached receipt detail: $e');
      return null;
    }
  }

  /// Saves the active warranties list scoped to the authenticated user ID.
  Future<void> cacheWarranties(String userId, List<WarrantyModel> warranties) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = warranties.map((w) => w.toJson()).toList();
      final jsonStr = jsonEncode(jsonList);
      await prefs.setString(_userWarrantiesKey(userId), jsonStr);
    } catch (e) {
      if (kDebugMode) print('[OfflineCache] Failed to cache warranties: $e');
    }
  }

  /// Retrieves the cached warranties list for the authenticated user ID.
  Future<List<WarrantyModel>> getCachedWarranties(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userWarrantiesKey(userId));
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => WarrantyModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      if (kDebugMode) print('[OfflineCache] Failed to read cached warranties: $e');
      return [];
    }
  }

  /// Caches an image file locally in the user's isolated cache directory.
  Future<File?> cacheReceiptImage(String userId, String receiptId, Uint8List imageBytes) async {
    if (userId.isEmpty || receiptId.isEmpty || imageBytes.isEmpty) return null;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final userImgDir = Directory(p.join(docDir.path, 'receipto_cache', userId, 'images'));
      if (!await userImgDir.exists()) {
        await userImgDir.create(recursive: true);
      }
      final file = File(p.join(userImgDir.path, 'receipt_$receiptId.jpg'));
      await file.writeAsBytes(imageBytes);
      return file;
    } catch (e) {
      if (kDebugMode) print('[OfflineCache] Failed to cache image: $e');
      return null;
    }
  }

  /// Gets the local cached image file if present.
  Future<File?> getCachedReceiptImage(String userId, String receiptId) async {
    if (userId.isEmpty || receiptId.isEmpty) return null;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(docDir.path, 'receipto_cache', userId, 'images', 'receipt_$receiptId.jpg'));
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clears in-memory and persisted cache for a specific user (on logout or account switch).
  Future<void> clearUserCache(String userId) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('${_prefix}user_${userId}_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }

      final docDir = await getApplicationDocumentsDirectory();
      final userCacheDir = Directory(p.join(docDir.path, 'receipto_cache', userId));
      if (await userCacheDir.exists()) {
        await userCacheDir.delete(recursive: true);
      }
    } catch (e) {
      if (kDebugMode) print('[OfflineCache] Failed to clear user cache: $e');
    }
  }
}
