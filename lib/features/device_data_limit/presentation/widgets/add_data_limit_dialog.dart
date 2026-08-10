import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/device_data_limit_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../../../connected_devices/domain/entities/connected_device_entity.dart';

class AddDataLimitDialog extends StatefulWidget {
  final DeviceDataLimitController controller;
  final String? initialMac;
  final String? initialComment;
  final int? initialQuotaBytes;

  const AddDataLimitDialog({
    Key? key,
    required this.controller,
    this.initialMac,
    this.initialComment,
    this.initialQuotaBytes,
  }) : super(key: key);

  @override
  _AddDataLimitDialogState createState() => _AddDataLimitDialogState();
}

class _AddDataLimitDialogState extends State<AddDataLimitDialog> {
  final _macController = TextEditingController();
  final _commentController = TextEditingController();
  final _quotaController = TextEditingController();
  
  String _selectedUnit = 'MB';
  final List<String> _units = ['KB', 'MB', 'GB'];
  
  List<ConnectedDeviceEntity> _connectedDevices = [];
  String? _selectedMac;
  bool _isManualMac = false;

  @override
  void initState() {
    super.initState();
    
    if (Get.isRegistered<ConnectedDevicesController>()) {
      _connectedDevices = Get.find<ConnectedDevicesController>().devices;
    }

    if (widget.initialMac != null) {
      _macController.text = widget.initialMac!;
      _selectedMac = widget.initialMac;
      _isManualMac = true; // In edit mode, default to showing the text field
    } else {
      if (_connectedDevices.isEmpty) {
        _isManualMac = true;
      }
    }

    if (widget.initialComment != null) {
      _commentController.text = widget.initialComment!;
    }

    if (widget.initialQuotaBytes != null && widget.initialQuotaBytes! > 0) {
      int bytes = widget.initialQuotaBytes!;
      double val;
      if (bytes >= 1024 * 1024 * 1024 && bytes % (1024 * 1024 * 1024) == 0) {
        _selectedUnit = 'GB';
        val = bytes / (1024 * 1024 * 1024);
      } else if (bytes >= 1024 * 1024) {
        _selectedUnit = 'MB';
        val = bytes / (1024 * 1024);
      } else {
        _selectedUnit = 'KB';
        val = bytes / 1024;
      }
      _quotaController.text = val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _macController.dispose();
    _commentController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  void _submit() {
    final mac = _isManualMac ? _macController.text.trim() : _selectedMac?.trim();
    final comment = _commentController.text.trim();
    final quotaStr = _quotaController.text.trim();

    if (mac == null || mac.isEmpty || quotaStr.isEmpty) {
      Get.snackbar('تنبيه', 'الرجاء إدخال الماك أدريس والباقة',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final quotaVal = double.tryParse(quotaStr);
    if (quotaVal == null || quotaVal <= 0) {
      Get.snackbar('تنبيه', 'الرجاء إدخال قيمة باقة صحيحة',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    int quotaBytes = 0;
    if (_selectedUnit == 'KB') {
      quotaBytes = (quotaVal * 1024).toInt();
    } else if (_selectedUnit == 'MB') {
      quotaBytes = (quotaVal * 1024 * 1024).toInt();
    } else if (_selectedUnit == 'GB') {
      quotaBytes = (quotaVal * 1024 * 1024 * 1024).toInt();
    }

    widget.controller.addLimitItem(mac, quotaBytes, comment);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.initialMac != null;
    
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      title: Text(isEdit ? 'تعديل قيد جهاز' : 'إضافة قيد جهاز', 
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEdit)
              TextField(
                controller: _macController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'الماك أدريس (MAC Address)',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.black12,
                ),
              )
            else if (_isManualMac)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _macController,
                    decoration: InputDecoration(
                      labelText: 'الماك أدريس (MAC Address)',
                      hintText: 'مثال: 00:11:22:33:44:55',
                    ),
                  ),
                  if (_connectedDevices.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isManualMac = false;
                        });
                      },
                      child: Text('اختيار من الأجهزة المتصلة', style: TextStyle(color: AppColors.primaryPurple)),
                    ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedMac,
                    decoration: InputDecoration(
                      labelText: 'اختر الجهاز',
                    ),
                    items: _connectedDevices.map((device) {
                      String name = device.name.isNotEmpty ? device.name : 'جهاز غير معروف';
                      return DropdownMenuItem<String>(
                        value: device.mac,
                        child: Text('$name (${device.mac})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMac = val;
                        // Auto-fill comment with device name
                        if (val != null && _commentController.text.isEmpty) {
                          final dev = _connectedDevices.firstWhereOrNull((d) => d.mac == val);
                          if (dev != null && dev.name.isNotEmpty) {
                            _commentController.text = dev.name;
                          }
                        }
                      });
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isManualMac = true;
                      });
                    },
                    child: Text('إدخال الماك يدوياً', style: TextStyle(color: AppColors.primaryPurple)),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'الاسم أو التعليق',
                hintText: 'مثال: هاتف أحمد',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quotaController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'الباقة المحددة',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    items: _units.map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedUnit = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
          ),
          child: const Text('حفظ', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
