import 'package:flutter/material.dart';
import '../../domain/entities/quick_tools_state_entity.dart';

/// ويدجت عريضة (4x1) بتصميم الكبسولة (Wide Pill Widget) مطابقة 100% للصورة المرفقة
class WidgetPreviewBanner extends StatelessWidget {
  final QuickToolsStateEntity state;

  const WidgetPreviewBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF091122),
              Color(0xFF131D33),
            ],
          ),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: const Color(0xFF1A3358),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              blurRadius: 22,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(
              children: [
                // ─── 1. القسم الأيسر: 3 صفوف مدمجة مرتبة عمودياً ───
                Expanded(
                  flex: 9,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الصف 1: البطارية
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBatteryIndicator(state.batteryLevel),
                          const SizedBox(width: 6),
                          Text(
                            '${state.batteryLevel}%',
                            style: const TextStyle(
                              fontSize: 13,
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
                          const SizedBox(width: 6),
                          Text(
                            '4G ${state.signalBars}/5',
                            style: const TextStyle(
                              fontSize: 12,
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
                            size: 15,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${state.connectedDevicesCount} أجهزة',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── 2. القسم الأوسط: الرصيد المتوهج + الأيام + شريط تقدم صغير ───
                Expanded(
                  flex: 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // الرصيد
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            state.balanceUnit,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.balanceNumericValue,
                            style: const TextStyle(
                              fontSize: 38,
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
                                  blurRadius: 26,
                                ),
                                Shadow(
                                  color: Color(0xFF38BDF8),
                                  blurRadius: 40,
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
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // شريط التقدم المصغر المتوهج
                      Container(
                        width: 78,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A263B),
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
                                    blurRadius: 5,
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

                // ─── 3. القسم الأيمن: اسم المودم وزر التحديث والدائرة الزرقاء للواي فاي ───
                Expanded(
                  flex: 11,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // العنوان وزر التحديث
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: state.isConnected ? const Color(0xFF34D399) : const Color(0xFFEF4444),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (state.isConnected ? const Color(0xFF34D399) : const Color(0xFFEF4444))
                                          .withValues(alpha: 0.9),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'SAM4G',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // زر تحديث
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'تحديث',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.refresh_rounded,
                                size: 15,
                                color: Color(0xFF38BDF8),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      // زر الواي فاي الدائري الكبير المتوهج
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF14223E),
                          border: Border.all(
                            color: const Color(0xFF1E365E),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.wifi_rounded,
                            size: 24,
                            color: Color(0xFF38BDF8),
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

  Widget _buildBatteryIndicator(int level) {
    final fillWidth = ((level / 100.0) * 14.0).clamp(2.0, 14.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 9.5,
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
          height: 4,
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
        final height = 4.5 + (index * 2.0);
        return Container(
          width: 2.5,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 0.7),
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
}
