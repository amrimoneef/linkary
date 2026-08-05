import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final Set<String> _notifiedApps = {};

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Request permission for Android 13+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showUsageAlert({
    required String packageName,
    required String title,
    required String body,
  }) async {
    // Prevent spamming the exact same app alert constantly in the same session
    if (_notifiedApps.contains(packageName)) return;

    final int id = packageName.hashCode;
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'linkary_usage_alerts',
      'تنبيهات الاستهلاك',
      channelDescription: 'إشعارات مساعدة لتجاوز سقف الاستهلاك المحدد للتطبيقات',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFE24A4A),
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
    
    _notifiedApps.add(packageName);
  }
  
  void resetSession() {
      _notifiedApps.clear();
  }
}
