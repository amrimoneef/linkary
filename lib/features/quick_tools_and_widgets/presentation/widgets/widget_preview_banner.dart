import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/quick_tools_state_entity.dart';

/// ويدجت عريضة (4x1) بتصميم الكبسولة الزجاجية الفاخرة (Frosted Glass Pill Widget)
class WidgetPreviewBanner extends StatelessWidget {
  final QuickToolsStateEntity state;

  const WidgetPreviewBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            height: 105,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.50),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.10),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // ─── 1. القسم الأيسر: 3 صفوف مدمجة (البطارية، الإشارة، الأجهزة) ───
                  Expanded(
                    flex: 9,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الصف 1: البطارية
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBatteryIndicator(state.batteryLevel),
                              const SizedBox(width: 5),
                              Text(
                                '${state.batteryLevel}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF8FAFC),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),

                          // الصف 2: الإشارة 4G 5/5
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSignalBars(state.signalBars),
                              const SizedBox(width: 5),
                              Text(
                                '4G ${state.signalBars}/5',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),

                          // الصف 3: الأجهزة المتصلة
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.desktop_windows_outlined,
                                size: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${state.connectedDevicesCount} أجهزة',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── 2. القسم الأوسط: الرصيد المتوهج + الأيام + شريط التقدم ───
                  Expanded(
                    flex: 10,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // الرصيد
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                state.balanceUnit,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                state.balanceNumericValue,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF67E8F9),
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFF38BDF8),
                                      blurRadius: 14,
                                    ),
                                    Shadow(
                                      color: Color(0xFF50E3C2),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // الأيام المتبقية
                          Text(
                            state.daysRemaining,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // شريط التقدم المصغر المتوهج
                          Container(
                            width: 72,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2),
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
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── 3. القسم الأيمن: العنوان + التحديث + زر الواي فاي الدائري الزجاجي ───
                  Expanded(
                    flex: 11,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // العنوان ونقطة الحالة الخضراء
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6.5,
                                    height: 6.5,
                                    decoration: BoxDecoration(
                                      color: state.isConnected
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (state.isConnected
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444))
                                              .withValues(alpha: 0.8),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'SAM4G',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),

                              // زر التحديث
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'تحديث',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 11,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(width: 8),

                          // زر الواي فاي الدائري بتصميم زجاجي فاخر
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.wifi_rounded,
                                color: Color(0xFF38BDF8),
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryIndicator(int level) {
    final fillWidth = ((level / 100.0) * 14.0).clamp(2.0, 14.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 17,
          height: 9,
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.5),
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
                borderRadius: BorderRadius.circular(1),
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
          width: 1.5,
          height: 3.5,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(1),
              bottomRight: Radius.circular(1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalBars(int bars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (index) {
        final isActive = index < bars;
        final height = 4.0 + (index * 1.8);
        return Container(
          width: 2.2,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 0.6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.15),
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
}
