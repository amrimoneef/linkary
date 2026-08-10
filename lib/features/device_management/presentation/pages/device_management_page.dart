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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Radial Glow Background
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withOpacity(isDark ? 0.2 : 0.1),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Iconsax.arrow_right_3, color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => Get.back(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'إدارة الأجهزة',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحكم شامل بأجهزتك من مكان واحد',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 14,
                          ),
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
                          'الأجهزة المُدارة',
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
