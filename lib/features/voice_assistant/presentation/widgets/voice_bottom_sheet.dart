import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui';

import '../controllers/voice_assistant_controller.dart';
import 'voice_waveform.dart';

class VoiceAssistantBottomSheet extends GetView<VoiceAssistantController> {
  const VoiceAssistantBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.97);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: bgColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── مقبض السحب ───
                const SizedBox(height: 12),
                Container(
                  width: 44, height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 4),
                // ─── المحتوى ───
                Obx(() {
                  final state = controller.currentState.value;
                  if (state == VoiceState.idle) {
                    return _CommandsGuide(
                      isDark: isDark,
                      controller: controller,
                    );
                  }
                  return _ActiveSessionView(
                    controller: controller,
                    isDark: isDark,
                    state: state,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// شاشة الأوامر الجاهزة (عند الخمول)
// ═══════════════════════════════════════════════════════════
class _CommandsGuide extends StatelessWidget {
  final bool isDark;
  final VoiceAssistantController controller;
  const _CommandsGuide({required this.isDark, required this.controller});

  static const _categories = [
    _CmdCategory(icon: Iconsax.cpu, color: Color(0xFF7367F0), title: 'الاستعلامات', cmds: [
      'كم جهاز متصل؟', 'ما اسم الأجهزة؟', 'قوة الإشارة؟', 'نسبة البطارية؟', 'كم سرعة النت؟', 'كم الرصيد المتبقي؟', 'كم استهلكت؟',
    ]),
    _CmdCategory(icon: Iconsax.shield_tick, color: Color(0xFFEA5455), title: 'الأمان', cmds: [
      'احظر جهاز', 'امنع الهاتف', 'فك الحظر', 'افتح شاشة الحظر',
    ]),
    _CmdCategory(icon: Iconsax.lovely, color: Color(0xFFFF9F43), title: 'الرقابة الأبوية', cmds: [
      'شغل الرقابة الأبوية', 'عطل الرقابة', 'افتح رقابة الأطفال', 'جدول وقت الجهاز',
    ]),
    _CmdCategory(icon: Iconsax.speedometer, color: Color(0xFF00CFE8), title: 'تحديد السرعة', cmds: [
      'حدد السرعة العامة', 'قيد سرعة جهاز معين', 'الغي تحديد السرعة', 'خفف سرعة الهاتف لـ 2 ميجا',
    ]),
    _CmdCategory(icon: Iconsax.chart_21, color: Color(0xFF28C76F), title: 'الاستهلاك', cmds: [
      'كم استهلكت من النت؟', 'حدد حجم الباقة بـ 20 جيجا', 'اضبط الحصة الشهرية',
    ]),
    _CmdCategory(icon: Iconsax.setting_2, color: Color(0xFFF72585), title: 'الواي فاي والإعدادات', cmds: [
      'غير باسورد الواي فاي', 'بدل اسم الشبكة', 'شغل الوضع الليلي', 'حول للوضع النهاري',
    ]),
    _CmdCategory(icon: Iconsax.routing, color: Color(0xFF3A86FF), title: 'التنقل', cmds: [
      'افتح الإعدادات', 'روح للرادار', 'خذني لفحص السرعة', 'انتقل للأجهزة المتصلة', 'افتح استهلاك البيانات', 'انتقل لتحديد السرعة', 'افتح الرقابة الأبوية', 'روح للرئيسية',
    ]),
    _CmdCategory(icon: Iconsax.refresh, color: Color(0xFFAB63FA), title: 'النظام', cmds: [
      'أعد تشغيل المودم', 'سجل الخروج', 'ريستارت الراوتر',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Column(children: [
        // ─── رأس الشاشة ───
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7367F0), Color(0xFF4776E6)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFF7367F0).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Iconsax.microphone, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('المساعد الصوتي', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('اضغط الزر وتكلم بأي من الأوامر التالية', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12)),
            ]),
          ]),
        ),

        // ─── شريط البحث التزييني ───
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
            ),
            child: Row(children: [
              Icon(Iconsax.microphone_2, size: 16, color: const Color(0xFF7367F0).withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Text('ماذا تريد أن تفعل؟', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 14)),
            ]),
          ),
        ),

        // ─── قائمة الأوامر ───
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: _categories.length,
            itemBuilder: (_, i) => _CategoryCard(cat: _categories[i], isDark: isDark),
          ),
        ),

        // ─── زر الميكروفون الرئيسي ───
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: GestureDetector(
            onTap: () => controller.startListening(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7367F0), Color(0xFF4776E6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7367F0).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.microphone, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'اضغط للتحدث',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CmdCategory {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> cmds;
  const _CmdCategory({required this.icon, required this.color, required this.title, required this.cmds});
}

class _CategoryCard extends StatefulWidget {
  final _CmdCategory cat;
  final bool isDark;
  const _CategoryCard({required this.cat, required this.isDark});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cat = widget.cat;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : cat.color.withValues(alpha: 0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);


    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _expanded ? cat.color.withValues(alpha: 0.3) : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04))),
      ),
      child: Column(children: [
        // ─── رأس القسم ───
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(cat.icon, color: cat.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(cat.title, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14))),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(Icons.expand_more_rounded, color: cat.color.withValues(alpha: 0.7)),
              ),
            ]),
          ),
        ),

        // ─── قائمة الأوامر ───
        SizeTransition(
          sizeFactor: _expandAnim,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: [
              Container(height: 1, color: cat.color.withValues(alpha: 0.15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: cat.cmds.map((cmd) => _CommandChip(text: cmd, color: cat.color, isDark: isDark)).toList(),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CommandChip extends StatefulWidget {
  final String text;
  final Color color;
  final bool isDark;
  const _CommandChip({required this.text, required this.color, required this.isDark});

  @override
  State<_CommandChip> createState() => _CommandChipState();
}

class _CommandChipState extends State<_CommandChip> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.93).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Iconsax.microphone_2, size: 11, color: widget.color.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(widget.text, style: TextStyle(color: widget.isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF1A1A2E), fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// عرض الجلسة النشطة (استماع / معالجة / نتيجة)
// ═══════════════════════════════════════════════════════════
class _ActiveSessionView extends StatelessWidget {
  final VoiceAssistantController controller;
  final bool isDark;
  final VoiceState state;
  const _ActiveSessionView({required this.controller, required this.isDark, required this.state});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ─── أيقونة الحالة ───
        _StateIndicator(state: state),
        const SizedBox(height: 24),

        // ─── النص المسموع ───
        Obx(() => controller.recognizedText.value.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(Iconsax.microphone, size: 16, color: const Color(0xFF7367F0).withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '"${controller.recognizedText.value}"',
                  style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 15, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                )),
              ]),
            )
          : state == VoiceState.listening
            ? Text('أنا أسمعك...', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 16, fontStyle: FontStyle.italic))
            : const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // ─── استجابة المساعد ───
        Obx(() => controller.assistantResponse.value.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradientForState(state),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _gradientForState(state).first.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Text(
                controller.assistantResponse.value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
                textAlign: TextAlign.center,
              ),
            )
          : const SizedBox.shrink(),
        ),

        // ─── أزرار التأكيد ───
        if (state == VoiceState.confirm) ...[
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ActionBtn(label: 'إلغاء', icon: Icons.close_rounded, color: Colors.grey, onTap: controller.cancelAction),
            _ActionBtn(label: 'تأكيد', icon: Icons.check_rounded, color: const Color(0xFF28C76F), onTap: controller.confirmAction),
          ]),
        ],

        const SizedBox(height: 20),

        // ─── اقتراحات سريعة ───
        if (state == VoiceState.listening) _QuickSuggestions(isDark: isDark),
      ]),
    );
  }

  List<Color> _gradientForState(VoiceState state) {
    switch (state) {
      case VoiceState.success: return [const Color(0xFF28C76F), const Color(0xFF00CFE8)];
      case VoiceState.error: return [const Color(0xFFEA5455), const Color(0xFFFF9F43)];
      case VoiceState.confirm: return [const Color(0xFFFF9F43), const Color(0xFFF72585)];
      default: return [const Color(0xFF7367F0), const Color(0xFF4776E6)];
    }
  }
}

class _StateIndicator extends StatefulWidget {
  final VoiceState state;
  const _StateIndicator({required this.state});

  @override
  State<_StateIndicator> createState() => _StateIndicatorState();
}

class _StateIndicatorState extends State<_StateIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulse = Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.state == VoiceState.listening) {
      return ScaleTransition(scale: _pulse, child: VoiceWaveform(isListening: true));
    }
    if (widget.state == VoiceState.processing) {
      return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: Color(0xFF7367F0), strokeWidth: 3)));
    }
    final icon = widget.state == VoiceState.success ? Iconsax.tick_circle
        : widget.state == VoiceState.error ? Iconsax.close_circle
        : widget.state == VoiceState.confirm ? Iconsax.warning_2
        : Iconsax.microphone;
    final color = widget.state == VoiceState.success ? const Color(0xFF28C76F)
        : widget.state == VoiceState.error ? const Color(0xFFEA5455)
        : widget.state == VoiceState.confirm ? const Color(0xFFFF9F43)
        : const Color(0xFF7367F0);
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12), border: Border.all(color: color.withValues(alpha: 0.3), width: 2)),
      child: Icon(icon, color: color, size: 32),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
    );
  }
}

class _QuickSuggestions extends StatelessWidget {
  final bool isDark;
  const _QuickSuggestions({required this.isDark});

  static const _suggestions = [
    'كم جهاز متصل؟', 'قوة الإشارة؟', 'كم الرصيد؟', 'شغل الرقابة', 'حدد السرعة', 'غير الباسورد', 'احظر جهاز', 'افتح الرادار',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('أمثلة سريعة:', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _suggestions.map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(s, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
        )).toList(),
      ),
    ]);
  }
}
