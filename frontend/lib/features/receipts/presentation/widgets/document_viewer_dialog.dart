import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart' as xml;
import 'package:receipto/core/constants/constants.dart';

class DocumentViewerDialog extends StatefulWidget {
  final String fileUrl;
  final File? preloadedFile;

  const DocumentViewerDialog({
    super.key,
    required this.fileUrl,
    this.preloadedFile,
  });

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  String _content = '';
  bool _isLoading = true;
  String? _error;
  File? _localFile;
  String _filename = '';
  String _extension = '';

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final String rawFilename = widget.fileUrl.split('/').last.split('?').first;
      _filename = rawFilename.isEmpty ? 'receipt_document' : rawFilename;
      _extension = _filename.contains('.') ? _filename.split('.').last.toLowerCase() : '';

      List<int> bytes;
      if (widget.preloadedFile != null && await widget.preloadedFile!.exists()) {
        _localFile = widget.preloadedFile;
        bytes = await widget.preloadedFile!.readAsBytes();
      } else {
        final response = await http.get(Uri.parse(widget.fileUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download document (${response.statusCode}).');
        }
        bytes = response.bodyBytes;

        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$_filename');
        await tempFile.writeAsBytes(bytes);
        _localFile = tempFile;
      }

      String parsedText = '';

      if (_extension == 'docx') {
        final archive = ZipDecoder().decodeBytes(bytes);
        final docFile = archive.findFile('word/document.xml');
        if (docFile != null) {
          final xmlStr = utf8.decode(docFile.content as List<int>);
          final document = xml.XmlDocument.parse(xmlStr);
          
          final buffer = StringBuffer();
          final body = document.findAllElements('w:body').firstOrNull;
          
          if (body != null) {
            for (final child in body.children) {
              if (child is xml.XmlElement) {
                if (child.name.local == 'p') {
                  final text = child.findAllElements('w:t').map((e) => e.innerText).join('').trim();
                  if (text.isNotEmpty) {
                    buffer.writeln(text);
                    buffer.writeln(); // Spacing between paragraphs
                  }
                } else if (child.name.local == 'tbl') {
                  for (final row in child.findAllElements('w:tr')) {
                    final cells = row.findAllElements('w:tc').map((cell) {
                      return cell.findAllElements('w:t').map((e) => e.innerText).join('').trim();
                    }).where((s) => s.isNotEmpty).toList();
                    if (cells.isNotEmpty) {
                      buffer.writeln(cells.join('   |   '));
                    }
                  }
                  buffer.writeln();
                }
              }
            }
          }

          if (buffer.isEmpty) {
            parsedText = document.findAllElements('w:p')
                .map((p) => p.findAllElements('w:t').map((t) => t.innerText).join('').trim())
                .where((s) => s.isNotEmpty)
                .join('\n\n');
          } else {
            parsedText = buffer.toString().trim();
          }
        }
      } else if (_extension == 'xlsx') {
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
        if (sheetFile != null) {
          final xmlStr = utf8.decode(sheetFile.content as List<int>);
          final document = xml.XmlDocument.parse(xmlStr);
          final List<String> rows = [];
          for (final rowNode in document.findAllElements('row')) {
            final List<String> cells = [];
            for (final cellNode in rowNode.findElements('c')) {
              final String? type = cellNode.getAttribute('t');
              final valNode = cellNode.findElements('v').firstOrNull;
              if (valNode != null) {
                final String val = valNode.innerText;
                if (type == 's') {
                  final int idx = int.tryParse(val) ?? -1;
                  if (idx >= 0 && idx < sharedStrings.length) {
                    cells.add(sharedStrings[idx]);
                  } else {
                    cells.add('');
                  }
                } else {
                  cells.add(val);
                }
              } else {
                cells.add('');
              }
            }
            if (cells.any((c) => c.trim().isNotEmpty)) {
              rows.add(cells.join('   |   '));
            }
          }
          parsedText = rows.join('\n');
        }
      } else if (['txt', 'csv'].contains(_extension)) {
        parsedText = utf8.decode(bytes);
      } else {
        // Fallback printable text parser
        final buffer = StringBuffer();
        int consecutivePrintable = 0;
        final currentWord = StringBuffer();

        for (final byte in bytes) {
          if (byte >= 32 && byte <= 126) {
            currentWord.writeCharCode(byte);
            consecutivePrintable++;
          } else {
            if (consecutivePrintable >= 3) {
              buffer.write(currentWord.toString());
              buffer.write(' ');
            }
            currentWord.clear();
            consecutivePrintable = 0;
          }
        }
        parsedText = buffer.toString().trim();
      }

      if (mounted) {
        setState(() {
          _content = parsedText.isNotEmpty ? parsedText : 'No textual preview available for this document.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _openInNativeApp() async {
    if (_localFile == null || !await _localFile!.exists()) return;
    try {
      final result = await OpenFilex.open(_localFile!.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _shareFile() async {
    if (_localFile == null || !await _localFile!.exists()) return;
    try {
      await Share.shareXFiles([XFile(_localFile!.path)], text: 'Receipt Document: $_filename');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWord = ['doc', 'docx'].contains(_extension);
    final isExcel = ['xls', 'xlsx', 'csv'].contains(_extension);
    final badgeColor = isWord
        ? const Color(0xFF2B579A)
        : isExcel
            ? const Color(0xFF217346)
            : AppColors.secondary;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        color: const Color(0xFF10121A),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _extension.toUpperCase().isEmpty ? 'DOC' : _extension.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: badgeColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Title
                Expanded(
                  child: Text(
                    'Original Document',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hankenGrotesk(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Open In App Button
                if (_localFile != null) ...[
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, color: AppColors.secondary, size: 20),
                    tooltip: 'Open in Word / Docs',
                    onPressed: _openInNativeApp,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 20),
                    tooltip: 'Share File',
                    onPressed: _shareFile,
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Action Banner to Open Original Document
          if (_localFile != null && !_isLoading && _error == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: badgeColor.withValues(alpha: 0.12),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: badgeColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'View full formatting in Microsoft Word or Google Docs',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _openInNativeApp,
                    style: TextButton.styleFrom(
                      backgroundColor: badgeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Open File',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Document Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.secondary),
                        SizedBox(height: 12),
                        Text(
                          'Loading original document...',
                          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                'Error loading document:\n$_error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB), // Clean document paper style
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SelectionArea(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Document Subtitle
                                Row(
                                  children: [
                                    Icon(Icons.description_outlined, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      _filename,
                                      style: GoogleFonts.inter(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, color: Color(0xFFE5E7EB)),
                                Text(
                                  _content,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1F2937), // Dark high-contrast document ink
                                    fontSize: 13.5,
                                    height: 1.6,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
