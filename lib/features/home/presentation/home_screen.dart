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

  const _FloatingPillNav(
      {required this.selectedIndex, required this.onTap, required this.s});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavDef(icon: Icons.radar_rounded,         iconFilled: Icons.radar_rounded,           label: s.navHunt),
      _NavDef(icon: Icons.person_outline_rounded, iconFilled: Icons.person_rounded,          label: s.navProfile),
      _NavDef(icon: Icons.emoji_events_outlined,  iconFilled: Icons.emoji_events_rounded,    label: s.navRanks),
    ];
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(28, 0, 28, (bottomPad > 0 ? bottomPad : 16) + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              // two-tone layered background — richer depth
              gradient: LinearGradient(
                colors: [
                  AppTheme.card.withValues(alpha: 0.92),
                  AppTheme.surface.withValues(alpha: 0.88),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 48,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Sliding active background pill
                _SlidingIndicator(
                  selectedIndex: selectedIndex,
                  itemCount: items.length,
                ),
                Row(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animates a blurred pill behind the active nav item.
class _SlidingIndicator extends StatelessWidget {
  final int selectedIndex;
  final int itemCount;
  const _SlidingIndicator(
      {required this.selectedIndex, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final itemW = constraints.maxWidth / itemCount;
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        left: itemW * selectedIndex + 8,
        top: 10,
        bottom: 10,
        width: itemW - 16,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.orange.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.orange.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.orange.withValues(alpha: 0.18),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      );
    });
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            selected ? def.iconFilled : def.icon,
            key: ValueKey(selected),
            color: selected ? AppTheme.orange : const Color(0xFF2E4A66),
            size: 22,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: selected ? AppTheme.orange : const Color(0xFF2E4A66),
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: selected ? 0.3 : 0,
          ),
          child: Text(def.label),
        ),
      ],
    );
  }
}

class _NavDef {
  final IconData icon;
  final IconData iconFilled;
  final String label;
  const _NavDef(
      {required this.icon, required this.iconFilled, required this.label});
}
