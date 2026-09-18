import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/features/receipts/presentation/widgets/receipt_card_item.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/features/scan/data/repositories/scan_repository.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_provider.dart';

class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Map<String, GlobalKey<ReceiptCardItemState>> _cardKeys = {};

  final List<String> _categories = [
    'All',
    'Electronics',
    'Groceries',
    'Food & Dining',
    'Fuel',
    'Shopping',
    'Fashion',
    'Furniture',
    'Home Appliances',
    'Healthcare',
    'Medical',
    'Pharmacy',
    'Beauty & Personal Care',
    'Travel',
    'Entertainment',
    'Education',
    'Utilities',
    'Office Supplies',
    'Sports',
    'Automotive',
    'Accessories',
    'Books',
    'Mobile & Gadgets',
    'Computers',
    'Subscription',
    'Others',
  ];

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase().trim()) {
      case 'grocery':
      case 'groceries':
        return Icons.shopping_cart;
      case 'food':
      case 'food & dining':
        return Icons.restaurant;
      case 'fuel':
        return Icons.local_gas_station;
      case 'shopping':
        return Icons.shopping_bag;
      case 'medical':
      case 'healthcare':
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'beauty & personal care':
        return Icons.face;
      case 'travel':
        return Icons.flight;
      case 'entertainment':
        return Icons.movie;
      case 'education':
        return Icons.school;
      case 'utilities':
      case 'bills':
        return Icons.bolt;
      case 'office supplies':
        return Icons.edit;
      case 'sports':
        return Icons.sports_soccer;
      case 'automotive':
        return Icons.directions_car;
      case 'accessories':
        return Icons.watch;
      case 'books':
        return Icons.book;
      case 'mobile & gadgets':
        return Icons.phone_android;
      case 'computers':
        return Icons.computer;
      case 'subscription':
        return Icons.subscriptions;
      case 'electronics':
        return Icons.devices;
      case 'fashion':
        return Icons.checkroom;
      case 'furniture':
        return Icons.chair;
      case 'home appliances':
        return Icons.kitchen;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSecureDelete(
    BuildContext context,
    ReceiptInventoryItem item,
    GlobalKey<ReceiptCardItemState> cardKey,
  ) async {
    // 1. Premium glass confirmation dialog to move to Recycle Bin
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Delete Receipt?',
          style: GoogleFonts.hankenGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Move this receipt to Recycle Bin?\nYou can restore it within 30 days before it is permanently deleted.',
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.sm,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Move to Bin',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete != true || !context.mounted) return;

    // 2. Trigger scale and fade exit animation on the card
    await cardKey.currentState?.animateOut();

    if (!context.mounted) return;

    // 3. Perform soft delete
    try {
      final user = ref.read(firebaseAuthServiceProvider).currentUser;
      final userId = user?.uid ?? '';
      await ref.read(scanRepositoryProvider).softDeleteReceipt(item.id, userId: userId);

      // Invalidate the active receipts, recycle bin, warranties, and notification providers
      ref.invalidate(dbReceiptsListProvider);
      ref.invalidate(recycleBinProvider);
      ref.invalidate(dbWarrantiesProvider);
      ref.invalidate(notificationNotifierProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt moved to Recycle Bin'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      // Rollback: reverse the animation if database update fails
      cardKey.currentState?.resetAnimation();

      if (context.mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed:\n$errorMsg'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final receiptsAsync = ref.watch(dbReceiptsListProvider);
    final warrantiesAsync = ref.watch(dbWarrantiesProvider);

    final List<WarrantyModel> warranties = warrantiesAsync.value ?? [];

    final List<ReceiptInventoryItem> allItems = receiptsAsync.value?.map((row) {
      final double amt = ReceiptModel.parseDouble(row['grand_total']) ?? ReceiptModel.parseDouble(row['total']) ?? 0.0;
      final String category = row['category'] as String? ?? 'Other';
      final String idStr = row['id'].toString();

      final receiptWarranties = warranties.where((w) => w.receiptId == idStr).toList();
      final hasWarranty = receiptWarranties.isNotEmpty;
      final warrantyStatus = hasWarranty ? receiptWarranties.first.status : null;

      String? warrantyLabel;
      if (hasWarranty) {
        if (receiptWarranties.length > 1) {
          warrantyLabel = '${receiptWarranties.length} Products Protected';
        } else {
          final w = receiptWarranties.first;
          if (w.status == 'EXPIRED') {
            warrantyLabel = 'Warranty expired';
          } else {
            final days = WarrantyUtils.calculateDaysRemaining(w.expiryDate);
            if (w.status == 'EXPIRING SOON' || w.status == 'EXPIRING_SOON') {
              warrantyLabel = 'Warranty expires in $days days';
            } else {
              warrantyLabel = '1 Product Protected';
            }
          }
        }
      }

      return ReceiptInventoryItem(
        id: idStr,
        merchant: row['merchant_name'] as String? ?? 'Unknown Merchant',
        date: row['date'] as String? ?? 'Unknown Date',
        amount: amt,
        category: category,
        matchScore: 100,
        icon: _getCategoryIcon(category),
        currency: row['currency'] as String?,
        hasWarranty: hasWarranty,
        warrantyStatus: warrantyStatus,
        warrantyLabel: warrantyLabel,
      );
    }).toList() ?? [];

    final filteredItems = allItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' || 
          item.category.toLowerCase() == _selectedCategory.toLowerCase() ||
          (_selectedCategory.toLowerCase() == 'groceries' && item.category.toLowerCase() == 'grocery') ||
          (_selectedCategory.toLowerCase() == 'food & dining' && item.category.toLowerCase() == 'food') ||
          (_selectedCategory.toLowerCase() == 'healthcare' && item.category.toLowerCase() == 'medical');
      
      final receiptWarranties = warranties.where((w) => w.receiptId == item.id).toList();
      final matchesWarrantyProduct = receiptWarranties.any((w) =>
          w.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (w.brand != null && w.brand!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (w.model != null && w.model!.toLowerCase().contains(_searchQuery.toLowerCase())));

      final matchesSearch = item.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          matchesWarrantyProduct;

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Title Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.base),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Receipto',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                        onPressed: () => context.push('/notifications'),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          StatefulNavigationShell.of(context).goBranch(4);
                        },
                        child: Builder(
                          builder: (context) {
                            final user = ref.watch(firebaseAuthServiceProvider).currentUser;
                            final photoURL = user?.photoURL;
                            final hasPhoto = photoURL != null && photoURL.isNotEmpty;
                            return Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    hasPhoto ? photoURL : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Chips (Sticky)
            Container(
              color: AppColors.background.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: Column(
                children: [
                  // Search Box
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            cursorColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: GoogleFonts.inter(
                              color: AppColors.onSurface,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search merchants or categories...',
                              hintStyle: GoogleFonts.inter(
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Redesigned Category Filter Chips Row
                  _buildCategoryFilterRow(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Receipts List Container
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'No receipts found matching filters.',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.gutter,
                        right: AppSpacing.gutter,
                        bottom: 110,
                      ),
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final key = _cardKeys.putIfAbsent(item.id, () => GlobalKey<ReceiptCardItemState>());
                        return ReceiptCardItem(
                          key: key,
                          item: item,
                          onTap: () {
                            // GoRouter detail push passing ID
                            context.push('/receipts/details/${item.id}');
                          },
                          onDelete: () => _handleSecureDelete(context, item, key),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow(BuildContext context) {
    const defaultChips = ['All', 'Electronics', 'Groceries', 'Food'];

    final isDefaultSelected = defaultChips.any(
      (c) => c.toLowerCase() == _selectedCategory.toLowerCase() ||
             (_selectedCategory.toLowerCase() == 'food & dining' && c.toLowerCase() == 'food') ||
             (_selectedCategory.toLowerCase() == 'grocery' && c.toLowerCase() == 'groceries')
    );

    final List<String> visibleChips = [
      'All',
      'Electronics',
      'Groceries',
      'Food',
      if (isDefaultSelected) '+ More ▼' else '$_selectedCategory ▼',
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleChips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chipText = visibleChips[index];
          final isMoreChip = chipText.contains('▼');
          final isCustomSelected = !isDefaultSelected && index == 4;

          final bool isSelected;
          if (chipText == 'All') {
            isSelected = _selectedCategory == 'All';
          } else if (chipText == 'Food') {
            isSelected = _selectedCategory.toLowerCase() == 'food' || _selectedCategory.toLowerCase() == 'food & dining';
          } else if (chipText == 'Groceries') {
            isSelected = _selectedCategory.toLowerCase() == 'groceries' || _selectedCategory.toLowerCase() == 'grocery';
          } else if (isCustomSelected) {
            isSelected = true;
          } else {
            isSelected = chipText.toLowerCase() == _selectedCategory.toLowerCase();
          }

          final displayLabel = chipText.replaceAll(' ▼', '');

          return GestureDetector(
            onTap: () {
              if (isMoreChip) {
                _showCategoriesBottomSheet(context);
              } else {
                setState(() {
                  _selectedCategory = chipText;
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.primaryBlueCyan : null,
                color: isSelected
                    ? null
                    : (isMoreChip
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.cardSurface.withValues(alpha: 0.85)),
                borderRadius: AppRadius.full,
                border: isSelected
                    ? null
                    : Border.all(
                        color: isMoreChip
                            ? AppColors.primary.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayLabel,
                    style: AppFonts.geist(
                      color: isSelected
                          ? AppColors.onPrimary
                          : (isMoreChip ? AppColors.primary : AppColors.onSurface),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                  if (isMoreChip) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isSelected ? AppColors.onPrimary : AppColors.primary,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCategoriesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: AppRadius.full,
                ),
              ),
              const SizedBox(height: 16),
              
              // Bottom Sheet Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.category_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Categories',
                          style: GoogleFonts.hankenGrotesk(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
              
              // Selectable Category List
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat.toLowerCase() == _selectedCategory.toLowerCase() ||
                        (_selectedCategory == 'Food' && cat == 'Food & Dining') ||
                        (_selectedCategory == 'Food & Dining' && cat == 'Food') ||
                        (_selectedCategory == 'Groceries' && cat == 'Grocery') ||
                        (_selectedCategory == 'Grocery' && cat == 'Groceries') ||
                        (_selectedCategory == 'Healthcare' && cat == 'Medical') ||
                        (_selectedCategory == 'Medical' && cat == 'Healthcare');

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        borderRadius: AppRadius.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: AppRadius.md,
                            border: isSelected
                                ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(cat),
                                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  cat,
                                  style: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : AppColors.onSurface,
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}


