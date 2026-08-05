import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/entities/signal_rank.dart';

class ReplaceLocationDialog extends StatelessWidget {
  final List<SavedLocation> existingLocations;

  const ReplaceLocationDialog({
    Key? key,
    required this.existingLocations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF070B19) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF070B19).withValues(alpha: 0.8) 
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blueAccent.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Non-scrollable)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.warning_2, color: Colors.amber, size: 24),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'الحد الأقصى للمواقع',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  'لقد وصلت للحد الأقصى (10 مواقع). الرجاء اختيار موقع قديم لاستبداله بالموقع الجديد:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Scrollable List
                Flexible(
                  child: ListView.builder(
                    itemCount: existingLocations.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final loc = existingLocations[index];
                      return _buildLocationItem(context, loc, isDark);
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Footer Button (Non-scrollable)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
                      ),
                    ),
                    child: const Text('إلغاء الحفظ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationItem(BuildContext context, SavedLocation loc, bool isDark) {
    final rankColor = _getRankColor(loc.rank);
    final rankText = _getRankText(loc.rank);

    return InkWell(
      onTap: () => Get.back(result: loc.id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: rankColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Score Circle
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loc.score / 100,
                    strokeWidth: 4,
                    backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                  ),
                  Text(
                    '${loc.score.toInt()}%',
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        rankText,
                        style: TextStyle(color: rankColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' • ${DateFormat('dd MMM, hh:mm a', 'ar').format(loc.timestamp)}',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_left_2,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(SignalRank rank) {
    switch (rank) {
      case SignalRank.deadZone:
        return Colors.redAccent;
      case SignalRank.critical:
        return Colors.orangeAccent;
      case SignalRank.stable:
        return Colors.blueAccent;
      case SignalRank.legendary:
        return Colors.greenAccent;
    }
  }

  String _getRankText(SignalRank rank) {
    switch (rank) {
      case SignalRank.deadZone: return 'ضعيف جداً';
      case SignalRank.critical: return 'مقبول';
      case SignalRank.stable: return 'جيد جداً';
      case SignalRank.legendary: return 'ممتاز';
    }
  }
}

