import 'package:flutter/material.dart';
import '../controllers/app_monitor_controller.dart';

class PermissionGateWidget extends StatelessWidget {
  final AppMonitorController controller;

  const PermissionGateWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF111827);
    final subText = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white54 
        : const Color(0xFF6B7280);
    final glow = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF4A90E2) 
        : const Color(0xFF60A5FA);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield Icon with Pulse effect
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: glow.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_rounded, size: 80, color: glow),
            ),
            
            const SizedBox(height: 40),
            
            Text(
              'مطلوب صلاحية الوصول', 
              style: TextStyle(
                color: text, 
                fontSize: 24, 
                fontWeight: FontWeight.bold
              )
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'ليتمكن المراقب من تزويدك بإحصائيات دقيقة، نحتاج لإذن "الوصول لبيانات الاستخدام" من إعدادات النظام.', 
              textAlign: TextAlign.center, 
              style: TextStyle(
                color: subText, 
                fontSize: 15, 
                height: 1.6,
                fontWeight: FontWeight.w400,
              )
            ),
            
            const SizedBox(height: 50),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.requestPermission(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: glow,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  elevation: 8,
                  shadowColor: glow.withValues(alpha: 0.4),
                ),
                child: const Text(
                  'منح الصلاحية الآن', 
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'خصوصيتك محمية: لن يتم إرسال أي بيانات خارج هاتفك.',
              style: TextStyle(color: subText.withValues(alpha: 0.6), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
