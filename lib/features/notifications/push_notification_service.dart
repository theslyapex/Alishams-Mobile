import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _notificationChannelId = 'alishams_updates';
const String _notificationChannelName = 'اعلان‌های علی‌شمس';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM displays notification payloads automatically while Android is backgrounded.
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<RemoteMessage> _foregroundMessages =
      StreamController<RemoteMessage>.broadcast();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool _localNotificationsReady = false;

  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  Future<void> initialize() async {
    if (kIsWeb || !Platform.isAndroid) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initializeLocalNotifications();
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((_) {
      unawaited(registerForUser());
    });

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((message) {
      if (!_foregroundMessages.isClosed) {
        _foregroundMessages.add(message);
      }
      unawaited(_showForegroundNotification(message));
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_alishams'),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // Notification routing can be connected to the app router later.
      },
    );

    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'به‌روزرسانی سفارش‌ها، پروژه‌ها و حساب کاربری',
      importance: Importance.max,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _localNotificationsReady = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_localNotificationsReady) return;
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'اعلان جدید علی‌شمس';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';
    if (body.isEmpty) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _notificationChannelId,
        _notificationChannelName,
        channelDescription: 'به‌روزرسانی سفارش‌ها، پروژه‌ها و حساب کاربری',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: 'ic_stat_alishams',
      ),
    );

    await _localNotifications.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: message.data.toString(),
    );
  }

  Future<void> registerForUser() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;
    try {
      final permission = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await client.functions.invoke('mobile-push-devices', body: {
        'action': 'register',
        'fcm_token': token,
        'platform': 'android',
        'device_label': 'android',
      });
    } catch (error) {
      debugPrint('FCM device registration failed: $error');
    }
  }

  Future<void> unregisterForCurrentUser() async {
    if (kIsWeb || !Platform.isAndroid) return;
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

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _foregroundMessages.close();
  }
}
