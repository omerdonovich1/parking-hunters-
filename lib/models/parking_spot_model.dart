import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

enum SpotStatus { available, soonAvailable, lowConfidence, taken }

class ParkingSpot {
  final String id;
  final double lat;
  final double lng;
  final String reportedBy;
  final DateTime reportedAt;
  final DateTime expiresAt;
  /// Raw AI confidence score (0.0–1.0). Stored in Firestore, never changes after submission.
  final double aiConfidence;
  /// 'taken' if manually marked; otherwise computed from confidence.
  final SpotStatus status;
  final String? photoUrl;
  final String? note;
  final int confirmedCount;

  const ParkingSpot({
    required this.id,
    required this.lat,
    required this.lng,
    required this.reportedBy,
    required this.reportedAt,
    required this.expiresAt,
    required this.aiConfidence,
    required this.status,
    this.photoUrl,
    this.note,
    this.confirmedCount = 0,
  });

  /// Live confidence = AI score × √(minutesRemaining / totalMinutes).
  /// Decays smoothly — gentle at first, steep near expiry.
  /// A high AI score stays green longer; a low score goes red quickly.
  double get confidence {
    if (status == SpotStatus.taken) return 0.0;
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0.0;
    final totalSecs = expiresAt.difference(reportedAt).inSeconds.toDouble();
    final remainingSecs = expiresAt.difference(now).inSeconds.toDouble();
    if (totalSecs <= 0) return 0.0;
    final timeDecay = math.sqrt((remainingSecs / totalSecs).clamp(0.0, 1.0));
    return (aiConfidence * timeDecay).clamp(0.0, 1.0);
  }

  /// Status derived dynamically from live confidence.
  SpotStatus get computedStatus {
    if (status == SpotStatus.taken) return SpotStatus.taken;
    final c = confidence;
    if (c <= 0.0) return SpotStatus.taken;
    if (c >= 0.65) return SpotStatus.available;
    if (c >= 0.35) return SpotStatus.soonAvailable;
    return SpotStatus.lowConfidence;
  }

  bool get isExpired =>
      status == SpotStatus.taken || DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lat': lat,
      'lng': lng,
      'reportedBy': reportedBy,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'aiConfidence': aiConfidence,
      'status': status.name,
      'photoUrl': photoUrl,
      'note': note,
      'confirmedCount': confirmedCount,
    };
  }

  factory ParkingSpot.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    SpotStatus parseStatus(String? name) {
      switch (name) {
        case 'soonAvailable':
          return SpotStatus.soonAvailable;
        case 'lowConfidence':
          return SpotStatus.lowConfidence;
        case 'taken':
          return SpotStatus.taken;
        default:
          return SpotStatus.available;
      }
    }

    return ParkingSpot(
      id: docId ?? map['id'] as String? ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      reportedBy: map['reportedBy'] as String? ?? '',
      reportedAt: parseDateTime(map['reportedAt']),
      expiresAt: parseDateTime(map['expiresAt']),
      // Support legacy docs that stored 'confidence' instead of 'aiConfidence'
      aiConfidence: (map['aiConfidence'] as num?)?.toDouble()
          ?? (map['confidence'] as num?)?.toDouble()
          ?? 0.7,
      status: parseStatus(map['status'] as String?),
      photoUrl: map['photoUrl'] as String?,
      note: map['note'] as String?,
      confirmedCount: (map['confirmedCount'] as num?)?.toInt() ?? 0,
    );
  }

  ParkingSpot copyWith({
    String? id,
    double? lat,
    double? lng,
    String? reportedBy,
    DateTime? reportedAt,
    DateTime? expiresAt,
    double? aiConfidence,
    SpotStatus? status,
    String? photoUrl,
    String? note,
    int? confirmedCount,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedAt: reportedAt ?? this.reportedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      note: note ?? this.note,
      confirmedCount: confirmedCount ?? this.confirmedCount,
    );
  }
}
