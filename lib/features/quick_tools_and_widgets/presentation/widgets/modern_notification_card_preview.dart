import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/quick_tools_state_entity.dart';

/// بطاقة تحاكي بدقة متناهية تصميم Stitch لمشروع "Modern Notification Bar Redesign"
/// متكيفة مع ألوان وهوية تطبيق Linkary (Electric Blue #4A90E2, Mint-Cyan #50E3C2, Deep Navy #0A0E21)
class ModernNotificationCardPreview extends StatelessWidget {
  final QuickToolsStateEntity state;
  final VoidCallback? onRefresh;
  final VoidCallback? onBill;
  final VoidCallback? onReboot;

  const ModernNotificationCardPreview({
    super.key,
    required this.state,
    this.onRefresh,
    VoidCallback? onBill,
    VoidCallback? onBalance,
    this.onReboot,
  }) : onBill = onBill ?? onBalance;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        state.isConnected ? const Color(0xFF50E3C2) : const Color(0xFFEA5455);
    final statusText = state.isConnected ? 'متصل' : 'غير متصل';

    final updateTime = state.lastUpdated12h;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF16213E).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF4A90E2).withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header: Emblem, Title, Status, Clock & Actions ───
                Row(
                  children: [
                    // Emblem
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF243048), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.router_rounded,
                              size: 22,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF50E3C2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SAM',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0A0E21),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Title & Live Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'مودم SAM4G',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusColor.withValues(alpha: 0.8),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'آخر تحديث: $updateTime',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Utility controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGlassCircleBtn(Icons.settings_outlined),
                        const SizedBox(width: 6),
                        _buildGlassCircleBtn(Icons.keyboard_arrow_up_rounded),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ─── CARD 1: Data Quota & Balance (Featured Card) ───
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121927).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.bar_chart_rounded,
                                  size: 16,
                                  color: Color(0xFF50E3C2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'الرصيد المتبقي',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF50E3C2).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF50E3C2).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 10,
                                  color: Color(0xFF50E3C2),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  state.daysRemaining,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF50E3C2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Balance Numbers Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            state.balanceText.replaceAll(RegExp(r'[^\d.]'), ''),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'جيجابايت (GB)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF50E3C2),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            state.cleanPackageName.startsWith('من أصل')
                                ? state.cleanPackageName
                                : (state.cleanPackageName.startsWith('باقة')
                                    ? 'من أصل ${state.cleanPackageName}'
                                    : 'من أصل باقة ${state.cleanPackageName}'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Gradient Progress Bar (Linkary Blue to Mint-Cyan)
                      Container(
                        width: double.infinity,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF202A3C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: state.quotaProgressRatio, // Dynamic real quota fill factor
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF50E3C2).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ─── Metric Subgrid: 3 Tiles ───
                Row(
                  children: [
                    // Tile 1: Battery
                    Expanded(
                      child: _buildMetricTile(
                        label: 'البطارية',
                        topTrailing: state.isCharging
                            ? Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF59E0B),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFF59E0B),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              )
                            : null,
                        icon: state.isCharging
                            ? Icons.battery_charging_full_rounded
                            : Icons.battery_std_rounded,
                        iconColor: const Color(0xFF50E3C2),
                        value: '${state.batteryLevel}%',
                        subtitle: state.isCharging ? 'شحن سريع' : 'على البطارية',
                        subtitleColor: state.isCharging
                            ? const Color(0xFFF59E0B)
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tile 2: Signal
                    Expanded(
                      child: _buildMetricTile(
                        label: 'الإشارة',
                        topTrailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '4G LTE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF50E3C2),
                            ),
                          ),
                        ),
                        icon: Icons.signal_cellular_alt_rounded,
                        iconColor: const Color(0xFF50E3C2),
                        value: '${state.signalBars}/5',
                        subtitle: state.signalBars >= 4
                            ? 'ممتازة جداً'
                            : (state.signalBars >= 2 ? 'جيدة' : 'ضعيفة'),
                        subtitleColor: const Color(0xFF50E3C2),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tile 3: Devices
                    Expanded(
                      child: _buildMetricTile(
                        label: 'الأجهزة',
                        topTrailing: const Icon(
                          Icons.wifi_rounded,
                          size: 13,
                          color: Color(0xFF4A90E2),
                        ),
                        icon: Icons.devices_rounded,
                        iconColor: const Color(0xFFE2E8F0),
                        value: '${state.connectedDevicesCount}',
                        subtitle: 'مأمون WPA2',
                        subtitleColor: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ─── Footer Action Buttons ───
                Row(
                  children: [
                    // Action 1: Refresh
                    Expanded(
                      flex: 10,
                      child: _buildActionBtn(
                        label: 'تحديث',
                        icon: Icons.refresh_rounded,
                        bg: const Color(0xFF121927).withValues(alpha: 0.8),
                        border: Colors.white.withValues(alpha: 0.1),
                        textColor: const Color(0xFFE2E8F0),
                        iconColor: const Color(0xFF94A3B8),
                        onTap: onRefresh,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Action 2: Recharge (Primary Highlight Gradient)
                    Expanded(
                      flex: 11,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF50E3C2).withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: onBill,
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.credit_card_rounded,
                                        size: 16,
                                        color: Color(0xFF0A0E21),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'الرصيد',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0A0E21),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Action 3: Reboot
                    Expanded(
                      flex: 10,
                      child: _buildActionBtn(
                        label: 'إعادة تشغيل',
                        icon: Icons.power_settings_new_rounded,
                        bg: const Color(0xFF121927).withValues(alpha: 0.8),
                        border: const Color(0xFFEA5455).withValues(alpha: 0.25),
                        textColor: const Color(0xFFEA5455),
                        iconColor: const Color(0xFFEA5455),
                        onTap: onReboot,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCircleBtn(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFFCBD5E1)),
    );
  }

  Widget _buildMetricTile({
    required String label,
    Widget? topTrailing,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121927).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              ?topTrailing,
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: subtitleColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color textColor,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 14, color: iconColor),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
