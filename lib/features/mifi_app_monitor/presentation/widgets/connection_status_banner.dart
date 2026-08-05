import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../controllers/app_monitor_controller.dart';

class ConnectionStatusBanner extends StatelessWidget {
  final AppMonitorController controller;

  const ConnectionStatusBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF111827);

    return Obx(() {
      if (controller.isConnectedToTargetMiFi.value) {
        return const SizedBox.shrink();
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.wifi2, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'العداد متوقف',
                    style: TextStyle(
                      color: text, 
                      fontSize: 14, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'يرجى الاتصال بمودم SAM 4G لتفعيل مراقبة الجلسة الحالية.',
                    style: TextStyle(
                      color: text.withValues(alpha: 0.7), 
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
