import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parking_spot_model.dart';
import '../services/firestore_service.dart';
import '../core/utils/constants.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final nearbyRadiusProvider = StateProvider<double>((ref) => Constants.defaultRadiusKm);
final isOfflineProvider = StateProvider<bool>((ref) => false);
final selectedSpotProvider = StateProvider<ParkingSpot?>((ref) => null);
final mapControllerProvider = StateProvider<MapController?>((ref) => null);

class ParkingSpotsNotifier extends StateNotifier<List<ParkingSpot>> {
  final FirestoreService _firestoreService;
  Timer? _expirationTimer;
  StreamSubscription<List<ParkingSpot>>? _spotsSubscription;

  ParkingSpotsNotifier(this._firestoreService) : super([]) {
    _loadDummySpots();
    _startExpirationTimer();
  }

  void _startExpirationTimer() {
    _expirationTimer = Timer.periodic(const Duration(minutes: 1), (_) => removeExpiredSpots());
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    _spotsSubscription?.cancel();
    super.dispose();
  }

  void _loadDummySpots() {
    const lat = Constants.defaultLat;
    const lng = Constants.defaultLng;
    final now = DateTime.now();
    state = [
      ParkingSpot(id: 'dummy_1', lat: lat + 0.002, lng: lng + 0.001, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 5)), expiresAt: now.add(const Duration(minutes: 55)),
          confidence: 0.9, status: SpotStatus.available, note: 'Near the corner', confirmedCount: 5),
      ParkingSpot(id: 'dummy_2', lat: lat - 0.001, lng: lng + 0.003, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 20)), expiresAt: now.add(const Duration(minutes: 40)),
          confidence: 0.6, status: SpotStatus.soonAvailable, note: 'Blue zone', confirmedCount: 2),
      ParkingSpot(id: 'dummy_3', lat: lat + 0.003, lng: lng - 0.002, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 40)), expiresAt: now.add(const Duration(minutes: 20)),
          confidence: 0.3, status: SpotStatus.lowConfidence, confirmedCount: 0),
      ParkingSpot(id: 'dummy_4', lat: lat - 0.003, lng: lng - 0.001, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 10)), expiresAt: now.add(const Duration(minutes: 50)),
          confidence: 0.85, status: SpotStatus.available, note: 'Free parking all day', confirmedCount: 8),
      ParkingSpot(id: 'dummy_5', lat: lat + 0.001, lng: lng - 0.003, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 15)), expiresAt: now.add(const Duration(minutes: 45)),
          confidence: 0.75, status: SpotStatus.available, note: 'Street parking', confirmedCount: 3),
    ];
  }

  void loadNearbySpots(double lat, double lng, {double? radiusKm}) {
    _spotsSubscription?.cancel();
    _spotsSubscription = _firestoreService
        .getNearbySpots(lat, lng, radiusKm ?? Constants.defaultRadiusKm)
        .listen((spots) => state = spots, onError: (e) => debugPrint('Spots error: $e'));
  }

  void addSpot(ParkingSpot spot) => state = [...state, spot];
  void removeExpiredSpots() => state = state.where((s) => !s.isExpired).toList();
  void updateSpot(ParkingSpot updated) => state = state.map((s) => s.id == updated.id ? updated : s).toList();
}

final parkingSpotsProvider = StateNotifierProvider<ParkingSpotsNotifier, List<ParkingSpot>>((ref) {
  return ParkingSpotsNotifier(ref.watch(firestoreServiceProvider));
});
