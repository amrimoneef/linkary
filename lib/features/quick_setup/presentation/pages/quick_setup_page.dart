import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:linkary/core/utils/validators.dart';
import '../controllers/quick_setup_controller.dart';

class QuickSetupPage extends StatelessWidget {
  QuickSetupPage({super.key});

  final QuickSetupController controller = Get.find<QuickSetupController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGradient = isDark 
        ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
        : [const Color(0xFF4A90E2), const Color(0xFF50E3C2)];

    return Scaffold(
      body: Stack(
        children: [
          // خلفية مساعدة
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: primaryGradient,
              ),
            ),
          ),
          
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // الهيدر
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الإعداد السريع',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'اضبط إعدادات المودم لأول مرة لتأمينه',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // البطاقة الزجاجية
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.85),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Obx(() => controller.isLoading.value
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              )
                            : Form(
                                key: controller.formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'إعدادات الشبكة',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF1E3C72),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 15),

                                    _buildTextField(
                                      controller: controller.ssidController,
                                      hint: 'اسم شبكة الواي فاي (SSID)',
                                      icon: Iconsax.wifi,
                                      validator: Validators.validateWifiSsid,
                                      isDark: isDark,
                                      textDirection: TextDirection.ltr,
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 15),

                                    Obx(() => _buildTextField(
                                      controller: controller.wifiPasswordController,
                                      hint: 'كلمة مرور الواي فاي',
                                      icon: Iconsax.lock,
                                      isPassword: !controller.isWifiPasswordVisible.value,
                                      validator: (val) => Validators.validateWifiPassword(val),
                                      isDark: isDark,
                                      textDirection: TextDirection.ltr,
                                      onSuffixTap: controller.toggleWifiPasswordVisibility,
                                      suffixIcon: controller.isWifiPasswordVisible.value ? Iconsax.eye : Iconsax.eye_slash,
                                    )),
                                    
                                    const SizedBox(height: 25),
                                    Divider(color: Colors.white.withValues(alpha: 0.2)),
                                    const SizedBox(height: 15),
                                    
                                    Text(
                                      'إعدادات تأمين المودم',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF1E3C72),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 15),

                                    // خيار المطابقة بين الرمزين
                                    Obx(() => Theme(
                                      data: Theme.of(context).copyWith(
                                        unselectedWidgetColor: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                      child: CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          'استخدام كلمة مرور الواي فاي للدخول الى تطلبق الأعدادات',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                        value: controller.useWifiPasswordForAdmin.value,
                                        activeColor: isDark ? const Color(0xFF50E3C2) : const Color(0xFF4A90E2),
                                        onChanged: (val) {
                                          controller.useWifiPasswordForAdmin.value = val ?? false;
                                          if (controller.useWifiPasswordForAdmin.value) {
                                            controller.adminPasswordController.text = controller.wifiPasswordController.text;
                                          }
                                        },
                                        controlAffinity: ListTileControlAffinity.leading,
                                      ),
                                    )),

                                    // إظهار حقل كلمة مرور المودم دائماً
                                    Obx(() {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 15.0),
                                        child: _buildTextField(
                                          controller: controller.adminPasswordController,
                                          hint: 'كلمة مرور المودم الدخول الى تطبيق الأعدادات',
                                          icon: Iconsax.shield_tick,
                                          isPassword: !controller.isAdminPasswordVisible.value,
                                          validator: Validators.validateAdminPassword,
                                          isDark: isDark,
                                          textDirection: TextDirection.ltr,
                                          onSuffixTap: controller.toggleAdminPasswordVisibility,
                                          suffixIcon: controller.isAdminPasswordVisible.value ? Iconsax.eye : Iconsax.eye_slash,
                                          readOnly: controller.useWifiPasswordForAdmin.value,
                                        ),
                                      );
                                    }),

                                    const SizedBox(height: 35),

                                    // زر الحفظ
                                    Obx(() => Container(
                                      width: double.infinity,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDark 
                                              ? [const Color(0xFF4A90E2), const Color(0xFF50E3C2)]
                                              : [const Color(0xFF1E3C72), const Color(0xFF2A5298)],
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          )
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        ),
                                        onPressed: controller.isSaving.value 
                                            ? null 
                                            : () {
                                                FocusScope.of(context).unfocus();
                                                controller.saveSettings();
                                              },
                                        child: controller.isSaving.value
                                            ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Text('حفظ الإعدادات والمتابعة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🛠️ دالة مساعدة لحقول الإدخال
  Widget _buildTextField({
    TextEditingController? controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    required bool isDark,
    TextDirection? textDirection,
    VoidCallback? onSuffixTap,
    IconData? suffixIcon,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword,
      readOnly: readOnly,
      textDirection: textDirection,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 11),
        prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.grey.shade500, size: 20),
        suffixIcon: suffixIcon != null 
            ? IconButton(
                icon: Icon(suffixIcon, color: isDark ? Colors.white38 : Colors.grey.shade500, size: 20),
                onPressed: onSuffixTap,
              )
            : null,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: isDark ? const Color(0xFF50E3C2) : const Color(0xFF4A90E2), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}
