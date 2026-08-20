import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../data/notification_repository.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Make sure Firebase is initialized
  await Firebase.initializeApp();
  AppLogger.info('Background message received: ${message.messageId}', 'FCMService');
}

class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  /// Initialize Firebase Messaging & Local Notifications
  Future<void> initialize(String userId) async {
    if (_initialized) return;

    try {
      AppLogger.info('Initializing FCM service...', 'FCMService');
      
      // 1. Request notifications permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      AppLogger.info('Notification permission status: ${settings.authorizationStatus}', 'FCMService');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Initialize Local Notifications (for foreground display)
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosInit = DarwinInitializationSettings();
        const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (response) {
            AppLogger.info('Notification clicked: ${response.payload}', 'FCMService');
            // Can be expanded to route/navigate using appRouter or deep links
          },
        );

        // 3. Create Android notification channel for heads-up alerts
        const channel = AndroidNotificationChannel(
          'seeme_notifications',
          'SeeMe Notifications',
          description: 'High-importance notifications for verifications, profile scans, etc.',
          importance: Importance.high,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // 4. Setup foreground message listeners
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          AppLogger.info('Foreground message received: ${message.notification?.title}', 'FCMService');
          _showForegroundNotification(message, channel);
        });

        // 5. Setup background message handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // 6. Fetch and register token
        final token = await _messaging.getToken();
        if (token != null) {
          await _registerToken(userId, token);
        }

        // 7. Watch token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          _registerToken(userId, newToken);
        });

        _initialized = true;
        AppLogger.info('FCM service initialized successfully ✓', 'FCMService');
      }
    } catch (e) {
      AppLogger.warning('FCM initialization skipped / failed: $e', 'FCMService');
    }
  }

  /// Register FCM token to backend
  Future<void> _registerToken(String userId, String token) async {
    try {
      final repo = _ref.read(notificationRepositoryProvider);
      final platformName = Platform.isAndroid ? 'android' : 'ios';
      final deviceInfo = 'OS: ${Platform.operatingSystem} v${Platform.operatingSystemVersion}';

      await repo.registerDeviceToken(
        userId: userId,
        token: token,
        platform: platformName,
        deviceInfo: deviceInfo,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to register device token', e, stack, 'FcmService');
    }
  }

  /// Show standard popup notification when in foreground
  void _showForegroundNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}

/// Provider for FcmService
final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});
