import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/parental_control_controller.dart';
import '../../domain/entities/parental_control_entity.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';

class ParentalControlPage extends StatelessWidget {
  ParentalControlPage({super.key});

  final ParentalControlController controller = Get.find<ParentalControlController>();

  // 🎨 الألوان الديناميكية (الهوية الموحدة)
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
            // 🌌 1. الدائرة السحرية المتدرجة في الزاوية العلوية (Radial Glow)
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: Get.isDarkMode ? 0.3 : 0.4),
                      glowColor.withValues(alpha: 0.0),
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),

            // 📝 2. المحتوى الرئيسي
            SafeArea(
              child: controller.isLoading.value
                  ? Center(child: CircularProgressIndicator(color: glowColor))
                  : SingleChildScrollView(
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
                      const SizedBox(height: 40),

                      // العنوان الرئيسي
                      Text('التحكم الأبوي', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تقييد أوقات السماح للأجهزة المحددة،', style: TextStyle(color: subTextColor, fontSize: 14)),
                          Text('باستخدام الانترنت خلالها ', style: TextStyle(color: subTextColor, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // ==========================================
                      // 1. مفتاح التشغيل الرئيسي
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: SwitchListTile(
                          title: Row(
                            children: [
                              Text('تفعيل التحكم الأبوي', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 10),
                              Text('${controller.isEnabled.value ? 'مفعل' : 'معطل'}', style: TextStyle(color: controller.isEnabled.value ? glowColor : subTextColor, fontSize: 12)),
                            ],
                          ),
                          subtitle: Text('تقييد وصول الأجهزة للإنترنت بناءً على الوقت', style: TextStyle(color: subTextColor, fontSize: 12)),
                          value: controller.isEnabled.value,
                          activeColor: glowColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onChanged: (val) => controller.toggleParentalControl(val),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 2. قائمة الأجهزة المقيدة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الأجهزة المقيدة', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (controller.isEnabled.value)
                            TextButton.icon(
                              onPressed: () => _showRuleEditor(context),
                              icon: Icon(Iconsax.add_square, color: glowColor),
                              label: Text('إضافة وقت', style: TextStyle(color: glowColor, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      const SizedBox(height: 15),

                      !controller.isEnabled.value
                          ? _buildEmptyState('التحكم الأبوي معطل. قم بتفعيله لإدارة الأجهزة.', Iconsax.shield_cross)
                          : (controller.devicesList.isEmpty)
                          ? _buildEmptyState('لا توجد أجهزة مقيدة. أضف قواعد جديدة الآن.', Iconsax.clock)
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.devicesList.length,
                        itemBuilder: (context, index) {
                          final dev = controller.devicesList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // إخفاء خطوط ExpansionTile المزعجة
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: glowColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                                  child: Icon(Iconsax.mobile, color: glowColor),
                                ),
                                title: Text(dev.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                                subtitle: Text(dev.mac, style: TextStyle(color: subTextColor, fontSize: 12, fontFamily: 'monospace')),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Iconsax.edit, size: 20, color: Colors.blueAccent),
                                      onPressed: () => _showRuleEditor(context, deviceToEdit: dev),
                                    ),
                                    IconButton(
                                      icon: const Icon(Iconsax.trash, size: 20, color: Colors.redAccent),
                                      onPressed: () => _confirmDelete(context, dev),
                                    ),
                                    const Icon(Icons.expand_more, color: Colors.grey),
                                  ],
                                ),
                                iconColor: glowColor,
                                children: dev.timeSlots.map((slot) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Get.isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ListTile(
                                      leading: const Icon(Iconsax.clock, color: Colors.orangeAccent),
                                      title: Text(slot.formattedTimeRange, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                                      subtitle: Text(slot.activeDays, style: TextStyle(color: Colors.green, fontSize: 12)),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                          );
                        },
                      ),
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

  // 🛠️ دالة مساعدة لحالة الفراغ (Empty State)
  Widget _buildEmptyState(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: subTextColor.withValues(alpha: 0.5), size: 50),
          const SizedBox(height: 15),
          Text(msg, style: TextStyle(color: subTextColor, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ParentalDevice device) {
    Get.defaultDialog(
      title: 'حذف التقييد',
      middleText: 'هل أنت متأكد من حذف جميع قيود الوقت لجهاز "${device.name}"؟',
      textConfirm: 'نعم، احذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        Get.back();
        controller.deleteDevice(device.mac);
      },
    );
  }

  // ==========================================
  // 🚀 النافذة السفلية الذكية (Smart Rule Editor) بهوية التصميم
  // ==========================================
  void _showRuleEditor(BuildContext context, {ParentalDevice? deviceToEdit}) {
    ConnectedDevicesController? devicesController;
    try {
      devicesController = Get.find<ConnectedDevicesController>();
      if (devicesController.devices.isEmpty) devicesController.fetchDevices();
    } catch (_) {}

    var selectedMac = (deviceToEdit?.mac ?? '').obs;
    
    // فك تشفير الوقت إذا كان هناك تعديل (بافتراض أول فترة زمنية)
    TimeOfDay initialStart = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay initialEnd = const TimeOfDay(hour: 23, minute: 59);
    List<int> initialDays = [];

    if (deviceToEdit != null && deviceToEdit.timeSlots.isNotEmpty) {
      final slot = deviceToEdit.timeSlots.first;
      initialStart = TimeOfDay(hour: slot.startTime ~/ 60, minute: slot.startTime % 60);
      initialEnd = TimeOfDay(hour: slot.endTime ~/ 60, minute: slot.endTime % 60);
      
      // فك تشفير bitmask للأيام
      for (int i = 0; i < 7; i++) {
        if ((slot.repeatMode & (1 << i)) != 0) initialDays.add(i);
      }
    }

    var startTime = initialStart.obs;
    var endTime = initialEnd.obs;
    var selectedDays = initialDays.obs; 

    final List<String> weekDays = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

    Get.bottomSheet(
      Container(
        height: Get.height * 0.88,
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
                    // 1. اختيار الجهاز
                    Text('1. اختر الجهاز:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: deviceToEdit == null ? 1.0 : 0.5,
                      child: AbsorbPointer(
                        absorbing: deviceToEdit != null,
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
                                        color: isSel ? glowColor.withValues(alpha: 0.1) : cardColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: isSel ? glowColor : Colors.grey.withValues(alpha: 0.2), width: isSel ? 2 : 1),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
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

                    // 2. اختيار الأوقات
                    Text('2. فترة السماح بالإنترنت:', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildTimePickerBox(context, 'من الساعة', startTime, (time) => startTime.value = time)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildTimePickerBox(context, 'إلى الساعة', endTime, (time) => endTime.value = time)),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 3. اختيار الأيام
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isSel ? glowColor : Colors.grey.withValues(alpha: 0.2))),
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

            // 4. زر الحفظ السفلي الثابت
            SizedBox(
              width: double.infinity, height: 60,
              child: Obx(() {
                bool isReady = selectedMac.value.isNotEmpty;
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReady ? glowColor : Colors.grey.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: isReady ? 5 : 0,
                    shadowColor: glowColor.withValues(alpha: 0.5),
                  ),
                  icon: Icon(Iconsax.tick_circle, color: isReady ? Colors.white : Colors.white54),
                  label: Text(deviceToEdit == null ? 'حفظ القاعدة' : 'تحديث القاعدة', style: TextStyle(color: isReady ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: isReady ? () {
                    if (selectedDays.isEmpty) selectedDays.addAll([0,1,2,3,4,5,6]); // الافتراضي كل الأيام
                    controller.saveRule(selectedMac.value, startTime.value, endTime.value, selectedDays);
                  } : null,
                );
              }),
            )
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // 🛠️ دالة مساعدة لرسم مربع اختيار الوقت النظيف
  Widget _buildTimePickerBox(BuildContext context, String title, Rx<TimeOfDay> timeObs, Function(TimeOfDay) onPicked) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context, initialTime: timeObs.value,
          builder: (context, child) => Theme(
            // تخصيص الألوان لتتناسب مع الهوية (نافذة اختيار الوقت الرسمية)
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
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
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