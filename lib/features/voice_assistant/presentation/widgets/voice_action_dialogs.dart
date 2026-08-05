import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../../../mac_filter/presentation/controllers/mac_filter_controller.dart';
import '../../../settings/presentation/controllers/wifi_settings_controller.dart';
import '../../../connected_devices/domain/entities/connected_device_entity.dart';
import '../../../speed_limit/presentation/controllers/speed_limit_controller.dart';
import '../../infrastructure/services/voice_prefs_service.dart';

class VoiceActionDialogs {
  // ════════════════════════════════════════════
  // إشعار الميزة التجريبية
  // ════════════════════════════════════════════
  static Future<void> showBetaNoticeIfNeeded({required VoidCallback onProceed}) async {
    final dismissed = await VoicePrefsService.isBetaNoticeDismissed();
    if (dismissed) {
      onProceed();
      return;
    }
    final dontShowAgain = false.obs;

    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Get.isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.97) : Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── أيقونة التجريبية ───
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7367F0), Color(0xFF4776E6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: const Color(0xFF7367F0).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Iconsax.microphone, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),

                  // ─── بادج تجريبي ───
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F43).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFF9F43).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science_rounded, size: 14, color: Color(0xFFFF9F43)),
                        SizedBox(width: 6),
                        Text('ميزة تجريبية', style: TextStyle(color: Color(0xFFFF9F43), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── العنوان ───
                  Text(
                    'المساعد الصوتي — سام',
                    style: TextStyle(
                      color: Get.isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // ─── الوصف ───
                  Text(
                    'هذه الميزة لا تزال في طور التجربة وقد يحدث بعض التفسير الخاطئ في بعض الأوامر. سيتم تحسينها باستمرار في التحديثات القادمة.',
                    style: TextStyle(
                      color: Get.isDarkMode ? Colors.white60 : Colors.black54,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // ─── تلميحة كلمة التنشيط ───
                  // Container(
                  //   margin: const EdgeInsets.only(top: 8),
                  //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFF7367F0).withValues(alpha: 0.08),
                  //     borderRadius: BorderRadius.circular(14),
                  //     border: Border.all(color: const Color(0xFF7367F0).withValues(alpha: 0.2)),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       const Icon(Iconsax.microphone_2, size: 14, color: Color(0xFF7367F0)),
                  //       const SizedBox(width: 8),
                  //       const Flexible(
                  //         child: Text(
                  //           'يمكنك تنشيطي بالقول: "يا سام" أو "سام"',
                  //           style: TextStyle(
                  //             color: Color(0xFF7367F0),
                  //             fontSize: 12,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 24),

                  // ─── خيار لا تعرضها ───
                  Obx(() => InkWell(
                    onTap: () => dontShowAgain.value = !dontShowAgain.value,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: dontShowAgain.value ? const Color(0xFF7367F0) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: dontShowAgain.value ? const Color(0xFF7367F0) : (Get.isDarkMode ? Colors.white38 : Colors.black26),
                                width: 2,
                              ),
                            ),
                            child: dontShowAgain.value
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                              : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'لاتظهر هذه الرسالة مستقبلاً',
                            style: TextStyle(
                              color: Get.isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),

                  // ─── زر فهمت ───
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (dontShowAgain.value) {
                          await VoicePrefsService.dismissBetaNotice();
                        }
                        Get.back();
                        onProceed();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7367F0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'فهمت، لنبدأ!',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ─── ألوان مشتركة ───
  static Color get _bg => Get.isDarkMode ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.97);
  static Color get _text => Get.isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
  static Color get _sub => Get.isDarkMode ? Colors.white54 : Colors.black45;
  static Color get _card => Get.isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);

  static Widget _dialogShell({required Widget child}) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxHeight: 560),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget _header(IconData icon, String title, Color color) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
      const SizedBox(height: 12),
      Text(title, style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Container(height: 2, width: 50, decoration: BoxDecoration(color: color.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(1))),
      const SizedBox(height: 18),
    ]);
  }

  // ════════════════════════════════════════════
  // حظر جهاز
  // ════════════════════════════════════════════
  static void showBlockDeviceDialog() {
    final connectedController = Get.find<ConnectedDevicesController>();
    final macController = Get.find<MacFilterController>();
    Get.dialog(_dialogShell(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _header(Iconsax.security_user, 'اختر الجهاز للحظر', Colors.redAccent),
      Flexible(child: Obx(() {
        if (connectedController.isLoading.value) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
        if (connectedController.devices.isEmpty) return Text('لا توجد أجهزة متصلة', style: TextStyle(color: _sub));
        return ListView.builder(
          shrinkWrap: true,
          itemCount: connectedController.devices.length,
          itemBuilder: (_, i) {
            final d = connectedController.devices[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Icon(Icons.devices_rounded, color: Colors.blueAccent.withValues(alpha: 0.8)),
                title: Text(d.name.isEmpty ? 'جهاز غير معروف' : d.name, style: TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(d.mac, style: TextStyle(color: _sub, fontSize: 11)),
                trailing: ElevatedButton(
                  onPressed: () { Get.back(); _confirmBlockDevice(macController, d); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.12), foregroundColor: Colors.redAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('حظر', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      })),
      const SizedBox(height: 10),
      TextButton(onPressed: () => Get.back(), child: Text('إلغاء', style: TextStyle(color: _sub))),
    ])));
  }

  static void _confirmBlockDevice(MacFilterController macController, ConnectedDeviceEntity device) {
    Get.defaultDialog(
      backgroundColor: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      title: 'تأكيد الحظر',
      titleStyle: TextStyle(color: _text),
      middleText: 'هل أنت متأكد من حظر جهاز (${device.name.isEmpty ? device.mac : device.name})؟\n\nسيتم فصل الإنترنت عنه فوراً.',
      middleTextStyle: TextStyle(color: _sub, height: 1.6),
      textConfirm: 'نعم، احظره',
      textCancel: 'تراجع',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.redAccent,
      buttonColor: Colors.redAccent,
      onConfirm: () async {
        Get.back();
        macController.selectedMode.value = 'deny';
        macController.addMac(device.mac);
        await macController.saveSettings();
      },
    );
  }

  // ════════════════════════════════════════════
  // إعدادات الواي فاي
  // ════════════════════════════════════════════
  static void showWifiSettingsDialog() {
    final wifiController = Get.find<WifiSettingsController>();
    if (wifiController.ssidController.text.isEmpty) wifiController.fetchSettings();
    Get.dialog(_dialogShell(child: Form(
      key: wifiController.formKey,
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _header(Iconsax.wifi, 'تحديث بيانات الواي فاي', Colors.blueAccent),
        TextFormField(
          controller: wifiController.ssidController,
          style: TextStyle(color: _text),
          decoration: InputDecoration(labelText: 'اسم الشبكة (SSID)', prefixIcon: const Icon(Iconsax.edit), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
        ),
        const SizedBox(height: 14),
        Obx(() => TextFormField(
          controller: wifiController.passwordController,
          obscureText: !wifiController.isPasswordVisible.value,
          style: TextStyle(color: _text),
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            prefixIcon: const Icon(Iconsax.lock),
            suffixIcon: IconButton(icon: Icon(wifiController.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off), onPressed: wifiController.togglePasswordVisibility),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          validator: (v) { if (v == null || v.isEmpty) return 'مطلوب'; if (v.length < 8) return 'يجب أن لا تقل عن 8 رموز'; return null; },
        )),
        const SizedBox(height: 22),
        SizedBox(width: double.infinity, height: 50, child: Obx(() => ElevatedButton(
          onPressed: wifiController.isSaving.value ? null : () { Get.back(); wifiController.saveSettings(); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: wifiController.isSaving.value
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('حفظ التغييرات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ))),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Get.back(), child: Text('إلغاء', style: TextStyle(color: _sub))),
      ])),
    )));
  }

  // ════════════════════════════════════════════
  // تحديد السرعة (عام + جهاز محدد)
  // ════════════════════════════════════════════
  static void showSpeedLimitDialog({int? presetSpeed, String mode = 'global', String? deviceName}) {
    final controller = Get.find<SpeedLimitController>();
    final RxInt selectedPreset = (presetSpeed ?? 0).obs;
    final RxBool isDeviceMode = (mode == 'device').obs;
    final RxInt selectedDeviceIdx = (-1).obs;

    // السرعات الجاهزة بـ kbps
    final presets = [
      {'label': '1/2 MB', 'value': 62, 'color': const Color(0xFF28C76F)},
      {'label': '1 MB', 'value': 124, 'color': const Color(0xFF00CFE8)},
      {'label': '2 MB', 'value': 248, 'color': const Color(0xFF7367F0)},
      {'label': '4 MB', 'value': 496, 'color': const Color(0xFF7367F0)},
      {'label': '5 MB', 'value': 620, 'color': const Color(0xFFFF9F43)},
      {'label': '6 MB', 'value': 744, 'color': const Color(0xFFEA5455)},
      {'label': 'بدون حد', 'value': 0, 'color': Colors.grey},
    ];

    Get.dialog(_dialogShell(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _header(Iconsax.speedometer, isDeviceMode.value ? 'تحديد سرعة جهاز' : 'تحديد السرعة العامة', const Color(0xFF7367F0)),

      // نوع الوضع
      Obx(() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _modeTab('عام', !isDeviceMode.value, () => isDeviceMode.value = false),
        const SizedBox(width: 10),
        _modeTab('جهاز محدد', isDeviceMode.value, () => isDeviceMode.value = true),
      ])),
      const SizedBox(height: 16),

      // اختيار الجهاز في وضع الجهاز
      Obx(() => isDeviceMode.value ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('اختر الجهاز:', style: TextStyle(color: _sub, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.deviceItems.length + (Get.find<ConnectedDevicesController>().devices.length),
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final connDevices = Get.find<ConnectedDevicesController>().devices;
              if (i >= connDevices.length) return const SizedBox.shrink();
              final dev = connDevices[i];
              return Obx(() => GestureDetector(
                onTap: () => selectedDeviceIdx.value = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  decoration: BoxDecoration(
                    color: selectedDeviceIdx.value == i ? const Color(0xFF7367F0).withValues(alpha: 0.15) : _card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selectedDeviceIdx.value == i ? const Color(0xFF7367F0) : Colors.transparent, width: 2),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.devices_rounded, color: selectedDeviceIdx.value == i ? const Color(0xFF7367F0) : _sub, size: 28),
                    const SizedBox(height: 6),
                    Text(dev.name.isEmpty ? 'جهاز' : dev.name, style: TextStyle(color: _text, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ));
            },
          ),
        ),
        const SizedBox(height: 16),
      ]) : const SizedBox.shrink()),

      // السرعات الجاهزة
      Text('اختر السرعة:', style: TextStyle(color: _sub, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Obx(() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: presets.map((p) {
          final val = p['value'] as int;
          final color = p['color'] as Color;
          final isSelected = selectedPreset.value == val;
          return GestureDetector(
            onTap: () {
              selectedPreset.value = val;
              if (val > 0) {
                controller.uploadController.text = val.toString();
                controller.downloadController.text = val.toString();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
              ),
              child: Text(p['label'] as String, style: TextStyle(color: isSelected ? color : _sub, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          );
        }).toList(),
      )),
      const SizedBox(height: 20),

      // زر التطبيق
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
        onPressed: () async {
          Get.back();
          if (selectedPreset.value == 0) {
            controller.isEnabled.value = false;
          } else {
            controller.isEnabled.value = true;
            if (isDeviceMode.value && selectedDeviceIdx.value >= 0) {
              controller.selectedMode.value = 2;
              final connDevices = Get.find<ConnectedDevicesController>().devices;
              final dev = connDevices[selectedDeviceIdx.value];
              controller.addDeviceRule(dev.ip, selectedPreset.value, selectedPreset.value, dev.name);
            } else {
              controller.selectedMode.value = 1;
            }
          }
          await controller.saveData();
        },
        icon: const Icon(Iconsax.tick_circle, color: Colors.white),
        label: const Text('تطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7367F0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      )),
      const SizedBox(height: 8),
      TextButton(onPressed: () => Get.back(), child: Text('إلغاء', style: TextStyle(color: _sub))),
    ]))));
  }

  static Widget _modeTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7367F0) : (Get.isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : (Get.isDarkMode ? Colors.white60 : Colors.black45), fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  // ════════════════════════════════════════════
  // ضبط حجم الباقة
  // ════════════════════════════════════════════
  static void showQuotaDialog({int? presetQuota, String presetUnit = 'GB'}) {
    final TextEditingController quotaCtrl = TextEditingController(text: presetQuota?.toString() ?? '');
    final RxString unit = presetUnit.obs;
    final quotas = [
      {'label': '1 GB', 'value': 1, 'unit': 'GB'},
      {'label': '2 GB', 'value': 2, 'unit': 'GB'},
      {'label': '3 GB', 'value': 3, 'unit': 'GB'},
      {'label': '4 GB', 'value': 4, 'unit': 'GB'},
      {'label': '5 GB', 'value': 5, 'unit': 'GB'},
      {'label': '6 GB', 'value': 6, 'unit': 'GB'},
      {'label': '7 GB', 'value': 7, 'unit': 'GB'},
      {'label': '8 GB', 'value': 8, 'unit': 'GB'},
      {'label': '9 GB', 'value': 9, 'unit': 'GB'},
      {'label': '10 GB', 'value': 10, 'unit': 'GB'},
      {'label': 'غير محدود', 'value': 0, 'unit': 'GB'},
    ];
    Get.dialog(_dialogShell(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _header(Iconsax.chart_21, 'تحديد حجم الباقة', const Color(0xFF00CFE8)),
      Text('اختر حجماً جاهزاً أو أدخل قيمة مخصصة:', style: TextStyle(color: _sub, fontSize: 13)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: quotas.map((q) {
          return GestureDetector(
            onTap: () {
              quotaCtrl.text = (q['value'] as int).toString();
              unit.value = q['unit'] as String;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00CFE8).withValues(alpha: 0.3))),
              child: Text(q['label'] as String, style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: TextField(
          controller: quotaCtrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: _text),
          decoration: InputDecoration(labelText: 'الحجم المخصص', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(width: 10),
        Obx(() => DropdownButton<String>(
          value: unit.value,
          dropdownColor: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(color: _text, fontWeight: FontWeight.bold),
          items: ['MB', 'GB'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
          onChanged: (v) => unit.value = v ?? 'GB',
        )),
      ]),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
        onPressed: () {
          Get.back();
          // هنا يمكن حفظ الحصة في SharedPreferences أو المتحكم المناسب
        },
        icon: const Icon(Iconsax.tick_circle, color: Colors.white),
        label: const Text('تطبيق الحصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00CFE8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      )),
      const SizedBox(height: 8),
      TextButton(onPressed: () => Get.back(), child: Text('إلغاء', style: TextStyle(color: _sub))),
    ]))));
  }

  // ════════════════════════════════════════════
  // قائمة المساعدة - الأوامر الصوتية
  // ════════════════════════════════════════════
  static void showHelpDialog() {
    Get.dialog(_dialogShell(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _header(Iconsax.message_question, 'الأوامر الصوتية', const Color(0xFFFF9F43)),
      Flexible(child: SingleChildScrollView(child: Column(children: _helpCommands.map((cat) => Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cat['title'] as String, style: const TextStyle(color: Color(0xFFFF9F43), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ...(cat['commands'] as List<String>).map((cmd) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.mic, size: 12, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(cmd, style: TextStyle(color: _text, fontSize: 12))),
            ]),
          )),
          const SizedBox(height: 12),
        ],
      )).toList()))),
      TextButton(onPressed: () => Get.back(), child: Text('حسناً', style: TextStyle(color: _sub))),
    ])));
  }

  static const _helpCommands = [
    {'title': '📡 الشبكة والاستعلامات', 'commands': ['كم جهاز متصل؟', 'قوة الإشارة؟', 'كم الرصيد المتبقي؟', 'كم استهلكت من النت؟', 'نسبة البطارية؟', 'كم سرعة الإنترنت؟']},
    {'title': '🛡️ الأمان والحظر', 'commands': ['احظر جهاز', 'امنع الهاتف', 'فك الحظر عن الجهاز', 'افتح شاشة الحظر']},
    {'title': '👨‍👩‍👧 الرقابة الأبوية', 'commands': ['شغل الرقابة الأبوية', 'عطل رقابة الأطفال', 'افتح شاشة الرقابة الأبوية', 'جدول وقت الجهاز']},
    {'title': '⚡ تحديد السرعة', 'commands': ['حدد السرعة العامة', 'قيد سرعة جهاز معين', 'الغي تحديد السرعة', 'خفف سرعة الهاتف']},
    {'title': '📊 الاستهلاك والباقة', 'commands': ['كم استهلكت؟', 'حدد حجم الباقة بـ 20 جيجا', 'اضبط الحصة الشهرية']},
    {'title': '⚙️ الواي فاي والإعدادات', 'commands': ['غير باسورد الواي فاي', 'بدل اسم الشبكة', 'شغل الوضع الليلي', 'غير للوضع النهاري']},
    {'title': '🗺️ التنقل بين الشاشات', 'commands': ['افتح الإعدادات', 'روح للرادار', 'خذني لفحص السرعة', 'انتقل للأجهزة المتصلة', 'افتح استهلاك البيانات', 'انتقل لشاشة تحديد السرعة']},
    {'title': '🔧 النظام', 'commands': ['أعد تشغيل المودم', 'سجل الخروج', 'ريستارت الراوتر']},
  ];
}
