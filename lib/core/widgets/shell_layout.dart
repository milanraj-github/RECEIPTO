import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';

class ShellLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellLayout({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        child: SizedBox(
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Glassmorphic Navbar Container with Cosmic Prism luminous border
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GlassCard(
                  borderRadius: AppRadius.lg,
                  backgroundColor: AppColors.glassSurface.withValues(alpha: 0.88),
                  border: Border.all(
                    color: const Color(0xFF3867FF).withValues(alpha: 0.22),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.electricBlue.withValues(alpha: 0.08),
                      blurRadius: 24,
                    ),
                  ],
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: 66,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          index: 0,
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                        ),
                        _buildNavItem(
                          index: 1,
                          icon: Icons.receipt_long_outlined,
                          activeIcon: Icons.receipt_long_rounded,
                          label: 'Receipts',
                        ),
                        // Spacer for Floating Center Scan Button
                        const SizedBox(width: 68),
                        _buildNavItem(
                          index: 3,
                          icon: Icons.analytics_outlined,
                          activeIcon: Icons.analytics_rounded,
                          label: 'Analytics',
                        ),
                        _buildNavItem(
                          index: 4,
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Center Circular Scan Button with Cosmic Prism Glow
              Positioned(
                top: 0,
                child: _buildFloatingScanButton(currentIndex == 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = index == navigationShell.currentIndex;
    final color = isActive ? AppColors.laserCyan : AppColors.onSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(index),
        child: AnimatedScale(
          scale: isActive ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: isActive
                    ? BoxDecoration(
                        color: AppColors.laserCyan.withValues(alpha: 0.12),
                        borderRadius: AppRadius.full,
                      )
                    : null,
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: color,
                  size: 22,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: AppColors.laserCyan.withValues(alpha: 0.6),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: AppColors.laserCyan.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingScanButton(bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: isActive ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primaryBlueViolet,
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withValues(alpha: isActive ? 0.6 : 0.4),
                  blurRadius: isActive ? 22 : 16,
                  spreadRadius: isActive ? 3 : 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.prismMagenta.withValues(alpha: isActive ? 0.4 : 0.25),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => _onTap(2),
                customBorder: const CircleBorder(),
                splashColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(
                    isActive ? Icons.document_scanner : Icons.document_scanner_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Scan',
          style: GoogleFonts.inter(
            color: isActive ? AppColors.laserCyan : AppColors.onSurfaceVariant,
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
