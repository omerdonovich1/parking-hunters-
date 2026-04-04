import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/locale_provider.dart';
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
      case 0: context.go('/');            break;
      case 1: context.go('/profile');     break;
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: AppTheme.bg,
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
        bottomNavigationBar: _FloatingPillNav(
          selectedIndex: index,
          onTap: _onTabTapped,
          s: ref.watch(appStringsProvider),
        ),
      ),
    );
  }
}

// ── Floating pill nav ─────────────────────────────────────────────────────────
class _FloatingPillNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final AppStrings s;

  const _FloatingPillNav({required this.selectedIndex, required this.onTap, required this.s});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavDef(icon: Icons.radar_rounded,          label: s.navHunt),
      _NavDef(icon: Icons.person_outline_rounded,  label: s.navProfile),
      _NavDef(icon: Icons.emoji_events_outlined,   label: s.navRanks),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.card.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppTheme.orange.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: _PillNavItem(
                      def: items[i],
                      selected: i == selectedIndex,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  final _NavDef def;
  final bool selected;

  const _PillNavItem({required this.def, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 18 : 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.orange.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(color: AppTheme.orange.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Icon(
            def.icon,
            color: selected ? AppTheme.orange : const Color(0xFF3A5A7A),
            size: 21,
          ),
        ),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            color: selected ? AppTheme.orange : const Color(0xFF3A5A7A),
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(def.label),
        ),
      ],
    );
  }
}

class _NavDef {
  final IconData icon;
  final String label;
  const _NavDef({required this.icon, required this.label});
}
