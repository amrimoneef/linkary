import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/device_management_controller.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../widgets/device_detail_sheet.dart';
import '../widgets/managed_device_card.dart';
import '../widgets/master_toggles_section.dart';
import '../widgets/stats_summary_card.dart';

class DeviceManagementPage extends GetView<DeviceManagementController> {
  const DeviceManagementPage({Key? key}) : super(key: key);

  Color get bgColor => Get.isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFFAFAFC);
  Color get cardColor => Get.isDarkMode ? const Color(0xFF16213E) : Colors.white;
  Color get textColor => Get.isDarkMode ? Colors.white : const Color(0xFF111827);
  Color get subTextColor => Get.isDarkMode ? Colors.white54 : const Color(0xFF6B7280);
  Color get glowColor => Get.isDarkMode ? const Color(0xFF3FBFB3) : const Color(
      0xFFA3F6EE);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 🌌 1. الدائرة السعرية المتدرجة (Radial Glow)
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 370,
              height: 370,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: Get.isDarkMode ? 0.3 : 0.4),
                    glowColor.withValues(alpha: 0.01),
                  ],
                  stops: const [0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const SizedBox(height: 10),

                    // زر العودة واللوجو
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: textColor),
                          onPressed: () => Get.back(),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                        Image.asset(
                          Get.isDarkMode ? 'assets/images/الشعار ابيض.png' : 'assets/images/الشعار اسود.png',
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(width: 30),

                    // العنوان الرئيسي
                    Text('إدارة الأجهزة', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('تحكم شامل بالأجهزة المتصلة ', style: TextStyle(color: subTextColor, fontSize: 14)),
                        Text('من مكان واحد', style: TextStyle(color: glowColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                        const SizedBox(height: 24),
                        const StatsSummaryCard(),
                        const SizedBox(height: 24),
                        Text(
                          'مفاتيح التحكم الرئيسية',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const MasterTogglesSection(),
                        const SizedBox(height: 24),
                        Text(
                          'الأجهزة المتصلة حالياً',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Obx(() {
                  if (controller.isLoading.value) {
                    return const SliverFillRemaining(
                      child: Center(child: LoadingIndicator()),
                    );
                  }

                  final devices = controller.managedDevices;
                  
                  if (devices.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'لا توجد أجهزة متصلة',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final device = devices[index];
                          return ManagedDeviceCard(
                            device: device,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => DraggableScrollableSheet(
                                  initialChildSize: 0.8,
                                  minChildSize: 0.5,
                                  maxChildSize: 0.95,
                                  builder: (_, scrollController) => DeviceDetailSheet(device: device),
                                ),
                              );
                            },
                          );
                        },
                        childCount: devices.length,
                      ),
                    ),
                  );
                }),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
