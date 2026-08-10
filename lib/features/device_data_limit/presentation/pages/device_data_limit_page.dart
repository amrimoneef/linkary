import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/device_data_limit_controller.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../../domain/entities/device_data_limit.dart';

class DeviceDataLimitPage extends GetView<DeviceDataLimitController> {
  const DeviceDataLimitPage({super.key});

  // 🎨 الألوان الديناميكية (الهوية الجديدة النظيفة)
  Color get bgColor => Get.isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFFAFAFC);
  Color get cardColor => Get.isDarkMode ? const Color(0xFF16213E) : Colors.white;
  Color get textColor => Get.isDarkMode ? Colors.white : const Color(0xFF111827);
  Color get subTextColor => Get.isDarkMode ? Colors.white54 : const Color(0xFF6B7280);
  Color get glowColor => Get.isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFFA78BFA); // Purple glow for data limit

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // 🌌 1. الدائرة اللونية المتدرجة (Radial Glow)
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
              child: controller.isLoading.value && controller.deviceLimits.isEmpty
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
                      Text('باقة الأجهزة', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('تحكم في استهلاك الباقة ', style: TextStyle(color: subTextColor, fontSize: 14)),
                          Text('لكل جهاز', style: TextStyle(color: glowColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 35),

                      // ==========================================
                      // 1. مفتاح التفعيل الرئيسي
                      _buildMainToggle(),
                      const SizedBox(height: 25),

                      // 2. 🌟 العرض الديناميكي للأجهزة
                      if (controller.isEnabled.value) ...[
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                              child: child,
                            ),
                          ),
                          child: _buildDeviceMode(context),
                        ),
                        const SizedBox(height: 40),
                      ]
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
        title: Text(' تحديد الاستهلاك${controller.isEnabled.value ? ' مفعل' : ' مغلق'}', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text('تحديد استهلاك البيانات لكل جهاز متصل', style: TextStyle(color: subTextColor, fontSize: 12)),
        value: controller.isEnabled.value,
        activeColor: glowColor,
        onChanged: (val) => controller.toggleEnable(val),
      ),
    );
  }

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

  Widget _buildDeviceMode(BuildContext context) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner('يمكنك تحديد باقة استهلاك مخصصة لكل جهاز متصل حسب الحاجة.'),
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

        Obx(() => controller.deviceLimits.isEmpty
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
          itemCount: controller.deviceLimits.length,
          itemBuilder: (context, index) {
            final limit = controller.deviceLimits[index];
            final progress = limit.quotaBytes > 0 
                ? (limit.currentUsageBytes / limit.quotaBytes).clamp(0.0, 1.0) 
                : 0.0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: glowColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(Iconsax.mobile5, color: glowColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    limit.comment.isNotEmpty ? limit.comment : limit.hostname,
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(limit.mac, style: TextStyle(color: subTextColor, fontSize: 11, fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Iconsax.edit, color: glowColor, size: 20),
                            onPressed: () => _showSmartAddDeviceSheet(context, limit: limit),
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              Get.defaultDialog(
                                title: 'تأكيد الحذف',
                                middleText: 'هل أنت متأكد من حذف القيد عن هذا الجهاز؟',
                                textConfirm: 'حذف',
                                textCancel: 'إلغاء',
                                confirmTextColor: Colors.white,
                                buttonColor: Colors.redAccent,
                                onConfirm: () {
                                  Get.back();
                                  controller.deleteLimitItem(limit.mac);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المستهلك: ${controller.formatBytes(limit.currentUsageBytes)}', style: TextStyle(color: subTextColor, fontSize: 12)),
                      Text('الباقة: ${controller.formatBytes(limit.quotaBytes)}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(progress >= 0.9 ? Colors.redAccent : glowColor),
                    ),
                  ),
                ],
              ),
            );
          },
        )
        )
      ],
    );
  }

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
        keyboardType: TextInputType.numberWithOptions(decimal: true),
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

  Widget _buildPresetsGrid({required Function(double, String) onApply, String? currentQuotaValue, String? currentUnit}) {
    final List<Map<String, dynamic>> presets = [
      {'label': '100 MB', 'val': 100.0, 'unit': 'MB'},
      {'label': '500 MB', 'val': 500.0, 'unit': 'MB'},
      {'label': '1 GB', 'val': 1.0, 'unit': 'GB'},
      {'label': '2 GB', 'val': 2.0, 'unit': 'GB'},
      {'label': '5 GB', 'val': 5.0, 'unit': 'GB'},
      {'label': '10 GB', 'val': 10.0, 'unit': 'GB'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: presets.map((p) {
        final bool isSelected = currentQuotaValue == (p['val'] == p['val'].toInt() ? p['val'].toInt().toString() : p['val'].toString()) && currentUnit == p['unit'];
        return GestureDetector(
          onTap: () => onApply(p['val'], p['unit']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (Get.width - 80) / 3, // عرض 3 عناصر في السطر
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? glowColor.withValues(alpha: 0.15) : cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? glowColor : Colors.grey.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Center(
              child: Text(p['label'], style: TextStyle(color: isSelected ? glowColor : textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // 🚀 النافذة السفلية لإضافة أو تعديل جهاز
  // ==========================================
  void _showSmartAddDeviceSheet(BuildContext context, {DeviceDataLimit? limit}) {
    final bool isEdit = limit != null;
    
    if (isEdit) {
      controller.selectedSmartMac.value = limit.mac;
      controller.selectedSmartName.value = limit.comment.isNotEmpty ? limit.comment : limit.hostname;
    } else {
      controller.selectedSmartMac.value = '';
      controller.selectedSmartName.value = '';
    }

    final quotaCtrl = TextEditingController();
    var selectedUnit = 'MB'.obs;

    if (isEdit && limit.quotaBytes > 0) {
      int bytes = limit.quotaBytes;
      double val;
      if (bytes >= 1024 * 1024 * 1024 && bytes % (1024 * 1024 * 1024) == 0) {
        selectedUnit.value = 'GB';
        val = bytes / (1024 * 1024 * 1024);
      } else if (bytes >= 1024 * 1024) {
        selectedUnit.value = 'MB';
        val = bytes / (1024 * 1024);
      } else {
        selectedUnit.value = 'KB';
        val = bytes / 1024;
      }
      quotaCtrl.text = val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);
    }

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
            Text(isEdit ? 'تعديل قيد جهاز' : 'إضافة قيد جهاز', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(isEdit ? 'قم بتعديل باقة البيانات المخصصة لهذا الجهاز.' : 'اختر جهازاً، ثم حدد الباقة المسموحة.', style: TextStyle(color: subTextColor, fontSize: 14)),
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
                            ? Center(child: Text('ميزة الأجهزة غير متوفرة', style: TextStyle(color: subTextColor)))
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
                                bool isSelected = controller.selectedSmartMac.value == dev.mac;
                                bool alreadyAdded = controller.deviceLimits.any((e) => e.mac == dev.mac);

                                return GestureDetector(
                                  onTap: alreadyAdded ? null : () => controller.selectSmartDevice(dev.mac, devName),
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
                    Obx(() => _buildTextField('MAC Address', TextEditingController(text: controller.selectedSmartMac.value), Iconsax.cpu, readOnly: true)),
                    const SizedBox(height: 20),

                    // 3. إعداد الباقة
                    Row(
                      children: [
                        Expanded(flex: 2, child: _buildTextField('حجم الباقة', quotaCtrl, Iconsax.data)),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Obx(() => DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedUnit.value,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, color: subTextColor),
                                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                                dropdownColor: cardColor,
                                borderRadius: BorderRadius.circular(15),
                                items: ['KB', 'MB', 'GB'].map((String unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    selectedUnit.value = value;
                                  }
                                },
                              ),
                            )),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 4. الباقات الجاهزة
                    Text('الباقات الجاهزة:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    ValueListenableBuilder(
                      valueListenable: quotaCtrl,
                      builder: (context, value, _) {
                        return Obx(() => _buildPresetsGrid(
                          onApply: (v, unit) {
                            quotaCtrl.text = v == v.toInt() ? v.toInt().toString() : v.toString();
                            selectedUnit.value = unit;
                          },
                          currentQuotaValue: quotaCtrl.text,
                          currentUnit: selectedUnit.value,
                        ));
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
                bool isReady = controller.selectedSmartMac.value.isNotEmpty;
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReady ? glowColor : Colors.grey.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: isReady ? 5 : 0,
                  ),
                  icon: Icon(isEdit ? Iconsax.tick_circle : Iconsax.add, color: isReady ? Colors.white : Colors.white54),
                  label: Text(isEdit ? 'تحديث البيانات' : 'تأكيد الإضافة', style: TextStyle(color: isReady ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: isReady ? () {
                    final quotaStr = quotaCtrl.text.trim();
                    final quotaVal = double.tryParse(quotaStr);
                    if (quotaVal == null || quotaVal <= 0) {
                      Get.snackbar('تنبيه', 'الرجاء إدخال قيمة باقة صحيحة',
                          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
                      return;
                    }

                    int quotaBytes = 0;
                    if (selectedUnit.value == 'KB') {
                      quotaBytes = (quotaVal * 1024).toInt();
                    } else if (selectedUnit.value == 'MB') {
                      quotaBytes = (quotaVal * 1024 * 1024).toInt();
                    } else if (selectedUnit.value == 'GB') {
                      quotaBytes = (quotaVal * 1024 * 1024 * 1024).toInt();
                    }

                    final commentName = controller.selectedSmartName.value.isEmpty ? 'جهاز مخصص' : controller.selectedSmartName.value;

                    if (isEdit) {
                      controller.updateLimitItem(
                        int.parse(limit.index),
                        controller.selectedSmartMac.value,
                        quotaBytes,
                        commentName
                      );
                    } else {
                      controller.addLimitItem(
                        controller.selectedSmartMac.value,
                        quotaBytes,
                        commentName
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
