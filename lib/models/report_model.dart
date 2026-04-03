import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingReport {
  final String id;
  final String spotId;
  final String userId;
  final double lat;
  final double lng;
  final String? photoUrl;
  final String? note;
  final DateTime estimatedAvailableUntil;
  final DateTime createdAt;
  final int confirmedCount;
  final int deniedCount;

  const ParkingReport({
    required this.id,
    required this.spotId,
    required this.userId,
    required this.lat,
    required this.lng,
    this.photoUrl,
    this.note,
    required this.estimatedAvailableUntil,
    required this.createdAt,
    required this.confirmedCount,
    required this.deniedCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spotId': spotId,
      'userId': userId,
      'lat': lat,
      'lng': lng,
      'photoUrl': photoUrl,
      'note': note,
      'estimatedAvailableUntil': Timestamp.fromDate(estimatedAvailableUntil),
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedCount': confirmedCount,
      'deniedCount': deniedCount,
    };
  }

  factory ParkingReport.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return ParkingReport(
      id: docId ?? map['id'] as String? ?? '',
      spotId: map['spotId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      photoUrl: map['photoUrl'] as String?,
      note: map['note'] as String?,
      estimatedAvailableUntil: parseDateTime(map['estimatedAvailableUntil']),
      createdAt: parseDateTime(map['createdAt']),
      confirmedCount: (map['confirmedCount'] as num?)?.toInt() ?? 0,
      deniedCount: (map['deniedCount'] as num?)?.toInt() ?? 0,
    );
  }

  ParkingReport copyWith({
    String? id,
    String? spotId,
    String? userId,
    double? lat,
    double? lng,
    String? photoUrl,
    String? note,
    DateTime? estimatedAvailableUntil,
    DateTime? createdAt,
    int? confirmedCount,
    int? deniedCount,
  }) {
    return ParkingReport(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      userId: userId ?? this.userId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      photoUrl: photoUrl ?? this.photoUrl,
      note: note ?? this.note,
      estimatedAvailableUntil: estimatedAvailableUntil ?? this.estimatedAvailableUntil,
      createdAt: createdAt ?? this.createdAt,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      deniedCount: deniedCount ?? this.deniedCount,
    );
  }
}
