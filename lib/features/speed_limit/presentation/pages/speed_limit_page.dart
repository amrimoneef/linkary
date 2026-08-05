import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/speed_limit_controller.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../../domain/entities/speed_limit_entity.dart';

class SpeedLimitPage extends StatelessWidget {
  SpeedLimitPage({super.key});

  final SpeedLimitController controller = Get.find<SpeedLimitController>();

  // 🎨 الألوان الديناميكية (الهوية الجديدة النظيفة)
  Color get bgColor => Get.isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFFAFAFC);
  Color get cardColor => Get.isDarkMode ? const Color(0xFF16213E) : Colors.white;
  Color get textColor => Get.isDarkMode ? Colors.white : const Color(0xFF111827);
  Color get subTextColor => Get.isDarkMode ? Colors.white54 : const Color(0xFF6B7280);
  Color get glowColor => Get.isDarkMode ? const Color(0xFF4A90E2) : const Color(0xFF92C0F6);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // 🌌 1. الدائرة السعرية المتدرجة (Radial Glow)
            Positioned(
              top: -120,
              right: -100,
              child: Container(
                width: 370,
                height: 370,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: Get.isDarkMode ? 0.3 : 0.4),
                      glowColor.withValues(alpha: 0.01),
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
              ),
            ),

            // 📝 2. المحتوى الرئيسي
            SafeArea(
              child: controller.isLoading.value
                  ? Center(child: CircularProgressIndicator(color: glowColor))
                  : SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // زر العودة واللوجو
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, color: textColor),
                            onPressed: () => Get.back(),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          Image.asset(
                            Get.isDarkMode ? 'assets/images/الشعار ابيض.png' : 'assets/images/الشعار اسود.png',
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const SizedBox(width: 30),

                      // العنوان الرئيسي
                      Text('إدارة السرعة (QoS)', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('تحكم في توزيع سرعة الإنترنت ', style: TextStyle(color: subTextColor, fontSize: 14)),
                          Text('بذكاء وفعالية', style: TextStyle(color: glowColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 35),

                      // ==========================================
                      // 1. مفتاح التفعيل الرئيسي
                      _buildMainToggle(),
                      const SizedBox(height: 25),

                      // 2. اختيار النمط (أزرار الاختيار الحديثة)
                      if (controller.isEnabled.value)
                        _buildModeSelectionGrid(),
                      const SizedBox(height: 25),

                      // 3. 🌟 العرض الديناميكي بناءً على النمط
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                            child: child,
                          ),
                        ),
                        child: controller.selectedMode.value == 1
                            ? _buildGeneralMode(context)
                            : _buildIPMode(context),
                      ),

                      const SizedBox(height: 40),

                      // 4. زر الحفظ
                      _buildSaveButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ==========================================
  // 🧩 دوال بناء الواجهة
  // ==========================================

  // مفتاح التفعيل الرئيسي
  Widget _buildMainToggle() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: controller.isEnabled.value ? glowColor.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: (controller.isEnabled.value ? glowColor : Colors.black).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(' إدارة السرعة${controller.isEnabled.value ? ' مفعلة' : ' مغلقة'}', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text('تقييد السرعة الكلية أو المخصصة', style: TextStyle(color: subTextColor, fontSize: 12)),
        value: controller.isEnabled.value,
        activeColor: glowColor,
        onChanged: (val) => controller.isEnabled.value = val,
      ),
    );
  }

  // اختيار النمط (أزرار عصرية)
  Widget _buildModeSelectionGrid() {
    return Row(
      children: [
        Expanded(child: _buildModeButton(1, 'النمط العام', 'تحديد السرعة على جميع الأجهزة', Iconsax.global)),
        const SizedBox(width: 15),
        Expanded(child: _buildModeButton(2, 'نمط الأجهزة', 'تحديد السرعة على أجهزة محددة', Iconsax.mobile)),
      ],
    );
  }

  Widget _buildModeButton(int mode, String title, String subtitle, IconData icon) {
    final isSel = controller.selectedMode.value == mode;
    return GestureDetector(
      onTap: () => controller.selectedMode.value = mode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSel ? glowColor : cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isSel ? glowColor : Colors.grey.withValues(alpha: 0.2)),
          boxShadow: isSel ? [BoxShadow(color: glowColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 6))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSel ? Colors.white : subTextColor, size: 28),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: isSel ? Colors.white : textColor, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(subtitle, style: TextStyle(color: isSel ? Colors.white : subTextColor, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // 💡 مربع الملاحظات (Banner)
  Widget _buildInfoBanner(String text, {Color? color}) {
    final accent = color ?? glowColor;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // 1. واجهة النمط العام (مع خيارات السرعة الجاهزة)
  Widget _buildGeneralMode(BuildContext context) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner('تنبيه: 124kb يساوي 1MB من السرعة الفعلية.', color: Colors.orangeAccent),
        const SizedBox(height: 25),

        Text('حدد سرعة يدوية (بالكيلوبايت):', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildTextField('تنزيل (KB/s)', controller.downloadController, Iconsax.arrow_down)),
            const SizedBox(width: 15),
            Expanded(child: _buildTextField('رفع (KB/s)', controller.uploadController, Iconsax.arrow_up_3)),
          ],
        ),
        const SizedBox(height: 30),
        Text('أو اختر سرعة جاهزة:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _buildPresetsGrid(onApply: (v) => controller.applyPreset(v)),
      ],
    );
  }

  // شبكة السرعات الجاهزة
  Widget _buildPresetsGrid({required Function(int) onApply, String? currentDlValue}) {
    final List<Map<String, dynamic>> presets = [
      {'label': '1/2M', 'sub': '62 bps', 'val': 62},
      {'label': '1MB', 'sub': '124 Kbps', 'val': 124},
      {'label': '2MB', 'sub': '248 Kbps', 'val': 248},
      {'label': '4MB', 'sub': '496 Kbps', 'val': 496},
      {'label': '5MB', 'sub': '620 Kbps', 'val': 620},
      {'label': '6MB', 'sub': '744 Kbps', 'val': 744},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: presets.map((p) {
        final bool isSelected = currentDlValue == p['val'].toString() || (currentDlValue == null && controller.rxDownloadSpeed.value == p['val'].toString());
        return GestureDetector(
          onTap: () => onApply(p['val']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (Get.width - 80) / 3, // عرض 3 عناصر في السطر
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? glowColor.withValues(alpha: 0.15) : cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? glowColor : Colors.grey.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              children: [
                Text(p['label'], style: TextStyle(color: isSelected ? glowColor : textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(p['sub'], style: TextStyle(color: subTextColor, fontSize: 10)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 2. واجهة نمط الأجهزة (IP Mode)
  Widget _buildIPMode(BuildContext context) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner('يمكنك تحديد سرعة مخصصة لكل جهاز متصل حسب الحاجة.'),
        const SizedBox(height: 25),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('الأجهزة المحددة', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showSmartAddDeviceSheet(context),
              icon: Icon(Iconsax.add_circle, color: glowColor),
              label: Text('إضافة جهاز', style: TextStyle(color: glowColor, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 10),

        Obx(() => controller.deviceItems.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(
              children: [
                Icon(Iconsax.computing, color: subTextColor.withValues(alpha: 0.3), size: 50),
                const SizedBox(height: 15),
                Text('لا توجد أجهزة مقيدة حالياً.', style: TextStyle(color: subTextColor, fontSize: 14)),
              ],
            )))
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.deviceItems.length,
          itemBuilder: (context, index) {
            final item = controller.deviceItems[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: glowColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Iconsax.mobile5, color: glowColor, size: 24),
                ),
                title: Text(item.comment.isEmpty ? "جهاز" : item.comment, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(item.ip, style: TextStyle(color: subTextColor, fontSize: 11, fontFamily: 'monospace')),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        children: [
                          const Icon(Iconsax.arrow_down, color: Colors.green, size: 12),
                          Text(' ${item.dlSpeed} KB/s', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          const Icon(Iconsax.arrow_up_3, color: Colors.blueAccent, size: 12),
                          Text(' ${item.upSpeed} KB/s', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Iconsax.edit, color: glowColor, size: 20),
                      onPressed: () => _showSmartAddDeviceSheet(context, item: item),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
                      onPressed: () => controller.removeDeviceRule(item.index),
                    ),
                  ],
                ),
              ),
            );
          },
        )
        )
      ],
    );
  }

  // حقل الإدخال
  Widget _buildTextField(String label, TextEditingController textController, IconData icon, {bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: textController,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: subTextColor, fontSize: 12),
          prefixIcon: Icon(icon, color: subTextColor, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      ),
    );
  }

  // زر الحفظ
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: glowColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 8,
          shadowColor: glowColor.withValues(alpha: 0.5),
        ),
        onPressed: controller.isSaving.value ? null : () => controller.saveData(),
        child: controller.isSaving.value
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('تطبيق الإعدادات', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Iconsax.tick_circle, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🚀 النافذة السفلية لإضافة أو تعديل جهاز
  // ==========================================
  void _showSmartAddDeviceSheet(BuildContext context, {SpeedLimitItem? item}) {
    final bool isEdit = item != null;
    
    if (isEdit) {
      controller.selectedSmartIp.value = item.ip;
      controller.selectedSmartName.value = item.comment;
    } else {
      controller.selectedSmartIp.value = '';
      controller.selectedSmartName.value = '';
    }

    final upCtrl = TextEditingController(text: isEdit ? item.upSpeed.toString() : '0');
    final dlCtrl = TextEditingController(text: isEdit ? item.dlSpeed.toString() : '0');

    ConnectedDevicesController? devicesController;
    try {
      devicesController = Get.find<ConnectedDevicesController>();
      if (devicesController.devices.isEmpty) devicesController.fetchDevices();
    } catch (_) {}

    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Text(isEdit ? 'تعديل قاعدة تقييد' : 'إضافة جهاز للقائمة', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(isEdit ? 'قم بتعديل السرعات المحددة لهذا الجهاز.' : 'اختر جهازاً، ثم حدد السرعات المسموحة.', style: TextStyle(color: subTextColor, fontSize: 14)),
            const SizedBox(height: 25),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. شريط الأجهزة المتصلة (فقط في حال الإضافة)
                    if (!isEdit) ...[
                      SizedBox(
                        height: 140,
                        child: devicesController == null
                            ? Center(child: Text('ميزة الأجهزة غير فعالة', style: TextStyle(color: subTextColor)))
                            : Obx(() {
                          if (devicesController!.isLoading.value) return Center(child: CircularProgressIndicator(color: glowColor));
                          final devicesList = devicesController.devices;
                          if (devicesList.isEmpty) return Center(child: Text('لا توجد أجهزة متصلة', style: TextStyle(color: subTextColor)));

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: devicesList.length,
                            itemBuilder: (context, index) {
                              final dev = devicesList[index];
                              final devName = dev.name.isEmpty ? 'جهاز مجهول' : dev.name;

                              return Obx(() {
                                bool isSelected = controller.selectedSmartIp.value == dev.ip;
                                bool alreadyAdded = controller.deviceItems.any((e) => e.ip == dev.ip);

                                return GestureDetector(
                                  onTap: alreadyAdded ? null : () => controller.selectSmartDevice(dev.ip, devName),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 120,
                                    margin: const EdgeInsets.only(left: 15),
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: alreadyAdded 
                                          ? Colors.grey.withValues(alpha: 0.05)
                                          : (isSelected ? glowColor.withValues(alpha: 0.1) : cardColor),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                          color: alreadyAdded
                                              ? Colors.transparent
                                              : (isSelected ? glowColor : Colors.grey.withValues(alpha: 0.1)),
                                          width: isSelected ? 2 : 1),
                                      boxShadow: isSelected ? [BoxShadow(color: glowColor.withValues(alpha: 0.1), blurRadius: 10)] : [],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                alreadyAdded
                                                    ? Iconsax.tick_circle
                                                    : (isSelected ? Iconsax.mobile5 : Iconsax.mobile),
                                                color: alreadyAdded
                                                    ? Colors.grey
                                                    : (isSelected ? glowColor : subTextColor),
                                                size: 30),
                                            const SizedBox(height: 10),
                                            Text(devName,
                                                style: TextStyle(
                                                    color: alreadyAdded ? Colors.grey : (isSelected ? glowColor : textColor),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                        if (alreadyAdded)
                                          Positioned(
                                            top: -5,
                                            right: -5,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8)),
                                              child: const Text('مضاف', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // 2. عرض البيانات المختارة / الثابتة
                    Obx(() => _buildTextField('IP الجهاز', TextEditingController(text: controller.selectedSmartIp.value), Iconsax.global, readOnly: true)),
                    const SizedBox(height: 20),

                    // 3. إعداد السرعات
                    Row(
                      children: [
                        Expanded(child: _buildTextField('سرعة التنزيل', dlCtrl, Iconsax.arrow_down)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildTextField('سرعة الرفع', upCtrl, Iconsax.arrow_up_3)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 4. السرعات الجاهزة للتسهيل
                    Text('السرعات الجاهزة:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    ValueListenableBuilder(
                      valueListenable: dlCtrl,
                      builder: (context, value, _) {
                        return _buildPresetsGrid(
                          onApply: (v) {
                            dlCtrl.text = v.toString();
                            upCtrl.text = v.toString();
                          },
                          currentDlValue: dlCtrl.text,
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // 5. زر الإضافة أو التحديث
            SizedBox(
              width: double.infinity,
              height: 60,
              child: Obx(() {
                bool isReady = controller.selectedSmartIp.value.isNotEmpty;
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReady ? glowColor : Colors.grey.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: isReady ? 5 : 0,
                  ),
                  icon: Icon(isEdit ? Iconsax.tick_circle : Iconsax.add, color: isReady ? Colors.white : Colors.white54),
                  label: Text(isEdit ? 'تحديث البيانات' : 'تأكيد الإضافة', style: TextStyle(color: isReady ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: isReady ? () {
                    if (isEdit) {
                      controller.updateDeviceRule(item.index, int.parse(upCtrl.text), int.parse(dlCtrl.text));
                    } else {
                      controller.addDeviceRule(
                        controller.selectedSmartIp.value,
                        int.parse(upCtrl.text),
                        int.parse(dlCtrl.text),
                        controller.selectedSmartName.value.isEmpty ? 'جهاز مخصص' : controller.selectedSmartName.value
                      );
                    }
                    Get.back();
                  } : null,
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}