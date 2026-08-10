import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/device_management_controller.dart';

class MasterTogglesSection extends StatelessWidget {
  const MasterTogglesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DeviceManagementController>();
    
    return Obx(() {
      return Column(
        children: [
          _buildToggleItem(
            context: context,
            title: 'التحكم الأبوي',
            subtitle: 'تحديد أوقات مسموحة للاتصال',
            icon: Iconsax.clock,
            color: Colors.amber,
            value: controller.parentalCtrl.isEnabled.value,
            onChanged: (val) => controller.toggleParentalControl(val),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            context: context,
            title: 'تحديد السرعة',
            subtitle: 'تقييد سرعة التحميل والرفع',
            icon: Iconsax.speedometer,
            color: Colors.teal,
            value: controller.speedCtrl.isEnabled.value,
            onChanged: (val) => controller.toggleSpeedLimit(val),
          ),
          const SizedBox(height: 12),
          _buildToggleItem(
            context: context,
            title: 'باقة الأجهزة',
            subtitle: 'تخصيص حصة بيانات محددة',
            icon: Iconsax.box,
            color: Colors.purple,
            value: controller.dataLimitCtrl.isEnabled.value,
            onChanged: (val) => controller.toggleDataLimit(val),
          ),
        ],
      );
    });
  }

  Widget _buildToggleItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
