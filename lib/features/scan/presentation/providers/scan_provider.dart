import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:receipto/features/scan/data/repositories/scan_repository.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_provider.dart';

class ScanState {
  final File? selectedImage;
  final String? selectedFilePath;
  final String? selectedFileName;
  final String? selectedFileType;
  final String? extractedContent;
  final bool isLoading;
  final String? errorMessage;
  
  // Preview state parameters
  final File? capturedImage;
  final List<File>? capturedImages;
  final bool isProcessing;
  final bool isAccepted;
  final String? uploadedUrl;
  
  // Gemini receipt analysis model
  final ReceiptModel? extractedReceipt;
  
  // Supabase Database receipt ID
  final String? savedReceiptId;
  final String? statusMessage;

  const ScanState({
    this.selectedImage,
    this.selectedFilePath,
    this.selectedFileName,
    this.selectedFileType,
    this.extractedContent,
    this.isLoading = false,
    this.errorMessage,
    this.capturedImage,
    this.capturedImages,
    this.isProcessing = false,
    this.isAccepted = false,
    this.uploadedUrl,
    this.extractedReceipt,
    this.savedReceiptId,
    this.statusMessage,
  });

  ScanState copyWith({
    File? selectedImage,
    String? selectedFilePath,
    String? selectedFileName,
    String? selectedFileType,
    String? extractedContent,
    bool? isLoading,
    String? errorMessage,
    File? capturedImage,
    List<File>? capturedImages,
    bool? isProcessing,
    bool? isAccepted,
    String? uploadedUrl,
    ReceiptModel? extractedReceipt,
    String? savedReceiptId,
    String? statusMessage,
    bool clearCapturedImage = false,
    bool clearCapturedImages = false,
    bool clearAll = false,
  }) {
    if (clearAll) {
      return const ScanState();
    }
    return ScanState(
      selectedImage: selectedImage ?? this.selectedImage,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      selectedFileName: selectedFileName ?? this.selectedFileName,
      selectedFileType: selectedFileType ?? this.selectedFileType,
      extractedContent: extractedContent ?? this.extractedContent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      capturedImage: clearCapturedImage ? null : (capturedImage ?? this.capturedImage),
      capturedImages: clearCapturedImages ? null : (capturedImages ?? this.capturedImages),
      isProcessing: isProcessing ?? this.isProcessing,
      isAccepted: isAccepted ?? this.isAccepted,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      extractedReceipt: extractedReceipt ?? this.extractedReceipt,
      savedReceiptId: savedReceiptId ?? this.savedReceiptId,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  final ScanRepository _repository;
  final Ref _ref;

  ScanNotifier(this._repository, this._ref) : super(const ScanState());

  /// Set the captured image awaiting preview confirmation, clearing previous scan metadata
  void setCapturedImage(File file) {
    state = ScanState(
      capturedImage: file,
      capturedImages: [file],
      selectedImage: file,
      selectedFilePath: file.path,
      selectedFileName: file.path.split('/').last.split('\\').last,
      isAccepted: false,
      isProcessing: false,
      isLoading: false,
      errorMessage: null,
      statusMessage: null,
    );
  }

  /// Set multiple captured images awaiting preview confirmation (Batch scan)
  void setCapturedImages(List<File> files) {
    state = ScanState(
      capturedImage: files.isNotEmpty ? files.first : null,
      capturedImages: List.from(files),
      selectedImage: files.isNotEmpty ? files.first : null,
      selectedFilePath: files.isNotEmpty ? files.first.path : null,
      selectedFileName: files.isNotEmpty ? files.first.path.split('/').last.split('\\').last : null,
      isAccepted: false,
      isProcessing: false,
      isLoading: false,
      errorMessage: null,
      statusMessage: null,
    );
  }

  /// Append a new captured page to the existing batch list
  void addCapturedImage(File file) {
    final currentList = state.capturedImages != null ? List<File>.from(state.capturedImages!) : <File>[];
    if (state.capturedImage != null && currentList.isEmpty) {
      currentList.add(state.capturedImage!);
    }
    currentList.add(file);
    state = state.copyWith(
      capturedImages: currentList,
      capturedImage: currentList.first,
    );
  }

  /// Remove a captured page at a specific index from the batch
  void removeCapturedImage(int index) {
    if (state.capturedImages == null || index < 0 || index >= state.capturedImages!.length) return;
    final updatedList = List<File>.from(state.capturedImages!)..removeAt(index);
    if (updatedList.isEmpty) {
      state = const ScanState();
    } else {
      state = state.copyWith(
        capturedImages: updatedList,
        capturedImage: updatedList.first,
        selectedImage: updatedList.first,
        selectedFilePath: updatedList.first.path,
      );
    }
  }

  /// Reset/delete the captured image awaiting preview
  void resetCapturedImage() {
    state = const ScanState();
  }

  /// Manually update processing state and optional status message
  void setProcessing(bool value, {String? statusMessage}) {
    state = state.copyWith(
      isLoading: value,
      isProcessing: value,
      statusMessage: statusMessage ?? (value ? 'Preparing Image...' : null),
    );
  }

  /// Dynamically update loading progress status message
  void setStatusMessage(String message) {
    state = state.copyWith(statusMessage: message);
  }

  /// Run the entire AI pipeline: upload image -> run Gemini vision -> save to Supabase database
  Future<bool> acceptAndProcessReceipt({required String userId}) async {
    final activeUid = FirebaseAuth.instance.currentUser?.uid ?? userId;
    if (activeUid.isEmpty || activeUid == 'guest') {
      throw Exception('Authentication required: Cannot save receipt without active user login.');
    }

    if (state.capturedImage == null) return false;
    
    state = state.copyWith(
      isLoading: true,
      isProcessing: true,
      isAccepted: false,
      errorMessage: null,
      statusMessage: 'Preparing Image...',
    );

    try {
      final File file = state.capturedImage!;
      final int size = await file.length();
      
      state = state.copyWith(statusMessage: 'Extracting Receipt...');

      // Execute the centralized repository workflow:
      final Map<String, dynamic> result = await _repository.processAndSaveReceiptFlow(
        imageFile: file,
        userId: activeUid,
        fileSize: size,
      );

      final ReceiptModel receipt = result['receipt'] as ReceiptModel;
      final String dbId = result['id'] as String;
      final String publicUrl = result['imageUrl'] as String;

      final fileResult = await _repository.processReceiptFile(file);
      
      state = state.copyWith(
        selectedImage: fileResult['file'] as File?,
        selectedFilePath: file.path,
        selectedFileName: fileResult['name'] as String?,
        selectedFileType: fileResult['type'] as String?,
        extractedContent: fileResult['extractedText'] as String?,
        uploadedUrl: publicUrl,
        extractedReceipt: receipt,
        savedReceiptId: dbId,
        isAccepted: true,
        statusMessage: 'Completed',
      );

      // Invalidate the lists provider to trigger dynamic refreshes across Dashboard, Receipts & Analytics
      _ref.invalidate(dbReceiptsListProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isAccepted: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', ''),
      );
      rethrow;
    } finally {
      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
      );
    }
  }

  /// Run the entire AI pipeline for multiple continuous pages (Batch Scan):
  /// Upload all page images in parallel -> run unified Gemini Vision analysis -> save to Supabase DB.
  Future<bool> acceptAndProcessBatchReceipt({
    required List<File> files,
    required String userId,
  }) async {
    final activeUid = FirebaseAuth.instance.currentUser?.uid ?? userId;
    if (activeUid.isEmpty || activeUid == 'guest') {
      throw Exception('Authentication required: Cannot save receipt without active user login.');
    }

    if (files.isEmpty) return false;

    if (files.length == 1) {
      return acceptAndProcessReceipt(userId: activeUid);
    }

    state = state.copyWith(
      isLoading: true,
      isProcessing: true,
      isAccepted: false,
      errorMessage: null,
      statusMessage: 'Preparing ${files.length} Pages...',
      capturedImages: files,
    );

    try {
      int totalSize = 0;
      for (final f in files) {
        totalSize += await f.length();
      }

      state = state.copyWith(statusMessage: 'Extracting Multi-Page Receipt...');

      // Centralized multi-page repository workflow
      final Map<String, dynamic> result = await _repository.processAndSaveBatchReceiptFlow(
        files: files,
        userId: activeUid,
        totalFileSize: totalSize,
      );

      final ReceiptModel receipt = result['receipt'] as ReceiptModel;
      final String dbId = result['id'] as String;
      final String publicUrl = result['imageUrl'] as String;

      state = state.copyWith(
        selectedImage: files.first,
        selectedFilePath: files.first.path,
        selectedFileName: 'batch_scan_${files.length}_pages.jpg',
        selectedFileType: 'Image',
        extractedContent: 'Multi-page batch receipt (${files.length} pages) extracted.',
        uploadedUrl: publicUrl,
        extractedReceipt: receipt,
        savedReceiptId: dbId,
        isAccepted: true,
        statusMessage: 'Completed',
      );

      // Invalidate the lists provider to trigger dynamic refreshes across Dashboard, Receipts & Analytics
      _ref.invalidate(dbReceiptsListProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isAccepted: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', ''),
      );
      rethrow;
    } finally {
      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
      );
    }
  }

  /// Runs ONLY extraction and uploads the file to storage without saving it to database.
  Future<ReceiptModel?> extractReceiptOnly({required String userId}) async {
    final activeUid = FirebaseAuth.instance.currentUser?.uid ?? userId;
    if (state.capturedImage == null) return null;
    
    // Return cached extraction only if performed for current session
    if (state.extractedReceipt != null && state.uploadedUrl != null) {
      return state.extractedReceipt;
    }

    state = state.copyWith(
      isLoading: true,
      isProcessing: true,
      isAccepted: false,
      errorMessage: null,
      statusMessage: 'Extracting Receipt...',
    );

    try {
      final File file = state.capturedImage!;
      
      // Parallel execution of file processor and AI extraction upload
      final fileResultFuture = _repository.processReceiptFile(file);
      final extractFuture = _repository.extractReceiptAndUpload(
        imageFile: file,
        userId: activeUid,
      );

      final results = await Future.wait([fileResultFuture, extractFuture]);
      final fileResult = results[0];
      final extractResult = results[1];

      final ReceiptModel receipt = extractResult['receipt'] as ReceiptModel;
      final String publicUrl = extractResult['imageUrl'] as String;
      
      state = state.copyWith(
        selectedImage: fileResult['file'] as File?,
        selectedFilePath: file.path,
        selectedFileName: fileResult['name'] as String?,
        selectedFileType: fileResult['type'] as String?,
        extractedContent: fileResult['extractedText'] as String?,
        uploadedUrl: publicUrl,
        extractedReceipt: receipt,
        isAccepted: false,
        statusMessage: 'Analyzing Products...',
      );

      return receipt;
    } catch (e) {
      state = state.copyWith(
        isAccepted: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', ''),
      );
      rethrow;
    } finally {
      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
      );
    }
  }

  /// Runs multi-page extraction and uploads all pages without saving to database immediately.
  Future<ReceiptModel?> extractBatchReceiptOnly({
    required List<File> files,
    required String userId,
  }) async {
    final activeUid = FirebaseAuth.instance.currentUser?.uid ?? userId;
    if (files.isEmpty) return null;

    if (files.length == 1) {
      state = state.copyWith(capturedImage: files.first);
      return extractReceiptOnly(userId: activeUid);
    }

    state = state.copyWith(
      isLoading: true,
      isProcessing: true,
      isAccepted: false,
      errorMessage: null,
      statusMessage: 'Extracting ${files.length} Pages with AI...',
      capturedImages: files,
      capturedImage: files.first,
    );

    try {
      final extractResult = await _repository.extractBatchReceiptAndUpload(
        files: files,
        userId: activeUid,
      );

      final ReceiptModel receipt = extractResult['receipt'] as ReceiptModel;
      final String publicUrl = extractResult['imageUrl'] as String;

      state = state.copyWith(
        selectedImage: files.first,
        selectedFilePath: files.first.path,
        selectedFileName: 'batch_scan_${files.length}_pages.jpg',
        selectedFileType: 'Image',
        extractedContent: 'Multi-page batch receipt (${files.length} pages)',
        uploadedUrl: publicUrl,
        extractedReceipt: receipt,
        isAccepted: false,
        statusMessage: 'Analyzing Products...',
      );

      return receipt;
    } catch (e) {
      state = state.copyWith(
        isAccepted: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', ''),
      );
      rethrow;
    } finally {
      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
      );
    }
  }

  /// Saves the already extracted receipt inside state to the database.
  Future<bool> saveExtracted({required String userId}) async {
    final activeUid = FirebaseAuth.instance.currentUser?.uid ?? userId;
    if (activeUid.isEmpty || activeUid == 'guest') {
      throw Exception('Authentication required: Cannot save receipt without active user login.');
    }

    final receipt = state.extractedReceipt;
    final publicUrl = state.uploadedUrl;
    if (receipt == null || publicUrl == null) {
      state = state.copyWith(
        errorMessage: 'Receipt data or uploaded image URL is missing. Please try scanning again.',
      );
      return false;
    }

    // Performance Optimization: Prevent redundant database save if already saved
    if (state.savedReceiptId != null) {
      return true;
    }

    state = state.copyWith(
      isLoading: true,
      isProcessing: true,
      errorMessage: null,
      statusMessage: 'Saving Receipt...',
    );

    try {
      int? size;
      if (state.capturedImages != null && state.capturedImages!.isNotEmpty) {
        int sum = 0;
        for (final f in state.capturedImages!) {
          sum += await f.length();
        }
        size = sum;
      } else if (state.capturedImage != null) {
        size = await state.capturedImage!.length();
      }
      final dbId = await _repository.saveExtractedReceiptFlow(
        receipt,
        publicUrl,
        activeUid,
        originalFileName: state.selectedFileName,
        fileSize: size,
      );

      state = state.copyWith(
        savedReceiptId: dbId,
        isAccepted: true,
        isProcessing: false,
        isLoading: false,
        statusMessage: 'Completed',
      );

      if (kDebugMode) print('Saved receipt $dbId for authenticated user $activeUid');

      // Invalidate providers to trigger dynamic refreshes across all screens
      _ref.invalidate(dbReceiptsListProvider);
      _ref.invalidate(dbWarrantiesProvider);
      _ref.invalidate(notificationNotifierProvider);
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', '');
      if (kDebugMode) print('[saveExtracted Error] $err');
      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: err,
      );
      return false;
    }
  }

  /// Deletes the old receipt cascade and saves the new receipt.
  Future<bool> replaceExisting({
    required String oldReceiptId,
    required String? oldImageUrl,
    required String userId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isProcessing: true,
      errorMessage: null,
    );

    try {
      if (kDebugMode) print('Replacing receipt');
      await _repository.deleteReceiptCascade(
        receiptId: oldReceiptId,
        userId: userId,
        imageUrl: oldImageUrl,
      );

      final success = await saveExtracted(userId: userId);
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', ''),
      );
      return false;
    }
  }

  /// Capture image from camera using legacy ImageSource method
  Future<void> captureImageFromCamera() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final file = await _repository.scanFromCamera();
      if (file != null) {
        state = state.copyWith(
          capturedImage: file,
          selectedImage: file,
          selectedFilePath: file.path,
          selectedFileName: file.path.split('/').last,
          selectedFileType: 'Image',
          extractedContent: 'Receipt image captured.',
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', ''),
      );
    }
  }

  /// Select image from device gallery using legacy ImageSource method
  Future<void> selectImageFromGallery() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final file = await _repository.scanFromGallery();
      if (file != null) {
        state = state.copyWith(
          capturedImage: file,
          selectedImage: file,
          selectedFilePath: file.path,
          selectedFileName: file.path.split('/').last,
          selectedFileType: 'Image',
          extractedContent: 'Receipt image selected from gallery.',
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', ''),
      );
    }
  }

  /// Process raw camera preview frame photo File
  Future<void> processCapturedImage(File file) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final compressedFile = await _repository.compressImage(file);
      state = state.copyWith(
        capturedImage: compressedFile,
        selectedImage: compressedFile,
        selectedFilePath: compressedFile.path,
        selectedFileName: compressedFile.path.split('/').last,
        selectedFileType: 'Image',
        extractedContent: 'Camera frame captured and compressed.',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', ''),
      );
    }
  }

  /// Launch file picker, parse selected document, upload it, and save to Supabase database
  Future<bool> pickAndProcessFile({required String userId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final file = await _repository.selectReceiptFile();
      if (file == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Execute the centralized repository workflow:
      final Map<String, dynamic> result = await _repository.processAndSaveReceiptFlow(
        imageFile: file,
        userId: userId,
      );

      final ReceiptModel receipt = result['receipt'] as ReceiptModel;
      final String dbId = result['id'] as String;
      final String publicUrl = result['imageUrl'] as String;

      final fileResult = await _repository.processReceiptFile(file);

      state = state.copyWith(
        capturedImage: file,
        selectedImage: fileResult['file'] as File?,
        selectedFilePath: file.path,
        selectedFileName: fileResult['name'] as String?,
        selectedFileType: fileResult['type'] as String?,
        extractedContent: fileResult['extractedText'] as String? ?? 'No content extracted',
        uploadedUrl: publicUrl,
        extractedReceipt: receipt,
        savedReceiptId: dbId,
        isLoading: false,
      );

      // Invalidate the lists provider to trigger dynamic refreshes across Dashboard, Receipts & Analytics
      _ref.invalidate(dbReceiptsListProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', ''),
      );
      return false;
    }
  }

  /// Clear current scan state
  void clearState() {
    state = const ScanState();
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  final repository = ref.watch(scanRepositoryProvider);
  return ScanNotifier(repository, ref);
});
