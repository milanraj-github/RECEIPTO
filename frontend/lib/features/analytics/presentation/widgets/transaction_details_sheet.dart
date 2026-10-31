import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/features/analytics/data/services/financial_persistence_service.dart';
import 'package:receipto/features/analytics/domain/models/refund_model.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';

class TransactionDetailsSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> receipt;
  final VoidCallback onUpdated;

  const TransactionDetailsSheet({
    super.key,
    required this.receipt,
    required this.onUpdated,
  });

  @override
  ConsumerState<TransactionDetailsSheet> createState() => _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends ConsumerState<TransactionDetailsSheet> {
  bool _isDeleting = false;

  void _showRecordRefundDialog() {
    final double grandTotal = ReceiptModel.parseDouble(widget.receipt['grand_total']) ??
        ReceiptModel.parseDouble(widget.receipt['total']) ??
        0.0;
    final controller = TextEditingController(text: grandTotal.toStringAsFixed(2));
    final reasonController = TextEditingController(text: 'Item return / order refund');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Record Refund',
          style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Specify the refund amount received for this purchase.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                labelText: 'Refund Amount',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Reason for Refund',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final amt = double.tryParse(controller.text.trim());
              if (amt == null || amt <= 0 || amt > grandTotal) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Refund cannot exceed receipt total (${CurrencyFormatter.format(grandTotal)})')),
                );
                return;
              }

              final user = ref.read(firebaseAuthServiceProvider).currentUser;
              if (user != null) {
                final refund = ReceiptRefund(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  receiptId: widget.receipt['id'].toString(),
                  merchant: widget.receipt['merchant_name'] as String? ?? 'Merchant',
                  originalAmount: grandTotal,
                  refundAmount: amt,
                  refundDate: DateTime.now(),
                  reason: reasonController.text.trim(),
                  createdAt: DateTime.now(),
                );
                await ref.read(financialPersistenceServiceProvider).saveRefund(user.uid, refund);
                widget.onUpdated();
              }
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refund recorded successfully. Net spending updated.')),
                );
              }
            },
            child: const Text('Confirm Refund', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Delete Expense?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove this transaction record?',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final user = ref.read(firebaseAuthServiceProvider).currentUser;
        if (user != null) {
          final id = widget.receipt['id'].toString();
          await ref.read(receiptDatabaseServiceProvider).softDeleteReceipt(id, userId: user.uid);
          ref.invalidate(dbReceiptsListProvider);
          widget.onUpdated();
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaction deleted.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchant = widget.receipt['merchant_name'] as String? ?? 'Merchant';
    final date = widget.receipt['date'] as String? ?? 'Unknown date';
    final category = widget.receipt['category'] as String? ?? 'Other';
    final payment = widget.receipt['payment_method'] as String? ?? 'Other';
    final amt = ReceiptModel.parseDouble(widget.receipt['grand_total']) ??
        ReceiptModel.parseDouble(widget.receipt['total']) ??
        0.0;
    final discount = ReceiptModel.parseDouble(widget.receipt['discount']) ?? 0.0;
    final isManual = (widget.receipt['original_file_name'] == 'Manual Expense') ||
        (widget.receipt['image_url'] == null || widget.receipt['image_url'].toString().isEmpty);

    final lineItems = (widget.receipt['receipt_items'] as List<dynamic>?) ?? [];

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + (bottomPadding > 0 ? bottomPadding : 12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isManual ? Colors.orangeAccent.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isManual ? 'MANUAL EXPENSE' : 'SCANNED RECEIPT',
                        style: TextStyle(
                          color: isManual ? Colors.orangeAccent : AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Merchant & Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchant,
                        style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(amt),
                  style: GoogleFonts.hankenGrotesk(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Details card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Payment Method', payment),
                  if (discount > 0) ...[
                    const Divider(color: Colors.white10, height: 16),
                    _buildDetailRow('Discount Captured', CurrencyFormatter.format(discount), valueColor: AppColors.tertiary),
                  ],
                  if (widget.receipt['invoice_number'] != null && widget.receipt['invoice_number'].toString().isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 16),
                    _buildDetailRow('Invoice #', widget.receipt['invoice_number'].toString()),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Line items if present
            if (lineItems.isNotEmpty) ...[
              Text(
                'Purchased Items (${lineItems.length})',
                style: GoogleFonts.hankenGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...lineItems.map((item) {
                final pName = item['name'] as String? ?? 'Item';
                final pQty = (item['quantity'] as num?)?.toInt() ?? 1;
                final pPrice = ReceiptModel.parseDouble(item['total_price']) ??
                    ReceiptModel.parseDouble(item['price']) ??
                    0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$pQty x $pName',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(pPrice),
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Actions row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.assignment_return_outlined, size: 16),
                    label: const Text('Record Refund'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _showRecordRefundDialog,
                  ),
                ),
                const SizedBox(width: 10),
                if (!isManual) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('View Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/receipt-details/${widget.receipt['id']}');
                      },
                    ),
                  ),
                ] else ...[
                  IconButton(
                    icon: _isDeleting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: _isDeleting ? null : _handleDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildDetailRow(String label, String value, {Color valueColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13)),
        Text(value, style: GoogleFonts.inter(color: valueColor, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
