import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/services/currency_converter_service.dart';

class ReceiptInventorySubItem {
  final String name;
  final double price;
  final int quantity;
  final String category;

  ReceiptInventorySubItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.category,
  });
}

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
  final List<ReceiptInventorySubItem> items;

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
    this.items = const [],
  });

  /// A mixed-category receipt is a receipt containing at least two products assigned to different categories.
  bool get isMixedCategory {
    if (items.length < 2) return false;
    final distinctCategories = items
        .map((i) => canonicalCategory(i.category))
        .where((c) => c.isNotEmpty && c.toLowerCase() != 'others' && c.toLowerCase() != 'other')
        .toSet();
    return distinctCategories.length >= 2;
  }

  /// Canonicalizes category names so related sub-disciplines align consistently.
  static String canonicalCategory(String cat) {
    final lower = cat.trim().toLowerCase();
    if (lower == 'computers' || lower == 'mobile & gadgets' || lower == 'electronics') {
      return 'Electronics';
    }
    if (lower == 'food' || lower == 'food & dining') {
      return 'Food';
    }
    if (lower == 'groceries' || lower == 'grocery') {
      return 'Groceries';
    }
    if (lower == 'beauty & personal care' || lower == 'beauty') {
      return 'Beauty';
    }
    if (lower == 'healthcare' || lower == 'medical' || lower == 'pharmacy') {
      return 'Healthcare';
    }
    return cat.trim();
  }

  /// Checks if an item's category matches the selected category filter
  static bool isCategoryMatch(String itemCategory, String selectedCategory) {
    if (selectedCategory == 'All') return true;
    final lowerItem = itemCategory.trim().toLowerCase();
    final lowerSelected = selectedCategory.trim().toLowerCase();
    if (lowerItem == lowerSelected) return true;

    final canItem = canonicalCategory(itemCategory).toLowerCase();
    final canSelected = canonicalCategory(selectedCategory).toLowerCase();
    return canItem == canSelected;
  }
}

class ReceiptCardItem extends StatefulWidget {
  final ReceiptInventoryItem item;
  final String? selectedCategory;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ReceiptCardItem({
    super.key,
    required this.item,
    this.selectedCategory,
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

  Widget _buildSubItemRow(
    BuildContext context,
    ReceiptInventorySubItem subItem,
    bool isMatching,
  ) {
    if (isMatching) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.accentCyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.accentCyan.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                subItem.category,
                style: GoogleFonts.inter(
                  color: AppColors.accentCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subItem.quantity > 1 ? '${subItem.name} (x${subItem.quantity})' : subItem.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              CurrencyFormatter.format(subItem.price, currency: widget.item.currency),
              style: GoogleFonts.inter(
                color: AppColors.accentCyan,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                subItem.category,
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subItem.quantity > 1 ? '${subItem.name} (x${subItem.quantity})' : subItem.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              CurrencyFormatter.format(subItem.price, currency: widget.item.currency),
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isMixedActive = widget.item.isMixedCategory &&
        widget.selectedCategory != null &&
        widget.selectedCategory != 'All';

    final Widget headerRow = Row(
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
                  color: AppColors.cardSurfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  widget.item.icon,
                  color: AppColors.accentCyan,
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

        // Amount and three-dot options menu perfectly aligned
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
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
                if (CurrencyConverterService.isForeign(widget.item.currency)) ...[
                  const SizedBox(height: 2),
                  Text(
                    CurrencyConverterService.formatConvertedInr(widget.item.amount, currency: widget.item.currency),
                    style: GoogleFonts.hankenGrotesk(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (isMixedActive) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: AppRadius.full,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          color: AppColors.primary,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Mixed Receipt',
                          style: AppFonts.geist(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(width: 2),
              SizedBox(
                width: 28,
                height: 36,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
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
            ],
          ],
        ),
      ],
    );

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
              child: isMixedActive
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        headerRow,
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 8),
                        ...widget.item.items.map((subItem) {
                          final bool isMatching = ReceiptInventoryItem.isCategoryMatch(
                            subItem.category,
                            widget.selectedCategory!,
                          );
                          return _buildSubItemRow(context, subItem, isMatching);
                        }),
                      ],
                    )
                  : headerRow,
            ),
          ),
        ),
      ),
    );
  }
}
