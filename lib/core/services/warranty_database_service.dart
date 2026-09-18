import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/core/services/offline_cache_service.dart';

final warrantyDatabaseServiceProvider = Provider<WarrantyDatabaseService>((ref) {
  return WarrantyDatabaseService(Supabase.instance.client, OfflineCacheService());
});

class WarrantyDatabaseService {
  final SupabaseClient _supabase;
  final OfflineCacheService? _cache;
  OfflineCacheService get _offlineCacheService => _cache ?? OfflineCacheService.instance;

  WarrantyDatabaseService([
    SupabaseClient? supabase,
    OfflineCacheService? offlineCacheService,
  ])  : _supabase = supabase ?? Supabase.instance.client,
        _cache = offlineCacheService ?? OfflineCacheService.instance;

  /// Saves a warranty record in the "warranties" table. Returns generated ID.
  Future<String> saveWarranty(WarrantyModel warranty) async {
    try {
      final payload = warranty.toJson();
      payload.remove('id');

      try {
        final response = await _supabase
            .from('warranties')
            .insert(payload)
            .select('id')
            .single();

        return response['id'].toString();
      } on PostgrestException catch (pe) {
        if (pe.message.contains('is_manual') || pe.code == 'PGRST204' || pe.code == '42703') {
          payload.remove('is_manual');
          final response = await _supabase
              .from('warranties')
              .insert(payload)
              .select('id')
              .single();
          return response['id'].toString();
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Supabase saveWarranty failed: $e');
    }
  }

  /// Fetches a single warranty by ID for a specific user.
  Future<WarrantyModel?> fetchWarranty(String id, {required String userId}) async {
    try {
      final response = await _supabase
          .from('warranties')
          .select()
          .eq('id', int.tryParse(id) ?? id)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return WarrantyModel.fromJson(response);
    } catch (e) {
      // Fallback: check if in user's cached warranties list
      final cachedList = await _offlineCacheService.getCachedWarranties(userId);
      final match = cachedList.where((w) => w.id == id).firstOrNull;
      if (match != null) return match;
      throw Exception('Supabase fetchWarranty failed: $e');
    }
  }

  /// Fetches all warranty records for a given user, with offline cache support.
  Future<List<WarrantyModel>> fetchAllWarranties(String userId) async {
    try {
      final response = await _supabase
          .from('warranties')
          .select()
          .eq('user_id', userId)
          .order('expiry_date', ascending: true);

      final List<dynamic> list = response as List<dynamic>? ?? [];
      final result = list.map((item) => WarrantyModel.fromJson(item as Map<String, dynamic>)).toList();
      
      // Update local cache
      await _offlineCacheService.cacheWarranties(userId, result);
      return result;
    } catch (e) {
      return await _offlineCacheService.getCachedWarranties(userId);
    }
  }

  /// Updates an existing warranty record for a specific user.
  Future<void> updateWarranty(WarrantyModel warranty, {required String userId}) async {
    try {
      if (warranty.id == null) throw Exception('Cannot update warranty without an ID.');
      
      final payload = warranty.toJson();
      payload.remove('id');

      try {
        await _supabase
            .from('warranties')
            .update(payload)
            .eq('id', int.tryParse(warranty.id!) ?? warranty.id!)
            .eq('user_id', userId);
      } on PostgrestException catch (pe) {
        if (pe.message.contains('is_manual') || pe.code == 'PGRST204' || pe.code == '42703') {
          payload.remove('is_manual');
          await _supabase
              .from('warranties')
              .update(payload)
              .eq('id', int.tryParse(warranty.id!) ?? warranty.id!)
              .eq('user_id', userId);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Supabase updateWarranty failed: $e');
    }
  }

  /// Deletes an existing warranty record by ID for a specific user.
  Future<void> deleteWarranty(String id, {required String userId}) async {
    try {
      await _supabase
          .from('warranties')
          .delete()
          .eq('id', int.tryParse(id) ?? id)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Supabase deleteWarranty failed: $e');
    }
  }
}
