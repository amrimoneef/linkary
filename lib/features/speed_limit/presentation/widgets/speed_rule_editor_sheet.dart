import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/speed_limit_entity.dart';
import '../controllers/speed_limit_controller.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';

class SpeedRuleEditorSheet {
  static void show(
    BuildContext context, {
    SpeedLimitItem? item, 
    String? preSelectedIp, 
    String? preSelectedName,
    Function(int up, int down)? onSaveDraft,
    VoidCallback? onDeleteDraft,
  }) {
    final SpeedLimitController controller = Get.find<SpeedLimitController>();
    final bool isEdit = item != null;
    
    if (isEdit) {
      controller.selectedSmartIp.value = item.ip;
      controller.selectedSmartName.value = item.comment;
    } else {
      controller.selectedSmartIp.value = preSelectedIp ?? '';
      controller.selectedSmartName.value = preSelectedName ?? '';
    }

    final upCtrl = TextEditingController(text: isEdit ? item.upSpeed.toString() : '0');
    final dlCtrl = TextEditingController(text: isEdit ? item.dlSpeed.toString() : '0');

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
                    if (!isEdit) ...[
                      Opacity(
                        opacity: preSelectedIp != null ? 0.5 : 1.0,
                        child: AbsorbPointer(
                          absorbing: preSelectedIp != null,
                          child: SizedBox(
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

                    Obx(() => buildTextField('IP الجهاز', TextEditingController(text: controller.selectedSmartIp.value), Iconsax.global, cardColor, textColor, subTextColor, readOnly: true)),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: buildTextField('سرعة التنزيل', dlCtrl, Iconsax.arrow_down, cardColor, textColor, subTextColor)),
                        const SizedBox(width: 15),
                        Expanded(child: buildTextField('سرعة الرفع', upCtrl, Iconsax.arrow_up_3, cardColor, textColor, subTextColor)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    Text('السرعات الجاهزة:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    ValueListenableBuilder(
                      valueListenable: dlCtrl,
                      builder: (context, value, _) {
                        return buildPresetsGrid(
                          cardColor: cardColor,
                          glowColor: glowColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
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
                            controller.removeDeviceRule(item.index);
                            controller.saveData();
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
                      bool isReady = controller.selectedSmartIp.value.isNotEmpty;
                      return ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReady ? glowColor : Colors.grey.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: isReady ? 5 : 0,
                        ),
                        icon: Icon(isEdit ? Iconsax.tick_circle : Iconsax.add, color: isReady ? Colors.white : Colors.white54),
                        label: Text(isEdit ? 'تحديث البيانات' : 'تأكيد الإضافة', style: TextStyle(color: isReady ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: isReady ? () {
                          if (onSaveDraft != null) {
                            onSaveDraft(int.parse(upCtrl.text), int.parse(dlCtrl.text));
                          } else {
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
                            controller.saveData(); // Apply explicitly.
                            Get.back(); // Closes the editor sheet.
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

  static Widget buildPresetsGrid({required Color cardColor, required Color glowColor, required Color textColor, required Color subTextColor, required Function(int) onApply, String? currentDlValue}) {
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
        final bool isSelected = currentDlValue == p['val'].toString();
        return GestureDetector(
          onTap: () => onApply(p['val']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (Get.width - 80) / 3,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? glowColor.withOpacity(0.15) : cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? glowColor : Colors.grey.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              children: [
                Text(p['label'], style: TextStyle(color: isSelected ? glowColor : textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(p['sub'], style: TextStyle(color: isSelected ? glowColor : subTextColor, fontSize: 10)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
