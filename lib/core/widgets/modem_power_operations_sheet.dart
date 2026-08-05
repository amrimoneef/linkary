import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../features/modem_auth/presentation/controllers/auth_controller.dart';

class ModemPowerOperationsSheet extends StatelessWidget {
  const ModemPowerOperationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ModemPowerOperationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authController = Get.find<AuthController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. مقبض السحب العلوي (Drag Handle)
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. ترويسة العنوان والرمز التعبيري
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة طاقة وتشغيل المودم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'اختر الإجراء المطلوب إجراؤه على جهاز المودم',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // 3. الأزرار الخيارات الثلاثية
          // الخيار الأول: إعادة التشغيل
          _buildOperationTile(
            context: context,
            title: 'إعادة تشغيل المودم',
            icon: Icons.rotate_right_rounded,
            gradientColors: const [Color(0xFF4A90E2), Color(0xFF007AFF)],
            onTap: () {
              Navigator.pop(context);
              authController.reboot();
            },
          ),
          const SizedBox(height: 14),

          // الخيار الثاني: إيقاف التشغيل
          _buildOperationTile(
            context: context,
            title: 'إيقاف تشغيل المودم',
            icon: Icons.power_settings_new_rounded,
            gradientColors: const [Color(0xFFFF9500), Color(0xFFFF5E00)],
            onTap: () {
              Navigator.pop(context);
              authController.powerOff();
            },
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildOperationTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDanger
                  ? Colors.red.withValues(alpha: 0.3)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDanger
                            ? (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F))
                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
