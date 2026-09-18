import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/utils/currency_formatter.dart';

class ReceiptInventoryItem {
  final String id;
  final String merchant;
  final String date;
  final double amount;
  final String category;
  final int matchScore;
  final IconData icon;
  final String? currency;
  final bool hasWarranty;
  final String? warrantyStatus;
  final String? warrantyLabel;

  ReceiptInventoryItem({
    required this.id,
    required this.merchant,
    required this.date,
    required this.amount,
    required this.category,
    required this.matchScore,
    required this.icon,
    this.currency,
    this.hasWarranty = false,
    this.warrantyStatus,
    this.warrantyLabel,
  });
}

class ReceiptCardItem extends StatefulWidget {
  final ReceiptInventoryItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ReceiptCardItem({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<ReceiptCardItem> createState() => ReceiptCardItemState();
}

class ReceiptCardItemState extends State<ReceiptCardItem> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Triggers the exit animation (fade and scale down)
  Future<void> animateOut() async {
    await _animationController.forward();
  }

  /// Resets the exit animation to normal state (reverts rollback)
  void resetAnimation() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
          child: GestureDetector(
            onTap: widget.onTap,
            child: GlassCard(
              borderRadius: AppRadius.lg,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon and merchant details
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.item.icon,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.merchant,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.hankenGrotesk(
                                      color: AppColors.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.item.date,
                                    style: textTheme.codeSm.copyWith(
                                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  if (widget.item.hasWarranty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: widget.item.warrantyStatus == 'EXPIRED'
                                                ? Colors.redAccent
                                                : (widget.item.warrantyStatus == 'EXPIRING SOON' || widget.item.warrantyStatus == 'EXPIRING_SOON'
                                                    ? Colors.orangeAccent
                                                    : Colors.greenAccent),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            widget.item.warrantyLabel ?? 'Product Protected',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: widget.item.warrantyStatus == 'EXPIRED'
                                                  ? Colors.redAccent
                                                  : (widget.item.warrantyStatus == 'EXPIRING SOON' || widget.item.warrantyStatus == 'EXPIRING_SOON'
                                                      ? Colors.orangeAccent
                                                      : Colors.greenAccent),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Amount and match indicator
                      Padding(
                        padding: const EdgeInsets.only(right: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                CurrencyFormatter.format(widget.item.amount, currency: widget.item.currency),
                                style: GoogleFonts.hankenGrotesk(
                                  color: AppColors.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                            // Match score indicator tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryContainer.withValues(alpha: 0.2),
                                borderRadius: AppRadius.full,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.bolt,
                                    color: AppColors.tertiary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.item.matchScore}% Match',
                                    style: AppFonts.geist(
                                      color: AppColors.tertiary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Three-dot overflow menu
                  if (widget.onDelete != null)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: GestureDetector(
                        onTap: () {}, // Prevent card onTap navigation
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                          color: AppColors.cardSurface,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.md,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              widget.onDelete!();
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete Receipt',
                                    style: GoogleFonts.inter(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
