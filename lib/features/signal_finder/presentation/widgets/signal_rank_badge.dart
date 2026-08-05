import 'package:flutter/material.dart';
import '../../domain/entities/signal_rank.dart';

class SignalRankBadge extends StatelessWidget {
  final SignalRank rank;

  const SignalRankBadge({Key? key, required this.rank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<SignalRank, _BadgeInfo> badgeData = {
      SignalRank.deadZone: _BadgeInfo(
        text: 'منطقة ميتة (Dead Zone)',
        icon: Icons.error_outline,
        color: Colors.redAccent,
      ),
      SignalRank.critical: _BadgeInfo(
        text: 'تغطية حرجة (Critical)',
        icon: Icons.warning_amber_rounded,
        color: Colors.orangeAccent,
      ),
      SignalRank.stable: _BadgeInfo(
        text: 'نقطة جيدة (Stable)',
        icon: Icons.check_circle_outline,
        color: Colors.blueAccent,
      ),
      SignalRank.legendary: _BadgeInfo(
        text: 'النقطة الأسطورية! (Legendary)',
        icon: Icons.star_rounded,
        color: Colors.greenAccent,
      ),
    };

    final info = badgeData[rank]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: info.color.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: info.color.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, color: info.color, size: 20),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              info.text,
              key: ValueKey(info.text),
              style: TextStyle(
                color: info.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (rank == SignalRank.legendary) ...[
            const SizedBox(width: 5),
            const Text('👑', style: TextStyle(fontSize: 18)),
          ]
        ],
      ),
    );
  }
}

class _BadgeInfo {
  final String text;
  final IconData icon;
  final Color color;

  _BadgeInfo({
    required this.text,
    required this.icon,
    required this.color,
  });
}
