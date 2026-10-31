import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/core/utils/warranty_utils.dart';

final dbWarrantiesProvider = FutureProvider<List<WarrantyModel>>((ref) async {
  final dbService = ref.watch(warrantyDatabaseServiceProvider);
  final authUser = ref.watch(authStateChangesProvider).value;
  final user = authUser ?? ref.watch(firebaseAuthServiceProvider).currentUser;
  if (user == null) return [];
  
  final activeReceipts = await ref.watch(dbReceiptsListProvider.future);
  final activeReceiptIds = activeReceipts.map((r) => r['id'].toString()).toSet();

  final list = await dbService.fetchAllWarranties(user.uid);
  
  // Ignore warranties belonging to soft-deleted receipts
  final activeWarranties = list.where((w) => activeReceiptIds.contains(w.receiptId)).toList();

  // Re-calculate the status dynamically on load using today's date
  return activeWarranties.map((w) {
    final status = WarrantyUtils.calculateStatus(w.expiryDate);
    return w.copyWith(status: status);
  }).toList();
});

final warrantiesByReceiptProvider = FutureProvider.family<List<WarrantyModel>, String>((ref, receiptId) async {
  final allWarranties = await ref.watch(dbWarrantiesProvider.future);
  return allWarranties.where((w) => w.receiptId == receiptId).toList();
});

final warrantyDetailProvider = FutureProvider.family<WarrantyModel?, String>((ref, warrantyId) async {
  final dbService = ref.watch(warrantyDatabaseServiceProvider);
  final user = ref.watch(firebaseAuthServiceProvider).currentUser;
  if (user == null) return null;
  
  final w = await dbService.fetchWarranty(warrantyId, userId: user.uid);
  if (w == null || w.userId != user.uid) return null;
  
  final status = WarrantyUtils.calculateStatus(w.expiryDate);
  return w.copyWith(status: status);
});
