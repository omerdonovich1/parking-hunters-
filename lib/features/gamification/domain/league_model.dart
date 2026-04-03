enum LeaguePeriod { weekly, allTime }

class LeagueEntry {
  final String userId;
  final String displayName;
  final int points;
  final int rank;
  final int weeklyPoints;

  const LeagueEntry({
    required this.userId,
    required this.displayName,
    required this.points,
    required this.rank,
    required this.weeklyPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'points': points,
      'rank': rank,
      'weeklyPoints': weeklyPoints,
    };
  }

  factory LeagueEntry.fromMap(Map<String, dynamic> map) {
    return LeagueEntry(
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      points: (map['points'] as num?)?.toInt() ?? 0,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      weeklyPoints: (map['weeklyPoints'] as num?)?.toInt() ?? 0,
    );
  }
}
