import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../providers/locale_provider.dart';
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
    final s = ref.watch(appStringsProvider);

    return Column(
      children: [
        _buildHeader(context, ref, scope, s),
        Expanded(
          child: leaderboard.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(s.failedToLoad(e.toString()))),
            data: (users) => _buildList(context, s, users, currentUser),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, LeagueTab scope, AppStrings s) {
    return Container(
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Text(
            s.leaderboardTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(25),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        tab == LeagueTab.weekly ? s.thisWeekTab : s.allTimeTab,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? AppTheme.primaryColor
                              : Colors.white,
                          fontWeight: FontWeight.w600,
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

  Widget _buildList(
      BuildContext context, AppStrings s, List<AppUser> users, AppUser? currentUser) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              s.noHuntersYet,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
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
          s: s,
        )
            .animate(delay: Duration(milliseconds: i * 60))
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.1, end: 0);
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final AppUser user;
  final int rank;
  final bool isMe;
  final AppStrings s;

  const _LeaderboardTile({
    required this.user,
    required this.rank,
    required this.isMe,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppTheme.primaryColor.withValues(alpha: 0.4)
              : Colors.transparent,
          width: isMe ? 1.5 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _RankBadge(rank: rank),
        title: Row(
          children: [
            Text(
              user.displayName,
              style: TextStyle(
                fontWeight:
                    isMe ? FontWeight.bold : FontWeight.w600,
                color: isMe ? AppTheme.primaryColor : null,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.you,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          s.levelAndReports(user.level, user.totalReports),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${user.points}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _rankColor(rank),
              ),
            ),
            Text(
              s.pts,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
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
        return AppTheme.primaryColor;
    }
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      return Text(
        rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
        style: const TextStyle(fontSize: 32),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
