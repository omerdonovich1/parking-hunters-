// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'road_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoadIncidentImpl _$$RoadIncidentImplFromJson(Map<String, dynamic> json) =>
    _$RoadIncidentImpl(
      id: json['id'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$IncidentTypeEnumMap, json['type']),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      reportedBy: json['reportedBy'] as String,
      confirmations: (json['confirmations'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$RoadIncidentImplToJson(_$RoadIncidentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'type': _$IncidentTypeEnumMap[instance.type]!,
      'lat': instance.lat,
      'lng': instance.lng,
      'reportedAt': instance.reportedAt.toIso8601String(),
      'reportedBy': instance.reportedBy,
      'confirmations': instance.confirmations,
    };

const _$IncidentTypeEnumMap = {
  IncidentType.accident: 'accident',
  IncidentType.construction: 'construction',
  IncidentType.closure: 'closure',
  IncidentType.other: 'other',
};

_$RoadStatusImpl _$$RoadStatusImplFromJson(Map<String, dynamic> json) =>
    _$RoadStatusImpl(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      trafficLevel: $enumDecode(_$TrafficLevelEnumMap, json['trafficLevel']),
      reportCount: (json['reportCount'] as num).toInt(),
      incidents: (json['incidents'] as List<dynamic>)
          .map((e) => RoadIncident.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$RoadStatusImplToJson(_$RoadStatusImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lat': instance.lat,
      'lng': instance.lng,
      'trafficLevel': _$TrafficLevelEnumMap[instance.trafficLevel]!,
      'reportCount': instance.reportCount,
      'incidents': instance.incidents,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

const _$TrafficLevelEnumMap = {
  TrafficLevel.light: 'light',
  TrafficLevel.moderate: 'moderate',
  TrafficLevel.heavy: 'heavy',
};
