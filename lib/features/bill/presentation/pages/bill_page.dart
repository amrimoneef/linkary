import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:linkary/core/widgets/glass_card.dart';
import '../controllers/bill_controller.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/services/tutorial_service.dart';

class BillPage extends StatelessWidget {
  BillPage({super.key});

  final BillController controller = Get.find<BillController>();

  // ─── ألوان مستوحاة ومطابقة لشاشة لوحة التحكم ──────────────────────────
  Color bgColor(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  Color cardColor(BuildContext context) => Theme.of(context).cardColor;
  Color textColor(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
  Color subTextColor(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white54;

  List<Color> get headerGradient => Get.isDarkMode
      ? [const Color(0xFF1E3C72), const Color(0xFF2A6E98)]
      : [const Color(0xFF4A90E2), const Color(0xFF50E3C2)];

  static const _primaryColor = Color(0xFF4A90E2);
  static const _accentColor = Color(0xFF50E3C2);
  static const _tealColor = Color(0xFF50E3C2);
  static const _errorColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<TutorialService>().showBillTutorial(context);
    });

    return Obx(() {
      return Scaffold(
        backgroundColor: bgColor(context),
        body: RefreshIndicator(
          onRefresh: controller.fetchBill,
          color: _primaryColor,
          backgroundColor: cardColor(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              children: [
                // ─── الترويسة الملونة الجذابة ───────────────────────
                _buildHeader(context),

                // ─── المحتوى الرئيسي (يطفو بشكل احترافي) ────────
                Transform.translate(
                  offset: const Offset(
                    0,
                    -65,
                  ), // يرفع كرت الرصيد ليطفو بوضوح فوق الهيدر
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        Container(
                          key: Get.find<TutorialService>().expectedBalanceKey,
                          child: _buildExpectedBalanceCard(context),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          key: Get.find<TutorialService>().billResultsKey,
                          child: _buildBody(context),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ─── الترويسة الفاخرة (Hero Section) ──────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. الخلفية المتدرجة ذات الحواف المنحنية بعمق وتطابق لوحة التحكم
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 50,
            left: 24,
            right: 24,
            bottom: 90,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان والأيقونة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.receipt_item,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'استعلام الرصيد والباقة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'الشبكة: Yemen 4G',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Get.find<TutorialService>().billHelpKey,
                        icon: Icon(Icons.help_outline, color: Colors.white, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 3))]),
                        onPressed: () => Get.find<TutorialService>().showBillTutorial(context, force: true),
                      ),
                      Image.asset(
                        'assets/images/الشعار ابيض.png',
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 38),

              // رقم الخط والوقت والتحديث
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم خط الـ4G',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.phoneNumber.value.isEmpty
                                  ? '...'
                                  : controller.phoneNumber.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (!controller.phoneNumber.value.isEmpty) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: controller.phoneNumber.value,
                                    ),
                                  );
                                  CustomSnackbar.showSuccess(
                                    'تم النسخ',
                                    'تم نسخ الرقم إلى الحافظة'
                                  );
                                },
                                child: const Icon(
                                  Iconsax.copy,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // وقت التحديث الأخير
                      Obx(() {
                        final text = controller.lastUpdatedText;
                        if (text.isEmpty) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.clock,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const Spacer(),

                  // زر التحديث الديناميكي
                  Obx(() {
                    final isLoading = controller.isLoading.value;
                    final isRateLimited = controller.isRateLimited;
                    final btnColor = isRateLimited
                        ? Colors.orange.shade100
                        : Colors.white;

                    return GestureDetector(
                      key: Get.find<TutorialService>().billRefreshButtonKey,
                      onTap: (isLoading || isRateLimited)
                          ? null
                          : controller.fetchBill,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: btnColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: isLoading
                                ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  _primaryColor,
                                ),
                              ),
                            )
                                : isRateLimited
                                ? const Icon(
                              Icons.timer_outlined,
                              color: Colors.orange,
                              size: 28,
                            )
                                : const Icon(
                              Iconsax.refresh,
                              color: _primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'استعلام',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        // 2. الدوائر الزجاجية
        Positioned(
          right: -30,
          top: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  // ─── المحتوى الرئيسي ────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    final error = controller.errorMessage.value;
    final isLoading = controller.isLoading.value;
    final hasData = controller.billData.value != null;

    // 1. حالة التحميل الأولي (بدون وجود بيانات قديمة)
    if ((isLoading || error.contains('جاري جلب')) && !hasData) {
      return _buildLoadingState(context);
    }

    return Column(
      children: [
        // 2. عرض رسالة الخطأ إذا فشل الاستعلام تماماً (لا توجد بيانات سابقة)
        if (error.isNotEmpty && !hasData)
          _buildErrorState(context)

        // 3. عرض النتائج (سواء كانت من الكاش أو من التحديث الناجح)
        else if (hasData)
          _buildResults(context, controller.billData.value!.data)

        // 4. عرض الحالة الفارغة (أول مرة)
        else
          _buildEmptyState(context),

        // 5. عرض تنبيه "فشل التحديث" إذا كان هناك بيانات قديمة ولكن الاستعلام الجديد فشل (مثل Rate Limit)
        if (error.isNotEmpty && hasData)
          _buildMiniErrorBanner(context, error),
      ],
    );
  }

  // ─── حالة التحميل ─────────────────────────
  Widget _buildLoadingState(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, val, child) {
            return Opacity(
              opacity: val,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 85,
                decoration: BoxDecoration(
                  color: cardColor(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: subTextColor(context).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              color: subTextColor(
                                context,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 14,
                            width: 70,
                            decoration: BoxDecoration(
                              color: subTextColor(
                                context,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );

            },

        ),
      ),
    );
  }

  // ─── حالة الخطأ ─────────────────────────────────────────
  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _errorColor.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: _errorColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.warning_2, color: _errorColor, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'للإستعلام عن الرصيد والباقة',
            style: TextStyle(
              color: textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor(context),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: controller.fetchBill,
              icon: const Icon(Iconsax.refresh, size: 20),
              label: const Text(
                'استعلام الآن',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── الحالة الفارغة ─────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.receipt_search,
              color: _primaryColor,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'للإستعلام عن الرصيد والباقة',
            style: TextStyle(
              color: textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'اسحب الشاشة للأسفل أو اضغط على زر استعلام في الاعلى لجلب تفاصيل فاتورتك بدقة وبشكل تلقائي.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor(context),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── النتائج ──────────────────────────────────────
  Widget _buildResults(BuildContext context, Map<String, String> data) {
    final entries = data.entries.where((e) => !e.key.contains('خارج الشبكة') && !e.key.contains('رقم الهاتف')).toList();
    final modifiedEntries = entries.map((e) {
      String newLabel = e.key;
      String newValue = e.value;
      if (newLabel.contains('الباقة')) {
        newLabel = newLabel.replaceAll('الباقة', 'الباقة الحالية');
      }
      if (newValue.contains('DATA_ONLY')) {
        newValue = newValue.replaceAll('DATA_ONLY', '');
      }
      if (newValue.contains('4G')) {
        newValue = newValue.replaceAll('4G', 'GB');
      }
      return MapEntry(newLabel, newValue);
    }).toList();
    return Column(
      children: List.generate(modifiedEntries.length, (i) {
        final entry = modifiedEntries[i];
        final config = _cardConfig(entry.key, i);
        return _buildAnimatedResultCard(
          context: context,
          index: i,
          label: entry.key,
          value: entry.value,
          icon: config.$1,
          color: config.$2,
        );
      }),
    );
  }

  // ─── كرت الرصيد المتوقع (يطفو ويحلّق) ───────
  Widget _buildExpectedBalanceCard(BuildContext context) {
    return Obx(() {
      // إزالة التحقق من billData.value == null للسماح بظهور الرصيد المتوقع المخزن مسبقاً
      final expectedBytes = controller.expectedBalanceBytes.value;
      final isReset = controller.isRouterResetDetected.value;

      if (expectedBytes == null && !isReset) return const SizedBox.shrink();

      if (isReset) {
        return _buildResetWarningCard(context);
      }

      // TweenAnimationBuilder لمعايرة وتأثيرات الأرقام
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: expectedBytes!.toDouble()),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        builder: (contextWidget, animatedValue, child) {
          final gb = animatedValue / (1024 * 1024 * 1024);
          final isLow = gb < 1.0;
          final color = isLow
              ? _errorColor
              : _primaryColor; // مطابقة اللون الرئيسي للوحة التحكم

          String displayVal;
          String unitVal;
          if (gb >= 1) {
            displayVal = gb.toStringAsFixed(2);
            unitVal = 'GB';
          } else {
            final mb = animatedValue / (1024 * 1024);
            displayVal = mb.toStringAsFixed(0);
            unitVal = 'MB';
          }

          return GlassCard(
            borderRadius: 32,
            padding: const EdgeInsets.all(26),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.flash_15, color: color, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الرصيد المتاح المتوقع',
                        style: TextStyle(
                          color: subTextColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            displayVal,
                            style: TextStyle(
                              color: textColor(context),
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            unitVal,
                            style: TextStyle(
                              color: color,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: isLow ? gb : 1.0,
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildResetWarningCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _errorColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _errorColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.info_circle,
              color: _errorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'تم اكتشاف إعادة تشغيل للمودم. يُرجى التحديث لتزامن الرصيد المتوقع بدقة.',
              style: TextStyle(
                color: textColor(context),
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── كرت المفردات المتحرك ───────────────────────────────────────
  Widget _buildAnimatedResultCard({
    required BuildContext context,
    required int index,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (contextWidget, val, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: Opacity(
            opacity: val,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: cardColor(context),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.withValues(
                    alpha: Get.isDarkMode ? 0.05 : 0.1,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: subTextColor(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          value,
                          style: TextStyle(
                            color: textColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── تنبيه الخطأ الصغير (عند وجود بيانات قديمة) ────────────────
  Widget _buildMiniErrorBanner(BuildContext context, String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _errorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: _errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _errorColor, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh, color: _errorColor, size: 18),
            onPressed: controller.fetchBill,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }


  // ─── خريطة الأيقونة واللون بناءً على مفتاح الحقل ────────────
  (IconData, Color) _cardConfig(String key, int index) {
    final k = key.toLowerCase();
    if (k.contains('بيانات') || k.contains('balance')) {
      return (Iconsax.chart_3, const Color(0xFF0EA5E9));
    }
    if (k.contains('باقة') || k.contains('package') || k.contains('plan')) {
      return (Iconsax.box_1, const Color(0xFFA855F7));
    }
    if (k.contains('تاريخ') || k.contains('date') || k.contains('انتهاء')) {
      return (Iconsax.calendar_1, const Color(0xFFEF4444));
    }
    if (k.contains('استهلاك') || k.contains('usage') || k.contains('data')) {
      return (Iconsax.data, const Color(0xFF0EA5E9));
    }
    if (k.contains('رقم') || k.contains('phone')) {
      return (Iconsax.simcard_1, const Color(0xFF3B82F6));
    }
    if (k.contains('المالي') || k.contains('status')) {
      return (Iconsax.wallet, const Color(0xFF22C55E));
    }

    final fallbackColors = [
      const Color(0xFF3B82F6),
      const Color(0xFFA855F7),
      const Color(0xFF22C55E),
      const Color(0xFFEF4444),
      const Color(0xFF0EA5E9),
    ];
    return (
      Iconsax.document_text,
      fallbackColors[index % fallbackColors.length],
    );
  }
}
