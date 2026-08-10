import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../models/managed_device.dart';
import '../controllers/device_management_controller.dart';
import 'parental_control_section.dart';
import 'speed_limit_section.dart';
import 'data_limit_section.dart';
import '../../../../core/theme/app_colors.dart';

class DeviceDetailSheet extends StatelessWidget {
  final ManagedDevice device;

  const DeviceDetailSheet({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<DeviceManagementController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  device.type == 'WIFI' ? Iconsax.wifi : Iconsax.monitor,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'MAC: ${device.mac}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Rules List
          Expanded(
            child: ListView(
              children: [
                ParentalControlSection(device: device, controller: controller),
                const Divider(),
                SpeedLimitSection(device: device, controller: controller),
                const Divider(),
                DataLimitSection(device: device, controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
