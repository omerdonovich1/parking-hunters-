import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/parking_spot_model.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../core/utils/constants.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<String> addParkingReport(ParkingReport report, {double aiConfidence = 0.7}) async {
    try {
      final docRef = await _db
          .collection(Constants.reportsCollection)
          .add(report.toMap());

      final spot = ParkingSpot(
        id: docRef.id,
        lat: report.lat,
        lng: report.lng,
        reportedBy: report.userId,
        reportedAt: report.createdAt,
        expiresAt: report.estimatedAvailableUntil,
        aiConfidence: aiConfidence,
        status: SpotStatus.available,
        photoUrl: report.photoUrl,
        note: report.note,
      );
      await _db
          .collection(Constants.spotsCollection)
          .doc(docRef.id)
          .set(spot.toMap());

      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('Firestore addParkingReport error: $e');
      return 'mock_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Real-time stream of all active spots.
  /// Single-field query (no composite index needed).
  /// Taken spots and expired spots are filtered client-side.
  Stream<List<ParkingSpot>> watchActiveSpots() {
    try {
      return _db
          .collection(Constants.spotsCollection)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ParkingSpot.fromMap(d.data(), docId: d.id))
              .where((spot) => spot.status != SpotStatus.taken)
              .toList());
    } catch (e) {
      debugPrint('watchActiveSpots error: $e');
      return Stream.value([]);
    }
  }

  Stream<List<ParkingSpot>> getNearbySpots(
      double lat, double lng, double radiusKm) {
    try {
      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * math.cos(lat * math.pi / 180));
      return _db
          .collection(Constants.spotsCollection)
          .where('lat', isGreaterThan: lat - latDelta)
          .where('lat', isLessThan: lat + latDelta)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ParkingSpot.fromMap(doc.data(), docId: doc.id))
            .where((spot) {
          final lngInRange =
              spot.lng >= lng - lngDelta && spot.lng <= lng + lngDelta;
          return lngInRange && !spot.isExpired;
        }).toList();
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore getNearbySpots error: $e');
      return Stream.value(_mockSpots(lat, lng));
    } catch (e) {
      debugPrint('getNearbySpots error: $e');
      return Stream.value(_mockSpots(lat, lng));
    }
  }

  List<ParkingSpot> _mockSpots(double centerLat, double centerLng) {
    final now = DateTime.now();
    return [
      ParkingSpot(
        id: 'mock_1',
        lat: centerLat + 0.002,
        lng: centerLng + 0.001,
        reportedBy: 'mock_user',
        reportedAt: now.subtract(const Duration(minutes: 5)),
        expiresAt: now.add(const Duration(minutes: 55)),
        aiConfidence: 0.9,
        status: SpotStatus.available,
        note: 'Near the corner',
      ),
      ParkingSpot(
        id: 'mock_2',
        lat: centerLat - 0.001,
        lng: centerLng + 0.003,
        reportedBy: 'mock_user2',
        reportedAt: now.subtract(const Duration(minutes: 20)),
        expiresAt: now.add(const Duration(minutes: 40)),
        aiConfidence: 0.6,
        status: SpotStatus.soonAvailable,
        note: 'Blue zone',
      ),
      ParkingSpot(
        id: 'mock_3',
        lat: centerLat + 0.003,
        lng: centerLng - 0.002,
        reportedBy: 'mock_user3',
        reportedAt: now.subtract(const Duration(minutes: 40)),
        expiresAt: now.add(const Duration(minutes: 20)),
        aiConfidence: 0.3,
        status: SpotStatus.lowConfidence,
      ),
      ParkingSpot(
        id: 'mock_4',
        lat: centerLat - 0.003,
        lng: centerLng - 0.001,
        reportedBy: 'mock_user4',
        reportedAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.add(const Duration(minutes: 50)),
        aiConfidence: 0.85,
        status: SpotStatus.available,
        note: 'Free parking',
      ),
      ParkingSpot(
        id: 'mock_5',
        lat: centerLat + 0.001,
        lng: centerLng - 0.003,
        reportedBy: 'mock_user5',
        reportedAt: now.subtract(const Duration(minutes: 15)),
        expiresAt: now.add(const Duration(minutes: 45)),
        aiConfidence: 0.75,
        status: SpotStatus.available,
        note: 'Street parking',
      ),
    ];
  }

  Future<void> updateUserPoints(String userId, int points) async {
    try {
      await _db
          .collection(Constants.usersCollection)
          .doc(userId)
          .update({'points': FieldValue.increment(points)});
    } on FirebaseException catch (e) {
      debugPrint('Firestore updateUserPoints error: $e');
    }
  }

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _db
          .collection(Constants.usersCollection)
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!, docId: doc.id);
    } on FirebaseException catch (e) {
      debugPrint('Firestore getUser error: $e');
      return _mockUser(userId);
    } catch (e) {
      debugPrint('getUser error: $e');
      return _mockUser(userId);
    }
  }

  AppUser _mockUser(String userId) {
    return AppUser(
      id: userId,
      email: 'hunter@example.com',
      displayName: 'Demo Hunter',
      points: 150,
      level: 1,
      badgeIds: ['first_hunter', 'speed_demon'],
      totalReports: 12,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  Future<void> createUser(AppUser user) async {
    try {
      await _db
          .collection(Constants.usersCollection)
          .doc(user.id)
          .set(user.toMap());
    } on FirebaseException catch (e) {
      debugPrint('Firestore createUser error: $e');
    }
  }

  Future<void> updateUser(AppUser user) async {
    try {
      await _db
          .collection(Constants.usersCollection)
          .doc(user.id)
          .update(user.toMap());
    } on FirebaseException catch (e) {
      debugPrint('Firestore updateUser error: $e');
    }
  }

  Future<void> confirmSpot(String spotId, String userId) async {
    try {
      final batch = _db.batch();
      final spotRef = _db.collection(Constants.spotsCollection).doc(spotId);
      batch.update(spotRef, {
        'confirmedCount': FieldValue.increment(1),
        'confidence': FieldValue.increment(0.05),
      });
      batch.commit();
    } on FirebaseException catch (e) {
      debugPrint('Firestore confirmSpot error: $e');
    }
  }

  Future<void> denySpot(String spotId, String userId) async {
    try {
      final batch = _db.batch();
      final spotRef = _db.collection(Constants.spotsCollection).doc(spotId);
      batch.update(spotRef, {
        'deniedCount': FieldValue.increment(1),
        'confidence': FieldValue.increment(-0.1),
      });
      batch.commit();
    } on FirebaseException catch (e) {
      debugPrint('Firestore denySpot error: $e');
    }
  }

  Future<void> markSpotTaken(String spotId) async {
    try {
      await _db.collection(Constants.spotsCollection).doc(spotId).update({
        'status': 'taken',
        'expiresAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore markSpotTaken error: $e');
    }
  }

  Stream<List<AppUser>> getLeaderboard() {
    try {
      return _db
          .collection(Constants.usersCollection)
          .orderBy('points', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), docId: doc.id))
              .toList());
    } on FirebaseException catch (e) {
      debugPrint('Firestore getLeaderboard error: $e');
      return Stream.value(_mockLeaderboard());
    } catch (e) {
      debugPrint('getLeaderboard error: $e');
      return Stream.value(_mockLeaderboard());
    }
  }

  List<AppUser> _mockLeaderboard() {
    final now = DateTime.now();
    return [
      AppUser(id: '1', email: 'a@a.com', displayName: 'ParkingPro', points: 2400, level: 5, badgeIds: ['gold_hunter'], totalReports: 120, createdAt: now),
      AppUser(id: '2', email: 'b@b.com', displayName: 'SpeedHunter', points: 1800, level: 4, badgeIds: ['silver_hunter'], totalReports: 95, createdAt: now),
      AppUser(id: '3', email: 'c@c.com', displayName: 'StreetWise', points: 1200, level: 3, badgeIds: ['bronze_hunter'], totalReports: 60, createdAt: now),
      AppUser(id: '4', email: 'd@d.com', displayName: 'CityRoamer', points: 800, level: 3, badgeIds: ['speed_demon'], totalReports: 45, createdAt: now),
      AppUser(id: '5', email: 'e@e.com', displayName: 'Demo Hunter', points: 150, level: 1, badgeIds: ['first_hunter'], totalReports: 12, createdAt: now),
    ];
  }
}
