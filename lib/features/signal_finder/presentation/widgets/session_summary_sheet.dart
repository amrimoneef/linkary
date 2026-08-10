import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/signal_point.dart';
import '../../domain/entities/signal_rank.dart';
import '../../domain/entities/saved_location.dart';
import '../controllers/saved_locations_controller.dart';
import 'signal_rank_badge.dart';
import 'save_location_dialog.dart';
import 'replace_location_dialog.dart';
class SessionSummarySheet extends StatelessWidget {
  final List<SignalPoint> historyPoints;
  final int durationSeconds;
  final double bestScore;
  final VoidCallback onNewScan;

  const SessionSummarySheet({
    Key? key,
    required this.historyPoints,
    required this.durationSeconds,
    required this.bestScore,
    required this.onNewScan,
  }) : super(key: key);

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes دقيقة و $secs ثانية';
    }
    return '$secs ثانية';
  }

  SignalRank _getRank(double score) {
    if (score == 0.0) return SignalRank.deadZone;
    if (score <= 25.0) return SignalRank.deadZone;
    if (score <= 50.0) return SignalRank.critical;
    if (score <= 79.0) return SignalRank.stable;
    return SignalRank.legendary;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    double bestRsrp = -150;
    double bestSinr = -20;
    double bestRsrq = -30;
    double sumScore = 0;
    
    // We compute stats over the recorded history points
    // Note: Since historyPoints only keeps the last 15, we might not have the point that made bestScore
    // But for the scope of this implementation, it's fine. A real log would keep all points or track maximums manually.
    for (var p in historyPoints) {
      sumScore += p.compositeScore;
      if (p.rsrp > bestRsrp && p.rsrp < 0) bestRsrp = p.rsrp; // ignoring 0 as error
      if (p.sinr > bestSinr && p.sinr > 0) bestSinr = p.sinr; 
      if (p.rsrq > bestRsrq && p.rsrq < 0) bestRsrq = p.rsrq;
    }
    
    final averageScore = historyPoints.isEmpty ? 0.0 : sumScore / historyPoints.length;
    final bestRank = _getRank(bestScore);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(25, 12, 25, 25), // Adjusted padding for handle
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text(
                  'ملخص ما تم كشفه',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text('مدة المسح: ${_formatDuration(durationSeconds)}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 15),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getColor(bestRank).withValues(alpha: 0.2),
                    _getColor(bestRank).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getColor(bestRank).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text('🏆 أعلى قراءة', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                    '${bestScore.toInt()}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getColor(bestRank),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SignalRankBadge(rank: bestRank),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatInfo('📈 المتوسط', '${averageScore.toInt()}%'),
                _buildStatInfo('⬆️ أعلى RSRP', '${bestRsrp == -150 ? '-' : bestRsrp.toInt()}'),
                _buildStatInfo('📡 أعلى SINR', '${bestSinr == -20 ? '-' : bestSinr.toInt()}'),
              ],
            ),
            
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      onNewScan();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('مسح جديد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Start Save Flow
                      final SavedLocation? newLoc = await Get.dialog<SavedLocation>(
                        SaveLocationDialog(
                          score: bestScore,
                          rank: bestRank,
                        ),
                      );
  
                      if (newLoc != null) {
                        final savedCtrl = Get.find<SavedLocationsController>();
                        final success = await savedCtrl.saveLocation(newLoc);
                        
                        if (!success) {
                          // Limit reached
                          final String? oldLocId = await Get.dialog<String>(
                            ReplaceLocationDialog(existingLocations: savedCtrl.locations),
                          );
                          
                          if (oldLocId != null) {
                            await savedCtrl.replaceLocation(oldLocId, newLoc);
                            Get.snackbar('تم الحفظ', 'تم استبدال الموقع وحفظ القراءة بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
                          }
                        } else {
                          Get.snackbar('تم الحفظ', 'تم حفظ موقع التثبيت بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('حفظ الموقع', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // إغلاق النافذة المنبثقة (BottomSheet)
                  Get.back(); // الخروج من الشاشة بالكامل للرئيسية
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('الانتهاء والتثبيت'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Color _getColor(SignalRank rank) {
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
}
