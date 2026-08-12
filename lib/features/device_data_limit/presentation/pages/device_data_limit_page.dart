import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/device_data_limit_controller.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../../domain/entities/device_data_limit.dart';
import '../widgets/data_rule_editor_sheet.dart';

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
            Text('الأجهزة المقيدة', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            if (controller.isEnabled.value)
              TextButton.icon(
                onPressed: () => DataRuleEditorSheet.show(context),
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
                            onPressed: () => DataRuleEditorSheet.show(context, limit: limit),
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
}
