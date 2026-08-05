import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/device_data_limit_controller.dart';
import '../../../../core/theme/app_colors.dart';

class AddDataLimitDialog extends StatefulWidget {
  final DeviceDataLimitController controller;
  final String? initialMac;

  const AddDataLimitDialog({Key? key, required this.controller, this.initialMac}) : super(key: key);

  @override
  _AddDataLimitDialogState createState() => _AddDataLimitDialogState();
}

class _AddDataLimitDialogState extends State<AddDataLimitDialog> {
  final _macController = TextEditingController();
  final _commentController = TextEditingController();
  final _quotaController = TextEditingController();
  
  String _selectedUnit = 'MB';
  final List<String> _units = ['KB', 'MB', 'GB'];

  @override
  void initState() {
    super.initState();
    if (widget.initialMac != null) {
      _macController.text = widget.initialMac!;
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
    final mac = _macController.text.trim();
    final comment = _commentController.text.trim();
    final quotaStr = _quotaController.text.trim();

    if (mac.isEmpty || quotaStr.isEmpty) {
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
    
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      title: Text('إضافة قيد جهاز', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _macController,
              decoration: InputDecoration(
                labelText: 'الماك أدريس (MAC Address)',
                hintText: 'مثال: 00:11:22:33:44:55',
              ),
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
