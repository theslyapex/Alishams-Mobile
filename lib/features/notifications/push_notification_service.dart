import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles native FCM lifecycle events for the ALISHAMS mobile app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is initialized in the main isolate. Background notification
  // payloads are displayed by Android automatically when the app is not active.
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final StreamController<RemoteMessage> _foregroundMessages =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onMessage.listen((message) {
      if (!_foregroundMessages.isClosed) {
        _foregroundMessages.add(message);
      }
    });
  }

  Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (error) {
      debugPrint('FCM token retrieval failed: $error');
      return null;
    }
  }

  Future<void> dispose() async {
    await _foregroundMessages.close();
  }
}
