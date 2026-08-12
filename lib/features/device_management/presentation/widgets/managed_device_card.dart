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

      final dummyEntity = ConnectedDeviceEntity(mac: device.mac, ip: device.ip ?? '', name: device.name, type: device.type ?? '');
      final String displayName = connectedCtrl.getDisplayName(dummyEntity);
      final bool hasCustomName = connectedCtrl.customNames[device.mac.toUpperCase()] != null &&
              connectedCtrl.customNames[device.mac.toUpperCase()]!.isNotEmpty;

      return Dismissible(
        key: ValueKey('managed_${device.mac}'),
        direction: isMyDevice ? DismissDirection.none : DismissDirection.startToEnd,
        background: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: const Icon(Iconsax.slash, color: Colors.white, size: 30),
        ),
        secondaryBackground: const SizedBox.shrink(),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _showBlockConfirmDialog(context, connectedCtrl, displayName);
          }
          return false;
        },
        child: Container(
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (connectedCtrl.isBgMonitorEnabled.value)
                                GestureDetector(
                                  onTap: () {
                                    if (connectedCtrl.knownMacs.contains(device.mac)) {
                                      _showUntrustDialog(context, connectedCtrl, displayName);
                                    } else {
                                      _showTrustDialog(context, connectedCtrl, displayName);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
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
                                      size: 24,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                connectedCtrl.knownMacs.contains(device.mac)
                                    ? 'موثّق'
                                    : 'غير موثّق',
                                style: TextStyle(
                                  color: connectedCtrl.knownMacs.contains(device.mac)
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
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
                                  if (isMyDevice)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
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
                            GestureDetector(
                              onTap: () => _showRenameDialog(context, connectedCtrl, displayName, connectedCtrl.customNames[device.mac.toUpperCase()] ?? ''),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: glowColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Iconsax.edit, color: glowColor, size: 18),
                              ),
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
                        ),
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
    ),
  );
});
}

  void _showBlockConfirmDialog(BuildContext context, ConnectedDevicesController controller, String displayName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Text('تأكيد الحظر', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'حظر الجهاز ($displayName) سيؤدي إلى تطبيق القواعد وإعادة تشغيل بث الـ Wi-Fi تلقائياً.\n\nهل أنت متأكد؟',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.blockDevice(ConnectedDeviceEntity(mac: device.mac, ip: device.ip ?? '', name: device.name, type: device.type ?? ''));
            },
            child: const Text('نعم، احظر الجهاز', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTrustDialog(BuildContext context, ConnectedDevicesController controller, String displayName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF16213E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Iconsax.shield_tick, color: Colors.green, size: 35)),
            const SizedBox(height: 20),
            Text('توثيق الجهاز', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(displayName, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text('MAC: ${device.mac}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(height: 25),
            Text(
              'هل تعرف هذا الجهاز؟ إذا كنت تعرفه، أضفه للأجهزة الموثوقة. وإلا، يمكنك تجاهله.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Get.back(), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('تجاهل'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Get.back(); controller.trustDevice(device.mac); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), icon: const Icon(Iconsax.shield_tick, color: Colors.white, size: 18), label: const Text('وثّق الجهاز', style: TextStyle(color: Colors.white)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUntrustDialog(BuildContext context, ConnectedDevicesController controller, String displayName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF16213E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Iconsax.shield_cross, color: Colors.orangeAccent, size: 35)),
            const SizedBox(height: 20),
            Text('إلغاء توثيق الجهاز', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(displayName, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text('MAC: ${device.mac}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(height: 25),
            Text(
              'عند إلغاء التوثيق، سيصبح هذا الجهاز غير موثوق وسيتم تنبيهك عند اتصاله بالشبكة.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Get.back(), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('إلغاء'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Get.back(); controller.removeTrustedDevice(device.mac); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent.shade700, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), icon: const Icon(Iconsax.shield_cross, color: Colors.white, size: 18), label: const Text('إلغاء التوثيق', style: TextStyle(color: Colors.white)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ConnectedDevicesController controller, String displayName, String currentCustomName) {
    final nameCtrl = TextEditingController(text: currentCustomName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(left: 25, right: 25, top: 25, bottom: MediaQuery.of(context).viewInsets.bottom + 25),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF0D1321) : const Color(0xFFF3F4F6), borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Iconsax.tag, color: Color(0xFF3B82F6), size: 22)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تسمية الجهاز', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('MAC: ${device.mac}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              decoration: BoxDecoration(color: isDark ? const Color(0xFF16213E) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3))),
              child: TextField(
                controller: nameCtrl,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: device.name.isEmpty ? 'جهاز مجهول' : device.name,
                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 14),
                  labelText: 'الاسم المخصص',
                  labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
                  prefixIcon: const Icon(Iconsax.mobile, color: Color(0xFF3B82F6), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text('اترك الحقل فارغاً لحذف الاسم المخصص والعودة للاسم الافتراضي', style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12)),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Get.back(), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: const Text('إلغاء'))),
                const SizedBox(width: 15),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    icon: const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
                    label: const Text('حفظ الاسم', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      Get.back();
                      await controller.renameDevice(device.mac, nameCtrl.text);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
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
