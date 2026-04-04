class DailyMission {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int targetCount;
  final int xpReward;

  const DailyMission({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.xpReward,
  });

  static const List<DailyMission> _pool = [
    DailyMission(
      id: 'daily_hunt',
      emoji: '🏁',
      title: 'Daily Hunt',
      description: 'Report at least 1 parking spot',
      targetCount: 1,
      xpReward: 20,
    ),
    DailyMission(
      id: 'double_hunt',
      emoji: '🎯',
      title: 'Double Hunt',
      description: 'Report 2 parking spots today',
      targetCount: 2,
      xpReward: 50,
    ),
    DailyMission(
      id: 'triple_threat',
      emoji: '🔥',
      title: 'Triple Threat',
      description: 'Report 3 parking spots today',
      targetCount: 3,
      xpReward: 80,
    ),
    DailyMission(
      id: 'speed_spree',
      emoji: '⚡',
      title: 'Speed Spree',
      description: 'Report 5 parking spots today',
      targetCount: 5,
      xpReward: 120,
    ),
    DailyMission(
      id: 'hunter_mode',
      emoji: '🦁',
      title: 'Hunter Mode',
      description: 'Report 4 parking spots today',
      targetCount: 4,
      xpReward: 100,
    ),
    DailyMission(
      id: 'spot_seeker',
      emoji: '🔍',
      title: 'Spot Seeker',
      description: 'Report 2 parking spots today',
      targetCount: 2,
      xpReward: 55,
    ),
    DailyMission(
      id: 'city_scout',
      emoji: '🗺️',
      title: 'City Scout',
      description: 'Report 3 parking spots today',
      targetCount: 3,
      xpReward: 85,
    ),
  ];

  /// Returns a deterministic mission for today (same for all users).
  static DailyMission forToday() {
    final today = DateTime.now();
    // Use day-of-year so the mission changes daily
    final dayOfYear = today.difference(DateTime(today.year)).inDays;
    return _pool[dayOfYear % _pool.length];
  }
}
