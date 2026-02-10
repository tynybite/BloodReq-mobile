import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/scroll_control_provider.dart';

import '../../../core/providers/language_provider.dart';

import '../../../core/constants/app_theme.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  List<_NavItem> _getNavItems(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: lang.getText('nav_home'),
        path: '/home',
      ),
      _NavItem(
        icon: Icons.water_drop_outlined,
        activeIcon: Icons.water_drop,
        label: lang.getText('nav_requests'),
        path: '/requests',
      ),
      _NavItem(
        icon: Icons.volunteer_activism_outlined,
        activeIcon: Icons.volunteer_activism,
        label: lang.getText('nav_funds'),
        path: '/fundraisers',
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: lang.getText('nav_profile'),
        path: '/profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _getNavItems(context);

    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: Consumer<ScrollControlProvider>(
        builder: (context, scrollProvider, child) {
          return AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            offset: scrollProvider.isBottomNavVisible
                ? Offset.zero
                : const Offset(0, 2), // Slide down out of view
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(
                bottom: 20,
              ), // Add explicit bottom margin since we extend body
              child: Row(
                children: [
                  // White pill with nav items
                  Expanded(
                    child: Container(
                      height: 68,
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: context.shadowColor,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          navItems.length,
                          (index) => _buildNavItem(index, navItems),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Plus button
                  _buildPlusButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, List<_NavItem> items) {
    final item = items[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        context.go(item.path);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon (no background)
          Icon(
            isSelected ? item.activeIcon : item.icon,
            color: isSelected ? AppColors.primary : AppColors.textTertiary,
            size: 26,
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlusButton() {
    return GestureDetector(
      onTap: () => context.push('/create-request'),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
