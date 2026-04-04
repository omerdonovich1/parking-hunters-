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
