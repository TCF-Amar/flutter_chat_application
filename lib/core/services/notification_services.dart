import 'dart:async';
import 'package:chat_kare/core/utils/get_device_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_kare/core/utils/notification_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationServices {
  NotificationServices._();
  static final NotificationServices instance = NotificationServices._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  final StreamController<NotificationResponse> _onTapStream =
      StreamController.broadcast();

  Stream<NotificationResponse> get onTap => _onTapStream.stream;
  String? _fcmToken;

  Future<void> init() async {
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final timezoneString = timezoneInfo.toString();
    final timezoneId = timezoneString.substring(
      timezoneString.indexOf('(') + 1,
      timezoneString.indexOf(','),
    );
    tz.setLocalLocation(tz.getLocation(timezoneId));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _onTapStream.add(response);
      },
    );

    await NotificationPermission.request(_plugin);
  }

  Future<void> show({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      icon: '@mipmap/ic_launcher',
      'chat_channel',
      'Chat Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  void listenToFcm() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        show(title: notification.title ?? '', body: notification.body ?? '');
      }
    });
  }

  /// Request FCM permission (iOS only, Android 13+ handled automatically)
  Future<void> requestFcmPermission() async {
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

      _logger.i('FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('User granted FCM permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _logger.i('User granted provisional FCM permission');
      } else {
        _logger.w('User declined or has not accepted FCM permission');
      }
    } catch (e) {
      _logger.e('Error requesting FCM permission: $e');
    }
  }

  /// Get FCM token
  Future<String?> getFcmToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        _logger.i('FCM Token: $_fcmToken');
        return _fcmToken;
      } else {
        _logger.w('Failed to get FCM token');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to Firestore
  Future<void> saveFcmTokenToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user logged in, cannot save FCM token');
        return;
      }

      final token = _fcmToken ?? await getFcmToken();
      if (token == null) {
        _logger.w('No FCM token available to save');
        return;
      }
      final deviceInfo = await getDeviceInfo();

      // Save token to user's document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceInfo.deviceId)
          .set({
            ...deviceInfo.toMap(),
            'lastActiveAt': FieldValue.serverTimestamp(),
            'fcmToken': token,
          }, SetOptions(merge: true));

      _logger.i('FCM token saved to Firestore for user: ${user.uid}');
    } catch (e) {
      _logger.e('Error saving FCM token to Firestore: $e');
    }
  }

  /// Setup token refresh listener
  void setupTokenRefreshListener() {
    _fcm.onTokenRefresh
        .listen((newToken) {
          _logger.i('FCM Token refreshed: $newToken');
          _fcmToken = newToken;
          saveFcmTokenToFirestore();
        })
        .onError((error) {
          _logger.e('Error on FCM token refresh: $error');
        });
  }

  /// Initialize FCM token management
  Future<void> initializeFcmToken() async {
    try {
      // Request permission
      await requestFcmPermission();

      // Get and save token
      await getFcmToken();
      await saveFcmTokenToFirestore();

      // Setup token refresh listener
      setupTokenRefreshListener();

      _logger.i('FCM token management initialized successfully');
    } catch (e) {
      _logger.e('Error initializing FCM token management: $e');
    }
  }

  /// Delete FCM token from Firestore (call on logout)
  Future<void> deleteFcmToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('No user logged in, cannot delete FCM token');
        return;
      }

      final token = _fcmToken ?? await getFcmToken();
      if (token == null) {
        _logger.w('No FCM token available to delete');
        return;
      }

      final deviceInfo = await getDeviceInfo();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceInfo.deviceId)
          .delete();

      _logger.i(
        'Device FCM token removed from Firestore for user: ${user.uid}',
      );

      await _fcm.deleteToken();
      _fcmToken = null;

      _logger.i('FCM token deleted from device');
    } catch (e) {
      _logger.e('Error deleting FCM token: $e');
    }
  }

  /// Test function to send a sample notification
  Future<void> testNotification() async {
    try {
      _logger.i('Sending test notification...');

      await show(
        title: 'Test Notification',
        body: 'This is a test notification from your Flutter Chat App!',
      );

      _logger.i('Test notification sent successfully');
    } catch (e) {
      _logger.e('Error sending test notification: $e');
    }
  }

  /// Send notification to a specific user by their FCM token
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        _logger.w('User $userId not found');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        _logger.w('No FCM token found for user $userId');
        return;
      }

      _logger.i('Sending notification to user $userId with token: $fcmToken');

      // Note: To actually send FCM messages, you need to use Firebase Cloud Functions
      // or a backend server with Firebase Admin SDK. This is just a placeholder.
      // For now, we'll show a local notification as a demo
      await show(title: title, body: body);
      

      _logger.i('Notification sent to user $userId');
    } catch (e) {
      _logger.e('Error sending notification to user: $e');
    }
  }

  void dispose() {
    _onTapStream.close();
  }
}
