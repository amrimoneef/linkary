import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/managed_device.dart';
import '../controllers/device_management_controller.dart';

class SpeedLimitSection extends StatelessWidget {
  final ManagedDevice device;
  final DeviceManagementController controller;

  const SpeedLimitSection({
    Key? key,
    required this.device,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // speed_limit uses IP, but currently our managed device links it via IP
    final bool canLimit = device.ip != null && device.ip!.isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Iconsax.speedometer, color: Colors.teal, size: 20),
            const SizedBox(width: 8),
            Text(
              'تحديد السرعة',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Text(
          device.hasSpeedRule ? 'السرعة مُقيدة' : (canLimit ? 'لا يوجد قيد' : 'غير مدعوم (لا يوجد IP)'),
          style: TextStyle(
            color: device.hasSpeedRule ? Colors.teal : Colors.grey,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!canLimit)
                  const Text('لا يمكن تحديد سرعة هذا الجهاز لأنه غير متصل حالياً أو لم يتم التعرف على عنوان الـ IP الخاص به.')
                else if (device.hasSpeedRule) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Iconsax.arrow_down, color: Colors.teal, size: 16),
                            const Text('التنزيل', style: TextStyle(fontSize: 12)),
                            Text('${device.speedRule!.dlSpeed} KB/s', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Iconsax.arrow_up, color: Colors.teal, size: 16),
                            const Text('الرفع', style: TextStyle(fontSize: 12)),
                            Text('${device.speedRule!.upSpeed} KB/s', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.trash, color: Colors.red),
                          onPressed: () {
                            controller.speedCtrl.removeDeviceRule(device.speedRule!.index);
                            controller.speedCtrl.saveData().then((_) {
                              controller.fetchAllData();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'قم بتحديد سرعة التنزيل والرفع لهذا الجهاز للتحكم باستهلاكه من النطاق الترددي.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
                const SizedBox(height: 12),
                if (canLimit)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSpeedDialog(context),
                      icon: Icon(device.hasSpeedRule ? Iconsax.edit : Iconsax.add, color: Colors.teal),
                      label: Text(
                        device.hasSpeedRule ? 'تعديل السرعة' : 'تحديد سرعة',
                        style: const TextStyle(color: Colors.teal),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal),
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

  void _showSpeedDialog(BuildContext context) {
    final upCtrl = TextEditingController(text: device.speedRule?.upSpeed.toString() ?? '512');
    final dlCtrl = TextEditingController(text: device.speedRule?.dlSpeed.toString() ?? '512');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تحديد السرعة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dlCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سرعة التنزيل (KB/s)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: upCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سرعة الرفع (KB/s)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final up = int.tryParse(upCtrl.text) ?? 0;
                final dl = int.tryParse(dlCtrl.text) ?? 0;
                if (device.hasSpeedRule) {
                  controller.speedCtrl.updateDeviceRule(device.speedRule!.index, up, dl);
                } else {
                  controller.speedCtrl.addDeviceRule(device.ip!, up, dl, device.name);
                }
                // Force mode 2 for per-device
                controller.speedCtrl.selectedMode.value = 2;
                controller.speedCtrl.isEnabled.value = true;
                controller.speedCtrl.saveData().then((_) {
                  controller.fetchAllData();
                  Navigator.pop(context);
                });
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      }
    );
  }
}
