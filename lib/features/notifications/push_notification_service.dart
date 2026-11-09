import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Android displays notification payloads automatically while the app is backgrounded.
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
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen((message) {
      if (!_foregroundMessages.isClosed) _foregroundMessages.add(message);
    });
  }

  Future<void> registerForUser() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;
    try {
      final permission = await _messaging.requestPermission(alert: true, badge: true, sound: true);
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await client.functions.invoke('mobile-push-devices', body: {
        'action': 'register',
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'device_label': Platform.operatingSystem,
      });
    } catch (error) {
      debugPrint('FCM device registration failed: $error');
    }
  }

  Future<void> unregisterForCurrentUser() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await Supabase.instance.client.functions.invoke('mobile-push-devices', body: {
        'action': 'unregister',
        'fcm_token': token,
      });
    } catch (error) {
      debugPrint('FCM device unregister failed: $error');
    }
  }

  Future<void> dispose() async => _foregroundMessages.close();
}
