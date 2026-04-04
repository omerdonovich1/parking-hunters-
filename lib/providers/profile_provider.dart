import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../models/daily_mission_model.dart';
import '../services/firestore_service.dart';
import '../services/gamification_service.dart';
import '../services/fcm_service.dart';
import 'auth_provider.dart';
import 'demo_provider.dart';
import 'map_provider.dart';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService();
});

class UserProfileNotifier extends StateNotifier<AppUser?> {
  final FirestoreService _firestoreService;
  final GamificationService _gamificationService;

  UserProfileNotifier(this._firestoreService, this._gamificationService)
      : super(null);

  Future<void> loadUser(String userId) async {
    final user = await _firestoreService.getUser(userId);
    if (user != null) {
      final level = _gamificationService.calculateLevel(user.points);
      final earnedBadges = _gamificationService.getEarnedBadges(user);
      state = user.copyWith(
        level: level,
        badgeIds: earnedBadges.map((b) => b.id).toList(),
      );
    }
  }

  Future<void> createUserFromAuth({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
    FcmService? fcmService,
  }) async {
    final existing = await _firestoreService.getUser(uid);
    if (existing != null) {
      state = existing;
      fcmService?.initialize(uid);
      return;
    }
    final newUser = AppUser(
      id: uid,
      email: email,
      displayName: displayName.isNotEmpty ? displayName : email.split('@').first,
      photoUrl: photoUrl,
      points: 0,
      level: 1,
      badgeIds: [],
      totalReports: 0,
      createdAt: DateTime.now(),
    );
    await _firestoreService.createUser(newUser);
    state = newUser;
    fcmService?.initialize(uid);
  }

  Future<void> updatePoints(int additionalPoints, {Ref? ref}) async {
    if (state == null) return;
    final oldLevel = state!.level;
    final newPoints = state!.points + additionalPoints;
    final newLevel = _gamificationService.calculateLevel(newPoints);
    state = state!.copyWith(points: newPoints, level: newLevel);
    await _firestoreService.updateUserPoints(state!.id, additionalPoints);
    _checkAndAwardBadges();
    // Signal level-up to UI
    if (newLevel > oldLevel && ref != null) {
      ref.read(levelUpProvider.notifier).state = newLevel;
    }
  }

  void clearUser() => state = null;

  Future<void> incrementReports({Ref? ref}) async {
    if (state == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = state!.lastReportDate;
    final lastDay =
        last != null ? DateTime(last.year, last.month, last.day) : null;

    // Streak logic
    int newStreak = state!.currentStreak;
    if (lastDay == null) {
      newStreak = 1;
    } else if (today.difference(lastDay).inDays == 1) {
      newStreak += 1;
    } else if (today.difference(lastDay).inDays == 0) {
      // already reported today — keep streak
    } else {
      newStreak = 1;
    }

    // Daily mission progress — reset if new day
    final isNewDay = lastDay == null || today.difference(lastDay).inDays >= 1;
    final newTodayCount = isNewDay ? 1 : state!.todayReportsCount + 1;

    state = state!.copyWith(
      totalReports: state!.totalReports + 1,
      currentStreak: newStreak,
      longestStreak:
          newStreak > state!.longestStreak ? newStreak : state!.longestStreak,
      lastReportDate: now,
      todayReportsCount: newTodayCount,
    );

    // Check daily mission completion and award bonus XP once
    final mission = _gamificationService.getDailyMission();
    final missionJustCompleted = newTodayCount == mission.targetCount;
    final alreadyCompletedToday = state!.lastMissionCompletedDate != null &&
        DateTime(state!.lastMissionCompletedDate!.year,
                state!.lastMissionCompletedDate!.month,
                state!.lastMissionCompletedDate!.day) ==
            today;

    if (missionJustCompleted && !alreadyCompletedToday) {
      state = state!.copyWith(lastMissionCompletedDate: now);
      await updatePoints(mission.xpReward, ref: ref);
    }

    await _firestoreService.updateUser(state!);
    _checkAndAwardBadges();
  }

  void _checkAndAwardBadges() {
    if (state == null) return;
    final earned = _gamificationService
        .getEarnedBadges(state!)
        .map((b) => b.id)
        .toList();
    // Only update if new badges were earned
    if (earned.length > state!.badgeIds.length) {
      state = state!.copyWith(badgeIds: earned);
      _firestoreService.updateUser(state!);
    }
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AppUser?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final gamificationService = ref.watch(gamificationServiceProvider);
  final fcmService = ref.read(fcmServiceProvider);
  final notifier =
      UserProfileNotifier(firestoreService, gamificationService);

  // Demo mode: skip Firebase auth and load a fake user immediately
  final isDemoMode = ref.read(demoModeProvider);
  if (isDemoMode) {
    notifier.state = demoUser;
    return notifier;
  }

  // React to auth state changes
  ref.listen(currentUserProvider, (previous, firebaseUser) {
    if (firebaseUser != null) {
      notifier.createUserFromAuth(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
        fcmService: fcmService,
      );
    } else {
      if (previous?.uid != null) {
        fcmService.removeToken(previous!.uid);
      }
      notifier.clearUser();
    }
  });

  // Load immediately if already signed in
  final firebaseUser = ref.read(currentUserProvider);
  if (firebaseUser != null) {
    notifier.createUserFromAuth(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      fcmService: fcmService,
    );
  }

  return notifier;
});

final earnedBadgesProvider = Provider<List<Badge>>((ref) {
  final user = ref.watch(userProfileProvider);
  final gamService = ref.watch(gamificationServiceProvider);
  if (user == null) return [];
  return gamService.getEarnedBadges(user);
});

/// Non-null when the user just leveled up. UI should show overlay then call dismiss.
final levelUpProvider = StateProvider<int?>((ref) => null);

/// Today's daily mission.
final dailyMissionProvider = Provider<DailyMission>((ref) {
  return DailyMission.forToday();
});

/// How many spots the user has reported today.
final todayReportsCountProvider = Provider<int>((ref) {
  final user = ref.watch(userProfileProvider);
  if (user == null) return 0;
  final last = user.lastReportDate;
  if (last == null) return 0;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final lastDay = DateTime(last.year, last.month, last.day);
  if (today.difference(lastDay).inDays > 0) return 0;
  return user.todayReportsCount;
});

/// True if the daily mission is completed today.
final missionCompletedTodayProvider = Provider<bool>((ref) {
  final user = ref.watch(userProfileProvider);
  if (user == null) return false;
  final completed = user.lastMissionCompletedDate;
  if (completed == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final completedDay =
      DateTime(completed.year, completed.month, completed.day);
  return today == completedDay;
});
