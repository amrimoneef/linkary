import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/blocked_app.dart';
import '../controllers/app_monitor_controller.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../domain/entities/app_usage_entity.dart';

class FirewallManagementScreen extends GetView<AppMonitorController> {
  const FirewallManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E21) : const Color(0xFFF3F4F6);
    final cardColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('جدار حماية التطبيقات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/images/الشعار ابيض.png'
                  : 'assets/images/الشعار اسود.png',
              height: 25,
              fit: BoxFit.contain,
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAppBottomSheet(context, bgColor, cardColor, textColor, subTextColor),
        icon: const Icon(Iconsax.add),
        label: const Text('إضافة تطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildMainToggleCard(cardColor, textColor, subTextColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'التطبيقات المحظورة',
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Obx(() => Text(
                    '${controller.blockedApps.length} تطبيقات',
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  )),
                ],
              ),
            ),
          ),
          Obx(() {
            if (controller.blockedApps.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.shield_tick, size: 80, color: subTextColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('التطبيقات المحظورة فارغة', style: TextStyle(color: textColor, fontSize: 18)),
                      Text('لم تقم بحظر أي تطبيق بعد', style: TextStyle(color: subTextColor)),
                    ],
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final app = controller.blockedApps[index];
                  return _buildBlockedAppTile(app, cardColor, textColor, subTextColor);
                },
                childCount: controller.blockedApps.length,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMainToggleCard(Color cardBg, Color text, Color subText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.shield_search, color: Color(0xFF4A90E2)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('حالة الجدار الناري', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
                    Obx(() => Text(
                      controller.isFirewallEnabled.value ? 'مفعّل وقيد التشغيل' : 'معطّل (لا يوجد حظر)',
                      style: TextStyle(
                        color: controller.isFirewallEnabled.value ? Colors.green : subText,
                      ),
                    )),
                  ],
                ),
              ),
              Obx(() => Switch(
                value: controller.isFirewallEnabled.value,
                onChanged: (val) => controller.toggleFirewall(val),
                activeColor: const Color(0xFF4A90E2),
              )),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, color: Color(0xFF4A90E2), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'عند التشغيل، ستظهر أيقونة مفتاح (VPN) في شريط حالة الجهاز. هذا ضروري لعملية الحظر المحلي.',
                    style: TextStyle(color: subText, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAppTile(BlockedApp app, Color cardBg, Color text, Color subText) {
    // البحث عن بيانات التطبيق للحصول على الأيقونة من القائمة الكاملة
    final usageApp = controller.allInstalledApps.firstWhereOrNull((u) => u.packageName == app.packageName);
    final iconData = usageApp?.iconData;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            // أيقونة التطبيق الأساسية
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: subText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: iconData != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(iconData, fit: BoxFit.cover),
                    )
                  : Icon(Iconsax.global, color: subText, size: 24),
            ),
            // علامة الحظر الأنيقة (تخرج قليلاً لليسار من الأسفل)
            Positioned(
              bottom: -2,
              left: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: cardBg, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.forbidden_2,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
        title: Text(app.appName, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
        subtitle: Text('محظور منذ ${app.blockedAt.day}/${app.blockedAt.month}/${app.blockedAt.year}', style: TextStyle(color: subText, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Iconsax.trash, color: Colors.redAccent),
          onPressed: () {
            controller.unblockApp(app.packageName);
          },
        ),
      ),
    );
  }

  void _showAddAppBottomSheet(BuildContext context, Color bgColor, Color cardColor, Color textColor, Color subTextColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: subTextColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text('اختر تطبيقاً لحظره', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (val) {
                        controller.updateSearch(val);
                      },
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن تطبيق...',
                        hintStyle: TextStyle(color: subTextColor),
                        prefixIcon: Icon(Iconsax.search_normal, color: subTextColor),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TabBar(
                    tabs: const [
                      Tab(text: 'تطبيقات المستخدم'),
                      Tab(text: 'تطبيقات النظام'),
                    ],
                    labelColor: const Color(0xFF4A90E2),
                    unselectedLabelColor: subTextColor,
                    indicatorColor: const Color(0xFF4A90E2),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAppList(controller.userApps, cardColor, textColor, subTextColor),
                        _buildAppList(controller.systemApps, cardColor, textColor, subTextColor, isSystem: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      controller.clearSearch(); // Reset search when bottom sheet is closed
    });
  }

  Widget _buildAppList(List<AppUsageEntity> apps, Color cardColor, Color textColor, Color subTextColor, {bool isSystem = false}) {
    return Obx(() {
      final availableApps = apps.where((app) => !controller.isAppBlocked(app.packageName)).toList();
      
      if (controller.isLoadingApps.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF4A90E2)));
      }

      if (availableApps.isEmpty) {
        return Center(child: Text('لا توجد تطبيقات إضافية للحظر', style: TextStyle(color: subTextColor)));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableApps.length,
        itemBuilder: (context, index) {
          final app = availableApps[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: subTextColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: app.iconData != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(app.iconData!, fit: BoxFit.cover))
                    : Icon(Iconsax.global, color: subTextColor, size: 20),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(app.appName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14))),
                  if (isSystem) 
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 0.5),
                      ),
                      child: const Text('نظام', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text(app.packageName, style: TextStyle(color: subTextColor, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Iconsax.add_circle, color: Color(0xFF4A90E2)),
                onPressed: () {
                  if (isSystem) {
                    _showSystemBlockWarning(context, app);
                  } else {
                    controller.blockApp(app.packageName, app.appName);
                    CustomSnackbar.showSuccess('تم الإضافة', 'تمت إضافة ${app.appName} إلى القائمة السوداء');
                  }
                },
              ),
            ),
          );
        },
      );
    });
  }

  void _showSystemBlockWarning(BuildContext context, AppUsageEntity app) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.amber),
            SizedBox(width: 10),
            Text('تحذير تطبيق نظام', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('أنت على وشك حظر تطبيق نظام (${app.appName}). قد يؤدي ذلك إلى توقف بعض خدمات الهاتف عن العمل أو عدم استقرار النظام. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              controller.blockApp(app.packageName, app.appName);
              Get.back();
              CustomSnackbar.showSuccess('تم الإضافة', 'تم حظر تطبيق النظام: ${app.appName}');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('حظر على أي حال'),
          ),
        ],
      ),
    );
  }
}
