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
    _subscribeToFirestore();
    // Every 30 seconds, recompute status and drop expired spots.
    // Confidence is a getter so it auto-updates; this just cleans up the list.
    _expirationTimer = Timer.periodic(const Duration(seconds: 30), (_) => removeExpiredSpots());
  }

  void _subscribeToFirestore() {
    _spotsSubscription?.cancel();
    _spotsSubscription = _firestoreService.watchActiveSpots().listen(
      (firestoreSpots) {
        if (firestoreSpots.isEmpty && state.isNotEmpty) {
          // Keep any locally-added spots (e.g. just submitted) while Firestore catches up
          final localOnly = state.where((s) => s.id.startsWith('demo_')).toList();
          state = [...firestoreSpots, ...localOnly];
        } else {
          state = firestoreSpots;
        }
        debugPrint('Live spots from Firestore: ${firestoreSpots.length}');
      },
      onError: (e) {
        debugPrint('watchActiveSpots error: $e');
        // Don't wipe existing spots on error — keep showing what we have
        if (state.isEmpty) _loadDemoSpots();
      },
    );
  }

  void _loadDemoSpots() {
    const lat = Constants.defaultLat;
    const lng = Constants.defaultLng;
    final now = DateTime.now();
    state = [
      ParkingSpot(id: 'demo_1', lat: lat + 0.002, lng: lng + 0.001, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 5)), expiresAt: now.add(const Duration(minutes: 55)),
          aiConfidence: 0.9, status: SpotStatus.available, note: 'Near the corner', confirmedCount: 5),
      ParkingSpot(id: 'demo_2', lat: lat - 0.001, lng: lng + 0.003, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 30)), expiresAt: now.add(const Duration(minutes: 30)),
          aiConfidence: 0.75, status: SpotStatus.available, note: 'Blue zone', confirmedCount: 2),
      ParkingSpot(id: 'demo_3', lat: lat + 0.003, lng: lng - 0.002, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 50)), expiresAt: now.add(const Duration(minutes: 10)),
          aiConfidence: 0.8, status: SpotStatus.available, confirmedCount: 0),
      ParkingSpot(id: 'demo_4', lat: lat - 0.003, lng: lng - 0.001, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 10)), expiresAt: now.add(const Duration(minutes: 50)),
          aiConfidence: 0.85, status: SpotStatus.available, note: 'Free parking all day', confirmedCount: 8),
      ParkingSpot(id: 'demo_5', lat: lat + 0.001, lng: lng - 0.003, reportedBy: 'system',
          reportedAt: now.subtract(const Duration(minutes: 15)), expiresAt: now.add(const Duration(minutes: 45)),
          aiConfidence: 0.6, status: SpotStatus.available, note: 'Street parking', confirmedCount: 3),
    ];
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    _spotsSubscription?.cancel();
    super.dispose();
  }

  void addSpot(ParkingSpot spot) {
    // If the Firestore stream is live, it will add the spot automatically.
    // This local add ensures the reporter sees it instantly without waiting.
    if (!state.any((s) => s.id == spot.id)) {
      state = [...state, spot];
    }
  }

  void removeExpiredSpots() =>
      state = state.where((s) => !s.isExpired).toList();

  void updateSpot(ParkingSpot updated) =>
      state = state.map((s) => s.id == updated.id ? updated : s).toList();
}

final parkingSpotsProvider =
    StateNotifierProvider<ParkingSpotsNotifier, List<ParkingSpot>>((ref) {
  return ParkingSpotsNotifier(ref.watch(firestoreServiceProvider));
});
