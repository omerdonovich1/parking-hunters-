import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> isPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position> getCurrentPosition() async {
    try {
      // Check permission explicitly
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('location_permission_denied');
      }

      // Request position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint(
        '✓ Location acquired: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } on TimeoutException {
      debugPrint('✗ Location request timed out (10s limit exceeded)');
      throw Exception('location_timeout');
    } on LocationServiceDisabledException {
      debugPrint('✗ Location service is disabled on device');
      throw Exception('location_service_disabled');
    } on PermissionDeniedException {
      debugPrint('✗ Location permission denied by user');
      throw Exception('location_permission_denied');
    } catch (e) {
      debugPrint('✗ Location service error: $e');
      rethrow;
    }
  }

  /// Returns a continuous stream of location updates as the user moves
  /// Updates every 5 seconds or when user moves more than 10 meters
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10+ meters
        timeLimit: Duration(seconds: 5), // Or every 5 seconds
      ),
    ).handleError((e) {
      debugPrint('✗ Location stream error: $e');
    });
  }

  Future<String> getAddressFromCoords(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return '$lat, $lng';
      final place = placemarks.first;
      final parts = <String>[
        if (place.street != null && place.street!.isNotEmpty) place.street!,
        if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
        if (place.country != null && place.country!.isNotEmpty) place.country!,
      ];
      return parts.isNotEmpty ? parts.join(', ') : '$lat, $lng';
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }
}
