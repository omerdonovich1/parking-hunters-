import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

/// Set to true to bypass auth and use a demo user — for testing/beta.
final demoModeProvider = StateProvider<bool>((ref) => true);

final demoUser = AppUser(
  id: 'demo_user',
  email: 'demo@parkinghunter.app',
  displayName: 'Demo Hunter',
  points: 350,
  level: 3,
  badgeIds: ['first_hunter', 'speed_demon'],
  totalReports: 24,
  currentStreak: 3,
  longestStreak: 7,
  createdAt: DateTime(2024, 1, 1),
);
