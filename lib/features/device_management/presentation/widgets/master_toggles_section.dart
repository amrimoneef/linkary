import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../controllers/device_management_controller.dart';

class MasterTogglesSection extends StatelessWidget {
  const MasterTogglesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DeviceManagementController>();
    final connectedCtrl = Get.find<ConnectedDevicesController>();
    
    return Obx(() {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildProfessionalToggle(
            context: context,
            title: 'التحكم الأبوي',
            subtitle: 'أوقات مسموحة للاتصال',
            icon: Iconsax.clock,
            color: Colors.amber,
            value: controller.parentalCtrl.isEnabled.value,
            onChanged: (val) => controller.toggleParentalControl(val),
          ),
          _buildProfessionalToggle(
            context: context,
            title: 'تحديد السرعة',
            subtitle: 'تقييد التحميل والرفع',
            icon: Iconsax.speedometer,
            color: Colors.teal,
            value: controller.speedCtrl.isEnabled.value,
            onChanged: (val) => controller.toggleSpeedLimit(val),
          ),
          _buildProfessionalToggle(
            context: context,
            title: 'باقة الأجهزة',
            subtitle: 'تخصيص حصة بيانات',
            icon: Iconsax.box,
            color: Colors.purple,
            value: controller.dataLimitCtrl.isEnabled.value,
            onChanged: (val) => controller.toggleDataLimit(val),
          ),
          _buildProfessionalToggle(
            context: context,
            title: 'مراقبة الشبكة',
            subtitle: 'إشعار بالأجهزة الجديدة',
            icon: Iconsax.shield_tick,
            color: Colors.blueAccent,
            value: connectedCtrl.isBgMonitorEnabled.value,
            onChanged: (val) => connectedCtrl.toggleBgMonitor(val),
          ),
        ],
      );
    });
  }

  Widget _buildProfessionalToggle({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : (isDark ? const Color(0xFF16213E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: value ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
            width: value ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: value ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
              blurRadius: value ? 15 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: value ? color : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: value ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]), size: 24),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
