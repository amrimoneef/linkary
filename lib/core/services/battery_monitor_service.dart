import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:linkary/core/services/balance_tracking_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

import '../../main.dart';

const String batteryMonitorTask = "batteryMonitorTask";
const String quotaExpiryMonitorTask = "quotaExpiryMonitorTask";
const String modemBaseUrl = 'http://mobile.router';

Future<void> _showNotification({required String title, required String body, int id = 9004}) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_notification');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'modem_battery_alerts',
    'إشعارات البطارية',
    channelDescription: 'تنبيهات انخفاض وامتلاء بطارية المودم',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  
  await flutterLocalNotificationsPlugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: platformChannelSpecifics,
  );
}

class BatteryMonitorService {
  static Timer? _foregroundBatteryTimer;
  static Timer? _foregroundQuotaTimer;

  static Future<void> checkBatteryAndNotify() async {
    try {
      // debugPrint('🔋 [BATTERY_MONITOR] checkBatteryAndNotify started');
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('battery_monitor_enabled') ?? true;
      
      // debugPrint('🔋 [BATTERY_MONITOR] isEnabled: $isEnabled');
      if (!isEnabled) {
        return;
      }

      final lowThreshold = prefs.getInt('battery_low_threshold') ?? 20;
      final notifyFull = prefs.getBool('battery_notify_full') ?? true;
      final lastAlert = prefs.getString('last_battery_alert') ?? 'normal';
      int alertCount = prefs.getInt('battery_alert_count') ?? 0;
      
      // debugPrint('🔋 [BATTERY_MONITOR] lowThreshold: $lowThreshold, notifyFull: $notifyFull, lastAlert: $lastAlert, alertCount: $alertCount');

      final response = await http.post(
        Uri.parse('$modemBaseUrl/api.cgi?path=aoc&method=get_bat_info&timeout=10'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: jsonEncode({
          "requests": [
            {"path": "aoc", "method": "get_bat_info"}
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      // debugPrint('🔋 [BATTERY_MONITOR] API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // debugPrint('🔋 [BATTERY_MONITOR] Raw Response: ${response.body}');
        final data = jsonDecode(response.body);
        
        int capacity = 0;
        int status = 0;
        bool hasData = false;

        if (data.containsKey('capacity') && data.containsKey('status')) {
          capacity = int.tryParse(data['capacity']?.toString() ?? '0') ?? 0;
          status = int.tryParse(data['status']?.toString() ?? '0') ?? 0;
          hasData = true;
          // debugPrint('🔋 [BATTERY_MONITOR] Parsed direct JSON: capacity=$capacity, status=$status');
        } else if (data['responses'] != null && data['responses'].isNotEmpty) {
          final batData = data['responses'][0]['data'];
          if (batData != null) {
            capacity = int.tryParse(batData['capacity']?.toString() ?? '0') ?? 0;
            status = int.tryParse(batData['status']?.toString() ?? '0') ?? 0;
            hasData = true;
            // debugPrint('🔋 [BATTERY_MONITOR] Parsed wrapped JSON: capacity=$capacity, status=$status');
          }
        }

        if (hasData) {
          String currentAlert = 'normal';
          
          if (capacity <= lowThreshold && status != 1) {
            currentAlert = 'low';
          } else if (capacity == 100 && notifyFull) {
            currentAlert = 'full';
          }
          
          debugPrint('🔋 [BATTERY_MONITOR] Evaluated currentAlert: $currentAlert');

          if (currentAlert != 'normal') {
            if (currentAlert != lastAlert) {
              alertCount = 1;
              await prefs.setInt('battery_alert_timestamp', DateTime.now().millisecondsSinceEpoch);
              debugPrint('🔋 [BATTERY_MONITOR] New alert state! Firing notification 1/3.');
              await _showNotification(
                title: currentAlert == 'low' 
                    ? 'بطارية المودم منخفضة' 
                    : 'بطارية المودم ممتلئة',
                body: currentAlert == 'low'
                    ? 'شحن بطارية المودم وصل إلى $capacity%، يرجى توصيل الشاحن.'
                    : 'المودم مشحون بالكامل 100%، يمكنك فصل الشاحن.',
              );
            } else if (alertCount < 3) {
              alertCount++;
              debugPrint('🔋 [BATTERY_MONITOR] Repeating alert state. Firing notification $alertCount/3.');
              await _showNotification(
                title: currentAlert == 'low' 
                    ? 'بطارية المودم منخفضة' 
                    : 'بطارية المودم ممتلئة',
                body: currentAlert == 'low'
                    ? 'شحن بطارية المودم وصل إلى $capacity%، يرجى توصيل الشاحن.'
                    : 'المودم مشحون بالكامل 100%، يمكنك فصل الشاحن.',
              );
            } else {
              // تم الوصول للحد الأقصى للإشعارات، نتحقق من مرور 12 ساعة
              final lastTimestamp = prefs.getInt('battery_alert_timestamp') ?? 0;
              final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
              if (DateTime.now().difference(lastDate).inHours >= 3) {
                alertCount = 1; // تصفير وبدء دورة جديدة
                await prefs.setInt('battery_alert_timestamp', DateTime.now().millisecondsSinceEpoch);
                debugPrint('🔋 [BATTERY_MONITOR] 12 hours passed. Resetting alert. Firing notification 1/3.');
                await _showNotification(
                  title: currentAlert == 'low' 
                      ? 'بطارية المودم منخفضة' 
                      : 'بطارية المودم ممتلئة',
                  body: currentAlert == 'low'
                      ? 'شحن بطارية المودم وصل إلى $capacity%، يرجى توصيل الشاحن.'
                      : 'المودم مشحون بالكامل 100%، يمكنك فصل الشاحن.',
                );
              } else {
                debugPrint('🔋 [BATTERY_MONITOR] Max notifications (3/3) reached for this alert. No notification needed until 12h pass.');
              }
            }
          } else {
            debugPrint('🔋 [BATTERY_MONITOR] Alert state is normal. No notification needed.');
          }
          
          if ((capacity > lowThreshold && capacity < 100) || (currentAlert == 'low' && status == 1)) {
            currentAlert = 'normal';
            alertCount = 0;
            debugPrint('🔋 [BATTERY_MONITOR] Resetting currentAlert to normal and alertCount to 0');
          }
          
          await prefs.setString('last_battery_alert', currentAlert);
          await prefs.setInt('battery_alert_count', alertCount);
          debugPrint('🔋 [BATTERY_MONITOR] Saved last_battery_alert: $currentAlert, count: $alertCount');
        } else {
          debugPrint('🔋 [BATTERY_MONITOR] hasData is false. Failed to parse.');
        }
      }
    } catch (e) {
      debugPrint('🔋 [BATTERY_MONITOR] Network/Parse Error: $e');
    }
  }

  static Future<void> checkQuotaAndNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotaEnabled = prefs.getBool('quota_monitor_enabled') ?? true;
      if (!quotaEnabled) return;

      final trackingData = await BalanceTrackingService.getData();
      if (trackingData == null) {
        debugPrint('📊 [QUOTA_MONITOR] No tracking data found. Skipping.');
        return;
      }

      final response = await http.post(
        Uri.parse('$modemBaseUrl/api.cgi?path=statistics&method=stat_get_common_data&timeout=10'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: jsonEncode({
          "requests": [
            {"path": "statistics", "method": "stat_get_common_data"}
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('statistics')) {
          final stats = data['statistics'];
          final totalUsage = int.tryParse(stats['total_rx_tx_bytes']?.toString() ?? '0') ?? 0;
          
          final initialUsage = trackingData.initialRouterUsageBytes;
          final lastFetchedBalance = trackingData.lastFetchedBalanceBytes;
          
          if (totalUsage >= initialUsage && initialUsage != 0) {
            final consumedSinceFetch = totalUsage - initialUsage;
            final expectedBalanceBytes = lastFetchedBalance - consumedSinceFetch;
            
            const oneGB = 1024 * 1024 * 1024;
            final lowThresholdGB = prefs.getInt('quota_low_threshold_gb') ?? 5;
            final lowThresholdBytes = lowThresholdGB * oneGB;
            
            String currentAlert = 'normal';
            if (expectedBalanceBytes <= oneGB) {
              currentAlert = 'critical'; 
            } else if (expectedBalanceBytes <= lowThresholdBytes) {
              currentAlert = 'low'; 
            }

            final lastAlert = prefs.getString('last_quota_alert') ?? 'normal';
            int alertCount = prefs.getInt('quota_alert_count') ?? 0;
            
            debugPrint('📊 [QUOTA_MONITOR] Expected Balance: ${(expectedBalanceBytes / oneGB).toStringAsFixed(2)}GB, Alert: $currentAlert');

            if (currentAlert != 'normal') {
              if (currentAlert != lastAlert) {
                alertCount = 1;
                await prefs.setInt('quota_alert_timestamp', DateTime.now().millisecondsSinceEpoch);
                debugPrint('📊 [QUOTA_MONITOR] New alert state! Firing notification 1/3.');
                await _showNotification(
                  id: 102,
                  title: currentAlert == 'critical' ? 'رصيد البيانات ينفد!' : 'رصيد البيانات منخفض',
                  body: 'الرصيد المتبقي المتوقع: ${(expectedBalanceBytes / oneGB).toStringAsFixed(2)} جيجا بايت.',
                );
              } else if (alertCount < 3) {
                alertCount++;
                debugPrint('📊 [QUOTA_MONITOR] Repeating alert state. Firing notification $alertCount/3.');
                await _showNotification(
                  id: 102,
                  title: currentAlert == 'critical' ? 'رصيد البيانات ينفد!' : 'رصيد البيانات منخفض',
                  body: 'الرصيد المتبقي المتوقع: ${(expectedBalanceBytes / oneGB).toStringAsFixed(2)} جيجا بايت.',
                );
              } else {
                // تم الوصول للحد الأقصى للإشعارات، نتحقق من مرور 12 ساعة
                final lastTimestamp = prefs.getInt('quota_alert_timestamp') ?? 0;
                final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
                if (DateTime.now().difference(lastDate).inHours >= 3) {
                  alertCount = 1; // تصفير وبدء دورة جديدة
                  await prefs.setInt('quota_alert_timestamp', DateTime.now().millisecondsSinceEpoch);
                  debugPrint('📊 [QUOTA_MONITOR] 12 hours passed. Resetting alert. Firing notification 1/3.');
                  await _showNotification(
                    id: 102,
                    title: currentAlert == 'critical' ? 'رصيد البيانات ينفد!' : 'رصيد البيانات منخفض',
                    body: 'الرصيد المتبقي المتوقع: ${(expectedBalanceBytes / oneGB).toStringAsFixed(2)} جيجا بايت.',
                  );
                } else {
                  debugPrint('📊 [QUOTA_MONITOR] Max notifications (3/3) reached for this alert. Waiting for 12h.');
                }
              }
            } else {
              debugPrint('📊 [QUOTA_MONITOR] Alert state is normal. No notification needed.');
            }
            
            if (expectedBalanceBytes > lowThresholdBytes) {
              currentAlert = 'normal';
              alertCount = 0;
            }
            
            await prefs.setString('last_quota_alert', currentAlert);
            await prefs.setInt('quota_alert_count', alertCount);
          }
        }
      }
    } catch (e) {
      debugPrint('📊 [QUOTA_MONITOR] Error: $e');
    }
  }

  static Future<void> checkExpiryAndNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryEnabled = prefs.getBool('expiry_monitor_enabled') ?? true;
      if (!expiryEnabled) return;

      final trackingData = await BalanceTrackingService.getData();
      if (trackingData == null || trackingData.expiryDate == null) {
        debugPrint('📅 [EXPIRY_MONITOR] No expiry date tracking data found. Skipping.');
        return;
      }

      final expiryDateStr = trackingData.expiryDate!;
      DateTime? expiryDate;
      try {
        String formattedDateStr = expiryDateStr;
        // Check if format is DD-MM-YYYY
        if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(expiryDateStr)) {
          final parts = expiryDateStr.split('-');
          formattedDateStr = '${parts[2]}-${parts[1]}-${parts[0]}';
        } else if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(expiryDateStr)) {
          final parts = expiryDateStr.split('/');
          formattedDateStr = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
        
        expiryDate = DateTime.parse(formattedDateStr);
      } catch (e) {
        debugPrint('📅 [EXPIRY_MONITOR] Error parsing date: $expiryDateStr. Exception: $e');
        return;
      }

      final today = DateTime.now();
      final difference = expiryDate.difference(today);
      
      final alertDays = prefs.getInt('expiry_alert_days') ?? 3;
      
      if (difference.inDays >= 0 && difference.inDays <= alertDays) {
        final lastTimestamp = prefs.getInt('expiry_alert_timestamp') ?? 0;
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
        
        // التنبيه مرة واحدة فقط كل 3 ساعات لتجنب الإزعاج
        if (today.difference(lastDate).inHours >= 12) {
          await prefs.setInt('expiry_alert_timestamp', today.millisecondsSinceEpoch);
          debugPrint('📅 [EXPIRY_MONITOR] Alerting for expiry. Days left: ${difference.inDays}');
          await _showNotification(
            id: 103,
            title: 'باقة البيانات تقترب من الانتهاء',
            body: 'تنبيه: ستنتهي باقة البيانات الخاصة بك خلال ${difference.inDays} أيام (في تاريخ $expiryDateStr).',
          );
        } else {
          debugPrint('📅 [EXPIRY_MONITOR] Expiry condition met but 12h not passed since last alert.');
        }
      } else {
         debugPrint('📅 [EXPIRY_MONITOR] Expiry condition not met. Days left: ${difference.inDays}, threshold: $alertDays');
      }

    } catch (e) {
      debugPrint('📅 [EXPIRY_MONITOR] Error: $e');
    }
  }

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    // بدء المراقبة السريعة أثناء فتح التطبيق
    startForegroundMonitoring();
  }

  static void startForegroundMonitoring() {
    _foregroundBatteryTimer?.cancel();
    _foregroundQuotaTimer?.cancel();
    
    // التحقق من البطارية كل 5 دقائق أثناء الشاشة الأمامية
    _foregroundBatteryTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await checkBatteryAndNotify();
    });

    // التحقق من الرصيد والانتهاء كل 120 دقيقة أثناء الشاشة الأمامية
    _foregroundQuotaTimer = Timer.periodic(const Duration(minutes: 40), (timer) async {
      await checkQuotaAndNotify();
      await checkExpiryAndNotify();
    });
  }

  static Future<void> requestPermissions() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      // طلب استثناء التطبيق من قيود توفير البطارية لضمان عمل الإشعارات في الخلفية
      try {
        final isGranted = await Permission.ignoreBatteryOptimizations.isGranted;
        if (!isGranted) {
          // Show explanation dialog first
          bool userAgreed = false;
          await Get.defaultDialog(
            title: "اشعارات البطارية و الرصيد",
            titleStyle: const TextStyle(fontWeight: FontWeight.bold),
            content: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "لكي تصلك إشعارات البطارية والرصيد في وقتها حتى لو كان التطبيق مغلقاً، نحتاج إلى استثناء التطبيق من قيود توفير الطاقة الخاصة بنظام أندرويد.\n\nبمجرد الضغط على 'موافق'، ستظهر لك رسالة من النظام، يرجى اختيار 'السماح' (Allow).\n\nهذا الاجراء أمن تماماً ولن يضر بجهازك",
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5),
              ),
            ),
            textConfirm: "موافق، السماح",
            textCancel: "ليس الآن",
            confirmTextColor: Colors.white,
            onConfirm: () {
              userAgreed = true;
              Get.back();
            },
            onCancel: () {
              userAgreed = false;
            }
          );
          
          if (userAgreed) {
            await Permission.ignoreBatteryOptimizations.request();
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error requesting ignoreBatteryOptimizations: $e');
      }
    }
  }

  static Future<void> startMonitoring() async {
    await requestPermissions();
    
    // مهمة مراقبة البطارية (كل 15 دقيقة كحد أدنى مسموح)
    await Workmanager().registerPeriodicTask(
      "modem_battery_monitor_task",
      batteryMonitorTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected, // Only run when connected to a network (WiFi)
      ),
    );

    // مهمة مراقبة الرصيد (كل 120 دقيقة)
    await Workmanager().registerPeriodicTask(
      "modem_quota_monitor_task",
      quotaExpiryMonitorTask,
      frequency: const Duration(minutes: 40),
      constraints: Constraints(
        networkType: NetworkType.connected, // Only run when connected to a network (WiFi)
      ),
    );
  }

  static Future<void> stopMonitoring() async {
    await Workmanager().cancelByUniqueName("modem_battery_monitor_task");
    await Workmanager().cancelByUniqueName("modem_quota_monitor_task");
  }

  static Future<void> testNotification() async {
    await requestPermissions();
    await _showNotification(
      title: 'اختبار الإشعار 🔋', 
      body: 'هذا الإشعار لتجربة نظام التنبيهات. كل شيء يعمل بنجاح!'
    );
  }
}
