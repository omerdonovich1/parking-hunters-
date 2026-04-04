import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../models/badge_model.dart' as badge_model;
import '../../../models/daily_mission_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/gamification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/gamification/domain/league_model.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/settings'),
            ),
          ),
          _buildProfileHeader(context, user.displayName, user.photoUrl,
              levelTitle, user.level),
          const SizedBox(height: 20),
          _buildDailyMissionCard(context, mission, todayCount, missionDone),
          const SizedBox(height: 16),
          _buildPointsCard(context, user.points, levelProgress, pointsToNext, user.level),
          const SizedBox(height: 16),
          _buildStatsRow(context, user.totalReports, earnedBadges.length, user.level),
          const SizedBox(height: 12),
          _buildStreakCard(context, user.currentStreak, user.longestStreak, streakInDanger),
          const SizedBox(height: 24),
          _buildBadgesSection(context, earnedBadges),
          const SizedBox(height: 24),
          _buildLeagueSection(context),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await authService.signOut();
              context.go('/auth');
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String? photoUrl,
    String levelTitle,
    int level,
  ) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'H';
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.primaryColor,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
        const SizedBox(height: 12),
        Text(
          name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, Color(0xFFFF8C00)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$levelTitle • Level $level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyMissionCard(
    BuildContext context,
    DailyMission mission,
    int todayCount,
    bool isCompleted,
  ) {
    final progress = (todayCount / mission.targetCount).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? AppTheme.neonGreen.withValues(alpha: 0.5)
              : AppTheme.orange.withValues(alpha: 0.4),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [
                  AppTheme.neonGreen.withValues(alpha: 0.08),
                  AppTheme.card,
                ]
              : [
                  AppTheme.orange.withValues(alpha: 0.08),
                  AppTheme.card,
                ],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mission.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
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
                                    : AppTheme.orange,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.neonGreen.withValues(alpha: 0.15)
                                : AppTheme.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCompleted ? '✓ Done' : '+${mission.xpReward} XP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? AppTheme.neonGreen
                                  : AppTheme.orange,
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
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      mission.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: LinearPercentIndicator(
                  percent: progress,
                  lineHeight: 10,
                  backgroundColor: AppTheme.cardBorder,
                  progressColor:
                      isCompleted ? AppTheme.neonGreen : AppTheme.orange,
                  barRadius: const Radius.circular(5),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${todayCount.clamp(0, mission.targetCount)}/${mission.targetCount}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? AppTheme.neonGreen : AppTheme.orange,
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPointsCard(
    BuildContext context,
    int points,
    double levelProgress,
    int pointsToNext,
    int level,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text(
                  '$points',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(width: 8),
                const Text('pts', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              pointsToNext > 0
                  ? '$pointsToNext points to next level'
                  : 'Maximum level reached!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              percent: levelProgress.clamp(0.0, 1.0),
              lineHeight: 14,
              backgroundColor: Colors.grey.shade200,
              progressColor: AppTheme.primaryColor,
              barRadius: const Radius.circular(7),
              padding: EdgeInsets.zero,
              center: Text(
                '${(levelProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int totalReports, int badgesCount, int level) {
    return Row(
      children: [
        _statCard(context, '📍', totalReports.toString(), 'Reports'),
        const SizedBox(width: 12),
        _statCard(context, '🏅', badgesCount.toString(), 'Badges'),
        const SizedBox(width: 12),
        _statCard(context, '⭐', level.toString(), 'Level'),
      ],
    );
  }

  Widget _statCard(
      BuildContext context, String emoji, String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int currentStreak, int longestStreak, bool inDanger) {
    final isOnFire = currentStreak >= 3;
    final dangerColor = const Color(0xFFFF1744);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: inDanger
              ? dangerColor.withValues(alpha: 0.6)
              : AppTheme.cardBorder,
          width: inDanger ? 1.5 : 1,
        ),
        color: AppTheme.card,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: inDanger
                      ? dangerColor.withValues(alpha: 0.12)
                      : isOnFire
                          ? Colors.orange.withValues(alpha: 0.15)
                          : AppTheme.cardBorder,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    inDanger ? '⚠️' : (isOnFire ? '🔥' : '📅'),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              )
                  .animate(
                    onPlay: inDanger ? (c) => c.repeat(reverse: true) : null,
                  )
                  .scaleXY(
                    begin: 1.0,
                    end: inDanger ? 1.08 : 1.0,
                    duration: 700.ms,
                  ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStreak == 0
                          ? 'No active streak'
                          : '$currentStreak-day streak!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: inDanger
                                ? dangerColor
                                : isOnFire
                                    ? Colors.orange
                                    : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Best: $longestStreak day${longestStreak == 1 ? '' : 's'}  •  Report daily to keep your streak',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (currentStreak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: inDanger
                        ? dangerColor.withValues(alpha: 0.12)
                        : isOnFire
                            ? Colors.orange.withValues(alpha: 0.15)
                            : AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: inDanger
                          ? dangerColor
                          : isOnFire
                              ? Colors.orange
                              : AppTheme.cardBorder,
                    ),
                  ),
                  child: Text(
                    '×$currentStreak',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: inDanger
                          ? dangerColor
                          : isOnFire
                              ? Colors.orange
                              : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          if (inDanger && currentStreak > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dangerColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: dangerColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Report a spot today to keep your streak!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: dangerColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
                begin: 0.6, end: 1.0, duration: 1200.ms),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildBadgesSection(BuildContext context, List<badge_model.Badge> earnedBadges) {
    final earnedIds = earnedBadges.map((b) => b.id).toSet();
    final allBadges = badge_model.Badge.allBadges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '${earnedBadges.length}/${allBadges.length} earned',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: allBadges.length,
          itemBuilder: (context, i) {
            final badge = allBadges[i];
            final isEarned = earnedIds.contains(badge.id);
            return _badgeCard(context, badge, isEarned);
          },
        ),
      ],
    );
  }

  Widget _badgeCard(BuildContext context, badge_model.Badge badge, bool isEarned) {
    return Container(
      decoration: BoxDecoration(
        color: isEarned
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned
              ? AppTheme.primaryColor.withValues(alpha: 0.4)
              : Colors.grey.shade300,
          width: isEarned ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: isEarned
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.saturation)
                  : const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 0.5, 0,
                    ]),
              child: Text(
                badge.iconEmoji,
                style: TextStyle(
                  fontSize: isEarned ? 32 : 28,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isEarned ? FontWeight.bold : FontWeight.normal,
                color: isEarned
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate(
      effects: isEarned
          ? [const ShimmerEffect(delay: Duration(milliseconds: 500), duration: Duration(seconds: 2))]
          : [],
    );
  }

  Widget _buildLeagueSection(BuildContext context) {
    final mockLeague = [
      LeagueEntry(userId: '1', displayName: 'ParkingPro', points: 2400, rank: 1, weeklyPoints: 340),
      LeagueEntry(userId: '2', displayName: 'SpeedHunter', points: 1800, rank: 2, weeklyPoints: 280),
      LeagueEntry(userId: '3', displayName: 'StreetWise', points: 1200, rank: 3, weeklyPoints: 190),
      LeagueEntry(userId: 'local_user', displayName: 'You', points: 150, rank: 5, weeklyPoints: 45),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly League',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Top hunters this week',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: mockLeague.asMap().entries.map((entry) {
              final i = entry.key;
              final leagueEntry = entry.value;
              final isMe = leagueEntry.userId == 'local_user';
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1),
                  Container(
                    color: isMe
                        ? AppTheme.primaryColor.withValues(alpha: 0.08)
                        : null,
                    child: ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _rankColor(leagueEntry.rank),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#${leagueEntry.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        leagueEntry.displayName,
                        style: TextStyle(
                          fontWeight:
                              isMe ? FontWeight.bold : FontWeight.normal,
                          color: isMe ? AppTheme.primaryColor : null,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${leagueEntry.weeklyPoints} pts',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'this week',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey.shade400;
    }
  }
}
