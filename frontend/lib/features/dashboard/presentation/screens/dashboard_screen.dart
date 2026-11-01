import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/widgets/subtle_neural_mesh.dart';
import 'package:receipto/features/dashboard/presentation/widgets/sparkline_widget.dart';
import 'package:receipto/features/dashboard/presentation/widgets/receipt_list_item.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/core/services/currency_converter_service.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_provider.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/features/ai_assistant/presentation/widgets/cat_robot_avatar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase().trim()) {
      case 'grocery':
      case 'groceries':
        return Icons.shopping_cart;
      case 'food':
      case 'food & dining':
      case 'dining':
        return Icons.restaurant;
      case 'fuel':
        return Icons.local_gas_station;
      case 'shopping':
        return Icons.shopping_bag;
      case 'medical':
      case 'healthcare':
      case 'pharmacy':
        return Icons.medical_services;
      case 'bills':
      case 'utilities':
        return Icons.bolt;
      case 'electronics':
        return Icons.devices;
      case 'mobile & gadgets':
        return Icons.phone_android;
      case 'computers':
        return Icons.computer;
      case 'home appliances':
        return Icons.kitchen;
      case 'fashion':
        return Icons.checkroom;
      case 'furniture':
        return Icons.chair;
      case 'beauty & personal care':
        return Icons.face;
      case 'travel':
        return Icons.flight;
      case 'entertainment':
        return Icons.movie;
      case 'education':
        return Icons.school;
      case 'sports':
        return Icons.sports_soccer;
      case 'automotive':
        return Icons.directions_car;
      case 'accessories':
        return Icons.watch;
      case 'books':
        return Icons.book;
      case 'subscription':
        return Icons.subscriptions;
      case 'office supplies':
        return Icons.edit;
      default:
        return Icons.receipt_long;
    }
  }

  String _getGreetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return '👋 Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      return '👋 Good Afternoon,';
    } else {
      return '👋 Good Evening,';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(dbReceiptsListProvider);
    final warrantiesAsync = ref.watch(dbWarrantiesProvider);

    // Watch and consume pending notification tap navigation payload
    final pendingPayload = ref.watch(pendingNotificationPayloadProvider);
    if (pendingPayload != null && pendingPayload.isNotEmpty) {
      debugPrint('[DashboardScreen] Pending notification payload detected: $pendingPayload');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reset provider state to null first to avoid infinite navigation loop
        ref.read(pendingNotificationPayloadProvider.notifier).state = null;
        // Retrieve service instance and handle routing with full logging
        final notiService = ref.read(notificationServiceProvider);
        notiService.handleNotificationTapPayloadWithRef(pendingPayload, ref, context);
      });
    }

    double totalSaved = 0.0;
    final List<Map<String, dynamic>> allRows = receiptsAsync.value ?? [];
    final DateTime now = DateTime.now();

    // 7-month spending trend (index 0 is 6 months ago, index 6 is current month)
    final List<double> monthlyTotals = List.filled(7, 0.0);
    int currentMonthReceiptCount = 0;

    DateTime? parseReceiptDate(Map<String, dynamic> r) {
      final rawDate = r['date']?.toString().trim();
      if (rawDate != null && rawDate.isNotEmpty) {
        final parsed = DateTime.tryParse(rawDate);
        if (parsed != null) return parsed;
        final parts = rawDate.split(RegExp(r'[/.-]'));
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) return DateTime(y, m, d);
          } else if (parts[2].length == 4) {
            final d = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final y = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) {
              if (m > 12 && d <= 12) return DateTime(y, d, m);
              return DateTime(y, m, d);
            }
          }
        }
      }
      final rawCreated = r['created_at']?.toString().trim();
      if (rawCreated != null && rawCreated.isNotEmpty) {
        final parsed = DateTime.tryParse(rawCreated);
        if (parsed != null) return parsed;
      }
      return null;
    }

    for (final r in allRows) {
      final String cur = (r['currency'] as String?) ?? '₹';
      final double rawAmt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
      final double amt = CurrencyConverterService.convertToInr(rawAmt, currency: cur);
      final double rawDisc = ReceiptModel.parseDouble(r['discount']) ?? 0.0;
      final double disc = CurrencyConverterService.convertToInr(rawDisc, currency: cur);
      totalSaved += disc;

      final rDate = parseReceiptDate(r) ?? now;
      for (int i = 0; i < 7; i++) {
        final targetMonth = DateTime(now.year, now.month - (6 - i), 1);
        if (rDate.year == targetMonth.year && rDate.month == targetMonth.month) {
          monthlyTotals[i] += amt;
          if (i == 6) {
            currentMonthReceiptCount++;
          }
          break;
        }
      }
    }

    final double currentMonthSpending = monthlyTotals[6];
    final double prevMonthSpending = monthlyTotals[5];

    final double maxMonthlySpend = monthlyTotals.reduce((a, b) => a > b ? a : b);
    final List<double> sparklineHeights = monthlyTotals.map((val) {
      if (val <= 0 || maxMonthlySpend <= 0) return 0.08;
      return (val / maxMonthlySpend).clamp(0.18, 1.0);
    }).toList();

    final List<String> monthLabels = List.generate(7, (i) {
      final target = DateTime(now.year, now.month - (6 - i), 1);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[target.month - 1];
    });

    final List<WarrantyModel> warranties = warrantiesAsync.value ?? [];
    final protectedProductsCount = warranties.length;
    final activeCount = warranties.where((w) => w.isActive).length;
    final expiringSoonCount = warranties.where((w) => w.isExpiringSoon).length;
    final expiredCount = warranties.where((w) => w.isExpired).length;

    final List<ReceiptData> recentReceipts = allRows.map((row) {
      final double amt = ReceiptModel.parseDouble(row['grand_total']) ?? ReceiptModel.parseDouble(row['total']) ?? 0.0;
      final String category = row['category'] as String? ?? 'Other';
      return ReceiptData(
        id: row['id'].toString(),
        merchant: row['merchant_name'] as String? ?? 'Unknown Merchant',
        date: row['date'] as String? ?? 'Unknown Date',
        amount: amt, // Positive value for clean formatted presentation
        category: category,
        icon: _getCategoryIcon(category),
        currency: row['currency'] as String?,
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle Living Neural Mesh background
          const Positioned.fill(
            child: IgnorePointer(
              child: SubtleNeuralMesh(),
            ),
          ),
          // Background content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar Space
                  _buildHeader(context, ref),
                  const SizedBox(height: 24),

                  // Greeting Info
                  _buildGreeting(context, ref),
                  const SizedBox(height: 24),

                  // Monthly Spending Hero Card
                  _buildMonthlySpendingCard(
                    context: context,
                    spending: currentMonthSpending,
                    prevMonthSpending: prevMonthSpending,
                    receiptCount: currentMonthReceiptCount,
                    sparklineHeights: sparklineHeights,
                    monthlyAmounts: monthlyTotals,
                    monthLabels: monthLabels,
                  ),
                  const SizedBox(height: 24),

                  // Stats Grid (Total Saved & Receipts Scanned)
                  _buildStatsGrid(context, totalSaved, recentReceipts.length),
                  const SizedBox(height: 24),

                  // Warranty Overview Premium Glass Card
                  Builder(
                    builder: (context) {
                      final List<WarrantyModel> nonExpiredWarranties = warranties.where((w) => w.status != 'EXPIRED').toList();
                      nonExpiredWarranties.sort((a, b) {
                        try {
                          final da = DateTime.parse(a.expiryDate);
                          final db = DateTime.parse(b.expiryDate);
                          return da.compareTo(db);
                        } catch (_) {
                          return 0;
                        }
                      });
                      final nextExpiring = nonExpiredWarranties.isNotEmpty ? nonExpiredWarranties.first : null;

                      return _buildWarrantyOverviewCard(
                        context,
                        total: protectedProductsCount,
                        active: activeCount,
                        expiring: expiringSoonCount,
                        expired: expiredCount,
                        nextExpiring: nextExpiring,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // AI Suggestions Card
                  _buildAISuggestion(
                    context: context,
                    suggestion: _generateAISuggestion(
                      allRows: allRows,
                      warranties: warranties,
                      currentMonthSpending: currentMonthSpending,
                      prevMonthSpending: prevMonthSpending,
                      totalSaved: totalSaved,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Receipts Title & List
                  _buildRecentReceiptsHeader(context),
                  const SizedBox(height: 16),
                  _buildReceiptList(context, recentReceipts),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Greeting widget displaying time-based greeting and user name
  Widget _buildGreeting(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthServiceProvider).currentUser;
    final displayName = user?.displayName ?? '';
    final firstName = displayName.trim().isNotEmpty ? displayName.trim().split(' ').first : 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreetingPrefix(),
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            firstName,
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your spending and protect your warranties.',
          style: AppFonts.geist(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Custom App Bar Header Row
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Receipto',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        
        ref.watch(unreadNotificationsCountProvider) > 0
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      onPressed: () => context.push('/notifications'),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${ref.watch(unreadNotificationsCountProvider)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.onSurface,
                    size: 22,
                  ),
                  onPressed: () => context.push('/notifications'),
                ),
              ),
      ],
    );
  }

  // Monthly Spending Glass Card with Dynamic Sparkline and Trend
  Widget _buildMonthlySpendingCard({
    required BuildContext context,
    required double spending,
    required double prevMonthSpending,
    required int receiptCount,
    required List<double> sparklineHeights,
    List<double>? monthlyAmounts,
    List<String>? monthLabels,
  }) {
    final textTheme = Theme.of(context).textTheme;

    // Determine dynamic trend badge details
    final IconData badgeIcon;
    final Color badgeColor;
    final String badgeText;

    if (prevMonthSpending > 0) {
      final double diff = spending - prevMonthSpending;
      final double pct = (diff / prevMonthSpending) * 100;
      if (pct > 0) {
        badgeIcon = Icons.trending_up;
        badgeColor = const Color(0xFFF59E0B);
        badgeText = '+${pct.toStringAsFixed(1)}% vs last month';
      } else if (pct < 0) {
        badgeIcon = Icons.trending_down;
        badgeColor = AppColors.tertiary;
        badgeText = '${pct.toStringAsFixed(1)}% vs last month';
      } else {
        badgeIcon = Icons.trending_flat;
        badgeColor = AppColors.onSurfaceVariant;
        badgeText = '0.0% vs last month';
      }
    } else {
      if (receiptCount > 0) {
        badgeIcon = Icons.receipt_long_outlined;
        badgeColor = AppColors.tertiary;
        badgeText = '$receiptCount ${receiptCount == 1 ? 'receipt' : 'receipts'} this month';
      } else {
        badgeIcon = Icons.calendar_today_outlined;
        badgeColor = AppColors.onSurfaceVariant;
        badgeText = 'No spending this month';
      }
    }

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          // Decorative background gradient blur blob
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spending Amount Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Spending',
                      style: textTheme.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(spending),
                        style: textTheme.displayLg.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            badgeIcon,
                            color: badgeColor,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            maxLines: 1,
                            style: textTheme.labelMd.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Sparkline graph bounded flexibly on the right
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 120, minWidth: 80),
                  height: 72,
                  child: SparklineWidget(
                    heights: sparklineHeights,
                    amounts: monthlyAmounts,
                    labels: monthLabels,
                    maxHeight: 36,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quick statistics grid
  Widget _buildStatsGrid(BuildContext context, double totalSaved, int scannedCount) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Total Saved
          Expanded(
            child: GlassCard(
              borderRadius: AppRadius.lg,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.tertiary.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.savings_outlined,
                      color: AppColors.tertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Saved',
                        style: textTheme.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.format(totalSaved),
                          style: textTheme.headlineLg.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Card 2: Receipts Scanned
          Expanded(
            child: GlassCard(
              borderRadius: AppRadius.lg,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.secondary.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipts Scanned',
                        style: textTheme.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$scannedCount',
                          style: textTheme.headlineLg.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dynamic AI Suggestion Data Container
  _AISuggestionInfo _generateAISuggestion({
    required List<Map<String, dynamic>> allRows,
    required List<WarrantyModel> warranties,
    required double currentMonthSpending,
    required double prevMonthSpending,
    required double totalSaved,
  }) {
    // 1. Critical Urgency: Check for warranties expiring soon
    final expiringSoon = warranties.where((w) => w.isExpiringSoon).toList();
    if (expiringSoon.isNotEmpty) {
      final w = expiringSoon.first;
      int? daysLeft;
      try {
        final exp = DateTime.parse(w.expiryDate);
        daysLeft = exp.difference(DateTime.now()).inDays;
      } catch (_) {}
      final String timeStr = (daysLeft != null && daysLeft >= 0) ? 'in $daysLeft days' : 'soon';
      return _AISuggestionInfo(
        before: 'Warranty Alert: Your warranty for ',
        highlight: w.productName,
        after: ' expires $timeStr. Consider checking claim terms.',
        highlightColor: const Color(0xFFF59E0B),
      );
    }

    // 2. Spending by category breakdown
    final Map<String, double> categorySpending = {};
    for (final r in allRows) {
      final double amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
      final String cat = (r['category'] as String?)?.trim() ?? 'Other';
      categorySpending[cat] = (categorySpending[cat] ?? 0.0) + amt;
    }

    String topCategory = '';
    double topCatSpend = 0.0;
    categorySpending.forEach((cat, spend) {
      if (spend > topCatSpend) {
        topCatSpend = spend;
        topCategory = cat;
      }
    });

    final double totalAll = categorySpending.values.fold(0.0, (sum, val) => sum + val);

    if (totalAll > 0 && topCategory.isNotEmpty) {
      if (categorySpending.length > 1) {
        final int pct = ((topCatSpend / totalAll) * 100).round();
        return _AISuggestionInfo(
          before: 'Smart Tip: You spent $pct% of your budget on ',
          highlight: topCategory,
          after: ' (${CurrencyFormatter.format(topCatSpend)}). Consider setting a category limit.',
          highlightColor: AppColors.secondary,
        );
      } else {
        return _AISuggestionInfo(
          before: 'Smart Tip: You spent ${CurrencyFormatter.format(topCatSpend)} on ',
          highlight: topCategory,
          after: '. Keep your digital receipts backed up for warranty claims.',
          highlightColor: AppColors.secondary,
        );
      }
    }

    // 3. Month-over-month trend if prior data exists
    if (prevMonthSpending > 0) {
      final double diff = currentMonthSpending - prevMonthSpending;
      final int pct = ((diff.abs() / prevMonthSpending) * 100).round();
      if (diff > 0) {
        return _AISuggestionInfo(
          before: 'Spending Trend: Your spending is up $pct% vs last month on ',
          highlight: topCategory.isNotEmpty ? topCategory : 'Purchases',
          after: '. Try setting a monthly budget limit.',
          highlightColor: const Color(0xFFF59E0B),
        );
      } else if (diff < 0) {
        return _AISuggestionInfo(
          before: 'Great Job: You spent $pct% less than last month! You are saving more on ',
          highlight: topCategory.isNotEmpty ? topCategory : 'Purchases',
          after: '. Keep up the smart financial habits.',
          highlightColor: AppColors.tertiary,
        );
      }
    }

    // 4. Discounts / Total Saved highlight
    if (totalSaved > 0) {
      return _AISuggestionInfo(
        before: 'Savings Highlight: You have saved a total of ',
        highlight: CurrencyFormatter.format(totalSaved),
        after: ' in discounts and promotions across your receipts!',
        highlightColor: AppColors.tertiary,
      );
    }

    // 5. Active warranties protection
    if (warranties.isNotEmpty) {
      final int count = warranties.length;
      return _AISuggestionInfo(
        before: 'Protection Active: You have ',
        highlight: '$count ${count == 1 ? 'product' : 'products'}',
        after: ' protected with digital receipts for stress-free warranty claims.',
        highlightColor: AppColors.secondary,
      );
    }

    // 6. Zero receipts state
    return const _AISuggestionInfo(
      before: 'Smart Tip: Tap the ',
      highlight: 'Scan button',
      after: ' below to digitize your bills and unlock real AI financial insights.',
      highlightColor: AppColors.primary,
    );
  }

  // AI suggestion dialog styled container with dynamic content
  Widget _buildAISuggestion({
    required BuildContext context,
    required _AISuggestionInfo suggestion,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: Stack(
          children: [
            // Custom Gradient Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.35),
                      AppColors.cardSurface,
                      const Color(0xFF005236).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Heading row
                  Row(
                    children: [
                      const CatRobotAvatar(size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'AI SUGGESTIONS',
                        style: textTheme.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  // Content text with dynamic highlight
                  RichText(
                    text: TextSpan(
                      style: textTheme.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: suggestion.before),
                        TextSpan(
                          text: suggestion.highlight,
                          style: TextStyle(
                            color: suggestion.highlightColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: suggestion.after),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push('/ai-assistant'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          'Ask AI Assistant',
                          style: textTheme.labelMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header row for recent receipts
  Widget _buildRecentReceiptsHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Receipts',
          style: textTheme.headlineMd.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        TextButton(
          onPressed: () {
            final navigationShell = StatefulNavigationShell.of(context);
            navigationShell.goBranch(1);
          },
          child: Text(
            'View All',
            style: textTheme.labelMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Vertical transaction/receipts list
  Widget _buildReceiptList(BuildContext context, List<ReceiptData> receipts) {
    if (receipts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No recent receipts found.',
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: receipts.length > 5 ? 5 : receipts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = receipts[index];
        return ReceiptListItem(
          data: item,
          onTap: () {
            context.push('/receipts/details/${item.id}');
          },
        );
      },
    );
  }

  Widget _buildWarrantyOverviewCard(
    BuildContext context, {
    required int total,
    required int active,
    required int expiring,
    required int expired,
    required WarrantyModel? nextExpiring,
  }) {
    return GestureDetector(
      onTap: () => context.push('/warranties'),
      child: GlassCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Warranty Protection',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildWarrantyStatItem('Protected', '$total', Colors.white)),
                Expanded(child: _buildWarrantyStatItem('Active', '$active', Colors.greenAccent)),
                Expanded(child: _buildWarrantyStatItem('Expiring', '$expiring', Colors.orangeAccent)),
                Expanded(child: _buildWarrantyStatItem('Expired', '$expired', Colors.redAccent)),
              ],
            ),
            if (nextExpiring != null) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.orangeAccent,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next Expiring:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nextExpiring.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${WarrantyUtils.calculateDaysRemaining(nextExpiring.expiryDate)} Days Left',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyStatItem(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.hankenGrotesk(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _AISuggestionInfo {
  final String before;
  final String highlight;
  final String after;
  final Color highlightColor;

  const _AISuggestionInfo({
    required this.before,
    required this.highlight,
    required this.after,
    this.highlightColor = AppColors.secondary,
  });
}


