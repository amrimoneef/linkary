import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quick_tools_controller.dart';
import '../widgets/modern_notification_card_preview.dart';
import '../widgets/glass_widget_preview_card.dart';
import '../widgets/widget_preview_small.dart';
import '../widgets/widget_preview_banner.dart';
import '../widgets/widget_preview_detailed.dart';
import '../../infrastructure/services/home_widget_sync_service.dart';

class WidgetsSettingsPage extends GetView<QuickToolsController> {
  const WidgetsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الأدوات السريعة والويدجت',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final state = controller.state.value;
        final isNotifEnabled = controller.isNotificationEnabled.value;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── القسم الأول: شريط الإشعارات ───
              _buildSectionHeader(
                icon: Icons.notifications_active_rounded,
                title: 'شريط الإشعارات التفاعلي',
                badge: 'دائم',
              ),
              const SizedBox(height: 12),
              _buildNotificationToggleCard(context, isNotifEnabled),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'معاينة شريط الإشعارات المطور:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'مباشر',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ModernNotificationCardPreview(
                state: state,
                onRefresh: () => controller.refreshAll(),
                onBalance: () => controller.openBalancePage(),
                onReboot: () => controller.rebootModem(),
              ),

              const SizedBox(height: 32),

              // ─── القسم الثاني: معرض الويدجت الزجاجية ───
              _buildSectionHeader(
                icon: Icons.widgets_rounded,
                title: 'الويدجت الزجاجية للشاشة الرئيسية',
                badge: '3 أحجام',
              ),
              const SizedBox(height: 8),
              Text(
                'اختر الحجم المناسب لشاشتك وقم بإضافته مباشرة بضغطة زر:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),

              // 1. الويدجت الموسع (4x2)
              GlassWidgetPreviewCard(
                title: 'الويدجت المتكامل (بطاقة تفاعلية)',
                subtitle: 'يعرض الرصيد والبطارية والأجهزة مع أزرار التحكم السريع',
                dimensions: '4 × 2',
                preview: WidgetPreviewDetailed(state: state),
                onPinPressed: () => controller.pinWidget(
                  HomeWidgetSyncService.detailedWidgetProvider,
                ),
              ),

              // 2. الويدجت الشريطي (4x1)
              GlassWidgetPreviewCard(
                title: 'الويدجت الشريطي (بانر أفقي)',
                subtitle: 'تصميم عريض أنيق ومدمج يناسب أعلى الشاشة الرئيسية',
                dimensions: '4 × 1',
                preview: WidgetPreviewBanner(state: state),
                onPinPressed: () => controller.pinWidget(
                  HomeWidgetSyncService.bannerWidgetProvider,
                ),
              ),

              // 3. الويدجت المصغر (2x2)
              GlassWidgetPreviewCard(
                title: 'الويدجت المصغر (مربع الرصيد)',
                subtitle: 'تركيز فوري على رصيد الباقة ونسبة بطارية المودم',
                dimensions: '2 × 2',
                preview: WidgetPreviewSmall(state: state),
                onPinPressed: () => controller.pinWidget(
                  HomeWidgetSyncService.smallWidgetProvider,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String badge,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF38BDF8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggleCard(BuildContext context, bool isEnabled) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEnabled
              ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isEnabled
                                ? const Color(0xFF38BDF8)
                                : Colors.grey.shade800)
                            .withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEnabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        color: isEnabled
                            ? const Color(0xFF38BDF8)
                            : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفعيل الإشعار التفاعلي الدائم',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEnabled
                                ? 'نشط الآن في شريط الإشعارات'
                                : 'معطل حالياً',
                            style: TextStyle(
                              fontSize: 12,
                              color: isEnabled
                                  ? const Color(0xFF34D399)
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: isEnabled,
                      activeTrackColor: const Color(0xFF38BDF8),
                      activeThumbColor: Colors.white,
                      onChanged: (val) => controller.toggleNotification(val),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'يمنحك وصولاً سريعاً لمؤشرات المودم (الرصيد، البطارية، المتصلون) وأزرار الإجراءات في لوحة الإشعارات دون الحاجة لفتح التطبيق.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
