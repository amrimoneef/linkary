import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../models/managed_device.dart';
import '../controllers/device_management_controller.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';

import '../../../parental_control/presentation/widgets/parental_rule_editor_sheet.dart';
import '../../../speed_limit/presentation/widgets/speed_rule_editor_sheet.dart';
import '../../../device_data_limit/presentation/widgets/data_rule_editor_sheet.dart';

import '../../../parental_control/presentation/controllers/parental_control_controller.dart';
import '../../../speed_limit/presentation/controllers/speed_limit_controller.dart';
import '../../../device_data_limit/presentation/controllers/device_data_limit_controller.dart';

import '../../../parental_control/domain/entities/parental_control_entity.dart';
import '../../../speed_limit/domain/entities/speed_limit_entity.dart';
import '../../../device_data_limit/domain/entities/device_data_limit.dart';

class DeviceDetailSheet extends StatefulWidget {
  final ManagedDevice device;

  const DeviceDetailSheet({super.key, required this.device});

  @override
  State<DeviceDetailSheet> createState() => _DeviceDetailSheetState();
}

class _DeviceDetailSheetState extends State<DeviceDetailSheet> {
  final ParentalControlController parCtrl = Get.find<ParentalControlController>();
  final SpeedLimitController spdCtrl = Get.find<SpeedLimitController>();
  final DeviceDataLimitController dataCtrl = Get.find<DeviceDataLimitController>();

  bool isSaving = false;
  
  ParentalDevice? draftParentalRule;
  SpeedLimitItem? draftSpeedRule;
  DeviceDataLimit? draftDataRule;

  bool deleteParentalRule = false;
  bool deleteSpeedRule = false;
  bool deleteDataRule = false;

  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Load initial state from controllers
    draftParentalRule = parCtrl.devicesList.firstWhereOrNull((d) => d.mac == widget.device.mac);
    draftSpeedRule = spdCtrl.deviceItems.firstWhereOrNull((d) => d.ip == widget.device.ip);
    draftDataRule = dataCtrl.deviceLimits.firstWhereOrNull((d) => d.mac == widget.device.mac);
  }

  void _checkChanges() {
    setState(() {
      hasChanges = true;
    });
  }

  Future<void> _saveAllChanges() async {
    setState(() {
      isSaving = true;
    });

    List<String> successMessages = [];
    List<String> errorMessages = [];

    // Parental Control
    try {
      if (deleteParentalRule) {
        final success = await parCtrl.deleteRuleUseCase.execute(widget.device.mac);
        if (success) successMessages.add('تم حذف قيود أوقات السماح');
      } else if (draftParentalRule != null && draftParentalRule!.timeSlots.isNotEmpty) {
        final slot = draftParentalRule!.timeSlots.first;
        final success = await parCtrl.saveRuleUseCase.execute(
          widget.device.mac, slot.startTime, slot.endTime, slot.repeatMode, 0
        );
        if (success) successMessages.add('تم تقييد أوقات الجهاز');
      }
    } catch (e) {
      errorMessages.add('فشل الأوقات: $e');
    }

    // Speed Limit
    try {
      if (deleteSpeedRule) {
        if (draftSpeedRule != null) {
          spdCtrl.removeDeviceRule(draftSpeedRule!.index);
          await spdCtrl.saveUseCase.execute(spdCtrl.isEnabled.value, spdCtrl.selectedMode.value, int.tryParse(spdCtrl.uploadController.text) ?? 248, int.tryParse(spdCtrl.downloadController.text) ?? 248, spdCtrl.deviceItems);
        }
        successMessages.add('تم إزالة قيود السرعة');
      } else if (draftSpeedRule != null) {
        final existing = spdCtrl.deviceItems.firstWhereOrNull((d) => d.ip == widget.device.ip);
        if (existing != null) {
          spdCtrl.updateDeviceRule(existing.index, draftSpeedRule!.upSpeed, draftSpeedRule!.dlSpeed);
        } else {
          spdCtrl.addDeviceRule(widget.device.ip ?? '', draftSpeedRule!.upSpeed, draftSpeedRule!.dlSpeed, widget.device.name);
        }
        await spdCtrl.saveUseCase.execute(spdCtrl.isEnabled.value, spdCtrl.selectedMode.value, int.tryParse(spdCtrl.uploadController.text) ?? 248, int.tryParse(spdCtrl.downloadController.text) ?? 248, spdCtrl.deviceItems);
        successMessages.add('تم تحديد السرعة');
      }
    } catch (e) {
      errorMessages.add('فشل السرعة: $e');
    }

    // Data Limit
    try {
      if (deleteDataRule) {
        final success = await dataCtrl.deleteLimitItem(widget.device.mac, showSnackbar: false);
        if (success) successMessages.add('تم إزالة قيد البيانات');
        else errorMessages.add('فشل إزالة الباقة');
      } else if (draftDataRule != null) {
        final existing = dataCtrl.deviceLimits.firstWhereOrNull((d) => d.mac == widget.device.mac);
        bool success = false;
        if (existing != null) {
          success = await dataCtrl.updateLimitItem(int.tryParse(existing.index) ?? 0, widget.device.mac, draftDataRule!.quotaBytes, widget.device.name, showSnackbar: false);
        } else {
          success = await dataCtrl.addLimitItem(widget.device.mac, draftDataRule!.quotaBytes, widget.device.name, showSnackbar: false);
        }
        if (success) successMessages.add('تم تحديد الباقة');
        else errorMessages.add('فشل تحديد الباقة');
      }
    } catch (e) {
      errorMessages.add('فشل الباقة: $e');
    }

    setState(() {
      isSaving = false;
    });

    // Close sheet FIRST before showing snackbars to avoid Get.back() closing the snackbar instead of the sheet
    Get.back(); 

    if (errorMessages.isNotEmpty) {
      CustomSnackbar.showError('حدث خطأ جزئي', errorMessages.join('\n'));
    } else if (successMessages.isNotEmpty) {
      CustomSnackbar.showSuccess('اكتمل بنجاح', successMessages.join('\n'));
    }
    
    // Refresh UI data
    Get.find<DeviceManagementController>().fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7);
    final glowColor = const Color(0xFF8BEDD7);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF4E4E4E);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: Get.height * 0.9,
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: glowColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)
                      ],
                    ),
                    child: Icon(
                      widget.device.type == 'WIFI' ? Iconsax.wifi : Iconsax.monitor,
                      color: glowColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.device.name.isEmpty ? 'جهاز مجهول' : widget.device.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Iconsax.cpu, size: 14, color: subTextColor),
                            const SizedBox(width: 4),
                            Text(widget.device.mac, style: TextStyle(color: subTextColor, fontSize: 13, fontFamily: 'monospace')),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Iconsax.global, size: 14, color: subTextColor),
                            const SizedBox(width: 4),
                            Text(widget.device.ip ?? 'لا يوجد IP', style: TextStyle(color: subTextColor, fontSize: 13, fontFamily: 'monospace')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Management Cards
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildFeatureCard(
                    title: 'تقييد وقت السماح',
                    subtitle: (draftParentalRule != null && !deleteParentalRule) ? 'مُفعل - اضغط للتعديل' : 'تحديد أوقات مسموحة للاتصال',
                    icon: Iconsax.clock,
                    color: (draftParentalRule != null && !deleteParentalRule) ? Colors.purpleAccent : subTextColor,
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    onTap: () {
                      ParentalRuleEditorSheet.show(
                        context, 
                        deviceToEdit: draftParentalRule, 
                        preSelectedMac: widget.device.mac,
                        onSaveDraft: (start, end, days) {
                          int sTime = (start.hour * 60) + start.minute;
                          int eTime = (end.hour * 60) + end.minute;
                          int mask = 0;
                          for (int day in days) mask += (1 << day);
                          if(mask == 0) mask = 127;
                          
                          draftParentalRule = ParentalDevice(mac: widget.device.mac, name: widget.device.name, timeSlots: [
                            TimeSlot(index: 0, startTime: sTime, endTime: eTime, repeatMode: mask)
                          ]);
                          deleteParentalRule = false;
                          _checkChanges();
                          Get.back();
                        },
                        onDeleteDraft: draftParentalRule != null ? () {
                          deleteParentalRule = true;
                          _checkChanges();
                          Get.back();
                        } : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    title: 'تحديد السرعة',
                    subtitle: (draftSpeedRule != null && !deleteSpeedRule) ? 'مُفعل - ↓${draftSpeedRule!.dlSpeed} ↑${draftSpeedRule!.upSpeed}' : 'تقييد سرعة التنزيل والرفع للجهاز',
                    icon: Iconsax.speedometer,
                    color: (draftSpeedRule != null && !deleteSpeedRule) ? Colors.orangeAccent : subTextColor,
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    onTap: () {
                      SpeedRuleEditorSheet.show(
                        context, 
                        item: draftSpeedRule, 
                        preSelectedIp: widget.device.ip, 
                        preSelectedName: widget.device.name,
                        onSaveDraft: (up, down) {
                          draftSpeedRule = SpeedLimitItem(index: 0, ip: widget.device.ip ?? '', upSpeed: up, dlSpeed: down, comment: widget.device.name);
                          deleteSpeedRule = false;
                          _checkChanges();
                          Get.back();
                        },
                        onDeleteDraft: draftSpeedRule != null ? () {
                          deleteSpeedRule = true;
                          _checkChanges();
                          Get.back();
                        } : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    title: 'تحديد الباقة',
                    subtitle: !dataCtrl.isFeatureSupported.value 
                        ? 'قريباً في التحديث القادم للمودم'
                        : (draftDataRule != null && !deleteDataRule) 
                            ? 'مُفعل - ${_formatBytes(draftDataRule!.quotaBytes)}' 
                            : 'تحديد كمية البيانات المسموح باستهلاكها',
                    icon: Iconsax.data,
                    color: !dataCtrl.isFeatureSupported.value 
                        ? const Color(0xFF8B5CF6) 
                        : (draftDataRule != null && !deleteDataRule) ? Colors.greenAccent : subTextColor,
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: !dataCtrl.isFeatureSupported.value ? const Color(0xFF8B5CF6) : subTextColor,
                    onTap: !dataCtrl.isFeatureSupported.value 
                        ? () { 
                            CustomSnackbar.showInfo(
                              'ميزة جديدة في طريقها لمودمك!', 
                              'يجري حالياً إطلاق التحديث الجديد للمودم تدريجياً من الشركة المصنعة لتفعيل التحكم في باقات واستهلاك الأجهزة. ستعمل الميزة تلقائياً فور وصول التحديث لجهازك.'
                            ); 
                          }
                        : () {
                      DataRuleEditorSheet.show(
                        context, 
                        limit: draftDataRule, 
                        preSelectedMac: widget.device.mac, 
                        preSelectedName: widget.device.name,
                        onSaveDraft: (bytes) {
                          draftDataRule = DeviceDataLimit(
                            index: '0',
                            hostname: widget.device.name,
                            mac: widget.device.mac, 
                            quotaBytes: bytes, 
                            status: '1', 
                            currentUsageBytes: 0,
                            comment: widget.device.name,
                            recordData: ''
                          );
                          deleteDataRule = false;
                          _checkChanges();
                          Get.back();
                        },
                        onDeleteDraft: draftDataRule != null ? () {
                          deleteDataRule = true;
                          _checkChanges();
                          Get.back();
                        } : null,
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Bottom Save Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1.5)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (!hasChanges || isSaving) ? null : _saveAllChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (!hasChanges || isSaving) ? Colors.grey.withOpacity(0.5) : glowColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSaving 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2))
                    : const Text('حفظ التغييرات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        surfaceColor: cardColor,
        borderColor: color.withValues(alpha: 0.3),
        opacity: 0.2,
        blur: 12,
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_left_2, color: subTextColor, size: 20),
          ],
        ),
      ),
    );
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
