import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../models/managed_device.dart';
import '../controllers/device_management_controller.dart';

class ParentalControlSection extends StatelessWidget {
  final ManagedDevice device;
  final DeviceManagementController controller;

  const ParentalControlSection({
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
            Icon(Iconsax.clock, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'التحكم الأبوي',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Text(
          device.hasParentalRule ? 'الجهاز مُقيد' : 'لا يوجد قيد',
          style: TextStyle(
            color: device.hasParentalRule ? Colors.amber : Colors.grey,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (device.hasParentalRule) ...[
                  for (var slot in device.timeSlots!)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.formattedTimeRange,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                slot.activeDays,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.trash, color: Colors.red),
                            onPressed: () {
                              controller.parentalCtrl.deleteDevice(device.mac).then((_) {
                                controller.fetchAllData();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ] else ...[
                  Text(
                    'يتيح لك التحكم الأبوي تحديد الأوقات المسموحة لهذا الجهاز للوصول إلى الإنترنت.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddParentalDialog(context),
                    icon: Icon(device.hasParentalRule ? Iconsax.edit : Iconsax.add, color: Colors.amber),
                    label: Text(
                      device.hasParentalRule ? 'تعديل القاعدة' : 'إضافة قاعدة',
                      style: const TextStyle(color: Colors.amber),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
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

  void _showAddParentalDialog(BuildContext context) {
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 22, minute: 0);
    List<int> selectedDays = [0, 1, 2, 3, 4, 5, 6];

    // If you want to use the existing Add Rule Bottom Sheet from ParentalControl, you can call it here.
    // For simplicity, we can show a basic time picker dialog or redirect to the existing UI.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إعداد التحكم الأبوي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('يتم هنا تعيين وقت البدء والانتهاء (أوقات السماح).'),
              const SizedBox(height: 16),
              // Simplified for illustration. In a real app, use the actual TimePicker.
              ElevatedButton(
                onPressed: () {
                  controller.parentalCtrl.saveRule(device.mac, startTime, endTime, selectedDays).then((_) {
                    controller.fetchAllData();
                    Navigator.pop(context);
                  });
                },
                child: const Text('تطبيق (8 ص - 10 م طوال الأسبوع)'),
              ),
            ],
          ),
        );
      }
    );
  }
}
