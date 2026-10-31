import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService(ImagePicker());
});

class ImagePickerService {
  final ImagePicker _picker;

  ImagePickerService(this._picker);

  /// Request camera permissions. Throws an exception if denied.
  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final requestStatus = await Permission.camera.request();
      if (!requestStatus.isGranted) {
        throw const HttpException('Camera permission denied. Please enable camera access in settings.');
      }
    }
  }

  /// Request storage/photos permissions. Throws an exception if denied.
  Future<void> _checkGalleryPermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (SDK 33+), check photos permission
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted) return;

      // Fallback/direct check for older Android storage permission
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return;

      // Request permissions
      final requestPhotos = await Permission.photos.request();
      if (requestPhotos.isGranted) return;

      final requestStorage = await Permission.storage.request();
      if (!requestStorage.isGranted) {
        throw const HttpException('Gallery access permission denied. Please enable storage access in settings.');
      }
    } else {
      // iOS / other platforms
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        final requestStatus = await Permission.photos.request();
        if (!requestStatus.isGranted) {
          throw const HttpException('Gallery access permission denied. Please enable photo access in settings.');
        }
      }
    }
  }

  /// Pick an image from the camera and compress it.
  Future<File?> pickFromCamera() async {
    await _checkCameraPermission();

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Native picking optimization
      );

      if (pickedFile == null) return null;

      final File file = File(pickedFile.path);
      return await compressImage(file);
    } catch (e) {
      if (e is HttpException) rethrow;
      throw Exception('Failed to capture image from camera: $e');
    }
  }

  /// Pick an image from the gallery and compress it.
  Future<File?> pickFromGallery() async {
    await _checkGalleryPermission();

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Native picking optimization
      );

      if (pickedFile == null) return null;

      final File file = File(pickedFile.path);
      return await compressImage(file);
    } catch (e) {
      if (e is HttpException) rethrow;
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Compresses the image using the image package and returns the new compressed File.
  Future<File> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return file;

      // Downscale if wider than 1600px to maintain aspect ratio and save space/network bandwidth
      img.Image processedImage = image;
      if (image.width > 1600) {
        processedImage = img.copyResize(image, width: 1600);
      }

      // Encode image to JPG with 75% quality compression
      final compressedBytes = img.encodeJpg(processedImage, quality: 75);

      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(
        tempDir.path,
        'scan_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedBytes);
      return compressedFile;
    } catch (_) {
      // Fallback to original file on compression errors
      return file;
    }
  }
}
