import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/domain/entities/notification_entity.dart';
import '../../features/notifications/presentation/controllers/notifications_controller.dart';
import '../widgets/glass_card.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  
  if (message.notification != null) {
    final notification = NotificationEntity(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      timestamp: message.sentTime ?? DateTime.now(),
      payload: message.data,
    );
    
    final List<String> jsonList = prefs.getStringList('sam4g_notifications_list') ?? [];
    final current = jsonList.map((str) => NotificationEntity.fromJson(str)).toList()..add(notification);
    
    if (current.length > 50) {
      current.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      current.removeRange(50, current.length);
    }
    
    await prefs.setStringList('sam4g_notifications_list', current.map((e) => e.toJson()).toList());
  }
}

class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._internal();

  factory FcmNotificationService() => _instance;

  FcmNotificationService._internal();

  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// تهيئة الفايربيس والإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. تهيئة Firebase الأساسية
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      // 2. إعداد إشعارات Foreground (Local Notifications)
      await _setupLocalNotifications();

      // 3. الاشتراك التلقائي في موضوع (Topic) الخاص بمستخدمي التطبيق
      await subscribeToAppUsersTopic();

      // تسجيل معالج الإشعارات في الخلفية
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. الاستماع للإشعارات أثناء فتح التطبيق (Foreground)
      _listenToForegroundMessages();
      
      _isInitialized = true;
      debugPrint('🔔 FCM Notification Service Initialized');
    } catch (e) {
      debugPrint('🚨 Error initializing FCM Notification Service: $e');
    }
  }

  /// طلب الصلاحيات (يتم استدعاءه بعد عرض شاشة أنيقة للمستخدم)
  Future<bool> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted permission');
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional permission');
        return true;
      } else {
        debugPrint('❌ User declined or has not accepted permission');
        return false;
      }
    } catch (e) {
      debugPrint('🚨 Error requesting notification permission: $e');
      return false;
    }
  }

  /// الاشتراك في الـ Topic الرئيسي
  Future<void> subscribeToAppUsersTopic() async {
    try {
      await _messaging.subscribeToTopic('pos_app_users');
      debugPrint('✅ Subscribed to topic: pos_app_users');
    } catch (e) {
      debugPrint('🚨 Error subscribing to topic: $e');
    }
  }

  /// إعداد الإشعارات المحلية لعرضها أثناء وجود التطبيق في الـ Foreground
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // التعامل مع الضغط على الإشعار هنا
        debugPrint('🔔 Notification Clicked: ${response.payload}');
      },
    );

    // إنشاء قناة إشعارات خاصة للأندرويد للأهمية العالية
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'إشعارات هامة', // name
      description: 'هذه القناة مخصصة للإشعارات الهامة.', // description
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // تفعيل إشعارات الفايربيس في وضع الـ Foreground للآيفون
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// الاستماع للإشعارات في وضع الـ Foreground
  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📥 Got a message whilst in the foreground!');

      if (message.notification != null) {
        // حفظ الإشعار محلياً
        final notification = NotificationEntity(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification?.title ?? '',
          body: message.notification?.body ?? '',
          timestamp: message.sentTime ?? DateTime.now(),
          payload: message.data,
        );
        
        if (Get.isRegistered<NotificationsController>()) {
          Get.find<NotificationsController>().addNotification(notification);
        }

        // عرض إشعار النظام (Local Notification)
        _showLocalNotification(message);
        
        // عرض اللافتة الزجاجية (In-App Banner)
        _showInAppBanner(notification);
      }
    });
  }

  void _showInAppBanner(NotificationEntity notification) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    
    Get.rawSnackbar(
      titleText: const SizedBox.shrink(),
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Get.isDarkMode
                    ? [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)]
                    : [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.4)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Get.isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // الأيقونة المضيئة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A90E2).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                
                // النصوص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          color: Get.isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Get.isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
      padding: EdgeInsets.zero,
      borderRadius: 24,
      duration: const Duration(seconds: 4),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutExpo,
      reverseAnimationCurve: Curves.easeInCirc,
    );
  }

  /// عرض إشعار محلي
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: const AndroidNotificationDetails(
            'high_importance_channel',
            'إشعارات هامة',
            channelDescription: 'هذه القناة مخصصة للإشعارات الهامة.',
            icon: '@mipmap/launcher_icon',
            importance: Importance.high,
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
