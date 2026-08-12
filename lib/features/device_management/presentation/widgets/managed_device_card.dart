import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../connected_devices/domain/entities/connected_device_entity.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../models/managed_device.dart';
import 'package:get/get.dart';

class ManagedDeviceCard extends StatelessWidget {
  final ManagedDevice device;
  final VoidCallback onTap;

  const ManagedDeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardColor = isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white.withOpacity(0.7);
    final glowColor = const Color(0xFF3B82F6);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    final connectedCtrl = Get.find<ConnectedDevicesController>();
    return Obx(() {
      final bool isWifi = (device.type ?? '').toUpperCase() == 'WIFI';
      final bool isMyDevice = device.ip == connectedCtrl.myDeviceIp.value;
      final IconData connectionIcon = isWifi ? Iconsax.wifi : Iconsax.link;
      final Color connectionColor = isWifi ? Colors.green : Colors.blueAccent;

      // We can map ManagedDevice to ConnectedDeviceEntity for getDisplayName
      final dummyEntity = ConnectedDeviceEntity(mac: device.mac, ip: device.ip ?? '', name: device.name, type: device.type ?? '');
      final String displayName = connectedCtrl.getDisplayName(dummyEntity);
      final bool hasCustomName = connectedCtrl.customNames[device.mac.toUpperCase()] != null &&
              connectedCtrl.customNames[device.mac.toUpperCase()]!.isNotEmpty;

      return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // أيقونة الجهاز
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: isMyDevice
                                  ? glowColor.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.05),
                              shape: BoxShape.circle),
                          child: Icon(
                              isMyDevice ? Iconsax.mobile : Iconsax.monitor,
                              color: isMyDevice ? glowColor : subTextColor,
                              size: 26),
                        ),
                        const SizedBox(width: 15),

                        // معلومات الجهاز (الاسم، IP، MAC)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName.isEmpty ? 'جهاز مجهول' : displayName,
                                            style: TextStyle(
                                                color: textColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // ✏️ مؤشر الاسم المخصص
                                        if (hasCustomName)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: Icon(Iconsax.edit_2,
                                                color: glowColor.withValues(alpha: 0.7), size: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (connectedCtrl.isBgMonitorEnabled.value)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: connectedCtrl.knownMacs.contains(device.mac)
                                            ? Colors.green.withValues(alpha: 0.15)
                                            : Colors.redAccent.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: connectedCtrl.knownMacs.contains(device.mac)
                                              ? Colors.green.withValues(alpha: 0.4)
                                              : Colors.redAccent.withValues(alpha: 0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        connectedCtrl.knownMacs.contains(device.mac)
                                            ? Iconsax.shield_tick
                                            : Iconsax.shield_cross,
                                        color: connectedCtrl.knownMacs.contains(device.mac)
                                            ? Colors.green
                                            : Colors.redAccent,
                                        size: 16,
                                      ),
                                    ),
                                  if (isMyDevice)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: glowColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Text('جهازي',
                                          style: TextStyle(
                                              color: glowColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('IP: ${device.ip ?? 'غير متوفر'}',
                                  style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 12,
                                      fontFamily: 'monospace')),
                              const SizedBox(height: 2),
                              Text('MAC: ${device.mac}',
                                  style: TextStyle(
                                      color: subTextColor.withValues(alpha: 0.6),
                                      fontSize: 10,
                                      fontFamily: 'monospace')),
                            ],
                          ),
                        ),

                        // أيقونة نوع الاتصال
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Iconsax.arrow_left_2, size: 16, color: subTextColor),
                            ),
                            const SizedBox(height: 8),
                            Icon(connectionIcon, color: connectionColor, size: 16),
                            const SizedBox(height: 2),
                            Text(
                              (device.type ?? '').toUpperCase(),
                              style: TextStyle(
                                  color: connectionColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBadge(
                          context,
                          icon: Iconsax.clock,
                          isActive: device.hasParentalRule,
                          color: Colors.purpleAccent,
                          label: device.hasParentalRule ? 'مُقيد' : '--',
                        ),
                        _buildBadge(
                          context,
                          icon: Icons.speed,
                          isActive: device.hasSpeedRule,
                          color: Colors.orangeAccent,
                          label: device.hasSpeedRule
                              ? '↓${device.speedRule!.dlSpeed} ↑${device.speedRule!.upSpeed}'
                              : '--',
                        ),
                        _buildBadge(
                          context,
                          icon: Iconsax.data,
                          isActive: device.hasDataLimit,
                          color: Colors.greenAccent,
                          label: device.hasDataLimit ? 'مُقيد' : '--',
                        ),
                      ],
                    ),
                    if (device.hasDataLimit) _buildDataProgressBar(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    });
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required bool isActive,
    required Color color,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = color.withOpacity(0.15);
    final inactiveBg = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);
    final activeColor = color;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataProgressBar(BuildContext context) {
    if (device.dataLimit == null) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final used = device.dataLimit!.currentUsageBytes;
    final total = device.dataLimit!.quotaBytes;
    final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    
    final progressColor = progress > 0.9 ? Colors.redAccent : progress > 0.7 ? Colors.orangeAccent : Colors.greenAccent;
    final bg = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('استهلاك الباقة', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('${_formatBytes(used)} / ${_formatBytes(total)}', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: bg,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    } else {
      return '$bytes B';
    }
  }
}
