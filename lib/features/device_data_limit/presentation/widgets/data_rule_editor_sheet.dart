import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/device_data_limit.dart';
import '../controllers/device_data_limit_controller.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';

class DataRuleEditorSheet {
  static void show(
    BuildContext context, {
    DeviceDataLimit? limit, 
    String? preSelectedMac, 
    String? preSelectedName,
    Function(int quotaBytes)? onSaveDraft,
    VoidCallback? onDeleteDraft,
  }) {
    final DeviceDataLimitController controller = Get.find<DeviceDataLimitController>();
    final bool isEdit = limit != null;
    
    if (isEdit) {
      controller.selectedSmartMac.value = limit.mac;
      controller.selectedSmartName.value = limit.comment.isNotEmpty ? limit.comment : limit.hostname;
    } else {
      controller.selectedSmartMac.value = preSelectedMac ?? '';
      controller.selectedSmartName.value = preSelectedName ?? '';
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

    Color bgColor = Get.isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFFAFAFC);
    Color cardColor = Get.isDarkMode ? const Color(0xFF16213E) : Colors.white;
    Color textColor = Get.isDarkMode ? Colors.white : const Color(0xFF111827);
    Color subTextColor = Get.isDarkMode ? Colors.white54 : const Color(0xFF6B7280);
    Color glowColor = Get.isDarkMode ? const Color(0xFF4A90E2) : const Color(0xFF92C0F6);

    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Text(isEdit ? 'تعديل باقة الجهاز' : 'إضافة جهاز للقائمة', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(isEdit ? 'قم بتعديل باقة البيانات المخصصة لهذا الجهاز.' : 'اختر جهازاً، ثم حدد الباقة المسموحة.', style: TextStyle(color: subTextColor, fontSize: 14)),
            const SizedBox(height: 25),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEdit) ...[
                      Opacity(
                        opacity: preSelectedMac != null ? 0.5 : 1.0,
                        child: AbsorbPointer(
                          absorbing: preSelectedMac != null,
                          child: SizedBox(
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
                                              ? Colors.grey.withOpacity(0.05)
                                              : (isSelected ? glowColor.withOpacity(0.1) : cardColor),
                                          borderRadius: BorderRadius.circular(22),
                                          border: Border.all(
                                              color: alreadyAdded
                                                  ? Colors.transparent
                                                  : (isSelected ? glowColor : Colors.grey.withOpacity(0.1)),
                                              width: isSelected ? 2 : 1),
                                          boxShadow: isSelected ? [BoxShadow(color: glowColor.withOpacity(0.1), blurRadius: 10)] : [],
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
                                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
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
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    Obx(() => buildTextField('MAC Address', TextEditingController(text: controller.selectedSmartMac.value), Iconsax.cpu, cardColor, textColor, subTextColor, readOnly: true)),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(flex: 2, child: buildTextField('حجم الباقة', quotaCtrl, Iconsax.data, cardColor, textColor, subTextColor)),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
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

                    Text('الباقات الجاهزة:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    ValueListenableBuilder(
                      valueListenable: quotaCtrl,
                      builder: (context, value, _) {
                        return Obx(() => buildPresetsGrid(
                          cardColor: cardColor,
                          glowColor: glowColor,
                          textColor: textColor,
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

            Row(
              children: [
                if (isEdit) ...[
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (onDeleteDraft != null) {
                            onDeleteDraft();
                          } else {
                            Get.back();
                            controller.deleteLimitItem(limit.mac);
                          }
                        },
                        child: const Icon(Iconsax.trash),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 60,
                    child: Obx(() {
                      bool isReady = controller.selectedSmartMac.value.isNotEmpty;
                      return ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReady ? glowColor : Colors.grey.withOpacity(0.3),
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

                          if (onSaveDraft != null) {
                            onSaveDraft(quotaBytes);
                          } else {
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
                            controller.fetchData(); // Refresh list after change
                            Get.back(); // close the sheet
                          }
                        } : null,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget buildTextField(String label, TextEditingController textController, IconData icon, Color cardColor, Color textColor, Color subTextColor, {bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: textController,
        readOnly: readOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  static Widget buildPresetsGrid({required Color cardColor, required Color glowColor, required Color textColor, required Function(double, String) onApply, String? currentQuotaValue, String? currentUnit}) {
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
              color: isSelected ? glowColor.withOpacity(0.15) : cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? glowColor : Colors.grey.withOpacity(0.2), width: 1.5),
            ),
            child: Center(
              child: Text(p['label'], style: TextStyle(color: isSelected ? glowColor : textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
