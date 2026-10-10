# ميزة إجراءات إشعار الأجهزة المتصلة دون فتح التطبيق (حظر، توثيق، تجاهل) - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** تمكين المستخدم من التفاعل الفوري مع إشعارات الأجهزة المتصلة الجديدة عبر 3 إجراءات سريعة (حظر، توثيق، تجاهل) مباشرة من شريط الإشعارات بدون الحاجة لفتح التطبيق أو الانتقال إلى واجهته.

**Architecture:** 
- **Domain & Infrastructure:** توسيع `SessionManager` لدعم الأجهزة المتجاهلة (`ignoredMacs`) والأجهزة المحظورة (`blockedMacs`).
- **Notification Service:** خدمة مخصصة `DeviceNotificationService` تتكامل مع `flutter_local_notifications` وتعرّف `AndroidNotificationAction` بخاصية `showsUserInterface: false` و`cancelNotification: true`.
- **Headless Execution:** معالج خلفي مستقل `@pragma('vm:entry-point')` يتولى التفاعل الصامت مع المودم لحظر الـ MAC، أو تحديث القوائم المحلية للتوثيق والتجاهل، وعرض إشعار تأكيد فوري للمستخدم.
- **Presentation:** مزامنة حالة شاشة `ConnectedDevicesPage` و`ConnectedDevicesController` تلقائياً مع التحديثات الخلفية.

**Tech Stack:** Flutter 3, Dart 3, `flutter_local_notifications`, `http`, `flutter_secure_storage`, GetX.

---

### Task 1: توسيع `SessionManager` لدعم الأجهزة المتجاهلة والمحظورة

**Files:**
- Modify: `lib/core/network/session_manager.dart`
- Create: `test/core/network/session_manager_devices_test.dart`

**Step 1: Write the failing unit test**
Create `test/core/network/session_manager_devices_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/core/network/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionManager Ignored & Blocked MACs Tests', () {
    test('ignoredMacs logic correctly adds, checks, and removes MAC', () async {
      const testSn = 'TEST_SN_123';
      const mac = 'AA:BB:CC:DD:EE:01';

      // Ensure initial clean state
      await SessionManager.removeIgnoredMac(mac, testSn);
      expect(await SessionManager.isDeviceIgnored(mac, testSn), false);

      // Add to ignored
      await SessionManager.addIgnoredMac(mac, testSn);
      expect(await SessionManager.isDeviceIgnored(mac, testSn), true);

      final list = await SessionManager.getIgnoredMacs(testSn);
      expect(list.contains(mac), true);

      // Remove from ignored
      await SessionManager.removeIgnoredMac(mac, testSn);
      expect(await SessionManager.isDeviceIgnored(mac, testSn), false);
    });

    test('blockedMacs logic correctly saves and retrieves blocked MACs', () async {
      const testSn = 'TEST_SN_123';
      const mac = 'AA:BB:CC:DD:EE:02';

      await SessionManager.removeBlockedMac(mac, testSn);
      expect(await SessionManager.isDeviceBlocked(mac, testSn), false);

      await SessionManager.addBlockedMac(mac, testSn);
      expect(await SessionManager.isDeviceBlocked(mac, testSn), true);

      final list = await SessionManager.getBlockedMacs(testSn);
      expect(list.contains(mac), true);

      await SessionManager.removeBlockedMac(mac, testSn);
      expect(await SessionManager.isDeviceBlocked(mac, testSn), false);
    });
  });
}
```

**Step 2: Run test to verify it fails**
Run: `cmd /c flutter test test/core/network/session_manager_devices_test.dart`
Expected: FAIL with compilation errors (`addIgnoredMac`, `isDeviceIgnored`, `addBlockedMac` not defined).

**Step 3: Implement minimal code in `lib/core/network/session_manager.dart`**
Add:
- `_ignoredMacsKey = 'ignored_devices_macs'`
- `_blockedMacsKey = 'blocked_devices_macs'`
- `saveIgnoredMacs(List<String> macs, [String? sn])`
- `getIgnoredMacs([String? sn])`
- `addIgnoredMac(String mac, [String? sn])`
- `removeIgnoredMac(String mac, [String? sn])`
- `isDeviceIgnored(String mac, [String? sn])`
- `saveBlockedMacs(List<String> macs, [String? sn])`
- `getBlockedMacs([String? sn])`
- `addBlockedMac(String mac, [String? sn])`
- `removeBlockedMac(String mac, [String? sn])`
- `isDeviceBlocked(String mac, [String? sn])`

**Step 4: Run test to verify it passes**
Run: `cmd /c flutter test test/core/network/session_manager_devices_test.dart`
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/core/network/session_manager.dart test/core/network/session_manager_devices_test.dart
git commit -m "feat(devices): add ignored and blocked macs management to SessionManager"
```

---

### Task 2: إنشاء خدمة `DeviceNotificationService` لمعالجة إجراءات الإشعار في الخلفية

**Files:**
- Create: `lib/features/connected_devices/infrastructure/services/device_notification_service.dart`
- Create: `test/features/connected_devices/device_notification_service_test.dart`

**Step 1: Write the failing unit test**
Create `test/features/connected_devices/device_notification_service_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/connected_devices/infrastructure/services/device_notification_service.dart';

void main() {
  group('DeviceNotificationService Payload & Action Tests', () {
    test('encodePayload and parsePayload work symmetrically', () {
      final payload = DeviceNotificationService.encodePayload(
        mac: '00:11:22:33:44:55',
        deviceName: 'iPhone 15 Pro',
        sn: 'SN998877',
      );

      final data = DeviceNotificationService.parsePayload(payload);
      expect(data['mac'], '00:11:22:33:44:55');
      expect(data['name'], 'iPhone 15 Pro');
      expect(data['sn'], 'SN998877');
      expect(data['type'], DeviceNotificationService.payloadType);
    });

    test('extractActionType separates action and mac correctly', () {
      expect(
        DeviceNotificationService.extractActionType(DeviceNotificationService.actionBlock),
        'block',
      );
      expect(
        DeviceNotificationService.extractActionType(DeviceNotificationService.actionTrust),
        'trust',
      );
      expect(
        DeviceNotificationService.extractActionType(DeviceNotificationService.actionDismiss),
        'dismiss',
      );
    });
  });
}
```

**Step 2: Run test to verify it fails**
Run: `cmd /c flutter test test/features/connected_devices/device_notification_service_test.dart`
Expected: FAIL with compilation error (class not found).

**Step 3: Implement `DeviceNotificationService`**
Create `lib/features/connected_devices/infrastructure/services/device_notification_service.dart`:
- تعريف ثوابت الإجراءات:
  - `actionBlock = 'action_block_device'`
  - `actionTrust = 'action_trust_device'`
  - `actionDismiss = 'action_dismiss_device'`
  - `payloadType = 'new_device_alert'`
- دالة `initialize({void Function(String mac)? onOpenDeviceDetails})`:
  - إعداد قنوات الإشعارات للأندرويد (`new_device_alerts_v2` و `device_feedback_channel`).
  - تسجيل `onDidReceiveNotificationResponse` للتعامل مع الضغط على الإشعار وفتح التطبيق.
  - تسجيل `onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse`.
- دالة `@pragma('vm:entry-point') static Future<void> onBackgroundNotificationResponse(NotificationResponse response)`:
  - التحقق من نوع الإشعار والـ actionId.
  - استدعاء `handleBlockAction` أو `handleTrustAction` أو `handleDismissAction`.
- دالة `showDeviceAlert({required String mac, required String deviceName, String? sn})`:
  - بناء الإشعار مع 3 أزرار تفاعلية:
    - `AndroidNotificationAction(actionBlock, 'حظر', showsUserInterface: false, cancelNotification: true)`
    - `AndroidNotificationAction(actionTrust, 'توثيق', showsUserInterface: false, cancelNotification: true)`
    - `AndroidNotificationAction(actionDismiss, 'تجاهل', showsUserInterface: false, cancelNotification: true)`
- دوال التنفيذ الصامتة (Silent background execution):
  - `handleBlockAction(String mac, String deviceName, String? sn)`:
    - فحص الجلسة وتسجيل الدخول الصامت مع المودم عند الحاجة عبر `http.Client()`.
    - جلب قائمة `maclist_deny` الحالية عبر `wifi_get_mac_filter`.
    - إضافة الـ MAC وإرسال طلب `wifi_set_mac_filter`.
    - تحديث `SessionManager`: إزالة من المعلقة وإضافة للمحظورة وإلغاء التوثيق.
    - إظهار إشعار تأكيد سريع: "تم حظر الجهاز بنجاح 🚫".
  - `handleTrustAction(String mac, String deviceName, String? sn)`:
    - توثيق الجهاز عبر `SessionManager.trustDevice(mac, sn)`.
    - إزالة من الأجهزة المتجاهلة.
    - إظهار إشعار تأكيد: "تم توثيق الجهاز بنجاح ✅".
  - `handleDismissAction(String mac, String deviceName, String? sn)`:
    - إضافة الـ MAC لقائمة المتجاهلة `SessionManager.addIgnoredMac(mac, sn)`.
    - إزالة من المعلّقة `SessionManager.removePendingMac(mac, sn)`.
    - إلغاء الإشعار فورياً دون أي إزعاج للمستخدم.

**Step 4: Run test to verify it passes**
Run: `cmd /c flutter test test/features/connected_devices/device_notification_service_test.dart`
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/features/connected_devices/infrastructure/services/device_notification_service.dart test/features/connected_devices/device_notification_service_test.dart
git commit -m "feat(notifications): implement DeviceNotificationService with headless background actions"
```

---

### Task 3: تحديث خدمة `BackgroundDeviceMonitor` لاستخدام الخدمة التفاعلية وتصفية الأجهزة المتجاهلة

**Files:**
- Modify: `lib/features/connected_devices/infrastructure/services/background_device_monitor.dart`

**Step 1: Update device monitoring logic**
- استيراد `DeviceNotificationService`.
- جلب `ignoredMacs`:
  ```dart
  List<String> ignoredMacs = await SessionManager.getIgnoredMacs(sn);
  if (ignoredMacs.isEmpty) {
    ignoredMacs = await SessionManager.getIgnoredMacs();
  }
  ```
- تصفية الأجهزة غير الموثوقة لاستبعاد الأجهزة التي اختار المستخدم تجاهلها مسبقاً:
  ```dart
  final untrustedMacs = currentMacs.where((mac) =>
    !knownMacs.contains(mac) && !ignoredMacs.contains(mac)
  ).toList();
  ```
- استبدال كود إرسال الإشعار القديم بـ `DeviceNotificationService.showDeviceAlert`:
  ```dart
  await DeviceNotificationService.showDeviceAlert(
    mac: mac,
    deviceName: deviceName,
    sn: sn,
  );
  ```

**Step 2: Validate with `dart analyze`**
Run: `cmd /c dart analyze lib/features/connected_devices/infrastructure/services/background_device_monitor.dart`
Expected: 0 errors/warnings.

**Step 3: Commit**
```bash
git add lib/features/connected_devices/infrastructure/services/background_device_monitor.dart
git commit -m "refactor(monitor): integrate interactive notifications and ignored macs filter"
```

---

### Task 4: تهيئة `DeviceNotificationService` في `main.dart` و`callbackDispatcher`

**Files:**
- Modify: `lib/main.dart`

**Step 1: Add initialization in `main()` and `callbackDispatcher()`**
- استيراد `DeviceNotificationService` و `ConnectedDevicesPage`.
- في `main()`:
  ```dart
  await DeviceNotificationService.initialize(
    onOpenConnectedDevices: () {
      Get.to(() => const ConnectedDevicesPage());
    },
  );
  ```
- في `callbackDispatcher()`:
  - استدعاء `await DeviceNotificationService.initialize();` لضمان تسجيل المعالجات في مساحة عزل Workmanager.

**Step 2: Validate with `dart analyze`**
Run: `cmd /c dart analyze lib/main.dart`
Expected: 0 errors.

**Step 3: Commit**
```bash
git add lib/main.dart
git commit -m "feat(main): initialize DeviceNotificationService and route on notification click"
```

---

### Task 5: مزامنة `ConnectedDevicesController` وصفحة الأجهزة مع الإجراءات والتجاهل

**Files:**
- Modify: `lib/features/connected_devices/presentation/controllers/connected_devices_controller.dart`
- Modify: `lib/features/connected_devices/presentation/pages/connected_devices_page.dart`

**Step 1: Update controller methods**
- في `ConnectedDevicesController`:
  - إضافة `var ignoredMacs = <String>[].obs;`
  - عند `dismissDevice(mac)`: استدعاء `SessionManager.addIgnoredMac(mac, sn)` بالإضافة لإزالته من المعلقة.
  - عند `trustDevice(mac)`: استدعاء `SessionManager.removeIgnoredMac(mac, sn)`.
  - عند `blockDevice(device)`: استدعاء `SessionManager.removeIgnoredMac(device.mac, sn)` و `SessionManager.addBlockedMac(device.mac, sn)`.
  - في `_checkForNewDevices()`:
    - استبعاد `ignoredMacs` من التنبيهات.
    - إرسال إشعار تفاعلي للأجهزة الجديدة عبر `DeviceNotificationService.showDeviceAlert`.

**Step 2: Validate with `dart analyze`**
Run: `cmd /c dart analyze lib/features/connected_devices/`
Expected: 0 errors.

**Step 3: Commit**
```bash
git add lib/features/connected_devices/presentation/controllers/connected_devices_controller.dart lib/features/connected_devices/presentation/pages/connected_devices_page.dart
git commit -m "feat(controller): synchronize ignored and blocked device states"
```

---

### Task 6: التحقق الشامل واختبار الانتهاء (Verification & End-to-End Audit)

**Step 1: Run project tests**
Run: `cmd /c flutter test test/features/connected_devices/ test/core/network/`
Expected: ALL PASS.

**Step 2: Run static analysis**
Run: `cmd /c dart analyze lib/features/connected_devices lib/core/network lib/main.dart`
Expected: No issues found.

**Step 3: Final commit and summary**
```bash
git add .
git commit -m "feat(notifications): complete interactive connected device notification actions (block, trust, dismiss)"
```
