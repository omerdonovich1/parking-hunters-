import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/profile_provider.dart';
import 'widgets/level_up_overlay.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Widget? child;
  const HomeScreen({super.key, this.child});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _levelUpValue;

  int _locationToIndex(String location) {
    if (location.startsWith('/profile'))     return 1;
    if (location.startsWith('/leaderboard')) return 2;
    return 0;
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0: context.go('/');             break;
      case 1: context.go('/profile');      break;
      case 2: context.go('/leaderboard'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(levelUpProvider, (_, newLevel) {
      if (newLevel != null) setState(() => _levelUpValue = newLevel);
    });

    final location = GoRouterState.of(context).uri.toString();
    final index    = _locationToIndex(location);
    final isMap    = index == 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: AppTheme.bg,
        // No app bar — map and screens control their own
        body: Stack(
          children: [
            widget.child ?? const SizedBox.shrink(),
            if (_levelUpValue != null)
              LevelUpOverlay(
                newLevel: _levelUpValue!,
                onDismiss: () {
                  setState(() => _levelUpValue = null);
                  ref.read(levelUpProvider.notifier).state = null;
                },
              ),
          ],
        ),
        // Floating glass bottom nav
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: isMap
                      ? AppTheme.card.withValues(alpha: 0.9)
                      : Theme.of(context).cardColor.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isMap ? AppTheme.cardBorder : AppTheme.dividerLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMap
                          ? Colors.black.withValues(alpha: 0.35)
                          : AppTheme.blue.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(icon: Icons.map_rounded,          activeIcon: Icons.map,          label: 'Hunt',   index: 0, selected: index),
                    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', index: 1, selected: index),
                    _NavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events,  label: 'Ranks',  index: 2, selected: index),
                  ].map((item) => Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTapped(item.index),
                      behavior: HitTestBehavior.opaque,
                      child: _buildNavItem(item, index),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int selectedIndex) {
    final selected = item.index == selectedIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppTheme.blue.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              selected ? item.activeIcon : item.icon,
              color: selected ? AppTheme.blue : const Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              color: selected ? AppTheme.blue : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selected;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.selected});
}
