class Constants {
  Constants._();

  static const int maxSpotValidityMinutes = 60;
  static const int pointsPerReport = 10;
  static const int pointsPerConfirmation = 5;

  static const List<int> levelThresholds = [0, 100, 300, 600, 1000, 2000];

  static const List<String> badgeIds = [
    'first_hunter',
    'bronze_hunter',
    'silver_hunter',
    'gold_hunter',
    'speed_demon',
    'neighborhood_hero',
  ];

  static const double defaultLat = 32.0853;
  static const double defaultLng = 34.7818;
  static const double defaultRadiusKm = 1.0;

  static const String spotsCollection = 'parking_spots';
  static const String usersCollection = 'users';
  static const String reportsCollection = 'reports';
}
