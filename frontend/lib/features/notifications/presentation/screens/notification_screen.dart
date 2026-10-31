import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/notifications/domain/models/notification_model.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  String _searchQuery = '';
  String _activeFilter = 'All'; // 'All', 'Unread', 'Read', 'Warranty', 'Email', 'System'

  @override
  void initState() {
    super.initState();
    // Automatically mark all loaded notifications as read upon opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).markAllAsRead();
    });
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'WARRANTY':
        return Icons.security_outlined;
      case 'EMAIL':
        return Icons.email_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'WARRANTY':
        return AppColors.primary;
      case 'EMAIL':
        return AppColors.secondary;
      default:
        return AppColors.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount New',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.outline),
            tooltip: 'Delete All',
            onPressed: () => _confirmDeleteAll(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search by product, merchant, or alert details...',
                hintStyle: const TextStyle(color: AppColors.outline),
                prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Unread'),
                _buildFilterChip('Read'),
                _buildFilterChip('Warranty'),
                _buildFilterChip('Email'),
                _buildFilterChip('System'),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: notificationsState.when(
              data: (list) {
                // Apply filter criteria
                var filtered = list.where((n) {
                  // Search query match
                  final matchQuery = n.title.toLowerCase().contains(_searchQuery) ||
                      n.message.toLowerCase().contains(_searchQuery);

                  if (!matchQuery) return false;

                  // Active Chip Filter Match
                  switch (_activeFilter) {
                    case 'Unread':
                      return !n.isRead;
                    case 'Read':
                      return n.isRead;
                    case 'Warranty':
                      return n.type.toUpperCase() == 'WARRANTY';
                    case 'Email':
                      return n.type.toUpperCase() == 'EMAIL';
                    case 'System':
                      return n.type.toUpperCase() == 'SYSTEM';
                    default:
                      return true;
                  }
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildDismissibleCard(item);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Failed to load notifications: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _activeFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _activeFilter = label;
            });
          }
        },
        selectedColor: AppColors.primaryContainer,
        backgroundColor: AppColors.inputBackground,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleCard(NotificationModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(item.id ?? UniqueKey().toString()),
        direction: DismissDirection.horizontal,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.green.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Mark Read', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.delete_outline, color: Colors.white),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe Right -> Mark Read
            if (item.id != null) {
              await ref.read(notificationNotifierProvider.notifier).markRead(item.id!);
            }
            return false; // Handled inline, don't dismiss card animation
          } else {
            // Swipe Left -> Delete
            return true;
          }
        },
        onDismissed: (direction) async {
          if (direction == DismissDirection.endToStart) {
            if (item.id != null) {
              await ref.read(notificationNotifierProvider.notifier).delete(item.id!);
            }
          }
        },
        child: _buildNotificationCard(item),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel item) {
    final typeColor = _getColorForType(item.type);
    final typeIcon = _getIconForType(item.type);

    return GestureDetector(
      onTap: () {
        if (item.warrantyId != null && item.warrantyId!.isNotEmpty) {
          context.push('/receipts/warranty/${item.warrantyId}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No warranty details linked to this message.')),
          );
        }
      },
      child: GlassCard(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon indicator bubble
          CircleAvatar(
            radius: 20,
            backgroundColor: typeColor.withValues(alpha: 0.15),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 14),

          // Message content text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getRelativeTime(item.createdAt),
                      style: const TextStyle(
                        color: AppColors.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: TextStyle(
                    color: item.isRead ? AppColors.onSurfaceVariant : AppColors.onSurface,
                    fontSize: 13,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.cardSurface.withValues(alpha: 0.5),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 40,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "We'll notify you about upcoming warranty expirations.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.outline,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: const Text('Delete All Alerts?'),
          content: const Text('Are you sure you want to clear your entire notifications history? This action is permanent.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
            ),
            TextButton(
              onPressed: () {
                ref.read(notificationNotifierProvider.notifier).deleteAll();
                Navigator.of(ctx).pop();
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
