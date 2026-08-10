import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/app_security_service.dart';
import 'core/services/battery_monitor_service.dart';
import 'core/services/fcm_notification_service.dart';
import 'features/connected_devices/infrastructure/services/background_device_monitor.dart';
import 'features/splash/presentation/pages/splash_page.dart';

/// نقطة الدخول الموحدة لجميع مهام الخلفية (Workmanager)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == batteryMonitorTask) {
      await BatteryMonitorService.checkBatteryAndNotify();
    } else if (task == quotaExpiryMonitorTask) {
      await BatteryMonitorService.checkQuotaAndNotify();
      await BatteryMonitorService.checkExpiryAndNotify();
    } else if (task == backgroundDeviceMonitorTask) {
      await BackgroundDeviceMonitor.checkDevicesAndNotify();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDI();

  // 🛡️ تهيئة نظام الحماية ضد الهندسة العكسية والعبث
  await AppSecurityService.instance.initialize();
  
  // تهيئة خدمة مراقبة البطارية في الخلفية
  await BatteryMonitorService.initialize();

  // تهيئة خدمة الإشعارات (Firebase Cloud Messaging) دون تعطيل بدء التطبيق
  FcmNotificationService().initialize();

  runApp(const ModemApp());
}

class ModemApp extends StatelessWidget {
  const ModemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'إعدادات مودم SAM4G', // لمسة شخصية لعلامتك التجارية
      themeMode: ThemeMode.system, // Using system preference to switch automatically
      debugShowCheckedModeBanner: false, 
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      // إعدادات التوطين واللغة العربية
      locale: const Locale('ar'), // اللغة الافتراضية
      supportedLocales: const [
        Locale('ar'), // العربية
        Locale('en'), // الإنجليزية (اختياري، تحسباً لاحتياجها لاحقاً)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      home: SplashPage(),
    );
  }
}