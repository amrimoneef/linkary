import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/parental_control_controller.dart';
import '../../domain/entities/parental_control_entity.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';

class ParentalRuleEditorSheet {
  static void show(
    BuildContext context, {
    ParentalDevice? deviceToEdit,
    String? preSelectedMac,
    Function(TimeOfDay start, TimeOfDay end, List<int> days)? onSaveDraft,
    VoidCallback? onDeleteDraft,
  }) {
    final ParentalControlController controller = Get.find<ParentalControlController>();
    ConnectedDevicesController? devicesController;
    try {
      devicesController = Get.find<ConnectedDevicesController>();
      if (devicesController.devices.isEmpty) devicesController.fetchDevices();
    } catch (_) {}

    var selectedMac = (deviceToEdit?.mac ?? preSelectedMac ?? '').obs;
    
    TimeOfDay initialStart = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay initialEnd = const TimeOfDay(hour: 23, minute: 59);
    List<int> initialDays = [];

    if (deviceToEdit != null && deviceToEdit.timeSlots.isNotEmpty) {
      final slot = deviceToEdit.timeSlots.first;
      initialStart = TimeOfDay(hour: slot.startTime ~/ 60, minute: slot.startTime % 60);
      initialEnd = TimeOfDay(hour: slot.endTime ~/ 60, minute: slot.endTime % 60);
      
      for (int i = 0; i < 7; i++) {
        if ((slot.repeatMode & (1 << i)) != 0) initialDays.add(i);
      }
    }

    var startTime = initialStart.obs;
    var endTime = initialEnd.obs;
    var selectedDays = initialDays.obs; 

    final List<String> weekDays = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

    Color bgColor = Get.isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFFAFAFC);
    Color cardColor = Get.isDarkMode ? const Color(0xFF16213E) : Colors.white;
    Color textColor = Get.isDarkMode ? Colors.white : const Color(0xFF111827);
    Color subTextColor = Get.isDarkMode ? Colors.white54 : const Color(0xFF6B7280);
    Color glowColor = Get.isDarkMode ? const Color(0xFF4A90E2) : const Color(0xFF92C0F6);

    Get.bottomSheet(
      Container(
        height: Get.height * 0.88,
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
            Text(deviceToEdit == null ? 'إعداد قاعدة وقت جديدة' : 'تعديل قاعدة الوقت', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(deviceToEdit == null ? 'اختر الجهاز، ثم حدد الأوقات والأيام المسموح بها.' : 'قم بتعديل الأوقات والأيام لهذا الجهاز.', style: TextStyle(color: subTextColor, fontSize: 14)),
            const SizedBox(height: 25),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. اختر الجهاز:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: (deviceToEdit == null && preSelectedMac == null) ? 1.0 : 0.5,
                      child: AbsorbPointer(
                        absorbing: deviceToEdit != null || preSelectedMac != null,
                        child: SizedBox(
                          height: 130,
                          child: devicesController == null
                              ? Center(child: Text('الرجاء التأكد من الأجهزة المتصلة', style: TextStyle(color: subTextColor)))
                              : Obx(() {
                            if (devicesController!.isLoading.value) return Center(child: CircularProgressIndicator(color: glowColor));
                            if (devicesController.devices.isEmpty) return Center(child: Text('لا توجد أجهزة متصلة', style: TextStyle(color: subTextColor)));
    
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: devicesController.devices.length,
                              itemBuilder: (context, index) {
                                final dev = devicesController!.devices[index];
                                return Obx(() {
                                  bool isSel = selectedMac.value == dev.mac;
                                  return GestureDetector(
                                    onTap: () => selectedMac.value = dev.mac,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 110,
                                      margin: const EdgeInsets.only(left: 15),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSel ? glowColor.withOpacity(0.1) : cardColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: isSel ? glowColor : Colors.grey.withOpacity(0.2), width: isSel ? 2 : 1),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Iconsax.mobile, color: isSel ? glowColor : subTextColor, size: 30),
                                          const SizedBox(height: 10),
                                          Text(dev.name.isEmpty ? 'جهاز مجهول' : dev.name, style: TextStyle(color: isSel ? glowColor : textColor, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                    const SizedBox(height: 25),

                    Text('2. فترة السماح بالإنترنت:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildTimePickerBox(context, 'من الساعة', startTime, (time) => startTime.value = time, cardColor, subTextColor, textColor, glowColor)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildTimePickerBox(context, 'إلى الساعة', endTime, (time) => endTime.value = time, cardColor, subTextColor, textColor, glowColor)),
                      ],
                    ),
                    const SizedBox(height: 25),

                    Text('3. الأيام المسموح بها:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Obx(() => Wrap(
                      spacing: 10, runSpacing: 10,
                      children: List.generate(7, (index) {
                        bool isSel = selectedDays.contains(index);
                        return FilterChip(
                          label: Text(weekDays[index], style: TextStyle(color: isSel ? Colors.white : textColor, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          showCheckmark: false,
                          selectedColor: glowColor,
                          backgroundColor: cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isSel ? glowColor : Colors.grey.withOpacity(0.2))),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          onSelected: (bool selected) {
                            if (selected) selectedDays.add(index);
                            else selectedDays.remove(index);
                          },
                        );
                      }),
                    )),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            Row(
              children: [
                if (deviceToEdit != null) ...[
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
                            controller.deleteDevice(selectedMac.value);
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
                      bool isReady = selectedMac.value.isNotEmpty;
                      return ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReady ? glowColor : Colors.grey.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: isReady ? 5 : 0,
                          shadowColor: glowColor.withOpacity(0.5),
                        ),
                        icon: Icon(Iconsax.tick_circle, color: isReady ? Colors.white : Colors.white54),
                        label: Text(deviceToEdit == null ? 'حفظ القاعدة' : 'تحديث القاعدة', style: TextStyle(color: isReady ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: isReady ? () {
                          if (selectedDays.isEmpty) selectedDays.addAll([0,1,2,3,4,5,6]); 
                          if (onSaveDraft != null) {
                            onSaveDraft(startTime.value, endTime.value, selectedDays.toList());
                          } else {
                            controller.saveRule(selectedMac.value, startTime.value, endTime.value, selectedDays);
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

  static Widget _buildTimePickerBox(BuildContext context, String title, Rx<TimeOfDay> timeObs, Function(TimeOfDay) onPicked, Color cardColor, Color subTextColor, Color textColor, Color glowColor) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context, initialTime: timeObs.value,
          builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Get.isDarkMode ? ColorScheme.dark(primary: glowColor) : ColorScheme.light(primary: glowColor),
              ),
              child: child!
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.clock, color: subTextColor, size: 16),
                const SizedBox(width: 5),
                Text(title, style: TextStyle(color: subTextColor, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() => Text(timeObs.value.format(context), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
          ],
        ),
      ),
    );
  }
}
