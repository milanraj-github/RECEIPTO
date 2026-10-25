import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final receiptEnhancerServiceProvider = Provider<ReceiptEnhancerService>((ref) {
  return ReceiptEnhancerService();
});

class ReceiptEnhancerService {
  /// Enhances a receipt image for optimal OCR extraction.
  /// 
  /// 1. Bakes EXIF orientation (rotation correction).
  /// 2. Downscales oversized images if max dimension > 1800px (preserving aspect ratio).
  /// 3. Adjusts contrast and brightness to enhance text sharpness.
  /// 4. Detects and trims uniform background borders/margins safely.
  /// 5. Compresses to high-quality JPG.
  /// 6. Safely falls back to the original file if any processing step fails.
  Future<File> enhanceReceiptImage(File originalFile) async {
    try {
      final bytes = await originalFile.readAsBytes();
      if (bytes.isEmpty) return originalFile;

      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return originalFile;

      // 1. Correct rotation/orientation from EXIF metadata
      image = img.bakeOrientation(image);

      // 2. Resize if oversized (keeps width/height within 1800px max)
      const int maxDimension = 1800;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width >= image.height) {
          image = img.copyResize(
            image,
            width: maxDimension,
            interpolation: img.Interpolation.linear,
          );
        } else {
          image = img.copyResize(
            image,
            height: maxDimension,
            interpolation: img.Interpolation.linear,
          );
        }
      }

      // 3. Auto-crop dark/light empty border margins safely
      image = _cropReceiptMargins(image);

      // 4. Enhance contrast and dynamic range for OCR readability
      image = img.adjustColor(
        image,
        contrast: 1.20,
        brightness: 1.04,
        gamma: 0.95,
      );

      // 5. Encode to JPG with 85% quality compression
      final enhancedBytes = img.encodeJpg(image, quality: 85);

      final tempDir = await getTemporaryDirectory();
      final enhancedPath = p.join(
        tempDir.path,
        'enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final enhancedFile = File(enhancedPath);
      await enhancedFile.writeAsBytes(enhancedBytes);
      return enhancedFile;
    } catch (e) {
      if (kDebugMode) {
        print('[ReceiptEnhancerService] Enhancement fallback to original: $e');
      }
      // Graceful fallback to original image
      return originalFile;
    }
  }

  /// Detects outer margin borders (e.g. table surface or camera padding) and trims them safely.
  img.Image _cropReceiptMargins(img.Image src) {
    try {
      final int width = src.width;
      final int height = src.height;
      if (width < 300 || height < 300) return src;

      // Sample border pixel luminance on edges
      final int maxCropY = (height * 0.08).round();

      int top = 0;
      int bottom = height;
      int left = 0;
      int right = width;

      // Sample corners to detect background color
      final cornerPixel = src.getPixel(10, 10);
      final cornerLum = cornerPixel.luminance;

      // Scan top margin
      for (int y = 0; y < maxCropY; y += 4) {
        double rowDiff = 0;
        for (int x = (width * 0.2).round(); x < (width * 0.8).round(); x += 10) {
          final p = src.getPixel(x, y);
          rowDiff += (p.luminance - cornerLum).abs();
        }
        final avgDiff = rowDiff / ((width * 0.6) / 10);
        if (avgDiff > 0.15) {
          top = math.max(0, y - 2);
          break;
        }
      }

      // Scan bottom margin
      for (int y = height - 1; y > height - maxCropY; y += 4) {
        double rowDiff = 0;
        for (int x = (width * 0.2).round(); x < (width * 0.8).round(); x += 10) {
          final p = src.getPixel(x, y);
          rowDiff += (p.luminance - cornerLum).abs();
        }
        final avgDiff = rowDiff / ((width * 0.6) / 10);
        if (avgDiff > 0.15) {
          bottom = math.min(height, y + 2);
          break;
        }
      }

      final cropW = right - left;
      final cropH = bottom - top;

      if (cropW > (width * 0.8) && cropH > (height * 0.8) && (top > 0 || bottom < height)) {
        return img.copyCrop(
          src,
          x: left,
          y: top,
          width: cropW,
          height: cropH,
        );
      }
      return src;
    } catch (_) {
      return src;
    }
  }
}
