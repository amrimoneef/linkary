import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/parental_control_controller.dart';
import '../../domain/entities/parental_control_entity.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../widgets/parental_rule_editor_sheet.dart';

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
                              onPressed: () => ParentalRuleEditorSheet.show(context),
                              icon: const Icon(Iconsax.add_square, color: Colors.blueAccent),
                              label: const Text('إضافة وقت', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
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
                                      onPressed: () => ParentalRuleEditorSheet.show(context, deviceToEdit: dev),
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

}