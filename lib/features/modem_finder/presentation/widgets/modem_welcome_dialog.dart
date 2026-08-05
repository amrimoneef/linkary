import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/services/calibration_service.dart';

class ModemWelcomeDialog extends StatefulWidget {
  const ModemWelcomeDialog({Key? key}) : super(key: key);

  static void show() {
    Get.dialog(
      const ModemWelcomeDialog(),
      barrierDismissible: false,
    );
  }

  @override
  State<ModemWelcomeDialog> createState() => _ModemWelcomeDialogState();
}

class _ModemWelcomeDialogState extends State<ModemWelcomeDialog> {
  bool _hideFuture = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.radar5, size: 48, color: primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'كيف يعمل البحث عن المودم؟ ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• تقيس هذه الميزة المسافة التقريبية بين هاتفك والمودم.\n\n• بسبب طبيعة الموجات وتأثرها بالجدران والأثاث، الدقة تصل إلى 95% وتعتبر كافية لإرشادك للمكان الصحيح.\n\n• اقترب من المودم حتى تصبح الدقة بالسنتيمتر! \n\n• اذا لم تكن دقة البحث جيدة، قم بعمل معايرة للمودم من زر الاعدادت الموجود أعلى يسار الشاشة',
                    style: TextStyle(fontSize: 14, height: 1.5),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _hideFuture,
                        activeColor: primaryColor,
                        onChanged: (val) {
                          setState(() {
                            _hideFuture = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'لا تظهر هذه الرسالة مستقبلاً',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_hideFuture) {
                          Get.find<CalibrationService>().saveHideWelcomeMessage(true);
                        }
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'حسناً، فهمت',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
