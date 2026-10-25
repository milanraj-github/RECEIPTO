import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/widgets/nebula_background.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/features/warranty/presentation/widgets/warranty_calendar_view.dart';
import 'package:receipto/features/warranty/presentation/widgets/warranty_claim_modal.dart';

class WarrantyTrackerScreen extends ConsumerStatefulWidget {
  const WarrantyTrackerScreen({super.key});

  @override
  ConsumerState<WarrantyTrackerScreen> createState() => _WarrantyTrackerScreenState();
}

class _WarrantyTrackerScreenState extends ConsumerState<WarrantyTrackerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';
  bool _isCalendarView = false;

  final List<String> _statusFilters = ['All', 'Active', 'Expiring Soon', 'Expired'];
  
  final List<String> _categories = [
    'All',
    'Electronics',
    'Appliances',
    'Mobile',
    'Laptop',
    'Other'
  ];

  IconData _getProductIcon(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('laptop') || lower.contains('macbook') || lower.contains('computer') || lower.contains('notebook') || lower.contains('desktop') || lower.contains('pc ') || lower.contains('thinkpad')) {
      return Icons.laptop_chromebook;
    }
    if (lower.contains('phone') || lower.contains('mobile') || lower.contains('iphone') || lower.contains('pixel') || lower.contains('android') || lower.contains('galaxy') || lower.contains('oneplus') || lower.contains('redmi') || lower.contains('tablet') || lower.contains('ipad')) {
      return Icons.phone_android;
    }
    if (lower.contains('watch') || lower.contains('smartwatch') || lower.contains('band') || lower.contains('fitbit') || lower.contains('wearable')) {
      return Icons.watch;
    }
    if (lower.contains('tv') || lower.contains('television') || lower.contains('monitor') || lower.contains('screen') || lower.contains('display')) {
      return Icons.tv;
    }
    if (lower.contains('headphone') || lower.contains('earbud') || lower.contains('airdopes') || lower.contains('airpod') || lower.contains('earphone') || lower.contains('tws') || lower.contains('speaker') || lower.contains('soundbar') || lower.contains('audio') || lower.contains('rockerz') || lower.contains('buds')) {
      return Icons.headphones;
    }
    if (lower.contains('fridge') || lower.contains('refrigerator') || lower.contains('washing machine') || lower.contains('dryer') || lower.contains('oven') || lower.contains('microwave') || lower.contains('stove') || lower.contains('kitchen') || lower.contains('cooker') || lower.contains('ac') || lower.contains('air conditioner') || lower.contains('geyser') || lower.contains('heater') || lower.contains('purifier') || lower.contains('mixer') || lower.contains('grinder') || lower.contains('iron') || lower.contains('vacuum')) {
      return Icons.kitchen;
    }
    if (lower.contains('powerbank') || lower.contains('power bank') || lower.contains('charger') || lower.contains('cable') || lower.contains('adapter') || lower.contains('usb') || lower.contains('type-c')) {
      return Icons.battery_charging_full;
    }
    if (lower.contains('camera') || lower.contains('dslr') || lower.contains('webcam') || lower.contains('lens')) {
      return Icons.camera_alt;
    }
    if (lower.contains('keyboard') || lower.contains('mouse') || lower.contains('printer') || lower.contains('scanner') || lower.contains('ssd') || lower.contains('hard disk') || lower.contains('hdd')) {
      return Icons.memory;
    }
    return Icons.verified_user_outlined;
  }

  String _guessCategory(String productName) {
    final lower = productName.toLowerCase();

    // 1. Laptop & Computers
    if (lower.contains('laptop') ||
        lower.contains('macbook') ||
        lower.contains('computer') ||
        lower.contains('notebook') ||
        lower.contains('desktop') ||
        lower.contains('thinkpad') ||
        lower.contains('pc ') ||
        lower.contains('keyboard') ||
        lower.contains('mouse') ||
        lower.contains('printer') ||
        lower.contains('scanner') ||
        lower.contains('ssd') ||
        lower.contains('hard disk') ||
        lower.contains('hdd') ||
        lower.contains('ram ') ||
        lower.contains('processor') ||
        lower.contains('motherboard') ||
        lower.contains('graphics card') ||
        lower.contains('gpu') ||
        lower.contains('cpu')) {
      return 'Laptop';
    }

    // 2. Mobile & Mobile Accessories
    if (lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('iphone') ||
        lower.contains('pixel') ||
        lower.contains('android') ||
        lower.contains('ipad') ||
        lower.contains('tablet') ||
        lower.contains('galaxy') ||
        lower.contains('oneplus') ||
        lower.contains('redmi') ||
        lower.contains('xiaomi') ||
        lower.contains('realme') ||
        lower.contains('oppo') ||
        lower.contains('vivo') ||
        lower.contains('smartwatch') ||
        lower.contains('watch') ||
        lower.contains('band') ||
        lower.contains('powerbank') ||
        lower.contains('power bank') ||
        lower.contains('charger') ||
        lower.contains('adapter') ||
        lower.contains('cable') ||
        lower.contains('type-c') ||
        lower.contains('lightning') ||
        lower.contains('back cover') ||
        lower.contains('case')) {
      return 'Mobile';
    }

    // 3. Appliances & Home Equipment
    if (lower.contains('kettle') ||
        lower.contains('fridge') ||
        lower.contains('refrigerator') ||
        lower.contains('oven') ||
        lower.contains('microwave') ||
        lower.contains('otg') ||
        lower.contains('stove') ||
        lower.contains('cooktop') ||
        lower.contains('induction') ||
        lower.contains('kitchen') ||
        lower.contains('cooker') ||
        lower.contains('washing machine') ||
        lower.contains('dryer') ||
        lower.contains('washer') ||
        lower.contains('vacuum') ||
        lower.contains('air conditioner') ||
        lower.contains('ac ') ||
        lower.contains('split ac') ||
        lower.contains('inverter') ||
        lower.contains('geyser') ||
        lower.contains('water heater') ||
        lower.contains('purifier') ||
        lower.contains('ro ') ||
        lower.contains('water purifier') ||
        lower.contains('chimney') ||
        lower.contains('mixer') ||
        lower.contains('grinder') ||
        lower.contains('blender') ||
        lower.contains('air fryer') ||
        lower.contains('toaster') ||
        lower.contains('iron') ||
        lower.contains('cooler') ||
        lower.contains('fan') ||
        lower.contains('stabilizer')) {
      return 'Appliances';
    }

    // 4. Electronics, Audio & Gadgets
    if (lower.contains('tv') ||
        lower.contains('television') ||
        lower.contains('monitor') ||
        lower.contains('screen') ||
        lower.contains('headphone') ||
        lower.contains('earbud') ||
        lower.contains('earphone') ||
        lower.contains('airdopes') ||
        lower.contains('airpod') ||
        lower.contains('tws') ||
        lower.contains('rockerz') ||
        lower.contains('buds') ||
        lower.contains('speaker') ||
        lower.contains('soundbar') ||
        lower.contains('audio') ||
        lower.contains('amplifier') ||
        lower.contains('camera') ||
        lower.contains('dslr') ||
        lower.contains('lens') ||
        lower.contains('gopro') ||
        lower.contains('webcam') ||
        lower.contains('playstation') ||
        lower.contains('ps5') ||
        lower.contains('ps4') ||
        lower.contains('xbox') ||
        lower.contains('nintendo') ||
        lower.contains('console') ||
        lower.contains('controller') ||
        lower.contains('drone') ||
        lower.contains('projector') ||
        lower.contains('trimmer') ||
        lower.contains('shaver')) {
      return 'Electronics';
    }

    return 'Other';
  }

  int _getStatusPriority(String status) {
    switch (status.toUpperCase()) {
      case 'EXPIRING SOON':
      case 'EXPIRING_SOON':
        return 0;
      case 'ACTIVE':
        return 1;
      case 'EXPIRED':
        return 2;
      default:
        return 3;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.greenAccent;
      case 'EXPIRING SOON':
      case 'EXPIRING_SOON':
        return Colors.orangeAccent;
      case 'EXPIRED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warrantiesAsync = ref.watch(dbWarrantiesProvider);
    final receiptsAsync = ref.watch(dbReceiptsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Premium Nebula dynamic visual overlay
          const Positioned.fill(
            child: AnimatedNebulaBackground(opacity: 0.35),
          ),
          
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () async {
                ref.invalidate(dbWarrantiesProvider);
                ref.invalidate(dbReceiptsListProvider);
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Warranty Tracker',
                            style: GoogleFonts.hankenGrotesk(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // List / Calendar View Toggle Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isCalendarView ? Icons.view_list_rounded : Icons.calendar_month_rounded,
                                color: AppColors.secondary,
                                size: 22,
                              ),
                              tooltip: _isCalendarView ? 'Switch to List View' : 'Switch to Warranty Calendar',
                              onPressed: () {
                                setState(() {
                                  _isCalendarView = !_isCalendarView;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Warranties Content state loading
                  warrantiesAsync.when(
                    data: (warranties) {
                      if (_isCalendarView) {
                        return SliverToBoxAdapter(
                          child: WarrantyCalendarView(warranties: warranties),
                        );
                      }

                      final receipts = receiptsAsync.value ?? [];
                      
                      // 1. Calculate protected total values
                      double protectedValue = 0.0;
                      for (final w in warranties) {
                        if (w.status != 'EXPIRED' && w.receiptId != null) {
                          final match = receipts.firstWhere(
                            (r) => r['id'].toString() == w.receiptId,
                            orElse: () => {},
                          );
                          if (match.isNotEmpty) {
                            protectedValue += ReceiptModel.parseDouble(match['grand_total']) ?? 
                                ReceiptModel.parseDouble(match['total']) ?? 0.0;
                          }
                        }
                      }

                      final totalActive = warranties.where((w) => w.isActive).length;
                      final totalExpiring = warranties.where((w) => w.isExpiringSoon).length;
                      final totalExpired = warranties.where((w) => w.isExpired).length;

                      // 2. Filter list
                      var filteredList = warranties.where((item) {
                        final cat = _guessCategory(item.productName);
                        final matchesCategory = _selectedCategory == 'All' || cat == _selectedCategory;
                        
                        final matchesStatus = _selectedStatus == 'All' ||
                            (_selectedStatus == 'Active' && item.isActive) ||
                            (_selectedStatus == 'Expiring Soon' && item.isExpiringSoon) ||
                            (_selectedStatus == 'Expired' && item.isExpired) ||
                            item.status.toLowerCase().replaceAll('_', ' ') == _selectedStatus.toLowerCase();

                        final query = _searchQuery.toLowerCase().trim();
                        final matchesSearch = query.isEmpty ||
                            item.productName.toLowerCase().contains(query) ||
                            item.merchantName.toLowerCase().contains(query) ||
                            (item.brand != null && item.brand!.toLowerCase().contains(query)) ||
                            (item.invoiceNumber != null && item.invoiceNumber!.toLowerCase().contains(query));

                        return matchesCategory && matchesStatus && matchesSearch;
                      }).toList();

                      // 3. Sort list: Expiring soon -> Active -> Expired
                      filteredList.sort((a, b) {
                        final pa = _getStatusPriority(a.status);
                        final pb = _getStatusPriority(b.status);
                        if (pa != pb) return pa.compareTo(pb);
                        
                        try {
                          final da = DateTime.parse(a.expiryDate);
                          final db = DateTime.parse(b.expiryDate);
                          return da.compareTo(db);
                        } catch (_) {
                          return 0;
                        }
                      });

                      return SliverList(
                        delegate: SliverChildListDelegate([
                          // Summary Cards Row
                          _buildSummaryCards(
                            context: context,
                            active: totalActive,
                            expiring: totalExpiring,
                            expired: totalExpired,
                            protectedValue: protectedValue,
                          ),
                          const SizedBox(height: 16),

                          // Search Panel & Filters
                          _buildSearchBox(),
                          const SizedBox(height: 12),
                          _buildStatusChips(),
                          const SizedBox(height: 8),
                          _buildCategoryChips(),
                          const SizedBox(height: 16),

                          // List items
                          if (filteredList.isEmpty)
                            _buildEmptyState()
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final item = filteredList[index];
                                return _buildWarrantyCard(context, item);
                              },
                            ),
                        ]),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.secondary),
                      ),
                    ),
                    error: (err, _) => SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Error loading warranties: $err',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required BuildContext context,
    required int active,
    required int expiring,
    required int expired,
    required double protectedValue,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatBox('Active', '$active', Colors.greenAccent),
          const SizedBox(width: 10),
          _buildStatBox('Expiring Soon', '$expiring', Colors.orangeAccent),
          const SizedBox(width: 10),
          _buildStatBox('Expired', '$expired', Colors.redAccent),
          const SizedBox(width: 10),
          _buildStatBox('Protected Value', CurrencyFormatter.format(protectedValue), AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      child: GlassCard(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.hankenGrotesk(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: AppColors.secondary,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search product, brand, merchant...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14.5),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _statusFilters.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedStatus = status;
                  });
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.3),
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : Colors.white12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                }
              },
              selectedColor: AppColors.secondary.withValues(alpha: 0.3),
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.secondary.withValues(alpha: 0.5) : Colors.white12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWarrantyCard(BuildContext context, WarrantyModel item) {
    final statusColor = _getStatusColor(item.status);
    final daysRemaining = WarrantyUtils.calculateDaysRemaining(item.expiryDate);
    
    // Calculate progress ratio
    double progress = 0.0;
    try {
      final pDate = DateTime.parse(item.purchaseDate);
      final eDate = DateTime.parse(item.expiryDate);
      final totalDays = eDate.difference(pDate).inDays;
      if (totalDays > 0) {
        final daysUsed = DateTime.now().difference(pDate).inDays;
        progress = (daysUsed / totalDays).clamp(0.0, 1.0);
      }
    } catch (_) {}

    final countdownText = item.status == 'EXPIRED'
        ? 'Expired ${daysRemaining.abs()} Days Ago'
        : '$daysRemaining Days Left';

    final categoryIcon = _getProductIcon(item.productName);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: GlassCard(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row (Product Icon, Product Name, Brand, Status Badge)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.brand != null && item.brand!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.brand!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Animated Status Badge
                _buildStatusBadge(item.status, statusColor),
              ],
            ),
            const SizedBox(height: 16),

            // Middle info details
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.0),
                1: FlexColumnWidth(1.2),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableItem('Merchant', item.merchantName),
                    _buildTableItem('Warranty Period', '${item.warrantyPeriod} ${item.warrantyUnit}'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableItem('Purchase Date', item.purchaseDate),
                    _buildTableItem('Expiry Date', item.expiryDate),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Bottom Section (Countdown + Progress Bar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  countdownText,
                  style: GoogleFonts.hankenGrotesk(
                    color: statusColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.status == 'EXPIRED' ? '100% elapsed' : '${(progress * 100).toInt()}% elapsed',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Custom Animated Progress bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 600),
              builder: (context, val, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: val,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    color: statusColor,
                    minHeight: 6,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Buttons Actions Row
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shield_outlined, size: 15),
                    label: const Text(
                      'Claim Warranty',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      WarrantyClaimModal.show(context, item);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      context.push('/receipts/warranty/${item.id}');
                    },
                    child: const Text(
                      'Details',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                  ),
                ),
                if (item.receiptId != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Open Original Receipt',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: const Icon(Icons.receipt_long, color: AppColors.secondary, size: 18),
                    onPressed: () {
                      context.push('/receipts/details/${item.receiptId}');
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.verified_user_outlined, color: Colors.white.withValues(alpha: 0.15), size: 64),
            const SizedBox(height: 16),
            Text(
              'No warranties match your filters.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

extension OutlineBtnThemeExtension on ButtonStyle {
  Widget applyTo(Widget child) {
    return Theme(
      data: ThemeData(
        outlinedButtonTheme: OutlinedButtonThemeData(style: this),
      ),
      child: child,
    );
  }
}
