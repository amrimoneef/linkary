import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/device_data_limit_controller.dart';
import '../widgets/add_data_limit_dialog.dart';
import '../../../../core/theme/app_colors.dart';

class DeviceDataLimitPage extends GetView<DeviceDataLimitController> {
  const DeviceDataLimitPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('إدارة باقة الأجهزة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchData(),
          ),
        ],
      ),
      floatingActionButton: Obx(() => controller.isEnabled.value 
        ? FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddDataLimitDialog(controller: controller),
              );
            },
            backgroundColor: AppColors.primaryPurple,
            child: const Icon(Icons.add, color: Colors.white),
          )
        : const SizedBox.shrink()),
      body: Obx(() {
        if (controller.isLoading.value && controller.deviceLimits.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Switch Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحديد استهلاك الباقة',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تفعيل هذه الميزة يسمح لك بتحديد كمية البيانات المسموح بها لكل جهاز متصل.',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: controller.isEnabled.value,
                    onChanged: (val) => controller.toggleEnable(val),
                    activeColor: AppColors.primaryPurple,
                  ),
                ],
              ),
            ),
            
            // List of limits
            if (controller.isEnabled.value)
              Expanded(
                child: controller.deviceLimits.isEmpty
                  ? Center(
                      child: Text(
                        'لا يوجد أجهزة مقيدة حالياً',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.deviceLimits.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final limit = controller.deviceLimits[index];
                        final progress = limit.quotaBytes > 0 
                            ? (limit.currentUsageBytes / limit.quotaBytes).clamp(0.0, 1.0) 
                            : 0.0;
                        
                        return Card(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        limit.comment.isNotEmpty ? limit.comment : limit.hostname,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.errorRed),
                                      onPressed: () {
                                        Get.defaultDialog(
                                          title: 'تأكيد الحذف',
                                          middleText: 'هل أنت متأكد من حذف القيد عن هذا الجهاز؟',
                                          textConfirm: 'حذف',
                                          textCancel: 'إلغاء',
                                          confirmTextColor: Colors.white,
                                          buttonColor: AppColors.errorRed,
                                          onConfirm: () {
                                            Get.back();
                                            controller.deleteLimitItem(limit.mac);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  limit.mac,
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'المستهلك: ${controller.formatBytes(limit.currentUsageBytes)}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'الباقة: ${controller.formatBytes(limit.quotaBytes)}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress >= 0.9 ? AppColors.errorRed : AppColors.primaryPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'قم بتفعيل الميزة لإدارة الأجهزة',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
