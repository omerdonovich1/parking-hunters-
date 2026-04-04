import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/user_model.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';

enum LeagueTab { weekly, allTime }

final leagueScopeProvider = StateProvider<LeagueTab>((ref) => LeagueTab.weekly);

final leaderboardStreamProvider = StreamProvider<List<AppUser>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getLeaderboard();
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardStreamProvider);
    final currentUser = ref.watch(userProfileProvider);
    final scope = ref.watch(leagueScopeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(context, ref, scope, isDark),
        Expanded(
          child: leaderboard.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                color: AppTheme.blue,
                strokeWidth: 2,
              ),
            ),
            error: (e, _) => Center(
              child: Text('Failed to load: $e',
                  style: const TextStyle(color: Colors.red)),
            ),
            data: (users) => _buildList(context, users, currentUser, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, LeagueTab scope, bool isDark) {
    final bg = isDark ? const Color(0xFF0F1219) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leaderboard',
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: LeagueTab.values.map((tab) {
                final selected = scope == tab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(leagueScopeProvider.notifier).state = tab,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: selected
                            ? (isDark ? AppTheme.blue : AppTheme.blue)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          tab == LeagueTab.weekly ? 'This Week' : 'All Time',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : const Color(0xFF64748B)),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AppUser> users,
      AppUser? currentUser, bool isDark) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded,
                size: 56,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'No hunters yet!',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to report a spot.',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final user = users[i];
        final rank = i + 1;
        final isMe = user.id == currentUser?.id;
        return _LeaderboardTile(
          user: user,
          rank: rank,
          isMe: isMe,
          isDark: isDark,
        )
            .animate(delay: Duration(milliseconds: i * 50))
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.06, end: 0);
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final AppUser user;
  final int rank;
  final bool isMe;
  final bool isDark;

  const _LeaderboardTile({
    required this.user,
    required this.rank,
    required this.isMe,
    required this.isDark,
  });

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFB0B8C8);
      case 3:
        return const Color(0xFFCD8B6A);
      default:
        return AppTheme.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final isTop3 = rank <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.blue.withValues(alpha: isDark ? 0.12 : 0.06)
            : bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppTheme.blue.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.transparent),
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isMe ? 0.06 : 0.04),
                  blurRadius: isMe ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: isTop3
                  ? Text(
                      rank == 1
                          ? '🥇'
                          : rank == 2
                              ? '🥈'
                              : '🥉',
                      style: const TextStyle(fontSize: 28),
                      textAlign: TextAlign.center,
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.45)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.blue.withValues(alpha: 0.15)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isMe
                        ? AppTheme.blue
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Name + level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isMe
                              ? AppTheme.blue
                              : (isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A)),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lv.${user.level} · ${user.totalReports} reports',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.35)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user.points}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _rankColor(rank),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'pts',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
