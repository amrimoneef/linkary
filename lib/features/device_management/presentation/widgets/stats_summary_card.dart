import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/device_management_controller.dart';

class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DeviceManagementController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Obx(() {
      final devices = controller.managedDevices;
      
      final parentalCount = devices.where((d) => d.hasParentalRule).length;
      final speedCount = devices.where((d) => d.hasSpeedRule).length;
      final dataLimitCount = devices.where((d) => d.hasDataLimit).length;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16213E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإحصائيات',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context: context,
                  icon: Iconsax.clock,
                  count: parentalCount,
                  label: 'وقت',
                  color: Colors.amber,
                ),
                _buildStatItem(
                  context: context,
                  icon: Iconsax.speedometer,
                  count: speedCount,
                  label: 'سرعة',
                  color: Colors.teal,
                ),
                _buildStatItem(
                  context: context,
                  icon: Iconsax.box,
                  count: dataLimitCount,
                  label: 'باقة',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
