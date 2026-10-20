import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/email_service.dart';
import 'package:receipto/core/services/reminder_engine.dart';
import 'package:receipto/core/services/app_lock_provider.dart';
import 'package:receipto/core/services/app_lock_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _cloudBackupEnabled = true;
  bool _devToolsExpanded = false;

  String _formatMemberSince(DateTime? creationTime) {
    if (creationTime == null) return 'Member since 2024';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthStr = months[creationTime.month - 1];
    return 'Member since $monthStr ${creationTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final lockNotifier = ref.read(appLockProvider.notifier);
    final receiptsAsync = ref.watch(dbReceiptsListProvider);
    final warrantiesAsync = ref.watch(dbWarrantiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header
              _buildHeader(context),
              const SizedBox(height: 20),

              // 2. User Profile Card
              _buildUserProfileCard(context),
              const SizedBox(height: 20),

              // 3. Live User Statistics Grid
              _buildStatsGrid(context, receiptsAsync, warrantiesAsync),
              const SizedBox(height: 28),

              // 4. 🔒 Security Section
              _buildSectionHeader(context, '🔒 Security'),
              const SizedBox(height: 10),
              _buildToggleSetting(
                title: 'Enable App Lock',
                subtitle: lockState.isEnabled
                    ? 'App lock active with custom PIN'
                    : 'Require custom PIN on launch',
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.primary,
                value: lockState.isEnabled,
                onChanged: (val) async {
                  if (val) {
                    _showSetupCustomPinDialog(context);
                  } else {
                    _promptPinOrBiometricToDisable(context);
                  }
                },
              ),
              if (lockState.isEnabled) ...[
                const SizedBox(height: 10),
                if (lockState.isBiometricAvailable)
                  _buildToggleSetting(
                    title: 'Use Fingerprint / Face Unlock',
                    subtitle: 'Quick biometric unlock option',
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.secondary,
                    value: lockState.isBiometricEnabled,
                    onChanged: (val) async {
                      await lockNotifier.setBiometricEnabled(val);
                    },
                  ),
                if (lockState.isBiometricAvailable) const SizedBox(height: 10),
                _buildActionSetting(
                  title: 'Change App PIN',
                  subtitle: 'Update your 4-digit PIN',
                  icon: Icons.key_outlined,
                  iconColor: AppColors.tertiary,
                  onTap: () => _showPinChangeDialog(context),
                ),
              ],
              const SizedBox(height: 24),

              // 5. ☁ Backup & Sync Section
              _buildSectionHeader(context, '☁ Backup & Sync'),
              const SizedBox(height: 10),
              _buildToggleSetting(
                title: 'Cloud Backup',
                subtitle: _cloudBackupEnabled ? 'Synced & Secured • Last backup just now' : 'Backup disabled',
                icon: Icons.cloud_done_outlined,
                iconColor: AppColors.primary,
                value: _cloudBackupEnabled,
                onChanged: (val) {
                  setState(() => _cloudBackupEnabled = val);
                },
              ),
              const SizedBox(height: 10),
              _buildActionSetting(
                title: 'Export Data',
                subtitle: 'Export records in PDF, Excel, or CSV format',
                icon: Icons.ios_share_rounded,
                iconColor: AppColors.secondary,
                onTap: () => _showInfoDialog(context, 'Export Data', 'Export options (PDF, Excel, CSV) are automatically formatted when downloading invoices or reports.'),
              ),
              const SizedBox(height: 24),

              // 6. 🧰 Developer Tools Section (Collapsible Accordion)
              _buildDeveloperToolsAccordion(context),
              const SizedBox(height: 24),

              // 7. 🗑 Data Section
              _buildSectionHeader(context, '🗑 Data Management'),
              const SizedBox(height: 10),
              _buildActionSetting(
                title: 'Recycle Bin',
                subtitle: 'View and restore deleted receipts',
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.primary,
                onTap: () => context.push('/profile/recycle-bin'),
              ),
              const SizedBox(height: 24),

              // 8. 🔔 Notifications Section
              _buildSectionHeader(context, '🔔 Notifications'),
              const SizedBox(height: 10),
              _buildActionSetting(
                title: 'Notification Settings',
                subtitle: 'Manage warranty reminder preferences',
                icon: Icons.notifications_none_outlined,
                iconColor: AppColors.primary,
                onTap: () => context.push('/profile/notification-settings'),
              ),
              const SizedBox(height: 24),

              // 9. ℹ About & Support Section
              _buildSectionHeader(context, 'ℹ About & Support'),
              const SizedBox(height: 10),
              _buildActionSetting(
                title: 'About Receipto',
                subtitle: 'AI-driven receipt & smart warranty system',
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primary,
                onTap: () => _showAboutDialog(context),
              ),
              const SizedBox(height: 10),
              _buildActionSetting(
                title: 'App Version',
                subtitle: 'v2.4.0 (Build 104) • Latest',
                icon: Icons.verified_outlined,
                iconColor: AppColors.secondary,
                onTap: () => _showInfoDialog(context, 'Receipto App Version', 'You are using Receipto Version 2.4.0 (Build 104). Your application is fully up to date.'),
              ),
              const SizedBox(height: 10),
              _buildActionSetting(
                title: 'Privacy Policy',
                subtitle: 'Read our end-to-end data security policy',
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.tertiary,
                onTap: () => _showInfoDialog(context, 'Privacy Policy', 'Receipto respects your data privacy. All receipts and extracted metadata are encrypted and tied strictly to your authenticated session.'),
              ),
              const SizedBox(height: 10),
              _buildActionSetting(
                title: 'Terms & Conditions',
                subtitle: 'Review terms of service',
                icon: Icons.description_outlined,
                iconColor: AppColors.onSurfaceVariant,
                onTap: () => _showInfoDialog(context, 'Terms & Conditions', 'By using Receipto, you agree to our standard terms of service regarding automated AI receipt processing and warranty tracking.'),
              ),
              const SizedBox(height: 10),
              _buildActionSetting(
                title: 'Help & FAQ',
                subtitle: 'Frequently asked questions & guides',
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.primary,
                onTap: () => _showInfoDialog(context, 'Help & FAQ', 'Q: How does Smart Warranty Detection work?\nA: Receipto uses AI OCR to extract product names and automatically computes warranty expiration dates from your receipt.'),
              ),
              const SizedBox(height: 10),
              _buildActionSetting(
                title: 'Contact Support',
                subtitle: 'receiptotechexplorers@gmail.com',
                icon: Icons.support_agent_rounded,
                iconColor: AppColors.secondary,
                onTap: () => _showContactSupportDialog(context),
              ),
              const SizedBox(height: 28),

              // 10. 🚪 Account & Logout
              _buildLogoutButton(context),
              const SizedBox(height: 24),

              // Footer app info
              _buildFooter(context),

              // Bottom navbar margin spacer
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  // Header App Title & Quick Avatar Indicator
  Widget _buildHeader(BuildContext context) {
    final user = ref.watch(firebaseAuthServiceProvider).currentUser;
    final photoURL = user?.photoURL;
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryBlueCyan,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.receipt_long_rounded, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Receipto',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              onPressed: () => context.push('/profile/notification-settings'),
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 4),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                image: DecorationImage(
                  image: NetworkImage(
                    hasPhoto ? photoURL : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Profile Header Card with Avatar, Badge, Full Name, Email, & Member Since
  Widget _buildUserProfileCard(BuildContext context) {
    final user = ref.watch(firebaseAuthServiceProvider).currentUser;
    final photoURL = user?.photoURL;
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;
    final name = user?.displayName ?? 'Receipto User';
    final email = user?.email ?? 'No email associated';
    final memberSince = _formatMemberSince(user?.metadata.creationTime);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: GlassCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Centered Large Verified Avatar
            Stack(
              alignment: Alignment.center,
              children: [
                // Glowing background aura ring
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.tertiary,
                        AppColors.primary,
                      ],
                    ),
                  ),
                ),
                // Main Avatar image box
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardSurface,
                    border: Border.all(color: AppColors.background, width: 3),
                    image: DecorationImage(
                      image: NetworkImage(
                        hasPhoto ? photoURL : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Verified Badge Shield overlay
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile info text labels
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Member Since & Verified Badges row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  memberSince,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: AppRadius.full,
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'VERIFIED USER',
                        style: GoogleFonts.inter(
                          color: Colors.greenAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Live User Statistics Summary Grid
  Widget _buildStatsGrid(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> receiptsAsync,
    AsyncValue<List<dynamic>> warrantiesAsync,
  ) {
    final receiptsCount = receiptsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    final protectedProductsCount = receiptsAsync.maybeWhen(
      data: (list) {
        int count = 0;
        for (final r in list) {
          final items = r['receipt_items'] ?? r['items'];
          if (items is List) {
            count += items.length;
          }
        }
        return count;
      },
      orElse: () => 0,
    );

    final activeWarrantiesCount = warrantiesAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Row(
      children: [
        _buildStatBox(context, receiptsCount.toString(), 'Receipts Scanned', AppColors.primary),
        const SizedBox(width: 10),
        _buildStatBox(context, protectedProductsCount.toString(), 'Protected Products', AppColors.secondary),
        const SizedBox(width: 10),
        _buildStatBox(context, activeWarrantiesCount.toString(), 'Active Warranties', AppColors.tertiary),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: GlassCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header Title Label
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Toggle Switch setting widget
  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: AppColors.onSurface,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.onSurfaceVariant,
            inactiveTrackColor: AppColors.surfaceVariant,
          ),
        ],
      ),
    );
  }

  // Action Navigation setting widget
  Widget _buildActionSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        splashColor: iconColor.withValues(alpha: 0.15),
        highlightColor: iconColor.withValues(alpha: 0.05),
        child: GlassCard(
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              color: AppColors.onSurface,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Collapsible Developer Tools Accordion Tile
  Widget _buildDeveloperToolsAccordion(BuildContext context) {
    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _devToolsExpanded = !_devToolsExpanded);
              },
              borderRadius: AppRadius.lg,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.build_outlined, color: Colors.purpleAccent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developer Tools',
                              style: GoogleFonts.inter(
                                color: AppColors.onSurface,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Internal diagnostic & testing tools',
                              style: GoogleFonts.inter(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(
                      _devToolsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _devToolsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Column(
                children: [
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 10),
                  _buildActionSetting(
                    title: 'Test Notification',
                    subtitle: 'Trigger a test local notification',
                    icon: Icons.notifications_active_outlined,
                    iconColor: AppColors.primary,
                    onTap: () async {
                      await ref.read(notificationServiceProvider).showNotification(
                            id: 999,
                            title: 'Receipto Test',
                            body: 'This is a test warranty reminder notification.',
                          );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionSetting(
                    title: 'Send Test Email',
                    subtitle: 'Send a test email to your address',
                    icon: Icons.email_outlined,
                    iconColor: AppColors.secondary,
                    onTap: () async {
                      final user = ref.read(firebaseAuthServiceProvider).currentUser;
                      if (user != null && user.email != null && user.email!.isNotEmpty) {
                        try {
                          await ref.read(emailServiceProvider).sendTestEmail(
                                recipientEmail: user.email!,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test email sent successfully!')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Email failed: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No logged-in user email found.')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionSetting(
                    title: 'Run Warranty Engine',
                    subtitle: 'Trigger background scanning immediately',
                    icon: Icons.play_arrow_outlined,
                    iconColor: AppColors.tertiary,
                    onTap: () async {
                      final user = ref.read(firebaseAuthServiceProvider).currentUser;
                      if (user != null) {
                        try {
                          await ref.read(reminderEngineProvider).checkWarrantyReminders(
                                user.uid,
                                user.email,
                                user.displayName,
                              );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Warranty engine run completed! Check console logs.')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Engine failed: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No logged-in user found.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Logout Button with subtle red warning styling & confirmation
  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutConfirmationDialog(context),
        borderRadius: AppRadius.lg,
        splashColor: AppColors.error.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface.withValues(alpha: 0.85),
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.08),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Logout of Account',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Logout of Receipto?',
          style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out? Your receipt and warranty data remain safely encrypted on cloud servers.',
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(firebaseAuthServiceProvider).signOut(ref);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryBlueCyan,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.receipt_long_rounded, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipto AI',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Smart Warranty & Receipt System',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Text(
              'Receipto is an intelligent AI-driven application for extracting receipt metadata, parsing purchased line items, calculating dynamic warranty expirations, and sending automated push & email reminders.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          title,
          style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          body,
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    const supportEmail = 'receiptotechexplorers@gmail.com';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: AppColors.secondary),
            const SizedBox(width: 10),
            Text(
              'Contact Support',
              style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help or have questions? Reach out to our technical support team:',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      supportEmail,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Email'),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: supportEmail));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support email copied to clipboard!')),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSetupCustomPinDialog(BuildContext context) {
    String pin = '';
    String confirmPin = '';
    String error = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Create App PIN',
            style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a 4-digit security PIN:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (val) => pin = val,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, letterSpacing: 8),
                decoration: const InputDecoration(hintText: 'PIN', counterText: ''),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirm 4-digit PIN:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (val) => confirmPin = val,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, letterSpacing: 8),
                decoration: const InputDecoration(hintText: 'Confirm PIN', counterText: ''),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (pin.length != 4) {
                  setDialogState(() => error = 'PIN must be 4 digits.');
                  return;
                }
                if (pin != confirmPin) {
                  setDialogState(() => error = 'PINs do not match.');
                  return;
                }
                await ref.read(appLockProvider.notifier).setCustomPin(pin);
                await ref.read(appLockProvider.notifier).setAppLockEnabled(true);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom PIN set and App Lock enabled!')),
                  );
                }
              },
              child: const Text('Enable Lock', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _promptPinOrBiometricToDisable(BuildContext context) async {
    final lockState = ref.read(appLockProvider);
    final lockService = ref.read(appLockServiceProvider);

    if (lockState.isBiometricEnabled && lockState.isBiometricAvailable) {
      final bioSuccess = await lockService.authenticateBiometricsOnly(
        reason: 'Scan fingerprint or face to disable App Lock',
      );
      if (bioSuccess) {
        await ref.read(appLockProvider.notifier).setAppLockEnabled(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App Lock disabled successfully.')),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    String enteredPin = '';
    String error = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Disable App Lock',
            style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your 4-digit PIN to disable lock:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (val) => enteredPin = val,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, letterSpacing: 8),
                decoration: const InputDecoration(counterText: ''),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final valid = await lockService.verifyCustomPin(enteredPin);
                if (valid) {
                  await ref.read(appLockProvider.notifier).setAppLockEnabled(false);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App Lock disabled.')),
                    );
                  }
                } else {
                  setDialogState(() => error = 'Incorrect PIN.');
                }
              },
              child: const Text('Disable', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinChangeDialog(BuildContext context) {
    String currentPin = '';
    String newPin = '';
    String confirmNewPin = '';
    String error = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Change App PIN',
            style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current PIN:', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (val) => currentPin = val,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, letterSpacing: 6),
                  decoration: const InputDecoration(counterText: ''),
                ),
                const SizedBox(height: 10),
                Text('New 4-digit PIN:', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (val) => newPin = val,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, letterSpacing: 6),
                  decoration: const InputDecoration(counterText: ''),
                ),
                const SizedBox(height: 10),
                Text('Confirm New PIN:', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (val) => confirmNewPin = val,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, letterSpacing: 6),
                  decoration: const InputDecoration(counterText: ''),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final lockService = ref.read(appLockServiceProvider);
                final validCurrent = await lockService.verifyCustomPin(currentPin);
                if (!validCurrent) {
                  setDialogState(() => error = 'Current PIN is incorrect.');
                  return;
                }
                if (newPin.length != 4) {
                  setDialogState(() => error = 'New PIN must be 4 digits.');
                  return;
                }
                if (newPin != confirmNewPin) {
                  setDialogState(() => error = 'New PINs do not match.');
                  return;
                }
                await ref.read(appLockProvider.notifier).setCustomPin(newPin);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN updated successfully!')),
                  );
                }
              },
              child: const Text('Update PIN', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'Receipto v2.4.0 (Build 104)',
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 12, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              'Encrypted End-to-End • Multi-User Isolated',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
