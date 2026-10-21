import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:receipto/core/constants/constants.dart';

class PdfViewerDialog extends StatefulWidget {
  final String pdfUrl;
  final File? preloadedFile;

  const PdfViewerDialog({
    super.key,
    required this.pdfUrl,
    this.preloadedFile,
  });

  @override
  State<PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends State<PdfViewerDialog> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _error;
  File? _localPdfFile;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      if (widget.preloadedFile != null && await widget.preloadedFile!.exists()) {
        _localPdfFile = widget.preloadedFile;
      } else {
        final response = await http.get(Uri.parse(widget.pdfUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download PDF document (${response.statusCode}).');
        }
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_view_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await tempFile.writeAsBytes(response.bodyBytes);
        _localPdfFile = tempFile;
      }

      _pdfController = PdfController(
        document: PdfDocument.openFile(_localPdfFile!.path),
      );

      if (mounted) {
        setState(() {
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
    if (_localPdfFile == null || !await _localPdfFile!.exists()) return;
    try {
      final result = await OpenFilex.open(_localPdfFile!.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open PDF: ${result.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_localPdfFile == null || !await _localPdfFile!.exists()) return;
    try {
      await Share.shareXFiles([XFile(_localPdfFile!.path)], text: 'Receipt PDF Document');
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
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6174).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF6174).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'PDF',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF6174),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Original PDF Receipt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hankenGrotesk(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_localPdfFile != null) ...[
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, color: AppColors.secondary, size: 20),
                    tooltip: 'Open in External PDF Viewer',
                    onPressed: _openInNativeApp,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 20),
                    tooltip: 'Share PDF',
                    onPressed: _sharePdf,
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // PDF View Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.secondary),
                        SizedBox(height: 12),
                        Text(
                          'Loading PDF...',
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
                                'Error loading PDF:\n$_error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: PdfView(
                          controller: _pdfController!,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
