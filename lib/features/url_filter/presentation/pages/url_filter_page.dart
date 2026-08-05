import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../controllers/url_filter_controller.dart';
import '../widgets/add_url_dialog.dart';

class UrlFilterPage extends StatelessWidget {
  const UrlFilterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UrlFilterController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF070B19) : const Color(0xFFF4F7FC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'حظر المواقع',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.warning_2, size: 60, color: AppColors.errorRed),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: controller.fetchData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final isEnabled = controller.filterMode.value == 'blacklist';

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Master Toggle Switch
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 20,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isEnabled 
                                ? AppColors.errorRed.withValues(alpha: 0.15) 
                                : AppColors.primaryBlue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEnabled ? Iconsax.shield_cross : Iconsax.shield_tick,
                            color: isEnabled ? AppColors.errorRed : AppColors.primaryBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفعيل حظر المواقع',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'منع الأجهزة من الوصول للقائمة السوداء',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isEnabled,
                          activeColor: AppColors.errorRed,
                          onChanged: (val) => controller.toggleMode(val),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'القائمة السوداء (${controller.blackItems.length}/10)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (isEnabled && controller.blackItems.length < 10)
                        InkWell(
                          onTap: () {
                            AddUrlDialog.show(onSave: controller.addUrl);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Iconsax.add, size: 18, color: AppColors.primaryBlue),
                                SizedBox(width: 4),
                                Text('إضافة', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Blacklist Items
                  Expanded(
                    child: !isEnabled 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.shield_search, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'الميزة معطلة حالياً',
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : controller.blackItems.isEmpty
                        ? Center(
                            child: Text(
                              'القائمة فارغة. أضف مواقع لحظرها.',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: controller.blackItems.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = controller.blackItems[index];
                              return GlassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                borderRadius: 16,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorRed.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Iconsax.global_search, size: 20, color: AppColors.errorRed),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Iconsax.edit, color: Colors.grey),
                                      onPressed: () {
                                        AddUrlDialog.show(
                                          initialUrl: item,
                                          onSave: (newUrl) => controller.editUrl(index, newUrl),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Iconsax.trash, color: AppColors.errorRed),
                                      onPressed: () => controller.removeUrl(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            
            // Saving Overlay
            if (controller.isSaving.value)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: GlassCard(
                    padding: EdgeInsets.all(24),
                    borderRadius: 20,
                    child: CircularProgressIndicator(color: AppColors.primaryBlue),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
