import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/managed_device.dart';

class ManagedDeviceCard extends StatelessWidget {
  final ManagedDevice device;
  final VoidCallback onTap;

  const ManagedDeviceCard({
    Key? key,
    required this.device,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    device.type == 'WIFI' ? Iconsax.wifi : Iconsax.monitor,
                    color: isDark ? Colors.white54 : Colors.black54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      device.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'MAC: ${device.mac}',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBadge(
                    context,
                    icon: Iconsax.clock,
                    isActive: device.hasParentalRule,
                    color: Colors.amber,
                    label: device.hasParentalRule ? 'مُقيد' : '--',
                  ),
                  _buildBadge(
                    context,
                    icon: Iconsax.speedometer,
                    isActive: device.hasSpeedRule,
                    color: Colors.teal,
                    label: device.hasSpeedRule
                        ? '↓${device.speedRule!.dlSpeed} ↑${device.speedRule!.upSpeed}'
                        : '--',
                  ),
                  _buildBadge(
                    context,
                    icon: Iconsax.box,
                    isActive: device.hasDataLimit,
                    color: Colors.purple,
                    label: device.hasDataLimit
                        ? _formatBytes(device.dataLimit!.quotaBytes)
                        : '--',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
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
