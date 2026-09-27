import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/widgets/glass_card.dart';
import '../controllers/feedback_controller.dart';
import '../widgets/feedback_category_selector.dart';
import '../widgets/feedback_history_card.dart';
import '../widgets/image_attachment_box.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FeedbackController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0A0E21) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final glowColor = isDark ? const Color(0xFF4A90E2) : const Color(0xFF38BDF8);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 🌌 1. Radial Glow Background (طابق شاشة إدارة التنبيهات الذكية)
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: isDark ? 0.25 : 0.2),
                    glowColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🏷️ 2. Top Header (زر الرجوع + العنوان + شعار Linkary)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 18),
                              onPressed: () => Get.back(),
                            ),
                            Text(
                              'صندوق الاقتراحات والملاحظات',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          isDark
                              ? 'assets/images/الشعار ابيض.png'
                              : 'assets/images/الشعار اسود.png',
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 🛡️ 3. Master Summary Card (بطاقة ملخص وتوجيه زجاجية)
                      _buildMasterSummaryCard(
                        context,
                        controller,
                        isDark,
                        cardColor,
                        textColor,
                        subTextColor,
                      ),
                      const SizedBox(height: 20),

                      // 📄 4. Body Content (Form vs History)
                      Obx(() {
                        final isFormTab = controller.currentTabIndex.value == 0;
                        if (isFormTab) {
                          return _buildFormSection(
                            context,
                            controller,
                            isDark,
                            cardColor,
                            textColor,
                            subTextColor,
                          );
                        } else {
                          return _buildHistorySection(
                            context,
                            controller,
                            isDark,
                            cardColor,
                            textColor,
                            subTextColor,
                          );
                        }
                      }),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🛡️ 1. Master Status Summary Card
  // ==========================================
  Widget _buildMasterSummaryCard(
    BuildContext context,
    FeedbackController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Obx(() {
      final isForm = controller.currentTabIndex.value == 0;
      final total = controller.submissions.length;
      final pending = controller.pendingCount;

      return GlassCard(
        surfaceColor: cardColor,
        borderColor: const Color(0xFF0072FF).withValues(alpha: 0.3),
        opacity: 0.7,
        blur: 15,
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0072FF).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.message_favorite,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صوتك يصنع مستقبل التطبيق',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pending > 0
                            ? '$pending ملاحظات محفوظة بانتظار الاتصال'
                            : (total > 0 ? '$total مشاركات سابقة مسجلة' : 'شاركنا أفكارك واقتراحاتك لتطوير التطبيق'),
                        style: TextStyle(color: subTextColor, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    controller.currentTabIndex.value = isForm ? 1 : 0;
                  },
                  icon: Icon(
                    isForm ? Iconsax.document_text : Iconsax.edit_2,
                    size: 16,
                  ),
                  label: Text(isForm ? 'سجل الملاحظات' : 'اقتراح جديد'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0072FF),
                    backgroundColor: const Color(0xFF0072FF).withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ==========================================
  // 📝 2. Submission Form (Sections)
  // ==========================================
  Widget _buildFormSection(
    BuildContext context,
    FeedbackController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 1. نوع المشاركة (الفئة)
        _buildSectionCard(
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
          title: 'نوع المشاركة',
          subtitle: 'حدد تصنيف طلبك لسرعة مراجعته وتوجيهه للمطورين.',
          icon: Iconsax.category,
          gradientColors: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
          expandedContent: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Obx(() => FeedbackCategorySelector(
                  selectedCategory: controller.selectedCategory.value,
                  onSelect: controller.selectCategory,
                  isDark: isDark,
                )),
          ),
        ),
        const SizedBox(height: 18),

        // 🔹 2. تفاصيل الاقتراح (العنوان والمحتوى)
        _buildSectionCard(
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
          title: 'تفاصيل الاقتراح أو المشكلة',
          subtitle: 'اكتب عنواناً وشرحاً واضحاً لمساعدتنا في تنفيذ فكرتك.',
          icon: Iconsax.edit,
          gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
          expandedContent: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  child: TextField(
                    controller: controller.titleController,
                    maxLength: 80,
                    style: TextStyle(color: textColor, fontSize: 13.5),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'عنوان مختصر (مثال: إضافة ويدجت استهلاك الباقة)',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(Iconsax.text, color: Color(0xFF10B981), size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  child: TextField(
                    controller: controller.descriptionController,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 800,
                    style: TextStyle(color: textColor, fontSize: 13.5, height: 1.45),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'اشرح فكرتك بالتفصيل: ما الفائدة منها؟ كيف تتوقع أن تعمل؟ وما هي المشاكل التي ستحلها؟',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(Iconsax.document, color: Color(0xFF10B981), size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 🔹 3. إرفاق لقطة شاشة توضيحية (اختياري)
        _buildSectionCard(
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
          title: 'إرفاق صورة أو لقطة شاشة',
          subtitle: 'إرفاق لقطة شاشة لتوضيح المشكلة أو شرح الفكرة بشكل أفضل.',
          icon: Iconsax.gallery,
          gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          expandedContent: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: ImageAttachmentBox(controller: controller),
          ),
        ),
        const SizedBox(height: 18),

        // 🔹 4. البيانات التشخيصية للمودم
        Obx(() {
          final isEnabled = controller.includeDiagnostics.value;
          final isExpanded = controller.isDiagnosticsExpanded.value;
          final diag = controller.diagnosticInfo.value;

          return _buildSectionCard(
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subTextColor: subTextColor,
            title: 'البيانات التشخيصية الذكية',
            subtitle: 'تضمين نوع المودم، قوة الإشارة، وإصدار النظام تلقائياً.',
            icon: Iconsax.cpu_setting,
            gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            isEnabled: isEnabled,
            onToggle: controller.toggleDiagnostics,
            expandedContent: isEnabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: controller.toggleDiagnosticsExpanded,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Iconsax.info_circle, color: Color(0xFF8B5CF6), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'عرض البيانات المرفقة (${diag?.deviceModel ?? 'جهاز أندرويد'})',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: const Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded && diag != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                _buildDiagRow('طراز الهاتف', diag.deviceModel, isDark),
                                const Divider(height: 14, thickness: 0.5),
                                _buildDiagRow('نوع النظام', diag.osVersion, isDark),
                                const Divider(height: 14, thickness: 0.5),
                                _buildDiagRow('إصدار التطبيق', diag.appVersion, isDark),
                                const Divider(height: 14, thickness: 0.5),
                                _buildDiagRow('المودم', diag.modemModel, isDark),
                                const Divider(height: 14, thickness: 0.5),
                                _buildDiagRow('نوع الشبكة / التردد', diag.networkType, isDark),
                                const Divider(height: 14, thickness: 0.5),
                                _buildDiagRow('قوة الإشارة والبطارية', '${diag.signalStrength} • ${diag.batteryLevel}', isDark),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : null,
          );
        }),
        const SizedBox(height: 18),

        // 🔹 5. وسيلة التواصل (اختياري)
        _buildSectionCard(
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
          title: 'وسيلة التواصل (اختياري)',
          subtitle: 'بريدك الإلكتروني أو معرف تيليجرام للتواصل معك عند توفر الميزة.',
          icon: Iconsax.direct_send,
          gradientColors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
          expandedContent: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              child: TextField(
                controller: controller.contactController,
                style: TextStyle(color: textColor, fontSize: 13.5),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'بريد إلكتروني أو رقم هاتف أو حساب تيليجرام للتواصل',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                  prefixIcon: const Icon(Iconsax.sms, color: Color(0xFFEC4899), size: 20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),

        // 🚀 6. زر الإرسال الرئيسي (مطابق لأزرار شاشة إدارة التنبيهات)
        Obx(() {
          final isSubmitting = controller.isSubmitting.value;

          return SizedBox(
            width: double.infinity,
            height: 54,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0072FF).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: isSubmitting ? null : controller.submitFeedback,
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.send_1, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'إرسال الاقتراح والملاحظة الآن',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),

        // 🛡️ ملاحظة العمل دون اتصال
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.cloud_connection, size: 14, color: subTextColor),
              const SizedBox(width: 6),
              Text(
                'يعمل التطبيق حتى دون إنترنت، وسيتم حفظ اقتراحك محلياً للإرسال التلقائي.',
                style: TextStyle(fontSize: 11, color: subTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 📋 3. History Section
  // ==========================================
  Widget _buildHistorySection(
    BuildContext context,
    FeedbackController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Obx(() {
      final list = controller.submissions;
      final pendingCount = controller.pendingCount;
      final isSyncing = controller.isSyncing.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offline Pending Banner if items exist
          if (pendingCount > 0) ...[
            GlassCard(
              surfaceColor: cardColor,
              borderColor: Colors.amber.shade700.withValues(alpha: 0.4),
              opacity: 0.7,
              blur: 15,
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Iconsax.warning_2, color: Colors.amber.shade800, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'يوجد $pendingCount طلب محفوظ بانتظار الاتصال',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'سيتم الإرسال تلقائياً فور توفر الإنترنت أو بالضغط على مزامنة.',
                          style: TextStyle(fontSize: 11, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: isSyncing ? null : controller.syncPending,
                    child: isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'مزامنة الكل',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (list.isEmpty) ...[
            GlassCard(
              surfaceColor: cardColor,
              borderColor: Colors.grey.withValues(alpha: 0.15),
              opacity: 0.7,
              blur: 15,
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0072FF).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.message_notif,
                        size: 40,
                        color: Color(0xFF0072FF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد اقتراحات أو ملاحظات سابقة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'عند إرسال أي اقتراح أو بلاغ عن مشكلة، ستظهر هنا لمتابعة حالتها.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: subTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...list.map((item) => FeedbackHistoryCard(
                  submission: item,
                  controller: controller,
                )),
          ],
        ],
      );
    });
  }

  // ==========================================
  // 🧩 دوال بناء الواجهة المشتركة (مطابقة BatterySettingsPage)
  // ==========================================
  Widget _buildSectionCard({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    bool isEnabled = true,
    ValueChanged<bool>? onToggle,
    Widget? expandedContent,
  }) {
    return GlassCard(
      surfaceColor: cardColor,
      borderColor: isEnabled ? gradientColors.first.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15),
      opacity: 0.7,
      blur: 15,
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEnabled ? gradientColors : [Colors.grey.shade600, Colors.grey.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: gradientColors.first.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: subTextColor, fontSize: 11.5, height: 1.3),
                    ),
                  ],
                ),
              ),
              if (onToggle != null) ...[
                Switch.adaptive(
                  value: isEnabled,
                  activeThumbColor: gradientColors.first,
                  onChanged: onToggle,
                ),
              ],
            ],
          ),
          if (expandedContent != null) ...[
            expandedContent,
          ],
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
