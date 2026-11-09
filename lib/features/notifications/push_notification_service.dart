import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'notifications_screen.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _notificationChannelId = 'alishams_updates';
const String _notificationChannelName = 'اعلان‌های علی‌شمس';
final GlobalKey<NavigatorState> pushNavigatorKey = GlobalKey<NavigatorState>();

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
  Map<String, dynamic>? _pendingTapData;
  int _navigationRetries = 0;

  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  Future<void> initialize() async {
    if (kIsWeb || !Platform.isAndroid) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initializeLocalNotifications();
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_openNotification(message.data));
    });
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingTapData = Map<String, dynamic>.from(initialMessage.data);
    }

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
        final raw = response.payload;
        if (raw == null || raw.isEmpty) return;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            unawaited(_openNotification(Map<String, dynamic>.from(decoded)));
          }
        } catch (error) {
          debugPrint('Notification payload parse failed: $error');
        }
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
    final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchPayload != null && launchPayload.isNotEmpty) {
      try {
        final decoded = jsonDecode(launchPayload);
        if (decoded is Map) {
          _pendingTapData = Map<String, dynamic>.from(decoded);
        }
      } catch (error) {
        debugPrint('Notification launch payload parse failed: $error');
      }
    }
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
      payload: jsonEncode(message.data),
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
    if (_pendingTapData != null) {
      final data = _pendingTapData!;
      _pendingTapData = null;
      await _openNotification(data);
    }
  }

  Future<void> _openNotification(Map<String, dynamic> data) async {
    if (Supabase.instance.client.auth.currentUser == null) {
      _pendingTapData = data;
      return;
    }
    final target = (data['category'] ?? data['target_type'] ?? '').toString();
    String category = 'account';
    if (target == 'order' || target == 'orders') category = 'orders';
    if (target == 'project' || target == 'projects') category = 'projects';
    if (target == 'payment' || target == 'payments') category = 'payments';
    if (target == 'club') category = 'club';
    if (target == 'plus') category = 'plus';
    final navigator = pushNavigatorKey.currentState;
    if (navigator == null) {
      _pendingTapData = data;
      if (_navigationRetries < 5) {
        _navigationRetries++;
        Future.delayed(const Duration(milliseconds: 600), () {
          final pending = _pendingTapData;
          if (pending != null) {
            _pendingTapData = null;
            unawaited(_openNotification(pending));
          }
        });
      }
      return;
    }
    _navigationRetries = 0;
    navigator.push(MaterialPageRoute(
      builder: (_) => NotificationsScreen(initialCategory: category),
    ));
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
