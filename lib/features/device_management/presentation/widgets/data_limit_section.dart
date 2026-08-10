import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../device_data_limit/presentation/widgets/add_data_limit_dialog.dart';
import '../models/managed_device.dart';
import '../controllers/device_management_controller.dart';

class DataLimitSection extends StatelessWidget {
  final ManagedDevice device;
  final DeviceManagementController controller;

  const DataLimitSection({
    Key? key,
    required this.device,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Iconsax.box, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              'باقة الأجهزة',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Text(
          device.hasDataLimit ? 'الباقة محددة' : 'لا يوجد قيد',
          style: TextStyle(
            color: device.hasDataLimit ? Colors.purple : Colors.grey,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (device.hasDataLimit) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الحصة المحددة', style: TextStyle(fontSize: 12)),
                            Text(
                              _formatBytes(device.dataLimit!.quotaBytes),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.trash, color: Colors.red),
                          onPressed: () {
                            controller.dataLimitCtrl.deleteLimitItem(device.mac).then((_) {
                              controller.fetchAllData();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'قم بتحديد حصة معينة من البيانات لهذا الجهاز.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddDataLimitDialog(context),
                    icon: Icon(device.hasDataLimit ? Iconsax.edit : Iconsax.add, color: Colors.purple),
                    label: Text(
                      device.hasDataLimit ? 'تعديل الباقة' : 'تحديد باقة',
                      style: const TextStyle(color: Colors.purple),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.purple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDataLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddDataLimitDialog(
          controller: controller.dataLimitCtrl,
          initialMac: device.mac,
          initialComment: device.name,
          initialQuotaBytes: device.dataLimit?.quotaBytes,
        );
      },
    ).then((_) => controller.fetchAllData());
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    } else {
      return '$bytes B';
    }
  }
}
