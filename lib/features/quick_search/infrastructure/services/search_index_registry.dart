import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/domain/entities/search_item.dart';

// Pages
import 'package:linkary/features/settings/presentation/pages/wifi_settings_page.dart';

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
import 'package:linkary/features/network_info/presentation/pages/network_info_page.dart';
import 'package:linkary/features/mifi_app_monitor/presentation/pages/app_monitor_screen.dart';
import 'package:linkary/features/mifi_app_monitor/presentation/pages/firewall_management_screen.dart';
import 'package:linkary/features/device_management/presentation/pages/device_management_page.dart';
import 'package:linkary/features/quick_setup/presentation/pages/quick_setup_page.dart';
import 'package:linkary/features/signal_finder/presentation/pages/saved_locations_page.dart';
import 'package:linkary/features/modem_finder/presentation/pages/modem_finder_settings_page.dart';
import 'package:linkary/features/feedback/presentation/pages/feedback_page.dart';

// Controllers & Services
import 'package:linkary/features/connected_devices/presentation/controllers/connected_devices_controller.dart';
import 'package:linkary/features/modem_auth/presentation/controllers/auth_controller.dart';
import 'package:linkary/features/settings/presentation/controllers/wifi_settings_controller.dart';
import 'package:linkary/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:linkary/features/modem_finder/presentation/controllers/modem_finder_controller.dart';
import 'package:linkary/core/services/tutorial_service.dart';

class SearchIndexRegistry {
  /// Returns the static index of all settings, tools, and screens in Linkary
  List<SearchItem> getStaticItems() {
    return [
      // ═══════════════════════════════════════════════════════════════
      // 1. الإجراءات المباشرة الفورية (Quick Actions)
      // ═══════════════════════════════════════════════════════════════

      // إجراء: نسخ كلمة سر الواي فاي الحالية
      SearchItem(
        id: 'action_copy_wifi_password',
        title: 'نسخ كلمة سر الواي فاي الحالية',
        subtitle: 'نسخ فوري للرمز السري لشبكة الواي فاي إلى الحافظة',
        icon: Iconsax.copy,
        category: SearchCategory.quickActions,
        priority: 12,
        keywords: const [
          'نسخ', 'باسورد', 'كلمة السر', 'واي فاي', 'wifi',
          'رمز', 'كود', 'نسخ الباسورد', 'copy password', 'رمز الشبكة'
        ],
        onTap: () {
          String pass = '';
          if (Get.isRegistered<WifiSettingsController>()) {
            pass = Get.find<WifiSettingsController>().passwordController.text;
          }
          if (pass.isEmpty) {
            Get.rawSnackbar(
              message: 'يرجى فتح إعدادات الواي فاي أولاً لجلب كلمة السر',
              duration: const Duration(seconds: 2),
            );
            Get.to(() => WifiSettingsPage());
            return;
          }
          Clipboard.setData(ClipboardData(text: pass));
          Get.rawSnackbar(
            message: 'تم نسخ كلمة سر الواي فاي: $pass',
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
      ),

      // إجراء: مشاركة شبكة الواي فاي عبر باركود QR
      SearchItem(
        id: 'action_wifi_qr',
        title: 'مشاركة الواي فاي عبر رمز QR',
        subtitle: 'عرض باركود فوري للاتصال بالشبكة دون كتابة الرمز',
        icon: Iconsax.scan_barcode,
        category: SearchCategory.quickActions,
        priority: 11,
        keywords: const [
          'qr', 'باركود', 'كود', 'مشاركة', 'واي فاي',
          'رمز qr', 'مسح', 'اتصال سريع', 'share wifi', 'مشاركة الواي فاي'
        ],
        onTap: () {
          String ssid = 'Linkary_4G';
          String pass = '';
          if (Get.isRegistered<WifiSettingsController>()) {
            final c = Get.find<WifiSettingsController>();
            if (c.ssidController.text.isNotEmpty) ssid = c.ssidController.text;
            pass = c.passwordController.text;
          }
          final qrData = 'WIFI:T:WPA;S:$ssid;P:$pass;;';
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('اتصال سريع بشبكة الواي فاي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('امسح الرمز بكاميرا الهاتف للاتصال بشبكة ($ssid)', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: QrImageView(data: qrData, size: 200, version: QrVersions.auto),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      // إجراء: تبديل الوضع الليلي / النهاري
      SearchItem(
        id: 'action_toggle_theme',
        title: 'تبديل الوضع الليلي / النهاري',
        subtitle: 'التحويل الفوري بين الثيم الداكن والفاتح',
        icon: Iconsax.moon,
        category: SearchCategory.quickActions,
        priority: 12,
        keywords: const [
          'ثيم', 'ليلي', 'نهاري', 'دارك', 'لايت', 'مظلم',
          'وضع ليلي', 'داكن', 'theme', 'dark mode', 'light mode'
        ],
        onTap: () {
          final isCurrentlyDark = Get.context != null
              ? Theme.of(Get.context!).brightness == Brightness.dark
              : Get.isDarkMode;
          Get.changeThemeMode(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
          Get.rawSnackbar(
            message: isCurrentlyDark ? 'تم التبديل إلى الوضع النهاري' : 'تم التبديل إلى الوضع الليلي',
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
      ),

      // إجراء: نسخ عنوان IP صفحة الراوتر
      SearchItem(
        id: 'action_copy_gateway_ip',
        title: 'نسخ عنوان لوحة تحكم الراوتر (IP)',
        subtitle: 'نسخ عنوان البوابة الافتراضية (192.168.8.1)',
        icon: Iconsax.copy,
        category: SearchCategory.quickActions,
        priority: 11,
        keywords: const [
          'ip', '192.168', 'عنوان', 'راوتر', 'بوابة', 'مودم', 'gateway', 'نسخ ip'
        ],
        onTap: () {
          Clipboard.setData(const ClipboardData(text: '192.168.8.1'));
          Get.rawSnackbar(
            message: 'تم نسخ عنوان IP الراوتر: 192.168.8.1',
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
      ),

      // إجراء: تحديث بيانات المودم
      SearchItem(
        id: 'action_refresh_data',
        title: 'تحديث بيانات وحالة المودم الآن',
        subtitle: 'إعادة جلب السرعة والبطارية والإشارة فوراً',
        icon: Iconsax.refresh_circle,
        category: SearchCategory.quickActions,
        priority: 10,
        keywords: const [
          'تحديث', 'ريفرش', 'جلب البيانات', 'فحص', 'الان', 'refresh'
        ],
        onTap: () {
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().fetchData();
          }
          Get.rawSnackbar(
            message: 'جاري تحديث بيانات الراوتر...',
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
      ),

      // إجراء: إعادة تشغيل المودم (Reboot)
      SearchItem(
        id: 'reboot_modem',
        title: 'إعادة تشغيل المودم (Reboot)',
        subtitle: 'إجراء فوري لإعادة إقلاع الراوتر وتحسين سرعة الاتصال',
        icon: Iconsax.refresh,
        category: SearchCategory.quickActions,
        isDestructive: true,
        confirmationMessage: 'هل أنت متأكد من رغبتك في إعادة تشغيل الراوتر الآن؟ سيتم فصل الاتصال لثوانٍ معدودة.',
        priority: 10,
        keywords: const [
          'اعادة تشغيل', 'ريستارت', 'reboot', 'restart',
          'راوتر', 'اطفاء وتشغيل', 'إعادة تشغيل', 'تنشيط الراوتر'
        ],
        onTap: () {
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().rebootDirect();
          }
        },
      ),

      // إجراء: إيقاف تشغيل المودم (Power Off)
      SearchItem(
        id: 'power_off',
        title: 'إيقاف تشغيل المودم (Power Off)',
        subtitle: 'إغلاق المودم بالكامل للحفاظ على البطارية',
        icon: Icons.power_settings_new_rounded,
        category: SearchCategory.quickActions,
        isDestructive: true,
        confirmationMessage: 'هل أنت متأكد من رغبتك في إيقاف تشغيل المودم؟ سيتطلب تشغيله مجدداً الضغط اليدوي على زر الباور.',
        priority: 9,
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

      // إجراء: رنين البحث عن المودم (Ring Modem)
      SearchItem(
        id: 'action_ring_modem',
        title: 'تشغيل رنين البحث عن الراوتر',
        subtitle: 'إطلاق نغمة صوتية عالية من الراوتر للمساعدة في إيجاده',
        icon: Iconsax.volume_high,
        category: SearchCategory.quickActions,
        priority: 9,
        keywords: const [
          'رنين', 'صوت', 'نغمة', 'ايجاد الراوتر', 'مفقود', 'ring', 'alert'
        ],
        onTap: () {
          Get.to(() => const ModemFinderPage());
          if (Get.isRegistered<ModemFinderController>()) {
            Get.find<ModemFinderController>().startScanning();
          }
        },
      ),

      // إجراء: استعادة ضبط المصنع (Factory Reset)
      SearchItem(
        id: 'action_factory_reset',
        title: 'استعادة ضبط المصنع للمودم (Reset)',
        subtitle: 'مسح كافة الإعدادات والرجوع للحالة الأصلية للراوتر',
        icon: Iconsax.danger,
        category: SearchCategory.quickActions,
        isDestructive: true,
        confirmationMessage: 'تحذير شديد: هذا الإجراء سيمسح جميع الإعدادات وكلمات المرور الخاصة بالراوتر ويعيدها لضبط المصنع!',
        priority: 6,
        keywords: const [
          'ضبط مصنع', 'فورمات', 'ريست', 'reset', 'factory reset', 'مسح'
        ],
        onTap: () {
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().factoryReset();
          }
        },
      ),

      // إجراء: تسجيل الخروج من المودم
      SearchItem(
        id: 'action_logout_modem',
        title: 'تسجيل الخروج من المودم',
        subtitle: 'إنهاء جلسة المشرف الحالية وقفل لوحة التحكم',
        icon: Iconsax.logout,
        category: SearchCategory.quickActions,
        isDestructive: true,
        confirmationMessage: 'هل أنت متأكد من رغبتك في تسجيل الخروج من لوحة تحكم المودم؟',
        priority: 7,
        keywords: const [
          'خروج', 'تسجيل خروج', 'logout', 'قفل', 'انهاء'
        ],
        onTap: () {
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().logout();
          }
        },
      ),

      // ═══════════════════════════════════════════════════════════════
      // 2. إعدادات المودم وشبكة الواي فاي (Settings)
      // ═══════════════════════════════════════════════════════════════

      // 1. Wi-Fi Settings
      SearchItem(
        id: 'wifi_settings',
        title: 'إعدادات الواي فاي',
        subtitle: 'تعديل اسم الشبكة (SSID)، كلمة السر، والتردد',
        icon: Iconsax.wifi,
        category: SearchCategory.settings,
        priority: 15,
        keywords: const [
          'wifi', 'واي فاي', 'باسورد', 'كلمة السر', 'اسم الشبكة',
          'ssid', 'الشبكة', 'password', 'كلمة المرور', 'وايرلس',
          'تردد', '5ghz', '2.4ghz', 'رمز الشبكة'
        ],
        onTap: () => Get.to(() => WifiSettingsPage()),
      ),

      // 2. Connected Devices Page -> Device Management
      SearchItem(
        id: 'connected_devices',
        title: 'الأجهزة المتصلة (إدارة الأجهزة)',
        subtitle: 'عرض وإدارة وحظر الأجهزة المتصلة بالمودم حالياً',
        icon: Iconsax.devices,
        category: SearchCategory.devices,
        priority: 14,
        keywords: const [
          'اجهزة', 'متصلة', 'هواتف', 'ip', 'mac', 'المتصلين',
          'devices', 'clients', 'من متصل', 'كم جهاز', 'أجهزة',
          'إدارة الأجهزة', 'ادارة الاجهزة'
        ],
        onTap: () => Get.to(() => const DeviceManagementPage()),
      ),

      // 3. Speed Limit
      SearchItem(
        id: 'speed_limit',
        title: 'تحديد سرعة الإنترنت',
        subtitle: 'تقييد سرعة الرفع والتنزيل لشبكة الواي فاي',
        icon: Iconsax.speedometer,
        category: SearchCategory.settings,
        priority: 11,
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
        priority: 12,
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
        priority: 10,
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
        priority: 11,
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
        priority: 10,
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
        priority: 9,
        keywords: const [
          'تحديد بيانات الاجهزة', 'استهلاك الاجهزة', 'ليمت',
          'device limit', 'سقف البيانات', 'تحديد استهلاك'
        ],
        onTap: () => Get.to(() => const DeviceDataLimitPage()),
      ),

      // 9. Device Management Page
      SearchItem(
        id: 'device_management',
        title: 'إدارة أجهزة المودم (Device Management)',
        subtitle: 'التحكم في الراوترات المسجلة وإعدادات الجهاز',
        icon: Iconsax.setting_2,
        category: SearchCategory.settings,
        priority: 9,
        keywords: const [
          'ادارة الاجهزة', 'راوترات', 'مودمات', 'device management',
          'اجهزة الراوتر', 'تبديل المودم'
        ],
        onTap: () => Get.to(() => const DeviceManagementPage()),
      ),

      // 10. Bill & Recharge
      SearchItem(
        id: 'bill',
        title: 'الفاتورة وتجديد الباقة',
        subtitle: 'شحن الرصيد وسداد الفواتير والاستعلام',
        icon: Iconsax.receipt_2,
        category: SearchCategory.settings,
        priority: 11,
        keywords: const [
          'فاتورة', 'شحن', 'سداد', 'رصيد', 'دفع',
          'bill', 'recharge', 'payment', 'تجديد'
        ],
        onTap: () => Get.to(() => BillPage()),
      ),

      // 11. Battery Settings
      SearchItem(
        id: 'battery_settings',
        title: 'إعدادات البطارية وتوفير الطاقة',
        subtitle: 'إدارة وضع السكون والحفاظ على عمر البطارية',
        icon: Iconsax.battery_charging,
        category: SearchCategory.settings,
        priority: 8,
        keywords: const [
          'بطارية', 'شحن', 'توفير الطاقة', 'battery',
          'power saving', 'حفظ الطاقة', 'استهلاك البطارية'
        ],
        onTap: () => Get.to(() => const BatterySettingsPage()),
      ),

      // 12. LCD Settings
      SearchItem(
        id: 'lcd_settings',
        title: 'إعدادات شاشة المودم (LCD)',
        subtitle: 'التحكم في سطوع شاشة الراوتر ومدة السكون',
        icon: Iconsax.monitor,
        category: SearchCategory.settings,
        priority: 8,
        keywords: const [
          'شاشة', 'اضاءة', 'سكون', 'lcd', 'display',
          'screen', 'timeout', 'شاشه الراوتر'
        ],
        onTap: () => Get.to(() => const LcdSettingsPage()),
      ),

      // 13. Admin Settings
      SearchItem(
        id: 'admin_settings',
        title: 'كلمة مرور صفحة المودم (Admin)',
        subtitle: 'تعديل كلمة سر لوحة التحكم وحساب المشرف',
        icon: Iconsax.key,
        category: SearchCategory.settings,
        priority: 9,
        keywords: const [
          'كلمة سر المودم', 'ادمن', 'تسجيل الدخول', 'admin',
          'password', 'login', 'باسورد المودم', 'لوحة التحكم'
        ],
        onTap: () => Get.to(() => const AdminSettingsPage()),
      ),

      // 14. Modem Finder Settings
      SearchItem(
        id: 'modem_finder_settings',
        title: 'إعدادات البحث عن الراوتر (Finder Settings)',
        subtitle: 'معايرة حساسية إشارة الرادار والتنبيه الصوتي والاهتزاز',
        icon: Iconsax.radar_2,
        category: SearchCategory.settings,
        priority: 7,
        keywords: const [
          'اعدادات الفايندر', 'معايرة', 'حساسية', 'صوت الفايندر', 'finder settings'
        ],
        onTap: () => Get.to(() => const ModemFinderSettingsPage()),
      ),

      // ═══════════════════════════════════════════════════════════════
      // 3. الأدوات الذكية والمتقدمة (Smart Tools)
      // ═══════════════════════════════════════════════════════════════

      // 1. Network Info & Band Locking
      SearchItem(
        id: 'network_info',
        title: 'معلومات الشبكة والترددات (Network Info)',
        subtitle: 'تفاصيل برج الاتصال، الترددات (Bands)، وقوة الإشارة (RSRP/SINR)',
        icon: Iconsax.chart_1,
        category: SearchCategory.smartTools,
        priority: 14,
        keywords: const [
          'شبكة', 'برج', 'تردد', 'ترددات', 'band', 'cell id',
          'rsrp', 'sinr', 'cqi', 'pci', 'تغطية', '4g', '5g',
          'معلومات الشبكة', 'قفل التردد', 'band lock'
        ],
        onTap: () => Get.to(() => NetworkInfoPage()),
      ),

      // 2. Speed Test
      SearchItem(
        id: 'speed_test',
        title: 'فحص سرعة الإنترنت (Speed Test)',
        subtitle: 'قياس سرعة التنزيل والرفع وزمن الاستجابة (Ping)',
        icon: Iconsax.flash_circle,
        category: SearchCategory.smartTools,
        priority: 13,
        keywords: const [
          'سرعة', 'قياس', 'نت', 'اختبار', 'فحص',
          'speed', 'fast', 'download', 'upload', 'ping'
        ],
        onTap: () => Get.to(() => const SpeedTestPage()),
      ),

      // 3. Signal Finder
      SearchItem(
        id: 'signal_finder',
        title: 'كاشف إشارة الشبكة (Signal Finder)',
        subtitle: 'البحث عن أقوى مكان للتغطية وأبراج الاتصال عبر البوصلة',
        icon: Iconsax.radar,
        category: SearchCategory.smartTools,
        priority: 12,
        keywords: const [
          'اشارة', 'ابراج', 'شبكة', 'افضل مكان', 'تغطية',
          'signal', '4g', '5g', 'rssi', 'rsrp', 'مكان التغطية'
        ],
        onTap: () => Get.to(() => const SignalFinderPage()),
      ),

      // 4. Saved Locations
      SearchItem(
        id: 'saved_locations',
        title: 'الأماكن المحفوظة للتغطية (Saved Locations)',
        subtitle: 'سجل أفضل المواقع المنزلية لإشارة المودم والشبكة',
        icon: Iconsax.location_tick,
        category: SearchCategory.smartTools,
        priority: 8,
        keywords: const [
          'اماكن محفوظة', 'مواقع', 'تغطية سابقة', 'مكان الراوتر', 'saved locations'
        ],
        onTap: () => Get.to(() => const SavedLocationsPage()),
      ),

      // 5. Modem Finder
      SearchItem(
        id: 'modem_finder',
        title: 'البحث عن الراوتر (Modem Finder)',
        subtitle: 'تحديد موقع جهاز الراوتر المفقود عبر الرنين والإشارة',
        icon: Iconsax.location,
        category: SearchCategory.smartTools,
        priority: 11,
        keywords: const [
          'البحث عن الراوتر', 'اين المودم', 'فايندر', 'finder',
          'locate', 'ضائع', 'رنين الراوتر', 'مكان المودم'
        ],
        onTap: () => Get.to(() => const ModemFinderPage()),
      ),

      // 6. App Monitor Screen
      SearchItem(
        id: 'app_monitor',
        title: 'مراقب استهلاك التطبيقات (App Monitor)',
        subtitle: 'متابعة البرامج المستهلكة للبيانات والإنترنت على المودم',
        icon: Iconsax.mobile,
        category: SearchCategory.smartTools,
        priority: 10,
        keywords: const [
          'تطبيقات', 'مراقب', 'برامج', 'استهلاك التطبيقات',
          'ترافيك', 'traffic', 'apps', 'سحب النت'
        ],
        onTap: () => Get.to(() => AppMonitorScreen()),
      ),

      // 7. Firewall Management Screen
      SearchItem(
        id: 'firewall_management',
        title: 'الجدار الناري وحظر التطبيقات (Firewall)',
        subtitle: 'منع تطبيقات محددة من استخدام إنترنت المودم',
        icon: Iconsax.shield_security,
        category: SearchCategory.smartTools,
        priority: 10,
        keywords: const [
          'جدار ناري', 'حظر تطبيقات', 'firewall', 'منع برنامج',
          'حجب برامج', 'سيكيورتي', 'حماية'
        ],
        onTap: () => Get.to(() => const FirewallManagementScreen()),
      ),

      // ═══════════════════════════════════════════════════════════════
      // 4. الأدوات العامة والمعلومات (Tools)
      // ═══════════════════════════════════════════════════════════════

      // 1. Quick Setup Page
      SearchItem(
        id: 'quick_setup',
        title: 'معالج الإعداد السريع للمودم (Quick Setup)',
        subtitle: 'خطوات ضبط اسم الشبكة وكلمة المرور من الصفر',
        icon: Iconsax.magic_star,
        category: SearchCategory.tools,
        priority: 9,
        keywords: const [
          'اعداد سريع', 'تهيئة', 'تثبيت', 'معالج', 'quick setup', 'اول مرة'
        ],
        onTap: () => Get.to(() => QuickSetupPage()),
      ),

      // 2. Quick Tools & Widgets Settings
      SearchItem(
        id: 'widgets_settings',
        title: 'تخصيص الودجات والأدوات السريعة',
        subtitle: 'إعداد الودجات على الشاشة الرئيسية وشريط التنبيهات',
        icon: Iconsax.element_plus,
        category: SearchCategory.tools,
        priority: 8,
        keywords: const [
          'ودجات', 'اختصارات', 'شريط اشعارات', 'widgets',
          'quick tools', 'tiles', 'ودجت', 'اختصار'
        ],
        onTap: () => Get.to(() => const WidgetsSettingsPage()),
      ),

      // 3. Notifications
      SearchItem(
        id: 'notifications',
        title: 'سجل الإشعارات والتنبيهات',
        subtitle: 'استعراض التنبيهات الأمنية وتغيرات الشبكة',
        icon: Iconsax.notification,
        category: SearchCategory.tools,
        priority: 8,
        keywords: const [
          'اشعارات', 'تنبيهات', 'notifications', 'alerts',
          'رسائل', 'تحذيرات'
        ],
        onTap: () => Get.to(() => NotificationsPage()),
      ),

      // 4. Tutorial
      SearchItem(
        id: 'action_show_tutorial',
        title: 'بدء الجولة التوضيحية للتطبيق',
        subtitle: 'شرح تفاعلي لكافة ميزات وعناصر التحكم في Linkary',
        icon: Iconsax.magicpen,
        category: SearchCategory.tools,
        priority: 7,
        keywords: const [
          'شرح', 'تعليم', 'جولة', 'دليل', 'كيف استخدم', 'tutorial', 'help', 'مساعدة'
        ],
        onTap: () {
          final context = Get.context;
          if (context != null && Get.isRegistered<TutorialService>()) {
            Get.find<TutorialService>().showDashboardTutorial(context, force: true);
          }
        },
      ),

      // 5. About Linkary
      SearchItem(
        id: 'about',
        title: 'حول التطبيق وتحديثات Linkary',
        subtitle: 'معلومات الإصدار، المطور، وحقوق التطبيق',
        icon: Iconsax.info_circle,
        category: SearchCategory.tools,
        priority: 5,
        keywords: const [
          'عن التطبيق', 'حول', 'اصدار', 'مطور',
          'version', 'about', 'تحديث', 'لينكاري'
        ],
        onTap: () => Get.to(() => const AboutPage()),
      ),

      // صندوق الاقتراحات والملاحظات
      SearchItem(
        id: 'screen_feedback_box',
        title: 'صندوق الاقتراحات والملاحظات',
        subtitle: 'تقديم اقتراح لميزة جديدة، إبلاغ عن مشكلة، أو إرسال تقييمك',
        icon: Iconsax.message_favorite,
        category: SearchCategory.settings,
        priority: 9,
        keywords: const [
          'اقتراح', 'اقتراحات', 'ملاحظة', 'ملاحظات', 'شكوى', 'مشكلة', 'عطل',
          'ميزة جديدة', 'فكرة', 'صندوق الاقتراحات', 'تقييم', 'رأي', 'feedback', 'bug', 'suggest'
        ],
        onTap: () => Get.to(() => const FeedbackPage()),
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
              priority: 10,
              keywords: [
                device.name,
                device.ip,
                device.mac,
                if (displayName.isNotEmpty) displayName,
                'جهاز', 'متصل', 'هاتف', 'كمبيوتر',
              ],
              onTap: () => Get.to(() => const DeviceManagementPage()),
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
