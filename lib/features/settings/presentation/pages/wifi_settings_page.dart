import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/wifi_settings_controller.dart';

class WifiSettingsPage extends StatelessWidget {
  WifiSettingsPage({super.key});

  final WifiSettingsController controller = Get.find<WifiSettingsController>();

  // 🎨 الألوان الديناميكية (نظيفة جداً لتطابق الصورة)
  Color get bgColor => Get.isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFFAFAFC);
  Color get cardColor => Get.isDarkMode ? const Color(0xFF16213E) : Colors.white;
  Color get textColor => Get.isDarkMode ? Colors.white : const Color(0xFF111827);
  Color get subTextColor => Get.isDarkMode ? Colors.white54 : const Color(0xFF6B7280);

  // لون التدرج الدائري في الزاوية (بنفسجي ناعم)
Color get glowColor => Get.isDarkMode ? const Color(0xFF4A90E2) : const Color(0xFF92C0F6);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // 🌌 1. الدائرة السحرية المتدرجة في الزاوية العلوية
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

            // 📝 2. المحتوى الرئيسي (النصوص والحقول)
            SafeArea(
              child: Form(
                key: controller.formKey,
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      Text('إعدادات الواي فاي', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('تعديل اسم الشبكة والحماية؟ ', style: TextStyle(color: subTextColor, fontSize: 14)),
                          Text('إدارة آمنة', style: TextStyle(color: glowColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // ==========================================
                      // 1. حقل اسم الشبكة
                      _buildTextField(
                        controller: controller.ssidController,
                        label: 'اسم الشبكة (SSID)',
                        validator: Validators.validateWifiSsid,
                      ),
                      const SizedBox(height: 20),

                      // 2. حقل كلمة المرور
                      _buildPasswordField(
                        controller: controller.passwordController,
                        label: 'كلمة المرور',
                        validator: (value) => Validators.validateWifiPassword(
                          value,
                          isEncryptionNone: controller.selectedEncryption.value == 'NONE',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('الإعدادات المتقدمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                      const SizedBox(height: 10),

                      // 3. القناة والأمان
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'القناة',
                              selectedValue: controller.selectedChannel,
                              items: [
                                const DropdownMenuItem(value: '0', child: Text('تلقائي')),
                                ...List.generate(13, (i) => DropdownMenuItem(value: '${i + 1}', child: Text('${i + 1}')))
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildDropdownField<int>(
                              label: 'أقصى عدد للأجهزة',
                              selectedValue: controller.selectedMaxClients,
                              items: List.generate(controller.maxClientsLimit.value, (i) {
                                return DropdownMenuItem(value: i + 1, child: Text('${i + 1}'));
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 4. نمط الأمان
                      _buildDropdownField<String>(
                        label: 'نوع الأمان',
                        selectedValue: controller.selectedEncryption,
                        items: const [
                          DropdownMenuItem(value: 'psk-mixed+tkip+ccmp', child: Text('WPA/WPA2-PSK (موصى به)')),
                          DropdownMenuItem(value: 'NONE', child: Text('مفتوحة (بدون رمز)')),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // 5. مفاتيح التشغيل
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            _buildSwitchTile('إظهار الشبكة للجميع', controller.isBroadcastEnabled),
                            // Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
                            // _buildWifiPowerSwitchTile(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 6. زر الحفظ الملون
                      _buildSaveButton(),
                      const SizedBox(height: 30),
                    ],
                  ),
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
  // 🧩 دوال بناء الواجهة (محدثة لتطابق الصورة)
  // ==========================================

  Widget _buildTextField({required TextEditingController controller, required String label, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor, fontSize: 14),
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: glowColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.redAccent, width: 2.0)),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String label, String? Function(String?)? validator}) {
    return Obx(() => TextFormField(
      controller: controller,
      validator: validator,
      obscureText: !this.controller.isPasswordVisible.value,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor, fontSize: 14),
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: glowColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.redAccent, width: 2.0)),
        suffixIcon: IconButton(
          icon: Icon(this.controller.isPasswordVisible.value ? Iconsax.eye : Iconsax.eye_slash, color: subTextColor, size: 20),
          onPressed: this.controller.togglePasswordVisibility,
        ),
      ),
    ));
  }

  Widget _buildDropdownField<T>({required String label, required Rx<T> selectedValue, required List<DropdownMenuItem<T>> items}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: selectedValue.value,
              dropdownColor: cardColor,
              icon: Icon(Icons.keyboard_arrow_down, color: subTextColor),
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
              isExpanded: true,
              items: items,
              onChanged: (val) { if (val != null) selectedValue.value = val; },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, RxBool rxValue) {
    return Obx(() => SwitchListTile(
      title: Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: const Text('إيقافه سيخفي الشبكة عن جميع الأجهزة!', style: TextStyle(color: Colors.grey, fontSize: 11)),
      value: rxValue.value,
      activeColor: glowColor,
      onChanged: (val) {
        if (val == false) {
          Get.defaultDialog(
            title: 'تحذير ⚠️',
            middleText: 'تعطيل هذا الخيار سيخفي الشبكة عن جميع الأجهزة!\n\n للأتصال بالشبكة يمكنك إدخال اسم الشبكة وكلمة المرور يدويًا من إعدادات الهاتف.\n\n هل أنت متأكد من تعطيله؟',
            textConfirm: 'نعم',
            onConfirm: () { rxValue.value = val; Get.back(); },
            textCancel: 'تراجع',
          );
        } else {
          rxValue.value = val;
        }
      }
    ));
  }

  Widget _buildWifiPowerSwitchTile() {
    return Obx(() => SwitchListTile(
      title: Text('بث إشارة الواي فاي', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: const Text('إيقافه سيفصل جميع الأجهزة فوراً!', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
      value: controller.isWifiEnabled.value,
      activeColor: glowColor,
      inactiveThumbColor: Colors.redAccent,
      onChanged: (val) {
        if (val == false) {
          Get.defaultDialog(
            title: 'تحذير ⚠️',
            middleText: 'تعطيل هذا الخيار سيطفئ الشبكة. هل أنت متأكد؟',
            textConfirm: 'أطفئ الشبكة',
            buttonColor: Colors.redAccent,
            onConfirm: () { controller.isWifiEnabled.value = false; Get.back(); },
            textCancel: 'تراجع',
          );
        } else {
          controller.isWifiEnabled.value = true;
        }
      },
    ));
  }

  Widget _buildSaveButton() {
    return Obx(() => Align(
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
    ));
  }
}