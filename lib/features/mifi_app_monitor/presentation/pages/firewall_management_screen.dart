import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/blocked_app.dart';
import '../../domain/entities/app_usage_entity.dart';
import '../../domain/entities/app_category.dart';
import '../controllers/app_monitor_controller.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class FirewallManagementScreen extends GetView<AppMonitorController> {
  const FirewallManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E21) : const Color(0xFFF3F4F6);
    final cardColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
    const primaryColor = Color(0xFF4A90E2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'جدار حماية التطبيقات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.blockedApps.length}',
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
              ],
            ),
            Image.asset(
              isDark
                  ? 'assets/images/الشعار ابيض.png'
                  : 'assets/images/الشعار اسود.png',
              height: 25,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.blockedApps.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'إلغاء حظر الكل',
              icon: const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
              onPressed: () => _showUnblockAllConfirmation(context, cardColor, textColor, subTextColor),
            );
          }),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAppBottomSheet(context, bgColor, cardColor, textColor, subTextColor),
        icon: const Icon(Iconsax.add),
        label: const Text('إضافة تطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. بطاقة مفتاح الجدار الرئيسي وإحصائيات الحظر
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildMainToggleCard(context, cardColor, textColor, subTextColor, primaryColor),
            ),
          ),

          // 2. شريط البحث والفلترة (يظهر عندما توجد تطبيقات محظورة)
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.blockedApps.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(cardColor, textColor, subTextColor, primaryColor),
                    const SizedBox(height: 12),
                    _buildFilterChips(cardColor, textColor, subTextColor, primaryColor),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            }),
          ),

          // 3. عنوان القسم وعداد النتائج
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Obx(() {
                if (controller.blockedApps.isEmpty) return const SizedBox.shrink();
                final count = controller.filteredBlockedApps.length;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'التطبيقات المحظورة',
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$count من إجمالي ${controller.blockedApps.length}',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                );
              }),
            ),
          ),

          // 4. قائمة التطبيقات المحظورة أو الحالات الفارغة
          Obx(() {
            if (controller.blockedApps.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.shield_tick, size: 64, color: primaryColor),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'لا توجد تطبيقات محظورة',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط على زر "إضافة تطبيق" بالأسفل لاختيار التطبيقات التي ترغب في منعها من استهلاك الإنترنت عبر المودم.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subTextColor, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final filteredList = controller.filteredBlockedApps;
            if (filteredList.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.search_status, size: 56, color: subTextColor.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد نتائج مطابقة',
                          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'لم يتم العثور على أي تطبيق يطابق البحث أو الفلتر المحدد.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            controller.clearFirewallSearch();
                            controller.setFirewallFilter(BlockedAppFilter.all);
                          },
                          icon: const Icon(Iconsax.refresh, size: 16),
                          label: const Text('إعادة تعيين البحث'),
                          style: TextButton.styleFrom(foregroundColor: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final app = filteredList[index];
                  return _buildBlockedAppTile(context, app, cardColor, textColor, subTextColor, primaryColor);
                },
                childCount: filteredList.length,
              ),
            );
          }),

          // 5. مساحة أمان سفلية تحل مشكلة تغطية زر الإضافة على آخر عنصر 🛡️
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggleCard(BuildContext context, Color cardBg, Color text, Color subText, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Obx(() => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (controller.isFirewallEnabled.value ? Colors.green : primaryColor).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.isFirewallEnabled.value ? Iconsax.shield_tick : Iconsax.shield_cross,
                  color: controller.isFirewallEnabled.value ? Colors.green : primaryColor,
                  size: 26,
                ),
              )),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('حالة الجدار الناري', style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Obx(() => Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.isFirewallEnabled.value ? Colors.green : Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.isFirewallEnabled.value ? 'مفعّل وقيد الحظر النشط' : 'معطّل (الحظر متوقف مؤقتاً)',
                          style: TextStyle(
                            color: controller.isFirewallEnabled.value ? Colors.green : Colors.amber.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
              ),
              Obx(() => Switch.adaptive(
                value: controller.isFirewallEnabled.value,
                onChanged: (val) => controller.toggleFirewall(val),
                activeThumbColor: primaryColor,
              )),
            ],
          ),
          const SizedBox(height: 14),
          // إحصائيات سريعة قابلة للضغط لتسهيل الفلترة الفورية
          Obx(() => Row(
            children: [
              Expanded(
                child: _buildQuickStatTile(
                  label: 'المحظور',
                  count: controller.blockedApps.length,
                  icon: Iconsax.forbidden_2,
                  color: Colors.redAccent,
                  isSelected: controller.firewallFilter.value == BlockedAppFilter.all,
                  onTap: () => controller.setFirewallFilter(BlockedAppFilter.all),
                  subText: subText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStatTile(
                  label: 'المستخدم',
                  count: controller.blockedUserAppsCount,
                  icon: Iconsax.user,
                  color: primaryColor,
                  isSelected: controller.firewallFilter.value == BlockedAppFilter.user,
                  onTap: () => controller.setFirewallFilter(BlockedAppFilter.user),
                  subText: subText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStatTile(
                  label: 'النظام',
                  count: controller.blockedSystemAppsCount,
                  icon: Iconsax.setting_2,
                  color: Colors.amber,
                  isSelected: controller.firewallFilter.value == BlockedAppFilter.system,
                  onTap: () => controller.setFirewallFilter(BlockedAppFilter.system),
                  subText: subText,
                ),
              ),
            ],
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Iconsax.info_circle, color: primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يعمل جدار الحماية محلياً بنسبة 100% عبر خدمة VPN آمنة دون خروج أي بيانات خارج هاتفك.',
                    style: TextStyle(color: subText, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatTile({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required Color subText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : subText.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.6) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: isSelected ? color : subText),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? color : subText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : subText,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color cardBg, Color text, Color subText, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.firewallSearchController,
        onChanged: controller.updateFirewallSearch,
        style: TextStyle(color: text, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ابحث في التطبيقات المحظورة بالاسم أو الحزمة...',
          hintStyle: TextStyle(color: subText, fontSize: 13),
          prefixIcon: Icon(Iconsax.search_normal_1, color: primaryColor, size: 18),
          suffixIcon: Obx(() {
            if (controller.firewallSearchQuery.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(Iconsax.close_circle, color: subText, size: 18),
              onPressed: controller.clearFirewallSearch,
            );
          }),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips(Color cardBg, Color text, Color subText, Color primaryColor) {
    return Obx(() {
      final currentFilter = controller.firewallFilter.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              title: 'الكل (${controller.blockedApps.length})',
              isSelected: currentFilter == BlockedAppFilter.all,
              onTap: () => controller.setFirewallFilter(BlockedAppFilter.all),
              cardBg: cardBg,
              primaryColor: primaryColor,
              subText: subText,
            ),
            const SizedBox(width: 8),
            _buildChip(
              title: 'تطبيقات المستخدم (${controller.blockedUserAppsCount})',
              isSelected: currentFilter == BlockedAppFilter.user,
              onTap: () => controller.setFirewallFilter(BlockedAppFilter.user),
              cardBg: cardBg,
              primaryColor: primaryColor,
              subText: subText,
            ),
            const SizedBox(width: 8),
            _buildChip(
              title: 'تطبيقات النظام (${controller.blockedSystemAppsCount})',
              isSelected: currentFilter == BlockedAppFilter.system,
              onTap: () => controller.setFirewallFilter(BlockedAppFilter.system),
              cardBg: cardBg,
              primaryColor: primaryColor,
              subText: subText,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardBg,
    required Color primaryColor,
    required Color subText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : subText.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : subText,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedAppTile(
    BuildContext context,
    BlockedApp app,
    Color cardBg,
    Color text,
    Color subText,
    Color primaryColor,
  ) {
    final installedApp = controller.allInstalledApps.firstWhereOrNull((u) => u.packageName == app.packageName);
    final usageApp = controller.appsUsage.firstWhereOrNull((u) => u.packageName == app.packageName);
    final iconData = installedApp?.iconData ?? usageApp?.iconData;
    final isSystem = installedApp?.isSystemApp ?? false;
    final category = installedApp?.category ?? usageApp?.category;

    return Dismissible(
      key: Key('blocked_${app.packageName}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'إلغاء الحظر',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(width: 8),
            Icon(Iconsax.trash, color: Colors.white, size: 22),
            SizedBox(width: 16),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showUnblockSingleConfirmation(context, app, cardBg, text);
      },
      onDismissed: (_) {
        controller.unblockApp(app.packageName);
        CustomSnackbar.showSuccess('تم إلغاء الحظر', 'تم رفع الحظر عن ${app.appName}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: subText.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: iconData != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(iconData, fit: BoxFit.cover),
                      )
                    : Icon(Iconsax.global, color: subText, size: 24),
              ),
              Positioned(
                bottom: -2,
                left: -4,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 2),
                  ),
                  child: const Icon(
                    Iconsax.forbidden_2,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  app.appName,
                  style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSystem)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: const Text('نظام', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Row(
                children: [
                  if (category != null) ...[
                    Text(
                      '${category.icon} ${category.displayName}',
                      style: TextStyle(color: subText, fontSize: 10),
                    ),
                    Text(' • ', style: TextStyle(color: subText, fontSize: 10)),
                  ],
                  Text(
                    'حُظر في ${app.blockedAt.day}/${app.blockedAt.month}/${app.blockedAt.year}',
                    style: TextStyle(color: subText, fontSize: 10),
                  ),
                ],
              ),
              if (usageApp != null && usageApp.totalBytes > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'الاستهلاك المسجل: ${controller.formatBytes(usageApp.totalBytes)}',
                  style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          trailing: IconButton(
            tooltip: 'إلغاء الحظر',
            icon: const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
            onPressed: () async {
              final confirm = await _showUnblockSingleConfirmation(context, app, cardBg, text);
              if (confirm == true) {
                controller.unblockApp(app.packageName);
                CustomSnackbar.showSuccess('تم إلغاء الحظر', 'تم رفع الحظر عن ${app.appName}');
              }
            },
          ),
        ),
      ),
    );
  }

  void _showUnblockAllConfirmation(BuildContext context, Color cardBg, Color text, Color subText) {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('إلغاء حظر جميع التطبيقات؟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'سيتم إزالة الحظر عن جميع التطبيقات (${controller.blockedApps.length}) وإيقاف الجدار الناري. هل أنت متأكد؟',
          style: TextStyle(color: subText, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              controller.unblockAllApps();
              Get.back();
              CustomSnackbar.showSuccess('تم بنجاح', 'تم إلغاء حظر جميع التطبيقات وإيقاف الجدار');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('إلغاء حظر الكل'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showUnblockSingleConfirmation(BuildContext context, BlockedApp app, Color cardBg, Color text) {
    return Get.dialog<bool>(
      AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.shield_security, color: Color(0xFF4A90E2)),
            SizedBox(width: 10),
            Text('إلغاء الحظر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('هل تريد السماح لتطبيق (${app.appName}) بالاتصال بالإنترنت مجدداً؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2), foregroundColor: Colors.white),
            child: const Text('تأكيد السماح'),
          ),
        ],
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
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: subTextColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'اختر تطبيقاً لحظره من الإنترنت',
                    style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: controller.searchTextController,
                      onChanged: (val) {
                        controller.updateSearch(val);
                      },
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن تطبيق لتحديده...',
                        hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                        prefixIcon: const Icon(Iconsax.search_normal_1, color: Color(0xFF4A90E2), size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(Iconsax.close_circle, color: subTextColor, size: 18),
                          onPressed: () {
                            controller.searchTextController.clear();
                            controller.updateSearch('');
                          },
                        ),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
      controller.clearSearch();
    });
  }

  Widget _buildAppList(List<AppUsageEntity> apps, Color cardColor, Color textColor, Color subTextColor, {bool isSystem = false}) {
    return Obx(() {
      final availableApps = apps.where((app) => !controller.isAppBlocked(app.packageName)).toList();

      if (controller.isLoadingApps.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF4A90E2)));
      }

      if (availableApps.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.tick_circle, size: 48, color: Colors.green.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('لا توجد تطبيقات إضافية للحظر في هذا القسم', style: TextStyle(color: subTextColor, fontSize: 13)),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
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
                width: 42,
                height: 42,
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
                  Expanded(
                    child: Text(
                      app.appName,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSystem)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 0.5),
                      ),
                      child: const Text('نظام', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Row(
                children: [
                  Text('${app.category.icon} ${app.category.displayName}', style: TextStyle(color: subTextColor, fontSize: 10)),
                  Text(' • ', style: TextStyle(color: subTextColor, fontSize: 10)),
                  Expanded(
                    child: Text(
                      app.packageName,
                      style: TextStyle(color: subTextColor, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Iconsax.add_circle, color: Color(0xFF4A90E2), size: 24),
                tooltip: 'حظر التطبيق',
                onPressed: () {
                  if (isSystem) {
                    _showSystemBlockWarning(context, app);
                  } else {
                    controller.blockApp(app.packageName, app.appName);
                    CustomSnackbar.showSuccess('تمت الإضافة', 'تم حظر ${app.appName} من الإنترنت');
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
            Text('تحذير تطبيق نظام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'أنت على وشك حظر تطبيق نظام (${app.appName}). قد يؤدي ذلك إلى توقف بعض خدمات الهاتف أو عدم استقرار النظام. هل أنت متأكد؟',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              controller.blockApp(app.packageName, app.appName);
              Get.back();
              CustomSnackbar.showSuccess('تمت الإضافة', 'تم حظر تطبيق النظام: ${app.appName}');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('حظر على أي حال'),
          ),
        ],
      ),
    );
  }
}
