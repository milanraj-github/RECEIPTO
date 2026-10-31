import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:xml/xml.dart' as xml;
import 'package:receipto/features/scan/data/services/image_picker_service.dart';

final fileProcessorServiceProvider = Provider<FileProcessorService>((ref) {
  final imagePickerService = ref.watch(imagePickerServiceProvider);
  return FileProcessorService(imagePickerService);
});

class FileProcessorService {
  final ImagePickerService _imagePickerService;

  FileProcessorService(this._imagePickerService);

  /// Allowed extensions across all supported categories
  final List<String> allowedExtensions = [
    // Images
    'jpg', 'jpeg', 'png', 'webp', 'heic',
    // PDF
    'pdf',
    // Word
    'doc', 'docx',
    // Excel
    'xls', 'xlsx',
    // Text / CSV
    'txt', 'csv',
  ];

  /// Launch file picker to select a single receipt file
  Future<File?> pickReceiptFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final String? path = result.files.first.path;
      if (path == null) {
        throw const HttpException('Failed to retrieve selected file path.');
      }

      final File file = File(path);
      
      // Limit file size to 20MB
      final int sizeInBytes = await file.length();
      final double sizeInMb = sizeInBytes / (1024 * 1024);
      if (sizeInMb > 20) {
        throw const HttpException('Selected file is too large. Maximum size is 20MB.');
      }

      return file;
    } catch (e) {
      if (e is HttpException) rethrow;
      throw Exception('Failed to select file: $e');
    }
  }

  /// Convert PDF pages to a list of image Files
  Future<List<File>> convertPdfToImages(File pdfFile) async {
    final List<File> imageFiles = [];
    try {
      final document = await PdfDocument.openFile(pdfFile.path);
      final tempDir = await getTemporaryDirectory();
      
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final pageRender = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
        );
        if (pageRender != null) {
          final imgPath = '${tempDir.path}/pdf_page_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File(imgPath);
          await file.writeAsBytes(pageRender.bytes);
          imageFiles.add(file);
        }
        await page.close();
      }
      await document.close();
      return imageFiles;
    } catch (e) {
      throw Exception('Failed to render PDF pages: $e');
    }
  }

  /// Extract text contents from docx (zipped XML)
  Future<String> extractTextFromDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.findFile('word/document.xml');
      if (docFile == null) return '';
      final xmlStr = utf8.decode(docFile.content as List<int>);
      final document = xml.XmlDocument.parse(xmlStr);
      final textNodes = document.findAllElements('w:t');
      return textNodes.map((node) => node.innerText).join(' ');
    } catch (e) {
      throw Exception('Failed to parse Docx document: $e');
    }
  }

  /// Extract text from binary doc/xls files using ASCII scanner
  Future<String> extractTextFromBinary(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final buffer = StringBuffer();
      int consecutivePrintable = 0;
      final currentWord = StringBuffer();
      
      for (final byte in bytes) {
        if (byte >= 32 && byte <= 126) {
          currentWord.writeCharCode(byte);
          consecutivePrintable++;
        } else {
          if (consecutivePrintable >= 4) {
            buffer.write(currentWord.toString());
            buffer.write(' ');
          }
          currentWord.clear();
          consecutivePrintable = 0;
        }
      }
      if (consecutivePrintable >= 4) {
        buffer.write(currentWord.toString());
      }
      return buffer.toString();
    } catch (e) {
      throw Exception('Failed to scan binary file printable text: $e');
    }
  }

  /// Extract tabular data from xlsx spreadsheet
  Future<String> extractTextFromXlsx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final List<String> sharedStrings = [];
      final stringsFile = archive.findFile('xl/sharedStrings.xml');
      if (stringsFile != null) {
        final xmlStr = utf8.decode(stringsFile.content as List<int>);
        final document = xml.XmlDocument.parse(xmlStr);
        for (final node in document.findAllElements('t')) {
          sharedStrings.add(node.innerText);
        }
      }

      final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
      if (sheetFile == null) return '';
      final xmlStr = utf8.decode(sheetFile.content as List<int>);
      final document = xml.XmlDocument.parse(xmlStr);

      final List<String> rowsText = [];
      for (final rowNode in document.findAllElements('row')) {
        final List<String> rowCells = [];
        for (final cellNode in rowNode.findElements('c')) {
          final String? type = cellNode.getAttribute('t');
          final valNode = cellNode.findElements('v').firstOrNull;
          if (valNode != null) {
            final String val = valNode.innerText;
            if (type == 's') {
              final int idx = int.tryParse(val) ?? -1;
              if (idx >= 0 && idx < sharedStrings.length) {
                rowCells.add(sharedStrings[idx]);
              } else {
                rowCells.add('');
              }
            } else {
              rowCells.add(val);
            }
          } else {
            rowCells.add('');
          }
        }
        rowsText.add(rowCells.join(' | '));
      }
      return rowsText.join('\n');
    } catch (e) {
      throw Exception('Failed to parse Excel sheet: $e');
    }
  }

  /// Extract text content of CSV / TXT files
  Future<String> extractTextFromPlainFile(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      // Fallback to binary scan if reading as UTF-8 throws
      return await extractTextFromBinary(file);
    }
  }

  /// Main processing entry method
  Future<Map<String, dynamic>> processFile(File file) async {
    final String extension = p.extension(file.path).toLowerCase().replaceAll('.', '');
    
    if (!allowedExtensions.contains(extension)) {
      throw HttpException('Unsupported file format: .$extension');
    }

    try {
      if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension)) {
        final File compressedImage = await _imagePickerService.compressImage(file);
        return {
          'file': compressedImage,
          'type': 'Image',
          'name': p.basename(file.path),
          'extractedText': 'Image file selected.',
        };
      }

      if (extension == 'pdf') {
        return {
          'file': file,
          'type': 'PDF',
          'name': p.basename(file.path),
          'extractedText': 'PDF document selected.',
        };
      }

      if (extension == 'docx') {
        final text = await extractTextFromDocx(file);
        return {
          'file': file,
          'type': 'Word Document',
          'name': p.basename(file.path),
          'extractedText': text,
        };
      }

      if (extension == 'doc') {
        final text = await extractTextFromBinary(file);
        return {
          'file': file,
          'type': 'Word Document',
          'name': p.basename(file.path),
          'extractedText': text,
        };
      }

      if (extension == 'xlsx') {
        final text = await extractTextFromXlsx(file);
        return {
          'file': file,
          'type': 'Spreadsheet',
          'name': p.basename(file.path),
          'extractedText': text,
        };
      }

      if (extension == 'xls') {
        final text = await extractTextFromBinary(file);
        return {
          'file': file,
          'type': 'Spreadsheet',
          'name': p.basename(file.path),
          'extractedText': text,
        };
      }

      if (['txt', 'csv'].contains(extension)) {
        final text = await extractTextFromPlainFile(file);
        return {
          'file': file,
          'type': extension.toUpperCase(),
          'name': p.basename(file.path),
          'extractedText': text,
        };
      }

      throw HttpException('Unsupported processing format: .$extension');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw Exception('Failed to extract document contents: $e');
    }
  }
}
