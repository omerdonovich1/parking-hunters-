import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int points;
  final int level;
  final List<String> badgeIds;
  final int totalReports;
  final DateTime createdAt;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReportDate;
  final int todayReportsCount;
  final DateTime? lastMissionCompletedDate;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.points,
    required this.level,
    required this.badgeIds,
    required this.totalReports,
    required this.createdAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastReportDate,
    this.todayReportsCount = 0,
    this.lastMissionCompletedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'points': points,
      'level': level,
      'badgeIds': badgeIds,
      'totalReports': totalReports,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReportDate':
          lastReportDate != null ? Timestamp.fromDate(lastReportDate!) : null,
      'todayReportsCount': todayReportsCount,
      'lastMissionCompletedDate': lastMissionCompletedDate != null
          ? Timestamp.fromDate(lastMissionCompletedDate!)
          : null,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return null;
    }

    return AppUser(
      id: docId ?? map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Hunter',
      photoUrl: map['photoUrl'] as String?,
      points: (map['points'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 0,
      badgeIds: List<String>.from(map['badgeIds'] as List? ?? []),
      totalReports: (map['totalReports'] as num?)?.toInt() ?? 0,
      createdAt: parseDateTime(map['createdAt']),
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      lastReportDate: parseNullableDateTime(map['lastReportDate']),
      todayReportsCount: (map['todayReportsCount'] as num?)?.toInt() ?? 0,
      lastMissionCompletedDate:
          parseNullableDateTime(map['lastMissionCompletedDate']),
    );
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    int? points,
    int? level,
    List<String>? badgeIds,
    int? totalReports,
    DateTime? createdAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastReportDate,
    bool clearLastReportDate = false,
    int? todayReportsCount,
    DateTime? lastMissionCompletedDate,
    bool clearLastMissionCompletedDate = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      points: points ?? this.points,
      level: level ?? this.level,
      badgeIds: badgeIds ?? this.badgeIds,
      totalReports: totalReports ?? this.totalReports,
      createdAt: createdAt ?? this.createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastReportDate: clearLastReportDate
          ? null
          : (lastReportDate ?? this.lastReportDate),
      todayReportsCount: todayReportsCount ?? this.todayReportsCount,
      lastMissionCompletedDate: clearLastMissionCompletedDate
          ? null
          : (lastMissionCompletedDate ?? this.lastMissionCompletedDate),
    );
  }
}
