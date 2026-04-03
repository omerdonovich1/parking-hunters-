import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/demo_provider.dart';
import '../../services/onboarding_service.dart';

/// Async provider — true once onboarding has been completed before.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  return OnboardingService().isOnboardingComplete();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingAsync = ref.watch(onboardingCompleteProvider);
  final isDemoMode = ref.watch(demoModeProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Demo mode bypasses all auth/onboarding requirements
      if (isDemoMode) {
        if (loc == '/splash' || loc == '/auth' || loc == '/onboarding') {
          return '/';
        }
        return null;
      }

      // Stay on splash while either auth or onboarding is still resolving
      if (authState.isLoading || onboardingAsync.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      final onboarded = onboardingAsync.value ?? false;
      final isLoggedIn = authState.value != null;

      // Not onboarded yet → onboarding (skip splash)
      if (!onboarded) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      // Onboarded but not logged in → auth
      if (!isLoggedIn) {
        return (loc == '/auth' || loc == '/onboarding') ? null : '/auth';
      }

      // Logged in + already onboarded — redirect away from splash/auth/onboarding
      if (loc == '/splash' || loc == '/auth' || loc == '/onboarding') {
        return '/';
      }

      return null;
    },
    refreshListenable: _RouterRefreshListenable(ref),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _SplashRouteWrapper(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const MapScreen(),
          ),
          GoRoute(
            path: '/report',
            builder: (_, __) => const ReportScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (_, __) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

/// Thin wrapper that shows the splash widget — no navigation logic of its own.
class _SplashRouteWrapper extends StatelessWidget {
  const _SplashRouteWrapper();

  @override
  Widget build(BuildContext context) {
    // Import inline to avoid a circular dep with core/widgets
    return _SplashWidget();
  }
}

class _SplashWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🅿️', style: TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Parking Hunter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hunt. Report. Conquer.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Triggers router re-evaluation when auth state, onboarding, or demo mode changes.
class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(onboardingCompleteProvider, (_, __) => notifyListeners());
    ref.listen(demoModeProvider, (_, __) => notifyListeners());
  }
}
