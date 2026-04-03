class Badge {
  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final int requiredPoints;
  final int requiredReports;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.requiredPoints,
    required this.requiredReports,
  });

  static const List<Badge> allBadges = [
    Badge(
      id: 'first_hunter',
      name: 'First Hunt',
      description: 'Report your first parking spot',
      iconEmoji: '🎯',
      requiredPoints: 0,
      requiredReports: 1,
    ),
    Badge(
      id: 'bronze_hunter',
      name: 'Bronze Hunter',
      description: 'Earn 100 points and report 10 spots',
      iconEmoji: '🥉',
      requiredPoints: 100,
      requiredReports: 10,
    ),
    Badge(
      id: 'silver_hunter',
      name: 'Silver Hunter',
      description: 'Earn 300 points and report 30 spots',
      iconEmoji: '🥈',
      requiredPoints: 300,
      requiredReports: 30,
    ),
    Badge(
      id: 'gold_hunter',
      name: 'Gold Hunter',
      description: 'Earn 1000 points and report 100 spots',
      iconEmoji: '🥇',
      requiredPoints: 1000,
      requiredReports: 100,
    ),
    Badge(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Earn 50 points and report 5 spots',
      iconEmoji: '⚡',
      requiredPoints: 50,
      requiredReports: 5,
    ),
    Badge(
      id: 'neighborhood_hero',
      name: 'Neighborhood Hero',
      description: 'Earn 200 points and report 20 spots',
      iconEmoji: '🦸',
      requiredPoints: 200,
      requiredReports: 20,
    ),
  ];

  static Badge? getById(String id) {
    try {
      return allBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
