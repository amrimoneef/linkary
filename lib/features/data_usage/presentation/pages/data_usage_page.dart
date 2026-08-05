import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/data_usage_controller.dart';

class DataUsagePage extends StatelessWidget {
  DataUsagePage({super.key});

  final DataUsageController controller = Get.find<DataUsageController>();

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
              top: -120,
              right: -100, // وضعها في الزاوية اليمنى كما في الصورة (يمكنك جعلها left إذا أردت العكس)
              child: Container(
                width: 370,
                height: 370,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: Get.isDarkMode ? 0.3 : 0.4), // لون الدائرة من المنتصف
                      glowColor.withValues(alpha: 0.01), // التلاشي الشفاف في الأطراف
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
                      Text('إدارة الباقة', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('تقييد استهلاك البيانات؟ ', style: TextStyle(color: subTextColor, fontSize: 14)),
                          Text('تحكم بمصروفك', style: TextStyle(color: glowColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // ==========================================
                      // 1. إعدادات الحزمة
                      Text('إعدادات الخطة', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            // نوع الحزمة
                            _buildDropdownField<String>(
                              label: 'نوع الباقة',
                              icon: Iconsax.chart_1,
                              selectedValue: controller.selectedPackageType.value == 'not_set' ? 'غير محدود' : 'محدد',
                              items: ['غير محدود', 'محدد'],
                              onChanged: (val) => controller.selectedPackageType.value = val == 'محدد' ? 'unlimited' : 'not_set',
                            ),

                            // بيانات الحزمة (تظهر بانسيابية إذا اختار "محدد")
                            AnimatedCrossFade(
                              firstChild: const SizedBox(width: double.infinity, height: 0),
                              secondChild: Column(
                                children: [
                                  const SizedBox(height: 15),
                                  Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
                                  const SizedBox(height: 15),
                                  _buildDropdownField<String>(
                                    label: 'حجم الباقة المسموح',
                                    icon: Iconsax.data,
                                    selectedValue: '${controller.selectedGB.value} جيجا بايت',
                                    items: List.generate(10, (i) => '${i + 1} جيجا بايت'),
                                    onChanged: (val) => controller.selectedGB.value = int.parse(val!.split(' ')[0]),
                                  ),
                                ],
                              ),
                              crossFadeState: controller.selectedPackageType.value == 'not_set' ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 2. زر الحفظ
                      _buildSaveButton(),
                      const SizedBox(height: 40),

                      // ==========================================
                      // 3. قسم المعايرة (بطاقة الاستهلاك الفعلي)
                      Text('الاستهلاك الفعلي للمودم', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [glowColor.withValues(alpha: 0.8), glowColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('البيانات المستخدمة', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                                const SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(controller.usedDataFormatted.value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                    const SizedBox(width: 5),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 5.0),
                                      child: Text('GB', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // زر المعايرة
                            GestureDetector(
                              onTap: () => _showSmartCalibrationSheet(context),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                                ),
                                child: Icon(Iconsax.edit_2, color: glowColor, size: 24),
                              ),
                            ),
                          ],
                        ),
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

  // ==========================================
  // 🧩 دوال بناء الواجهة
  // ==========================================

  Widget _buildDropdownField<T>({required String label, required IconData icon, required T selectedValue, required List<T> items, required Function(T?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: subTextColor, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          decoration: BoxDecoration(
            color: Get.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: selectedValue,
              dropdownColor: cardColor,
              icon: Icon(Icons.keyboard_arrow_down, color: subTextColor),
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: glowColor,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          shadowColor: glowColor.withValues(alpha: 0.5),
        ),
        onPressed: controller.isSaving.value ? null : () => controller.saveSettings(),
        child: controller.isSaving.value
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Iconsax.arrow_right_1, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🚀 النافذة السفلية الذكية للمعايرة (Smart Calibration Sheet)
  // ==========================================
  void _showSmartCalibrationSheet(BuildContext context) {
    final valueCtrl = TextEditingController(text: controller.usedDataFormatted.value);
    var selectedUnit = 'جيجا بايت'.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Text('معايرة عداد البيانات', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('قم بإدخال الرقم الفعلي لاستهلاكك لتصحيح قراءة المودم.', style: TextStyle(color: subTextColor, fontSize: 14)),
            const SizedBox(height: 25),

            // حقل إدخال القيمة والوحدة
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: valueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: glowColor, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0.0',
                        hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Obx(() => DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedUnit.value,
                          dropdownColor: cardColor,
                          icon: Icon(Icons.keyboard_arrow_down, color: subTextColor),
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                          isExpanded: true,
                          items: ['جيجا بايت', 'ميجا بايت'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => selectedUnit.value = val!,
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // زر تأكيد المعايرة
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: glowColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  shadowColor: glowColor.withValues(alpha: 0.5),
                ),
                icon: const Icon(Iconsax.magic_star, color: Colors.white),
                label: const Text('تأكيد المعايرة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final double amount = double.tryParse(valueCtrl.text) ?? 0.0;
                  controller.calibrateData(amount, selectedUnit.value);
                },
              ),
            ),
            const SizedBox(height: 20), // لترك مسافة أمان للكيبورد
          ],
        ),
      ),
      isScrollControlled: true, // ضروري للكيبورد
    );
  }
}