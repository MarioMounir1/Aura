import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('🔔 [FCM Background] Message received: ${message.messageId} | ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String channelId = 'aura_high_importance_channel';
  static const String channelName = 'Aura Notifications';
  static const String channelDescription = 'Daily workout, nutrition, hydration and AI coach updates.';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  bool _isInitialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Callback when a notification is clicked that contains a route payload (e.g., '/workout', '/meals')
  void Function(String route)? onNotificationTapped;

  /// Initialize Firebase Messaging & Local Notifications
  Future<void> initialize({void Function(String route)? onRouteNavigation}) async {
    if (_isInitialized) return;
    _isInitialized = true;
    onNotificationTapped = onRouteNavigation;

    // 1. Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Android notification channel initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: darwinSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty && onNotificationTapped != null) {
          onNotificationTapped!(payload);
        }
      },
    );

    // Create the high-importance channel on Android
    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_channel);
    }

    // 3. Foreground message listener (Show local heads-up notification)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        final route = message.data['route'] as String? ?? '';
        _localNotifications.show(
          notification.hashCode,
          notification.title ?? 'Aura',
          notification.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: route,
        );
      }
    });

    // 4. Background click listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route'] as String?;
      if (route != null && route.isNotEmpty && onNotificationTapped != null) {
        onNotificationTapped!(route);
      }
    });

    // 5. Terminated state launch check
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      final route = initialMessage.data['route'] as String?;
      if (route != null && route.isNotEmpty && onNotificationTapped != null) {
        onNotificationTapped!(route);
      }
    }

    // 6. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      syncTokenWithBackend();
    });
  }

  /// Request push notification permissions from the user
  Future<bool> requestPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isAuthorized) {
        await getAndSyncToken();
      }

      return isAuthorized;
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Permission request failed: $e');
      return false;
    }
  }

  /// Retrieve the current FCM token
  Future<String?> getDeviceToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Could not retrieve FCM token: $e');
      return null;
    }
  }

  /// Fetch and sync token with the Aura backend
  Future<void> getAndSyncToken() async {
    final token = await getDeviceToken();
    if (token != null && token.isNotEmpty) {
      await syncTokenWithBackend();
    }
  }

  /// Send FCM token and platform details to backend
  Future<void> syncTokenWithBackend() async {
    if (_fcmToken == null || _fcmToken!.isEmpty) return;
    try {
      final dio = ApiClient().dio;
      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      final timezoneName = DateTime.now().timeZoneName;

      await dio.post(
        '/notifications/register-token',
        data: {
          'token': _fcmToken,
          'platform': platform,
          'timezone': timezoneName,
        },
      );
      debugPrint('✅ [NotificationService] FCM token synced with backend.');
    } catch (e) {
      // Backend endpoint might not be deployed yet; silently log for graceful offline operation
      debugPrint('ℹ️ [NotificationService] Token sync skipped or pending backend: $e');
    }
  }

  /// In-workout local rest interval notification (triggers when user backgrounds app)
  Future<void> showInWorkoutRestNotification({required int nextSetNumber}) async {
    try {
      await _localNotifications.show(
        999, // Static ID for rest timers
        'Rest Complete! 💧',
        'Take a sip of water and start Set $nextSetNumber!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        payload: '/workout',
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationService] In-workout notification error: $e');
    }
  }

  /// Cancel all active notifications
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }
}
