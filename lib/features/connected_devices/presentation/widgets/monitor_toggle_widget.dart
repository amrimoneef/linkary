import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/connected_devices_controller.dart';

class MonitorToggleWidget extends StatelessWidget {
  const MonitorToggleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConnectedDevicesController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF6B7280);

    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: controller.isBgMonitorEnabled.value
                ? Colors.tealAccent.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: SwitchListTile(
          title: Text(
            'مراقبة الأجهزة الجديدة',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            controller.isBgMonitorEnabled.value
                ? 'تحت المراقبة...'
                : 'تنبيهك عند اتصال جهاز غير معروف بالشبكة.',
            style: TextStyle(color: subTextColor, fontSize: 11),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: controller.isBgMonitorEnabled.value
                  ? Colors.tealAccent.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.shield_tick,
              color: controller.isBgMonitorEnabled.value
                  ? Colors.tealAccent
                  : Colors.grey,
              size: 22,
            ),
          ),
          value: controller.isBgMonitorEnabled.value,
          activeColor: Colors.tealAccent,
          onChanged: (value) => controller.toggleBgMonitor(value),
        ),
      );
    });
  }
}
