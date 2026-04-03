import 'package:cloud_firestore/cloud_firestore.dart';

enum SpotStatus { available, soonAvailable, lowConfidence, taken }

class ParkingSpot {
  final String id;
  final double lat;
  final double lng;
  final String reportedBy;
  final DateTime reportedAt;
  final DateTime expiresAt;
  final double confidence;
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
    required this.confidence,
    required this.status,
    this.photoUrl,
    this.note,
    this.confirmedCount = 0,
  });

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
      'confidence': confidence,
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
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
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
    double? confidence,
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
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      note: note ?? this.note,
      confirmedCount: confirmedCount ?? this.confirmedCount,
    );
  }
}
