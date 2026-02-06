import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationPermission {
  static Future<void> request(FlutterLocalNotificationsPlugin plugin) async {
    if (Platform.isAndroid) {
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    if (Platform.isIOS || Platform.isMacOS) {
      await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }
}
