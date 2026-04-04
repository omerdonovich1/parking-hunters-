// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'road_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RoadIncident _$RoadIncidentFromJson(Map<String, dynamic> json) {
  return _RoadIncident.fromJson(json);
}

/// @nodoc
mixin _$RoadIncident {
  String get id => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  IncidentType get type => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  DateTime get reportedAt => throw _privateConstructorUsedError;
  String get reportedBy => throw _privateConstructorUsedError;
  int get confirmations => throw _privateConstructorUsedError;

  /// Serializes this RoadIncident to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoadIncident
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoadIncidentCopyWith<RoadIncident> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoadIncidentCopyWith<$Res> {
  factory $RoadIncidentCopyWith(
          RoadIncident value, $Res Function(RoadIncident) then) =
      _$RoadIncidentCopyWithImpl<$Res, RoadIncident>;
  @useResult
  $Res call(
      {String id,
      String description,
      IncidentType type,
      double lat,
      double lng,
      DateTime reportedAt,
      String reportedBy,
      int confirmations});
}

/// @nodoc
class _$RoadIncidentCopyWithImpl<$Res, $Val extends RoadIncident>
    implements $RoadIncidentCopyWith<$Res> {
  _$RoadIncidentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoadIncident
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? type = null,
    Object? lat = null,
    Object? lng = null,
    Object? reportedAt = null,
    Object? reportedBy = null,
    Object? confirmations = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      reportedAt: null == reportedAt
          ? _value.reportedAt
          : reportedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reportedBy: null == reportedBy
          ? _value.reportedBy
          : reportedBy // ignore: cast_nullable_to_non_nullable
              as String,
      confirmations: null == confirmations
          ? _value.confirmations
          : confirmations // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoadIncidentImplCopyWith<$Res>
    implements $RoadIncidentCopyWith<$Res> {
  factory _$$RoadIncidentImplCopyWith(
          _$RoadIncidentImpl value, $Res Function(_$RoadIncidentImpl) then) =
      __$$RoadIncidentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String description,
      IncidentType type,
      double lat,
      double lng,
      DateTime reportedAt,
      String reportedBy,
      int confirmations});
}

/// @nodoc
class __$$RoadIncidentImplCopyWithImpl<$Res>
    extends _$RoadIncidentCopyWithImpl<$Res, _$RoadIncidentImpl>
    implements _$$RoadIncidentImplCopyWith<$Res> {
  __$$RoadIncidentImplCopyWithImpl(
      _$RoadIncidentImpl _value, $Res Function(_$RoadIncidentImpl) _then)
      : super(_value, _then);

  /// Create a copy of RoadIncident
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? type = null,
    Object? lat = null,
    Object? lng = null,
    Object? reportedAt = null,
    Object? reportedBy = null,
    Object? confirmations = null,
  }) {
    return _then(_$RoadIncidentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      reportedAt: null == reportedAt
          ? _value.reportedAt
          : reportedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reportedBy: null == reportedBy
          ? _value.reportedBy
          : reportedBy // ignore: cast_nullable_to_non_nullable
              as String,
      confirmations: null == confirmations
          ? _value.confirmations
          : confirmations // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoadIncidentImpl implements _RoadIncident {
  const _$RoadIncidentImpl(
      {required this.id,
      required this.description,
      required this.type,
      required this.lat,
      required this.lng,
      required this.reportedAt,
      required this.reportedBy,
      this.confirmations = 0});

  factory _$RoadIncidentImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoadIncidentImplFromJson(json);

  @override
  final String id;
  @override
  final String description;
  @override
  final IncidentType type;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final DateTime reportedAt;
  @override
  final String reportedBy;
  @override
  @JsonKey()
  final int confirmations;

  @override
  String toString() {
    return 'RoadIncident(id: $id, description: $description, type: $type, lat: $lat, lng: $lng, reportedAt: $reportedAt, reportedBy: $reportedBy, confirmations: $confirmations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoadIncidentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.reportedAt, reportedAt) ||
                other.reportedAt == reportedAt) &&
            (identical(other.reportedBy, reportedBy) ||
                other.reportedBy == reportedBy) &&
            (identical(other.confirmations, confirmations) ||
                other.confirmations == confirmations));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, description, type, lat, lng,
      reportedAt, reportedBy, confirmations);

  /// Create a copy of RoadIncident
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoadIncidentImplCopyWith<_$RoadIncidentImpl> get copyWith =>
      __$$RoadIncidentImplCopyWithImpl<_$RoadIncidentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoadIncidentImplToJson(
      this,
    );
  }
}

abstract class _RoadIncident implements RoadIncident {
  const factory _RoadIncident(
      {required final String id,
      required final String description,
      required final IncidentType type,
      required final double lat,
      required final double lng,
      required final DateTime reportedAt,
      required final String reportedBy,
      final int confirmations}) = _$RoadIncidentImpl;

  factory _RoadIncident.fromJson(Map<String, dynamic> json) =
      _$RoadIncidentImpl.fromJson;

  @override
  String get id;
  @override
  String get description;
  @override
  IncidentType get type;
  @override
  double get lat;
  @override
  double get lng;
  @override
  DateTime get reportedAt;
  @override
  String get reportedBy;
  @override
  int get confirmations;

  /// Create a copy of RoadIncident
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoadIncidentImplCopyWith<_$RoadIncidentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoadStatus _$RoadStatusFromJson(Map<String, dynamic> json) {
  return _RoadStatus.fromJson(json);
}

/// @nodoc
mixin _$RoadStatus {
  String get id => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  TrafficLevel get trafficLevel => throw _privateConstructorUsedError;
  int get reportCount => throw _privateConstructorUsedError;
  List<RoadIncident> get incidents => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this RoadStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoadStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoadStatusCopyWith<RoadStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoadStatusCopyWith<$Res> {
  factory $RoadStatusCopyWith(
          RoadStatus value, $Res Function(RoadStatus) then) =
      _$RoadStatusCopyWithImpl<$Res, RoadStatus>;
  @useResult
  $Res call(
      {String id,
      double lat,
      double lng,
      TrafficLevel trafficLevel,
      int reportCount,
      List<RoadIncident> incidents,
      DateTime lastUpdated});
}

/// @nodoc
class _$RoadStatusCopyWithImpl<$Res, $Val extends RoadStatus>
    implements $RoadStatusCopyWith<$Res> {
  _$RoadStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoadStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lat = null,
    Object? lng = null,
    Object? trafficLevel = null,
    Object? reportCount = null,
    Object? incidents = null,
    Object? lastUpdated = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      trafficLevel: null == trafficLevel
          ? _value.trafficLevel
          : trafficLevel // ignore: cast_nullable_to_non_nullable
              as TrafficLevel,
      reportCount: null == reportCount
          ? _value.reportCount
          : reportCount // ignore: cast_nullable_to_non_nullable
              as int,
      incidents: null == incidents
          ? _value.incidents
          : incidents // ignore: cast_nullable_to_non_nullable
              as List<RoadIncident>,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoadStatusImplCopyWith<$Res>
    implements $RoadStatusCopyWith<$Res> {
  factory _$$RoadStatusImplCopyWith(
          _$RoadStatusImpl value, $Res Function(_$RoadStatusImpl) then) =
      __$$RoadStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      double lat,
      double lng,
      TrafficLevel trafficLevel,
      int reportCount,
      List<RoadIncident> incidents,
      DateTime lastUpdated});
}

/// @nodoc
class __$$RoadStatusImplCopyWithImpl<$Res>
    extends _$RoadStatusCopyWithImpl<$Res, _$RoadStatusImpl>
    implements _$$RoadStatusImplCopyWith<$Res> {
  __$$RoadStatusImplCopyWithImpl(
      _$RoadStatusImpl _value, $Res Function(_$RoadStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of RoadStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lat = null,
    Object? lng = null,
    Object? trafficLevel = null,
    Object? reportCount = null,
    Object? incidents = null,
    Object? lastUpdated = null,
  }) {
    return _then(_$RoadStatusImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      trafficLevel: null == trafficLevel
          ? _value.trafficLevel
          : trafficLevel // ignore: cast_nullable_to_non_nullable
              as TrafficLevel,
      reportCount: null == reportCount
          ? _value.reportCount
          : reportCount // ignore: cast_nullable_to_non_nullable
              as int,
      incidents: null == incidents
          ? _value._incidents
          : incidents // ignore: cast_nullable_to_non_nullable
              as List<RoadIncident>,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoadStatusImpl implements _RoadStatus {
  const _$RoadStatusImpl(
      {required this.id,
      required this.lat,
      required this.lng,
      required this.trafficLevel,
      required this.reportCount,
      required final List<RoadIncident> incidents,
      required this.lastUpdated})
      : _incidents = incidents;

  factory _$RoadStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoadStatusImplFromJson(json);

  @override
  final String id;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final TrafficLevel trafficLevel;
  @override
  final int reportCount;
  final List<RoadIncident> _incidents;
  @override
  List<RoadIncident> get incidents {
    if (_incidents is EqualUnmodifiableListView) return _incidents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_incidents);
  }

  @override
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'RoadStatus(id: $id, lat: $lat, lng: $lng, trafficLevel: $trafficLevel, reportCount: $reportCount, incidents: $incidents, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoadStatusImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.trafficLevel, trafficLevel) ||
                other.trafficLevel == trafficLevel) &&
            (identical(other.reportCount, reportCount) ||
                other.reportCount == reportCount) &&
            const DeepCollectionEquality()
                .equals(other._incidents, _incidents) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      lat,
      lng,
      trafficLevel,
      reportCount,
      const DeepCollectionEquality().hash(_incidents),
      lastUpdated);

  /// Create a copy of RoadStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoadStatusImplCopyWith<_$RoadStatusImpl> get copyWith =>
      __$$RoadStatusImplCopyWithImpl<_$RoadStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoadStatusImplToJson(
      this,
    );
  }
}

abstract class _RoadStatus implements RoadStatus {
  const factory _RoadStatus(
      {required final String id,
      required final double lat,
      required final double lng,
      required final TrafficLevel trafficLevel,
      required final int reportCount,
      required final List<RoadIncident> incidents,
      required final DateTime lastUpdated}) = _$RoadStatusImpl;

  factory _RoadStatus.fromJson(Map<String, dynamic> json) =
      _$RoadStatusImpl.fromJson;

  @override
  String get id;
  @override
  double get lat;
  @override
  double get lng;
  @override
  TrafficLevel get trafficLevel;
  @override
  int get reportCount;
  @override
  List<RoadIncident> get incidents;
  @override
  DateTime get lastUpdated;

  /// Create a copy of RoadStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoadStatusImplCopyWith<_$RoadStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
