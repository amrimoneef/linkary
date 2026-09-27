import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/domain/entities/search_item.dart';

// Pages
import 'package:linkary/features/settings/presentation/pages/wifi_settings_page.dart';
import 'package:linkary/features/connected_devices/presentation/pages/connected_devices_page.dart';
import 'package:linkary/features/speed_limit/presentation/pages/speed_limit_page.dart';
import 'package:linkary/features/data_usage/presentation/pages/data_usage_page.dart';
import 'package:linkary/features/parental_control/presentation/pages/parental_control_page.dart';
import 'package:linkary/features/mac_filter/presentation/pages/mac_filter_page.dart';
import 'package:linkary/features/url_filter/presentation/pages/url_filter_page.dart';
import 'package:linkary/features/device_data_limit/presentation/pages/device_data_limit_page.dart';
import 'package:linkary/features/bill/presentation/pages/bill_page.dart';
import 'package:linkary/features/settings/presentation/pages/battery_settings_page.dart';
import 'package:linkary/features/settings/presentation/pages/lcd_settings_page.dart';
import 'package:linkary/features/settings/presentation/pages/admin_settings_page.dart';
import 'package:linkary/features/quick_tools_and_widgets/presentation/pages/widgets_settings_page.dart';
import 'package:linkary/features/about/presentation/pages/about_page.dart';
import 'package:linkary/features/notifications/presentation/pages/notifications_page.dart';
import 'package:linkary/features/speed_test/presentation/pages/speed_test_page.dart';
import 'package:linkary/features/signal_finder/presentation/pages/signal_finder_page.dart';
import 'package:linkary/features/modem_finder/presentation/pages/modem_finder_page.dart';

// Controllers
import 'package:linkary/features/connected_devices/presentation/controllers/connected_devices_controller.dart';
import 'package:linkary/features/modem_auth/presentation/controllers/auth_controller.dart';

class SearchIndexRegistry {
  /// Returns the static index of all settings, tools, and screens in Linkary
  List<SearchItem> getStaticItems() {
    return [
      // 1. Wi-Fi Settings
      SearchItem(
        id: 'wifi_settings',
        title: 'إعدادات الواي فاي',
        subtitle: 'تعديل اسم الشبكة (SSID)، كلمة السر، والتردد',
        icon: Iconsax.wifi,
        category: SearchCategory.settings,
        priority: 10,
        keywords: const [
          'wifi', 'واي فاي', 'باسورد', 'كلمة السر', 'اسم الشبكة',
          'ssid', 'الشبكة', 'password', 'كلمة المرور', 'وايرلس',
          'تردد', '5ghz', '2.4ghz', 'رمز الشبكة'
        ],
        onTap: () => Get.to(() => WifiSettingsPage()),
      ),

      // 2. Connected Devices Page
      SearchItem(
        id: 'connected_devices',
        title: 'الأجهزة المتصلة',
        subtitle: 'عرض وإدارة الأجهزة المتصلة بالمودم حالياً',
        icon: Iconsax.devices,
        category: SearchCategory.devices,
        priority: 9,
        keywords: const [
          'اجهزة', 'متصلة', 'هواتف', 'ip', 'mac', 'المتصلين',
          'devices', 'clients', 'من متصل', 'كم جهاز', 'أجهزة'
        ],
        onTap: () => Get.to(() => ConnectedDevicesPage()),
      ),

      // 3. Speed Limit
      SearchItem(
        id: 'speed_limit',
        title: 'تحديد سرعة الإنترنت',
        subtitle: 'تقييد سرعة الرفع والتنزيل لشبكة الواي فاي',
        icon: Iconsax.speedometer,
        category: SearchCategory.settings,
        priority: 7,
        keywords: const [
          'تحديد السرعة', 'سرعة', 'limit', 'باندويث',
          'bandwidth', 'throttle', 'تخفيض السرعة', 'تحديد سرعه'
        ],
        onTap: () => Get.to(() => SpeedLimitPage()),
      ),

      // 4. Data Usage
      SearchItem(
        id: 'data_usage',
        title: 'استهلاك البيانات والباقة',
        subtitle: 'متابعة الرصيد المتبقي وسجل استهلاك الجيجابايت',
        icon: Iconsax.chart_2,
        category: SearchCategory.settings,
        priority: 8,
        keywords: const [
          'استهلاك', 'باقة', 'بيانات', 'رصيد', 'جيجا',
          'usage', 'data', 'quota', 'النت المتبقي', 'كم باقي'
        ],
        onTap: () => Get.to(() => DataUsagePage()),
      ),

      // 5. Parental Control
      SearchItem(
        id: 'parental_control',
        title: 'الرقابة الأبوية',
        subtitle: 'جدولة أوقات الاتصال وحماية الأطفال على الشبكة',
        icon: Iconsax.security_user,
        category: SearchCategory.settings,
        priority: 6,
        keywords: const [
          'رقابة ابوية', 'رقابة', 'حظر', 'وقت', 'مواقع',
          'parental', 'filter', 'time', 'جدول', 'توقيت'
        ],
        onTap: () => Get.to(() => ParentalControlPage()),
      ),

      // 6. MAC Filter
      SearchItem(
        id: 'mac_filter',
        title: 'تصفية وحظر الماك (MAC Filter)',
        subtitle: 'القائمة السوداء والبيضاء لحظر أجهزة محددة تماماً',
        icon: Iconsax.shield_cross,
        category: SearchCategory.settings,
        priority: 7,
        keywords: const [
          'ماك ادرس', 'حظر', 'تبليك', 'mac', 'blacklist',
          'whitelist', 'عنوان', 'طرد', 'بلوك'
        ],
        onTap: () => Get.to(() => MacFilterPage()),
      ),

      // 7. URL Filter
      SearchItem(
        id: 'url_filter',
        title: 'حجب المواقع والروابط (URL Filter)',
        subtitle: 'منع الوصول لمواقع أو نطاقات محددة من المودم',
        icon: Iconsax.global_refresh,
        category: SearchCategory.settings,
        priority: 6,
        keywords: const [
          'حجب المواقع', 'روابط', 'فلترة', 'url', 'website',
          'block', 'موقع', 'دومين', 'حظر رابط'
        ],
        onTap: () => Get.to(() => const UrlFilterPage()),
      ),

      // 8. Device Data Limit
      SearchItem(
        id: 'device_data_limit',
        title: 'تحديد بيانات كل جهاز',
        subtitle: 'تعيين سقف ميجابايت مخصص لكل جهاز متصل',
        icon: Iconsax.percentage_circle,
        category: SearchCategory.settings,
        priority: 6,
        keywords: const [
          'تحديد بيانات الاجهزة', 'استهلاك الاجهزة', 'ليمت',
          'device limit', 'سقف البيانات', 'تحديد استهلاك'
        ],
        onTap: () => Get.to(() => const DeviceDataLimitPage()),
      ),

      // 9. Bill & Recharge
      SearchItem(
        id: 'bill',
        title: 'الفاتورة وتجديد الباقة',
        subtitle: 'شحن الرصيد وسداد الفواتير والاستعلام',
        icon: Iconsax.receipt_2,
        category: SearchCategory.settings,
        priority: 7,
        keywords: const [
          'فاتورة', 'شحن', 'سداد', 'رصيد', 'دفع',
          'bill', 'recharge', 'payment', 'تجديد'
        ],
        onTap: () => Get.to(() => BillPage()),
      ),

      // 10. Battery Settings
      SearchItem(
        id: 'battery_settings',
        title: 'إعدادات البطارية وتوفير الطاقة',
        subtitle: 'إدارة وضع السكون والحفاظ على عمر البطارية',
        icon: Iconsax.battery_charging,
        category: SearchCategory.settings,
        priority: 5,
        keywords: const [
          'بطارية', 'شحن', 'توفير الطاقة', 'battery',
          'power saving', 'حفظ الطاقة', 'استهلاك البطارية'
        ],
        onTap: () => Get.to(() => const BatterySettingsPage()),
      ),

      // 11. LCD Settings
      SearchItem(
        id: 'lcd_settings',
        title: 'إعدادات شاشة المودم (LCD)',
        subtitle: 'التحكم في سطوع شاشة المودم ومدة السكون',
        icon: Iconsax.monitor,
        category: SearchCategory.settings,
        priority: 5,
        keywords: const [
          'شاشة', 'اضاءة', 'سكون', 'lcd', 'display',
          'screen', 'timeout', 'شاشه المودم'
        ],
        onTap: () => Get.to(() => const LcdSettingsPage()),
      ),

      // 12. Admin Settings
      SearchItem(
        id: 'admin_settings',
        title: 'كلمة مرور تطبيق المودم (Admin)',
        subtitle: 'تعديل كلمة سر لوحة التحكم وحساب المشرف',
        icon: Iconsax.key,
        category: SearchCategory.settings,
        priority: 6,
        keywords: const [
          'كلمة سر المودم', 'ادمن', 'تسجيل الدخول', 'admin',
          'password', 'login', 'باسورد المودم', 'لوحة التحكم'
        ],
        onTap: () => Get.to(() => const AdminSettingsPage()),
      ),

      // 13. Smart Tool: Speed Test
      SearchItem(
        id: 'speed_test',
        title: 'فحص سرعة الإنترنت (Speed Test)',
        subtitle: 'قياس سرعة التنزيل والرفع وزمن الاستجابة (Ping)',
        icon: Iconsax.flash_circle,
        category: SearchCategory.smartTools,
        priority: 9,
        keywords: const [
          'سرعة', 'قياس', 'نت', 'اختبار', 'فحص',
          'speed', 'fast', 'download', 'upload', 'ping'
        ],
        onTap: () => Get.to(() => const SpeedTestPage()),
      ),

      // 14. Smart Tool: Signal Finder
      SearchItem(
        id: 'signal_finder',
        title: 'كاشف إشارة الشبكة (Signal Finder)',
        subtitle: 'البحث عن أقوى مكان للتغطية وأبراج الاتصال',
        icon: Iconsax.radar,
        category: SearchCategory.smartTools,
        priority: 8,
        keywords: const [
          'اشارة', 'ابراج', 'شبكة', 'افضل مكان', 'تغطية',
          'signal', '4g', '5g', 'rssi', 'rsrp', 'مكان التغطية'
        ],
        onTap: () => Get.to(() => const SignalFinderPage()),
      ),

      // 15. Smart Tool: Modem Finder
      SearchItem(
        id: 'modem_finder',
        title: 'البحث عن المودم (Modem Finder)',
        subtitle: 'تحديد موقع جهاز المودم المفقود عبر الرنين والإشارة',
        icon: Iconsax.location,
        category: SearchCategory.smartTools,
        priority: 8,
        keywords: const [
          'البحث عن المودم', 'اين المودم', 'فايندر', 'finder',
          'locate', 'ضائع', 'رنين المودم', 'مكان المودم'
        ],
        onTap: () => Get.to(() => const ModemFinderPage()),
      ),

      // 16. Tool: Quick Tools & Widgets Settings
      SearchItem(
        id: 'widgets_settings',
        title: 'تخصيص الودجات والأدوات السريعة',
        subtitle: 'إعداد الودجات على الشاشة الرئيسية وشريط التنبيهات',
        icon: Iconsax.element_plus,
        category: SearchCategory.tools,
        priority: 5,
        keywords: const [
          'ودجات', 'اختصارات', 'شريط اشعارات', 'widgets',
          'quick tools', 'tiles', 'ودجت', 'اختصار'
        ],
        onTap: () => Get.to(() => const WidgetsSettingsPage()),
      ),

      // 17. Tool: Notifications
      SearchItem(
        id: 'notifications',
        title: 'سجل الإشعارات والتنبيهات',
        subtitle: 'استعراض التنبيهات الأمنية وتغيرات الشبكة',
        icon: Iconsax.notification,
        category: SearchCategory.tools,
        priority: 5,
        keywords: const [
          'اشعارات', 'تنبيهات', 'notifications', 'alerts',
          'رسائل', 'تحذيرات'
        ],
        onTap: () => Get.to(() => NotificationsPage()),
      ),

      // 18. Tool: About Linkary
      SearchItem(
        id: 'about',
        title: 'حول التطبيق وتحديثات Linkary',
        subtitle: 'معلومات الإصدار، المطور، وحقوق التطبيق',
        icon: Iconsax.info_circle,
        category: SearchCategory.tools,
        priority: 3,
        keywords: const [
          'عن التطبيق', 'حول', 'اصدار', 'مطور',
          'version', 'about', 'تحديث', 'لينكاري'
        ],
        onTap: () => Get.to(() => const AboutPage()),
      ),

      // 19. Quick Action: Reboot Modem
      SearchItem(
        id: 'reboot_modem',
        title: 'إعادة تشغيل المودم (Reboot)',
        subtitle: 'إجراء فوري لإعادة إقلاع المودم وتحسين الاتصال',
        icon: Iconsax.refresh,
        category: SearchCategory.quickActions,
        isDestructive: true,
        confirmationMessage: 'هل أنت متأكد من رغبتك في إعادة تشغيل المودم الآن؟ سيتم فصل الاتصال لثوانٍ معدودة.',
        priority: 8,
        keywords: const [
          'اعادة تشغيل', 'ريستارت', 'reboot', 'restart',
          'راوتر', 'اطفاء وتشغيل', 'إعادة تشغيل'
        ],
        onTap: () {
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().rebootDirect();
          }
        },
      ),

      // 20. Quick Action: Power Off
      SearchItem(
        id: 'power_off',
        title: 'إيقاف تشغيل المودم (Power Off)',
        subtitle: 'إغلاق المودم بالكامل للحفاظ على البطارية',
        icon: Icons.power_settings_new_rounded,
        category: SearchCategory.quickActions,
        isDestructive: true,
        confirmationMessage: 'هل أنت متأكد من رغبتك في إيقاف تشغيل المودم؟ سيتطلب تشغيله مجدداً الضغط اليدوي على زر الباور.',
        priority: 7,
        keywords: const [
          'ايقاف', 'اغلاق', 'اطفاء', 'shutdown',
          'power off', 'باور', 'ايقاف تشغيل'
        ],
        onTap: () {
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().powerOff();
          }
        },
      ),
    ];
  }

  /// Returns dynamic items from live registered controllers (Connected Devices, etc.)
  List<SearchItem> getDynamicItems() {
    final List<SearchItem> dynamicItems = [];

    // Dynamically pull connected devices from ConnectedDevicesController
    if (Get.isRegistered<ConnectedDevicesController>()) {
      try {
        final devicesController = Get.find<ConnectedDevicesController>();
        final devices = devicesController.devices;
        final customNames = devicesController.customNames;

        for (final device in devices) {
          final displayName = customNames[device.mac] ?? device.name;
          final isWifi = device.type.toUpperCase() == 'WIFI';

          dynamicItems.add(
            SearchItem(
              id: 'device_${device.mac}',
              title: displayName.isNotEmpty ? displayName : 'جهاز متصل (${device.ip})',
              subtitle: 'IP: ${device.ip}  •  MAC: ${device.mac}',
              icon: isWifi ? Iconsax.wifi : Icons.cable_rounded,
              category: SearchCategory.devices,
              priority: 9,
              keywords: [
                device.name,
                device.ip,
                device.mac,
                if (displayName.isNotEmpty) displayName,
                'جهاز', 'متصل', 'هاتف', 'كمبيوتر',
              ],
              onTap: () => Get.to(() => ConnectedDevicesPage()),
              quickActionWidget: IconButton(
                icon: const Icon(Iconsax.copy, size: 18),
                tooltip: 'نسخ عنوان IP و MAC',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '${device.ip} (${device.mac})'));
                  Get.rawSnackbar(
                    message: 'تم نسخ بيانات الجهاز (${device.ip})',
                    duration: const Duration(seconds: 2),
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(15),
                    borderRadius: 12,
                  );
                },
              ),
            ),
          );
        }
      } catch (_) {
        // Safe fallback if controller is not yet initialized with data
      }
    }

    return dynamicItems;
  }
}
