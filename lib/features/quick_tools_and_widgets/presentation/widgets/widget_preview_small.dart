import 'package:flutter/material.dart';
import '../../domain/entities/quick_tools_state_entity.dart';

/// ويدجت مربعة (2x2) متطابقة 100% مع الصورة المرفقة دون أي اختلاف مع التوهج الاحترافي
class WidgetPreviewSmall extends StatelessWidget {
  final QuickToolsStateEntity state;

  const WidgetPreviewSmall({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 270,
        height: 275,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0C1424),
              Color(0xFF080D1A),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFF1B3252),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
              blurRadius: 28,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // إضاءة محيطية علوية ناعمة (Ambient Top Glow)
              Positioned(
                top: -50,
                left: 0,
                right: 0,
                height: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.85,
                      colors: [
                        const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ─── 1. Header: كبسولة الحالة (يسار) + SAM4G وشارة المودم (يمين) ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // كبسولة الحالة: متصل مع النقطة الخضراء المتوهجة
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2520),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF1B4E3B),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.isConnected ? 'متصل' : 'غير متصل',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: state.isConnected ? const Color(0xFF34D399) : const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: state.isConnected ? const Color(0xFF34D399) : const Color(0xFFEF4444),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (state.isConnected ? const Color(0xFF34D399) : const Color(0xFFEF4444))
                                          .withValues(alpha: 0.9),
                                      blurRadius: 7,
                                      spreadRadius: 1.5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // اسم المودم + أيقونة المودم المربعة ذات الراوتر المزدوج
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'SAM4G',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF132037),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF1D3557),
                                  width: 1.2,
                                ),
                              ),
                              child: const Center(
                                child: _DualModemIcon(
                                  size: 19,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ─── 2. Hero Center: الرصيد المتوهج + الأيام المتبقية + شريط التقدم ───
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الرصيد مع التوهج النيوني الاحترافي
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              state.balanceUnit,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.balanceNumericValue,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF67E8F9),
                                letterSpacing: -1.0,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF38BDF8),
                                    blurRadius: 18,
                                  ),
                                  Shadow(
                                    color: Color(0xFF50E3C2),
                                    blurRadius: 32,
                                  ),
                                  Shadow(
                                    color: Color(0xFF38BDF8),
                                    blurRadius: 50,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // الأيام المتبقية
                        Text(
                          state.daysRemaining,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // شريط التقدم النحيف والمتوهج
                        Container(
                          height: 5,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF182337),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: state.quotaProgressRatio,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF38BDF8),
                                      Color(0xFF50E3C2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ملخص الاستهلاك والإجمالي (مطابق تماماً لمواضع الصورة)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${state.accumulatedUsageText} :الإجمالي',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${state.currentSessionUsageText} :المستهلك',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ─── 3. Footer: شريط المقاييس العائم ───
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10192A),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: const Color(0xFF1A2B44),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. الأجهزة المتصلة (يسار)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${state.connectedDevicesCount} أجهزة',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.desktop_windows_outlined,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),

                          // 2. إشارة الشبكة 4G مع الأعمدة المتوهجة (وسط)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '4G',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              const SizedBox(width: 5),
                              _buildSignalBars(state.signalBars),
                            ],
                          ),

                          // 3. البطارية ونسبتها (يمين)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${state.batteryLevel}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              _buildBatteryIndicator(state.batteryLevel, state.isCharging),
                            ],
                          ),
                        ],
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
  }

  /// أعمدة الإشارة الخمسة المتوهجة
  Widget _buildSignalBars(int bars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (index) {
        final isActive = index < bars;
        final height = 6.0 + (index * 2.2);
        return Container(
          width: 3.0,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 0.9),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(1),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  /// أيقونة بطارية أفقية مع تعبئة داخلية خضراء متوهجة
  Widget _buildBatteryIndicator(int level, bool isCharging) {
    final fillWidth = ((level / 100.0) * 15.0).clamp(2.0, 15.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 10,
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: const Color(0xFF10B981),
              width: 1.2,
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: fillWidth,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399),
                borderRadius: BorderRadius.circular(1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 2,
          height: 4.5,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(1.5),
              bottomRight: Radius.circular(1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// رسم احترافي لأيقونة المودم المزدوج (Dual-layer Modem) المطابقة للصورة
class _DualModemIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _DualModemIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.8),
      painter: _DualModemPainter(color: color),
    );
  }
}

class _DualModemPainter extends CustomPainter {
  final Color color;

  _DualModemPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final unitHeight = (size.height - 3) / 2;

    // الراوتر العلوي
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, unitHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(topRect, strokePaint);
    canvas.drawCircle(Offset(size.width - 4, unitHeight / 2), 1.2, dotPaint);

    // الراوتر السفلي
    final bottomRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, unitHeight + 3, size.width, unitHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(bottomRect, strokePaint);
    canvas.drawCircle(Offset(size.width - 4, unitHeight + 3 + (unitHeight / 2)), 1.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
