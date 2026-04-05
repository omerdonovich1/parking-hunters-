import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../models/badge_model.dart' as badge_model;
import '../../../models/daily_mission_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/gamification_service.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final gamService = ref.watch(gamificationServiceProvider);
    final earnedBadges = ref.watch(earnedBadgesProvider);
    final authService = ref.read(authServiceProvider);
    final mission = ref.watch(dailyMissionProvider);
    final todayCount = ref.watch(todayReportsCountProvider);
    final missionDone = ref.watch(missionCompletedTodayProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final levelProgress = gamService.getLevelProgress(user.points);
    final levelTitle = gamService.getLevelTitle(user.level);
    final pointsToNext = gamService.getPointsToNextLevel(user.points);
    final streakInDanger = gamService.isStreakInDanger(user);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            title: const Text('Profile',
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeroCard(context, user, levelTitle, levelProgress,
                    pointsToNext, isDark),
                const SizedBox(height: 16),
                _buildQuickStats(context, user.totalReports,
                    earnedBadges.length, user.currentStreak, streakInDanger, isDark),
                const SizedBox(height: 16),
                _buildDailyMission(context, mission, todayCount, missionDone, isDark),
                const SizedBox(height: 16),
                _buildBadgesSection(context, earnedBadges, isDark),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    context.go('/auth');
                  },
                  icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                  label: const Text('Sign Out',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, user, String levelTitle,
      double levelProgress, int pointsToNext, bool isDark) {
    final initial =
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'H';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.blue, AppTheme.blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                child: user.photoUrl != null
                    ? ClipOval(
                        child: Image.network(user.photoUrl!, fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$levelTitle · Level ${user.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${user.points}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'pts',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP Progress',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    pointsToNext > 0
                        ? '$pointsToNext pts to next level'
                        : 'Max level!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: levelProgress.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildQuickStats(BuildContext context, int reports, int badges,
      int streak, bool inDanger, bool isDark) {
    return Row(
      children: [
        _statCard(context, '📍', '$reports', 'Reports', isDark),
        const SizedBox(width: 10),
        _statCard(context, '🏅', '$badges', 'Badges', isDark),
        const SizedBox(width: 10),
        _statCard(
          context,
          inDanger ? '⚠️' : (streak >= 3 ? '🔥' : '📅'),
          '$streak',
          'Streak',
          isDark,
          danger: inDanger,
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _statCard(BuildContext context, String emoji, String value,
      String label, bool isDark,
      {bool danger = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.card : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? null : AppTheme.cardShadow,
          border: danger
              ? Border.all(
                  color: AppTheme.neonRed.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: danger ? AppTheme.neonRed : AppTheme.blue,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyMission(BuildContext context, DailyMission mission,
      int todayCount, bool isCompleted, bool isDark) {
    final progress = (todayCount / mission.targetCount).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.card : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? null : AppTheme.cardShadow,
        border: Border.all(
          color: isCompleted
              ? AppTheme.neonGreen.withValues(alpha: 0.4)
              : AppTheme.blue.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.neonGreen.withValues(alpha: 0.1)
                  : AppTheme.blueLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                isCompleted ? '✅' : mission.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Daily Mission',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isCompleted
                                ? AppTheme.neonGreen
                                : AppTheme.blue,
                            letterSpacing: 1,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.neonGreen.withValues(alpha: 0.1)
                            : AppTheme.blueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCompleted ? 'Done!' : '+${mission.xpReward} XP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCompleted
                              ? AppTheme.neonGreen
                              : AppTheme.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mission.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor:
                              AppTheme.blue.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? AppTheme.neonGreen : AppTheme.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${todayCount.clamp(0, mission.targetCount)}/${mission.targetCount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            isCompleted ? AppTheme.neonGreen : AppTheme.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildBadgesSection(
      BuildContext context, List<badge_model.Badge> earnedBadges, bool isDark) {
    final allBadges = badge_model.Badge.allBadges;
    final earnedIds = earnedBadges.map((b) => b.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Badges',
                style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${earnedBadges.length}/${allBadges.length}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.blue,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: allBadges.length,
          itemBuilder: (context, i) {
            final badge = allBadges[i];
            final isEarned = earnedIds.contains(badge.id);
            return _badgeCard(context, badge, isEarned, isDark);
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _badgeCard(BuildContext context, badge_model.Badge badge,
      bool isEarned, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isEarned
            ? (isDark
                ? AppTheme.blue.withValues(alpha: 0.12)
                : AppTheme.blueLight)
            : (isDark ? AppTheme.card : const Color(0xFFF8FAFF)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isEarned && !isDark ? AppTheme.cardShadow : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: isEarned
                ? const ColorFilter.mode(
                    Colors.transparent, BlendMode.saturation)
                : const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 0.4, 0,
                  ]),
            child: Text(
              badge.iconEmoji,
              style: TextStyle(fontSize: isEarned ? 30 : 26),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isEarned ? FontWeight.w700 : FontWeight.w500,
              color: isEarned
                  ? (isDark ? Colors.white : AppTheme.textDark)
                  : AppTheme.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate(
      effects: isEarned
          ? [
              ShimmerEffect(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(seconds: 2),
                color: AppTheme.blue.withValues(alpha: 0.3),
              )
            ]
          : [],
    );
  }
}
