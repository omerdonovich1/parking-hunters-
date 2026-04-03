import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../core/utils/constants.dart';

class GamificationService {
  int calculateLevel(int points) {
    final thresholds = Constants.levelThresholds;
    int level = 0;
    for (int i = 0; i < thresholds.length; i++) {
      if (points >= thresholds[i]) {
        level = i;
      } else {
        break;
      }
    }
    return level;
  }

  List<Badge> getEarnedBadges(AppUser user) {
    return Badge.allBadges.where((badge) {
      return user.points >= badge.requiredPoints &&
          user.totalReports >= badge.requiredReports;
    }).toList();
  }

  int calculatePointsForAction(String action) {
    switch (action) {
      case 'report':
        return Constants.pointsPerReport;
      case 'confirm':
        return Constants.pointsPerConfirmation;
      case 'deny':
        return 1;
      case 'photo_report':
        return Constants.pointsPerReport + 5;
      default:
        return 0;
    }
  }

  String getLevelTitle(int level) {
    switch (level) {
      case 0:
        return 'Rookie';
      case 1:
        return 'Scout';
      case 2:
        return 'Hunter';
      case 3:
        return 'Expert';
      case 4:
        return 'Master';
      case 5:
        return 'Legend';
      default:
        return 'Legend';
    }
  }

  int getPointsToNextLevel(int currentPoints) {
    final thresholds = Constants.levelThresholds;
    final currentLevel = calculateLevel(currentPoints);
    if (currentLevel >= thresholds.length - 1) return 0;
    return thresholds[currentLevel + 1] - currentPoints;
  }

  double getLevelProgress(int currentPoints) {
    final thresholds = Constants.levelThresholds;
    final currentLevel = calculateLevel(currentPoints);
    if (currentLevel >= thresholds.length - 1) return 1.0;
    final levelStart = thresholds[currentLevel].toDouble();
    final levelEnd = thresholds[currentLevel + 1].toDouble();
    return (currentPoints - levelStart) / (levelEnd - levelStart);
  }
}
