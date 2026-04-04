import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'road_status_model.freezed.dart';
part 'road_status_model.g.dart';

enum TrafficLevel {
  light,      // Green - free flowing
  moderate,   // Yellow - some congestion
  heavy,      // Red - heavy traffic
}

enum IncidentType {
  accident,
  construction,
  closure,
  other,
}

@freezed
class RoadIncident with _$RoadIncident {
  const factory RoadIncident({
    required String id,
    required String description,
    required IncidentType type,
    required double lat,
    required double lng,
    required DateTime reportedAt,
    required String reportedBy,
    @Default(0) int confirmations,
  }) = _RoadIncident;

  factory RoadIncident.fromJson(Map<String, dynamic> json) =>
      _$RoadIncidentFromJson(json);

  factory RoadIncident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoadIncident.fromJson({...data, 'id': doc.id});
  }
}

@freezed
class RoadStatus with _$RoadStatus {
  const factory RoadStatus({
    required String id,
    required double lat,
    required double lng,
    required TrafficLevel trafficLevel,
    required int reportCount,
    required List<RoadIncident> incidents,
    required DateTime lastUpdated,
  }) = _RoadStatus;

  factory RoadStatus.fromJson(Map<String, dynamic> json) =>
      _$RoadStatusFromJson(json);

  factory RoadStatus.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final incidents = (data['incidents'] as List<dynamic>?)
        ?.map((inc) => RoadIncident.fromJson(inc as Map<String, dynamic>))
        .toList() ?? [];

    return RoadStatus(
      id: doc.id,
      lat: data['lat'] as double,
      lng: data['lng'] as double,
      trafficLevel: TrafficLevel.values.byName(data['trafficLevel'] as String),
      reportCount: data['reportCount'] as int? ?? 0,
      incidents: incidents,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
