import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:linkary/core/utils/validators.dart';

import '../controllers/auth_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGradient = isDark 
        ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
        : [const Color(0xFF4A90E2), const Color(0xFF50E3C2)];

    return Scaffold(
      body: Stack(
        children: [
          // 🌌 خلفية التدرج المتحرك (عن طريق التدرج اللوني الأساسي للهوية)
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

          // إضافة دوائر ضوئية ناعمة في الخلفية لتعزيز الشعور بالعمق
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
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 45),
                  
                  // 1. الشعار والنصوص (Entrance Animation)
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
                        Image.asset(
                          'assets/images/الشعار ابيض.png',
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                        Text(
                          'تحكم بمودمك الذكي',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 2. بطاقة تسجيل الدخول (Glassmorphism Effect)
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
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.85),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Form(
                            key: authController.formKey,
                            child: Column(
                              children: [
                                Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF1E3C72),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'أدخل كلمة مرور المسؤول للمتابعة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // حقل اسم المستخدم (مغلق)
                                _buildTextField(
                                  hint: 'admin',
                                  icon: Iconsax.user,
                                  isEnabled: false,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 20),

                                // حقل كلمة المرور
                                  _buildTextField(
                                    controller: authController.passwordController,
                                    hint: 'كلمة المرور',
                                    icon: Iconsax.lock,
                                    isPassword: true,
                                    isEnabled: authController.lockRemainingSeconds.value == 0,
                                    validator: Validators.validateAdminPassword,
                                    isDark: isDark,
                                  ),
                                const SizedBox(height: 30),

                                // زر تسجيل الدخول (Identity Gradient)
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
                                    onPressed: (authController.isLoading.value || authController.lockRemainingSeconds.value > 0) 
                                        ? null 
                                        : () {
                                            FocusScope.of(context).unfocus();
                                            authController.login(authController.passwordController.text);
                                          },
                                    child: authController.isLoading.value
                                        ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('دخول آمن', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                )),

                                const SizedBox(height: 25),

                                // خيار تسجيل الدخول بالبصمة
                                Obx(() {
                                  if (authController.isBiometricAvailable.value && authController.isBiometricEnabled.value) {
                                    return Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text('أو استخدم البصمة', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
                                            ),
                                            Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        GestureDetector(
                                          onTap: (authController.isLoading.value || authController.lockRemainingSeconds.value > 0) ? null : () => authController.loginWithBiometric(),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                              color: Colors.white.withValues(alpha: 0.05),
                                            ),
                                            child: Icon(
                                              Icons.fingerprint,
                                              color: isDark ? Colors.white : const Color(0xFF1E3C72),
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // نص تلميح (Footer Hint)
                  Center(
                    child: Obx(() {
                      final lockSeconds = authController.lockRemainingSeconds.value;
                      final retryTimes = authController.retryTimes.value;
                      
                      String message = 'سيتم قفل الحساب بعد 5 محاولات خاطئة متتالية';
                      Color color = Colors.white.withValues(alpha: 0.7);
                      
                      if (lockSeconds > 0) {
                        final minutes = (lockSeconds / 60).floor();
                        final seconds = lockSeconds % 60;
                        message = 'يرجى المحاولة بعد ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} دقيقة';
                        color = Colors.deepOrangeAccent;
                      } else if (retryTimes <= 4) {
                        message = 'تحذير: تبقت $retryTimes محاولات!';
                        color = Colors.redAccent;
                      }
                      
                      return Text(
                        message,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  // 🛠️ دالة مساعدة مطورة لحقول الإدخال
  Widget _buildTextField({
    TextEditingController? controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    required bool isEnabled,
    String? Function(String?)? validator,
    required bool isDark,
  }) {
    Widget field() => TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword ? !authController.isPasswordVisible.value : false,
      enabled: isEnabled,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  authController.isPasswordVisible.value ? Iconsax.eye : Iconsax.eye_slash,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: () => authController.isPasswordVisible.toggle(),
              )
            : null,
        filled: true,
        fillColor: isEnabled 
            ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5))
            : Colors.transparent,
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

    return isPassword ? Obx(() => field()) : field();
  }
}