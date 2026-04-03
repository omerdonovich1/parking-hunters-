import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles FCM token registration and incoming message routing.
class FcmService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Call once after login. Requests permission, stores FCM token in Firestore.
  Future<void> initialize(String userId) async {
    try {
      // Request permission (iOS requires explicit grant)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM permission denied');
        return;
      }

      // Get and store FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeFcmToken(userId, token);
      }

      // Refresh token when it rotates
      _messaging.onTokenRefresh.listen((newToken) {
        _storeFcmToken(userId, newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Handle background message tap (app was in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTapped);

      // Check if app was opened from a terminated-state notification
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _onMessageTapped(initial);
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  }

  Future<void> _storeFcmToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FCM token store error: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
        'FCM foreground: ${message.notification?.title} — ${message.notification?.body}');
    // In-app banner is shown via NotificationOverlay in HomeScreen
    // The message payload can contain: type, spotId, lat, lng
  }

  void _onMessageTapped(RemoteMessage message) {
    debugPrint('FCM tapped: ${message.data}');
    // Navigate to the relevant spot — handled by the router via query params
    // e.g. push to '/map?spotId=xyz' in a real implementation
  }

  /// Removes the FCM token on sign-out so notifications stop.
  Future<void> removeToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM remove token error: $e');
    }
  }
}

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}
