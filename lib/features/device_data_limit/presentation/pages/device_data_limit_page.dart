import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/widgets/custom_snackbar.dart';
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
  Color get glowColor => Get.isDarkMode ? const Color(0xFF4A90E2) : const Color(
      0xFF538ACA); // Purple glow for data limit

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
                      // 1. حالة الميزة (مدعومة أو قادمة في التحديث)
                      if (!controller.isFeatureSupported.value) ...[
                        _buildComingSoonView(context),
                      ] else ...[
                        // مفتاح التفعيل الرئيسي
                        _buildMainToggle(),
                        const SizedBox(height: 25),

                        // 🌟 العرض الديناميكي للأجهزة
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
  // 🚀 واجهة الميزة القادمة (في حال عدم دعم المودم الحالي)
  // ==========================================

  Widget _buildComingSoonView(BuildContext context) {
    final isDark = Get.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: glowColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // شارة الحالة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4A90E2).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'قريباً في التحديث القادم للمودم',
                  style: TextStyle(
                    color: Color.fromRGBO(74, 144, 226, 1),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // عنوان
          Text(
            'ميزة جديدة قادمة لمودمك!',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // الشرح التوضيحي
          Text(
            'أطلقت شركة SAM4G للمودم تحديثاً برمجياً جديداً يدعم تحديد ومراقبة باقات الأجهزة المتصلة. يجري حالياً إطلاق التحديث تدريجياً لجميع المودمات، وستعمل هذه الشاشة لديك فور وصول التحديث لجهازك.',
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // بطاقة المميزات القادمة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _buildUpcomingFeatureItem(
                  icon: Iconsax.chart_2,
                  title: 'تحديد حصة البيانات',
                  desc: 'تحديد حجم ميجابايت مخصص لكل جهاز متصل بالشبكة.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                _buildUpcomingFeatureItem(
                  icon: Iconsax.status_up,
                  title: 'متابعة الاستهلاك اللحظي',
                  desc: 'شريط تقدم يوضح كمية البيانات المستهلكة بدقة.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                _buildUpcomingFeatureItem(
                  icon: Iconsax.shield_cross,
                  title: 'إيقاف الإنترنت التلقائي',
                  desc: 'قطع الإنترنت عن الجهاز تلقائياً عند انتهاء باقته المحددة.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // زر التحقق من التحديث
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await controller.fetchData(silent: true);
                if (controller.isFeatureSupported.value) {
                  CustomSnackbar.showSuccess('مبروك!', 'تم تفعيل ميزة باقة الأجهزة في مودمك بنجاح.');
                } else {
                  CustomSnackbar.showInfo(
                    'لم يصل التحديث بعد',
                    'لم يتلقَّ مودمك التحديث بعد. يرجى إعادة المحاولة لاحقاً بعد نزول التحديث للمودم.',
                  );
                }
              },
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Iconsax.refresh, size: 18),
              label: Text(
                controller.isLoading.value ? 'جاري الفحص...' : 'فحص توفر الميزة في مودمي الآن',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: glowColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: glowColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: glowColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
