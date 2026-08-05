import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../controllers/app_monitor_controller.dart';

class LiveSpeedIndicator extends StatelessWidget {
  final AppMonitorController controller;

  const LiveSpeedIndicator({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF111827);
    final cardBg = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF16213E) 
        : const Color(0xFFE5E7EB);

    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSpeedItem(
            context,
            Iconsax.arrow_down,
            const Color(0xFF00D2FF),
            controller.formatSpeed(controller.totalRxSpeed.value),
            text,
            cardBg,
          ),
          const SizedBox(width: 20),
          Container(
            width: 1,
            height: 20,
            color: text.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 20),
          _buildSpeedItem(
            context,
            Iconsax.arrow_up_1,
            const Color(0xFF00FF87),
            controller.formatSpeed(controller.totalTxSpeed.value),
            text,
            cardBg,
          ),
        ],
      );
    });
  }

  Widget _buildSpeedItem(
    BuildContext context, 
    IconData icon, 
    Color color, 
    String speed,
    Color text,
    Color cardBg,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          speed,
          style: TextStyle(
            color: text,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
