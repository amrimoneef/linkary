import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../controllers/feedback_controller.dart';
import '../widgets/diagnostic_info_card.dart';
import '../widgets/feedback_category_selector.dart';
import '../widgets/feedback_history_card.dart';
import '../widgets/image_attachment_box.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with SingleTickerProviderStateMixin {
  late final FeedbackController controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<FeedbackController>();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        controller.currentTabIndex.value = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _bgColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0E21)
          : const Color(0xFFF4F7FC);

  Color _cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF16213E)
          : Colors.white;

  Color _textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1E293B);

  Color _subTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white60
          : const Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bgColor(context),
        body: Column(
          children: [
            // 🌌 1. Header (متوافق مع هوية Linkary)
            _buildHeader(context, isDark),

            // 📑 2. Segmented Tab Switcher
            _buildTabSwitcher(context, isDark),

            // 📄 3. Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSubmissionTab(context, isDark),
                  _buildHistoryTab(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
              : [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'صندوق الاقتراحات والملاحظات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'شاركنا أفكارك وتجاربك لتطوير التطبيق معاً',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.message_favorite, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF4A90E2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: [
          const Tab(text: 'تقديم اقتراح جديد'),
          Obx(() {
            final pending = controller.pendingCount;
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('سجل الملاحظات'),
                  if (pending > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$pending',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubmissionTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💡 Intro Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4A90E2), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صوتك يرسم مستقبل التطبيق',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _textColor(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'نقرأ كافة الاقتراحات والملاحظات بعناية، ونعمل على تضمينها في التحديثات المستمرة.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _subTextColor(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 1. نوع المشاركة (الفئة)
          Obx(() => FeedbackCategorySelector(
                selectedCategory: controller.selectedCategory.value,
                onSelect: controller.selectCategory,
                isDark: isDark,
              )),
          const SizedBox(height: 20),

          // 2. عنوان الاقتراح
          _buildFieldLabel('عنوان الاقتراح أو الملاحظة *', isDark),
          const SizedBox(height: 8),
          TextField(
            controller: controller.titleController,
            maxLength: 80,
            style: TextStyle(color: _textColor(context), fontSize: 14),
            decoration: _inputDecoration(
              context: context,
              hint: 'مثال: إضافة ويدجت لعرض استهلاك الباقة بالشاشة الرئيسية',
              prefixIcon: Icons.title_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 12),

          // 3. تفاصيل الاقتراح
          _buildFieldLabel('التفاصيل والشرح *', isDark),
          const SizedBox(height: 8),
          TextField(
            controller: controller.descriptionController,
            minLines: 4,
            maxLines: 7,
            maxLength: 800,
            style: TextStyle(color: _textColor(context), fontSize: 13.5, height: 1.4),
            decoration: _inputDecoration(
              context: context,
              hint: 'اشرح فكرتك بالتفصيل: ما الفائدة منها؟ كيف تتوقع أن تعمل؟ وما هي المشاكل التي ستحلها؟',
              prefixIcon: Icons.notes_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),

          // 4. إرفاق صورة توضيحية
          _buildFieldLabel('إرفاق صورة أو لقطة شاشة', isDark),
          const SizedBox(height: 8),
          ImageAttachmentBox(controller: controller),
          const SizedBox(height: 18),

          // 5. بطاقة البيانات التشخيصية
          Obx(() => DiagnosticInfoCard(
                isEnabled: controller.includeDiagnostics.value,
                isExpanded: controller.isDiagnosticsExpanded.value,
                diagnosticInfo: controller.diagnosticInfo.value,
                onToggleEnabled: controller.toggleDiagnostics,
                onToggleExpanded: controller.toggleDiagnosticsExpanded,
                isDark: isDark,
              )),
          const SizedBox(height: 18),

          // 6. معلومات التواصل (اختياري)
          _buildFieldLabel('وسيلة تواصل (اختياري)', isDark),
          const SizedBox(height: 8),
          TextField(
            controller: controller.contactController,
            style: TextStyle(color: _textColor(context), fontSize: 14),
            decoration: _inputDecoration(
              context: context,
              hint: 'بريد إلكتروني أو رقم هاتف أو حساب تيليجرام للتواصل',
              prefixIcon: Icons.contact_mail_outlined,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 24),

          // 🚀 زر الإرسال
          Obx(() {
            final isSubmitting = controller.isSubmitting.value;

            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF4A90E2).withValues(alpha: 0.4),
                ),
                onPressed: isSubmitting ? null : controller.submitFeedback,
                child: isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'إرسال الاقتراح الآن',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
                Icon(Icons.cloud_done_rounded, size: 14, color: _subTextColor(context)),
                const SizedBox(width: 6),
                Text(
                  'يعمل التطبيق حتى بدون إنترنت، ويحفظ طلبك للمزامنة لاحقاً.',
                  style: TextStyle(fontSize: 11, color: _subTextColor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, bool isDark) {
    return Obx(() {
      final list = controller.submissions;
      final pendingCount = controller.pendingCount;
      final isSyncing = controller.isSyncing.value;

      return Column(
        children: [
          // Offline Pending Banner if items waiting
          if (pendingCount > 0) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'يوجد $pendingCount طلب محفوظ محلياً بانتظار الاتصال بالإنترنت',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: isSyncing ? null : controller.syncPending,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'مزامنة الكل',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: _cardColor(context),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: Icon(
                              Iconsax.message_notif,
                              size: 48,
                              color: _subTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'لا توجد اقتراحات أو ملاحظات سابقة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'أي ملاحظة أو فكرة تشاركها ستظهر هنا مع حالتها للمتابعة المستمرة.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _subTextColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return FeedbackHistoryCard(
                        submission: item,
                        controller: controller,
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : const Color(0xFF334155),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
    required IconData prefixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: isDark ? Colors.white30 : Colors.black38,
      ),
      filled: true,
      fillColor: _cardColor(context),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF4A90E2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF4A90E2),
          width: 1.8,
        ),
      ),
    );
  }
}
