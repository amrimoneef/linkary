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

      final glowColor = isDark ? const Color(0xFF4A90E2) : const Color(0xFF92C0F6);

      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [glowColor.withValues(alpha: 0.8), glowColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي الأجهزة النشطة',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${devices.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'أجهزة',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2), 
                    shape: BoxShape.circle
                  ),
                  child: const Icon(
                    Icons.devices,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context: context,
                    icon: Iconsax.clock,
                    count: parentalCount,
                    label: 'وقت',
                    color: Colors.white,
                  ),
                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                  _buildStatItem(
                    context: context,
                    icon: Icons.speed,
                    count: speedCount,
                    label: 'سرعة',
                    color: Colors.white,
                  ),
                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                  _buildStatItem(
                    context: context,
                    icon: Iconsax.box,
                    count: dataLimitCount,
                    label: 'باقة',
                    color: Colors.white,
                  ),
                ],
              ),
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
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
