import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:linkary/features/settings/presentation/controllers/admin_settings_controller.dart';

class LcdSettingsPage extends GetView<AdminSettingsController> {
  const LcdSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0A0E21) 
          : const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('إعدادات الشاشة',
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
              _buildSectionHeader(context, 'حماية الشاشة', Iconsax.lock),
              _buildCard(context, [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('كلمة مرور شاشة LCD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Obx(() => Switch(
                      value: controller.isLcdPwEnabled.value,
                      onChanged: (val) => controller.isLcdPwEnabled.value = val,
                      activeColor: const Color(0xFF4A90E2),
                    )),
                  ],
                ),
                Obx(() => controller.isLcdPwEnabled.value 
                  ? Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: _buildTextField(
                        controller: controller.lcdPwController,
                        label: 'أدخل كلمة مرور الشاشة (3 أرقام)',
                        icon: Iconsax.mobile,
                        isNumber: true,
                        maxLength: 3,
                      ),
                    )
                  : const SizedBox.shrink()),
              ]),
              
              const SizedBox(height: 25),

              _buildSectionHeader(context, 'توفير الطاقة', Iconsax.flash_1),
              _buildCard(context, [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('تفعيل وضع النوم', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Obx(() => Switch(
                      value: controller.isSleepTimeoutEnabled.value,
                      onChanged: (val) {
                        controller.isSleepTimeoutEnabled.value = val;
                        if (!val) {
                          controller.sleepTimeoutMin.value = 0; // تعطيل
                        } else if (controller.sleepTimeoutMin.value == 0) {
                          controller.sleepTimeoutMin.value = 10; // القيمة الافتراضية عند التفعيل
                        }
                      },
                      activeColor: const Color(0xFF4A90E2),
                    )),
                  ],
                ),
                Obx(() => controller.isSleepTimeoutEnabled.value 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),
                        const Text('وقت وضع النوم', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _buildTimeSelector(
                          options: [10, 20, 30, 40],
                          currentValue: controller.sleepTimeoutMin,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'سيتم إيقاف تشغيل البث تلقائياً بعد مرور الوقت المحدد لتوفير البطارية.',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink()),
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
      child: Column(children: children, crossAxisAlignment: CrossAxisAlignment.start),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isNumber = false,
    bool readOnly = false,
    int? maxLength,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: label,
        counterText: '', // إخفاء عداد الحروف (حسب رغبة المستخدم في التصميم النظيف)
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
