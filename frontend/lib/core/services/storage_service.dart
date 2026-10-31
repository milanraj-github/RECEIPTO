import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(Supabase.instance.client);
});

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  /// Compress image if it exceeds 5 MB
  Future<File> _compressIfLarge(File file) async {
    try {
      final int sizeInBytes = await file.length();
      if (sizeInBytes <= 5 * 1024 * 1024) {
        return file;
      }

      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return file;

      // Compress to a lower quality JPG
      final compressedBytes = img.encodeJpg(decodedImage, quality: 70);

      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(
        tempDir.path,
        'storage_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedBytes);
      return compressedFile;
    } catch (_) {
      return file;
    }
  }

  /// Upload receipt to public receipts bucket and return the public url
  Future<String> uploadReceipt({
    required File image,
    required String userId,
  }) async {
    try {
      final File fileToUpload = await _compressIfLarge(image);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String path = '$userId/receipt_$timestamp.jpg';

      await _supabase.storage.from('receipts').upload(
        path,
        fileToUpload,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final String publicUrl = _supabase.storage.from('receipts').getPublicUrl(path);
      
      if (kDebugMode) print('=== Storage upload URL: $publicUrl ===');

      return publicUrl;
    } catch (e) {
      throw Exception('Supabase storage upload failed: $e');
    }
  }

  /// Upload generic file of any type and return the public url
  Future<String> uploadReceiptFile({
    required File file,
    required String userId,
  }) async {
    try {
      final String ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
      
      // Determine content type
      String contentType = 'application/octet-stream';
      if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)) {
        contentType = 'image/jpeg';
        final File fileToUpload = await _compressIfLarge(file);
        return await uploadReceipt(image: fileToUpload, userId: userId);
      } else if (ext == 'pdf') {
        contentType = 'application/pdf';
      } else if (ext == 'txt') {
        contentType = 'text/plain';
      } else if (ext == 'csv') {
        contentType = 'text/csv';
      } else if (ext == 'doc' || ext == 'docx') {
        contentType = 'application/msword';
      } else if (ext == 'xls' || ext == 'xlsx') {
        contentType = 'application/vnd.ms-excel';
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String path = '$userId/doc_$timestamp.$ext';

      await _supabase.storage.from('receipts').upload(
        path,
        file,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      final String publicUrl = _supabase.storage.from('receipts').getPublicUrl(path);
      
      if (kDebugMode) print('=== Storage upload URL: $publicUrl ===');

      return publicUrl;
    } catch (e) {
      throw Exception('Supabase storage upload failed: $e');
    }
  }

  /// Deletes a file from Supabase storage bucket by parsing its public URL.
  Future<void> deleteReceiptFileByUrl(String publicUrl) async {
    try {
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;
      final receiptsIndex = segments.indexOf('receipts');
      if (receiptsIndex != -1 && receiptsIndex < segments.length - 1) {
        final path = segments.sublist(receiptsIndex + 1).join('/');
        await _supabase.storage.from('receipts').remove([path]);
        if (kDebugMode) print('=== Storage File Deleted Successfully ===');
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting stored file from Supabase Storage: $e');
    }
  }
}
