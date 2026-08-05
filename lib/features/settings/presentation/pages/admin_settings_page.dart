import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:linkary/features/settings/presentation/controllers/admin_settings_controller.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';

class AdminSettingsPage extends GetView<AdminSettingsController> {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0E21) : const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('إعدادات المسؤول',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/images/الشعار ابيض.png'
                  : 'assets/images/الشعار اسود.png',
              height: 25,
              fit: BoxFit.contain,
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
      ),
      body: Obx(() {
        if (controller.isAdminInfoLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, 'حساب المسؤول', Iconsax.user_edit),
              _buildCard(context, [
                _buildTextField(
                  controller: controller.usernameController,
                  label: 'اسم المستخدم',
                  icon: Iconsax.user,
                  readOnly: true, // غير قابل للتعديل
                ),
                const SizedBox(height: 15),
                Obx(() => _buildTextField(
                  controller: controller.passwordController,
                  label: 'كلمة مرور Admin',
                  icon: Iconsax.key,
                  isPassword: !controller.isPasswordVisible.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value ? Iconsax.eye : Iconsax.eye_slash,
                      color: const Color(0xFF4A90E2),
                    ),
                    onPressed: () => controller.isPasswordVisible.toggle(),
                  ),
                )),
                const SizedBox(height: 7),
                Text('ضبط كلمة مرور الدخول للتطبيق والاعدادات', style: TextStyle(color: Colors.grey, fontSize: 10)),

                const SizedBox(height: 20),
                const Text('وقت انتهاء الجلسة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTimeSelector(
                  options: [1, 5, 10, 15],
                  currentValue: controller.sessionTimeoutMin,
                ),
              ]),

              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.updateSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ التغييرات', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              
              // قسم الخيارات المتقدمة (إعادة ضبط المصنع)
              _buildSectionHeader(context, 'خيارات متقدمة', Iconsax.danger),
              _buildCard(context, [
                const Row(
                  children: [
                    Icon(Iconsax.warning_2, color: Colors.red, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تنبيه: إعادة ضبط المصنع ستمحو جميع الإعدادات الحالية، بما في ذلك كلمات المرور واسم الشبكة.',
                        style: TextStyle(color: Colors.red, fontSize: 12, ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Get.find<AuthController>().factoryReset(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('إعادة ضبط المصنع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4A90E2)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isNumber = false,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        filled: true,
        fillColor: Get.theme.brightness == Brightness.dark 
            ? Colors.black.withValues(alpha: 0.2) 
            : Colors.grey.withValues(alpha: 0.1),
        enabled: !readOnly,
      ),
    );
  }

  Widget _buildTimeSelector({
    required List<int> options,
    required RxInt currentValue,
  }) {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((time) {
        final isSelected = currentValue.value == time;
        return GestureDetector(
          onTap: () => currentValue.value = time,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? const Color(0xFF4A90E2) : Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$time د',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    ));
  }
}
