import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/scan/presentation/providers/scan_provider.dart';
import 'package:receipto/features/scan/data/repositories/scan_repository.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/duplicate_receipt_service.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/utils/warranty_eligibility_filter.dart';
import 'package:receipto/features/warranty/presentation/widgets/manual_warranty_modal.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_provider.dart';

class PreviewScanScreen extends ConsumerWidget {
  final File imageFile;

  const PreviewScanScreen({
    super.key,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Dark Blurred Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(imageFile),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),

          // 2. Entire Scrollable SafeArea Body
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top AppBar
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: scanState.isProcessing
                                ? null
                                : () {
                                    ref.read(scanProvider.notifier).resetCapturedImage();
                                    Navigator.of(context).pop();
                                  },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Preview Receipt',
                            style: GoogleFonts.hankenGrotesk(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image preview frame
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.55,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            clipBehavior: Clip.none,
                            maxScale: 4.5,
                            minScale: 1.0,
                            child: Hero(
                              tag: 'scan_preview_hero',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  imageFile,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Premium Bottom Glassmorphic Actions Panel
                      GlassCard(
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            // Retake Button (Left)
                            Expanded(
                              child: _buildActionBtn(
                                context: context,
                                label: 'Retake',
                                icon: Icons.replay_rounded,
                                color: Colors.white.withValues(alpha: 0.1),
                                textColor: Colors.white,
                                disabled: scanState.isProcessing,
                                onTap: () {
                                  ref.read(scanProvider.notifier).resetCapturedImage();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Use Receipt Button (Right)
                            Expanded(
                              child: _buildActionBtn(
                                context: context,
                                label: 'Use Receipt',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.secondary,
                                textColor: Colors.black,
                                disabled: scanState.isProcessing,
                                onTap: () async {
                                  final currentUser = ref.read(firebaseAuthServiceProvider).currentUser ?? FirebaseAuth.instance.currentUser;
                                  if (currentUser == null || currentUser.uid.isEmpty) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please log in to process receipts.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  final userId = currentUser.uid;

                                  Future<void> performExtraction() async {
                                    try {
                                      // 1. Direct fast AI extraction (includes receipt validation in a single roundtrip)
                                      ref.read(scanProvider.notifier).setProcessing(true, statusMessage: 'Extracting receipt with AI...');
                                      final receipt = await ref.read(scanProvider.notifier).extractReceiptOnly(userId: userId);
                                      if (receipt == null) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Unexpected error occurred.'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      // Validate receipt content from the unified extraction response
                                      if (!receipt.isValidReceipt) {
                                        ref.read(scanProvider.notifier).setProcessing(false);
                                        if (context.mounted) {
                                          _showInvalidReceiptDialog(context, ref, reason: receipt.invalidReason);
                                        }
                                        return;
                                      }

                                      if (!context.mounted) return;

                                      ref.read(scanProvider.notifier).setStatusMessage('Analyzing Products...');
                                      final originalFileName = imageFile.path.split('/').last.split('\\').last;
                                      final fileSizeFuture = imageFile.length();
                                      final rawText = ref.read(scanProvider).extractedContent;
                                      
                                      final fileSize = await fileSizeFuture;
                                      final dupResult = await ref.read(duplicateReceiptServiceProvider).checkDuplicate(
                                            receipt: receipt,
                                            userId: userId,
                                            fileName: originalFileName,
                                            fileSize: fileSize,
                                            rawText: rawText,
                                          );

                                      if (!context.mounted) return;

                                      if (dupResult.isDuplicate && dupResult.existingReceipt != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Possible Duplicate Detected!'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );

                                        _showDuplicateDialog(
                                          context,
                                          ref,
                                          receipt,
                                          dupResult.existingReceipt!,
                                          dupResult.matchReason ?? 'Matching parameters',
                                          userId,
                                        );
                                      } else {
                                        // 3. Smart Warranty Detection Processing (Case 1, Case 2, Case 3)
                                        ref.read(scanProvider.notifier).setStatusMessage('Detecting Warranty...');
                                        final List<ReceiptItemModel> manualEligibleItems = [];
                                        for (final item in receipt.items) {
                                          final hasExplicitExpiry = item.warrantyExpiry != null && item.warrantyExpiry!.trim().isNotEmpty;
                                          final hasWarrantyPeriod = item.warrantyPeriod != null && item.warrantyPeriod! > 0;
                                          if (!hasExplicitExpiry && !hasWarrantyPeriod) {
                                            if (WarrantyEligibilityFilter.isEligible(item.name, category: item.category ?? receipt.category)) {
                                              manualEligibleItems.add(item);
                                            }
                                          }
                                        }

                                        Future<void> executeFinalSave(List<ManualWarrantySelection> manualSelections) async {
                                          final activeUid = FirebaseAuth.instance.currentUser?.uid ?? userId;
                                          ref.read(scanProvider.notifier).setProcessing(true, statusMessage: 'Saving Receipt...');

                                          try {
                                            // 1. Insert receipt metadata and items into database under live activeUid
                                            final success = await ref.read(scanProvider.notifier).saveExtracted(userId: activeUid);
                                            if (!success) {
                                              ref.read(scanProvider.notifier).setProcessing(false);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(ref.read(scanProvider).errorMessage?.isNotEmpty == true
                                                        ? ref.read(scanProvider).errorMessage!
                                                        : 'Failed to save receipt. Please try again.'),
                                                    backgroundColor: Colors.redAccent,
                                                  ),
                                                );
                                              }
                                              return;
                                            }

                                            final dbId = ref.read(scanProvider).savedReceiptId;
                                            final publicUrl = ref.read(scanProvider).uploadedUrl ?? '';
                                            final merchantName = receipt.merchantName ?? 'Unknown Merchant';
                                            final purchaseDate = receipt.date ?? DateTime.now().toString().split(' ').first;

                                            // 2. Persist manual warranties into warranties table under live activeUid
                                            if (manualSelections.isNotEmpty && dbId != null) {
                                              ref.read(scanProvider.notifier).setStatusMessage('Saving Warranties...');
                                              await ref.read(scanRepositoryProvider).saveManualWarranties(
                                                receiptId: dbId,
                                                userId: activeUid,
                                                merchantName: merchantName,
                                                invoiceNumber: receipt.invoiceNumber,
                                                purchaseDate: purchaseDate,
                                                imageUrl: publicUrl,
                                                selections: manualSelections,
                                              );
                                            }

                                            // 3. Invalidate Riverpod providers to trigger dynamic refreshes across Dashboard, Warranty Tracker, Analytics & Details
                                            ref.invalidate(dbReceiptsListProvider);
                                            ref.invalidate(dbWarrantiesProvider);
                                            ref.invalidate(notificationNotifierProvider);

                                            ref.read(scanProvider.notifier).setProcessing(false);

                                            if (!context.mounted) return;

                                            // 4. Success SnackBar and clean navigation
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Receipt & Warranties saved successfully!'),
                                                backgroundColor: AppColors.primary,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );

                                            if (dbId != null && dbId.isNotEmpty) {
                                              context.pushReplacement('/receipts/details/$dbId');
                                            } else {
                                              context.go('/receipts');
                                            }
                                          } catch (e) {
                                            ref.read(scanProvider.notifier).setProcessing(false);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error saving receipt: ${e.toString().replaceAll('Exception: ', '')}'),
                                                backgroundColor: Colors.redAccent,
                                                duration: const Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        }

                                        if (manualEligibleItems.isNotEmpty) {
                                          ref.read(scanProvider.notifier).setProcessing(false);
                                          // Case 3: Display Manual Warranty Screen ONCE for all eligible products
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            barrierColor: Colors.black.withValues(alpha: 0.65),
                                            builder: (sheetContext) {
                                              return ManualWarrantyModal(
                                                eligibleItems: manualEligibleItems,
                                                purchaseDate: receipt.date ?? DateTime.now().toString().split(' ').first,
                                                merchantName: receipt.merchantName ?? 'Unknown Merchant',
                                                onSave: (selections) async {
                                                  Navigator.of(sheetContext).pop();
                                                  await executeFinalSave(selections);
                                                },
                                                onSkip: () async {
                                                  Navigator.of(sheetContext).pop();
                                                  await executeFinalSave([]);
                                                },
                                              );
                                            },
                                          );
                                        } else {
                                          // Case 1 & Case 2: Save automatically with zero user prompts
                                          await executeFinalSave([]);
                                        }
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      final errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', '');

                                      // Check if it's a 429 Quota Exceeded error
                                      final is429 = errorMessage.contains('limit has been reached') || errorMessage.contains('limit');

                                      if (is429) {
                                        // Display the 429 Quota dialog
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              backgroundColor: AppColors.background,
                                              title: Text(
                                                'AI Service Busy',
                                                style: GoogleFonts.hankenGrotesk(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                'The free Gemini API request limit has been reached.\n\nPlease wait a few moments and try again.\n\nRetry After:\n5 seconds',
                                                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(dialogContext).pop();
                                                  },
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.secondary,
                                                    foregroundColor: Colors.black,
                                                  ),
                                                  onPressed: () async {
                                                    Navigator.of(dialogContext).pop();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Retrying receipt analysis...'),
                                                        duration: Duration(seconds: 4),
                                                      ),
                                                    );
                                                    await Future.delayed(const Duration(seconds: 5));
                                                    performExtraction();
                                                  },
                                                  child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        // Regular error dialog
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              backgroundColor: AppColors.background,
                                              title: Text(
                                                'Analysis Failed',
                                                style: GoogleFonts.hankenGrotesk(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                errorMessage,
                                                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                                  child: const Text('OK', style: TextStyle(color: AppColors.secondary)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    }
                                  }

                                  await performExtraction();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Processing / OCR Loading Overlay with Dynamic Status
          if (scanState.isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: GlassCard(
                    borderRadius: AppRadius.lg,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.secondary,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          scanState.statusMessage ?? 'Analyzing Receipt...',
                          style: GoogleFonts.hankenGrotesk(
                            color: AppColors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildActionBtn({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: color == AppColors.secondary ? 0.1 : 0.05),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.hankenGrotesk(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDuplicateDialog(
    BuildContext context,
    WidgetRef ref,
    ReceiptModel newReceipt,
    Map<String, dynamic> existingReceipt,
    String matchReason,
    String userId,
  ) {
    final merchant = existingReceipt['merchant_name'] as String? ?? 'Unknown Merchant';
    final invoice = existingReceipt['invoice_number'] as String? ?? 'N/A';
    final date = existingReceipt['date'] as String? ?? 'Unknown Date';
    final currency = existingReceipt['currency'] as String? ?? '₹';
    final double amountValue = ReceiptModel.parseDouble(existingReceipt['grand_total']) ??
        ReceiptModel.parseDouble(existingReceipt['total']) ??
        0.0;
    final formattedAmount = CurrencyFormatter.format(amountValue, currency: currency);

    final existingImageUrl = existingReceipt['image_url'] as String?;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duplicate Receipt Found',
                              style: GoogleFonts.hankenGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'A similar receipt already exists.',
                              style: TextStyle(color: AppColors.outline, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Existing Record Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(2.0),
                          },
                          children: [
                            _buildTableRow('Merchant', merchant),
                            _buildTableRow('Invoice', invoice),
                            _buildTableRow('Purchase Date', date),
                            _buildTableRow('Amount', formattedAmount),
                          ],
                        ),
                        if (existingImageUrl != null && existingImageUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),
                          const Text(
                            'Existing Receipt Preview',
                            style: TextStyle(
                              color: AppColors.outline,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              existingImageUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 60,
                                color: Colors.white.withValues(alpha: 0.02),
                                child: const Icon(Icons.broken_image, color: AppColors.outline),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions Buttons Stack
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      if (kDebugMode) print('Replacing receipt');
                      Navigator.of(dialogContext).pop();
                      final success = await ref.read(scanProvider.notifier).replaceExisting(
                            oldReceiptId: existingReceipt['id'].toString(),
                            oldImageUrl: existingReceipt['image_url'] as String?,
                            userId: userId,
                          );
                      if (success && context.mounted) {
                        final dbId = ref.read(scanProvider).savedReceiptId;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Receipt Updated Successfully'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        context.push('/receipts/details/$dbId');
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Replace Existing', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      if (kDebugMode) print('Saving as new');
                      Navigator.of(dialogContext).pop();
                      final success = await ref.read(scanProvider.notifier).saveExtracted(userId: userId);
                      if (success && context.mounted) {
                        final dbId = ref.read(scanProvider).savedReceiptId;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved as new receipt!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        context.push('/receipts/details/$dbId');
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Save as New', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),

                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInvalidReceiptDialog(BuildContext context, WidgetRef ref, {String? reason}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Invalid Receipt',
            style: GoogleFonts.hankenGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            reason?.isNotEmpty == true
                ? reason!
                : 'The selected image is not recognized as a valid shopping receipt. Please upload a clear purchase receipt or invoice.',
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(scanProvider.notifier).resetCapturedImage();
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.sm,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.outline, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            value,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
