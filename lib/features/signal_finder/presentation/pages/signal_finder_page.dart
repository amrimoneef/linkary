import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/signal_finder_controller.dart';
import '../../domain/entities/signal_rank.dart';
import '../widgets/composite_score_gauge.dart';
import '../widgets/guidance_message_card.dart';
import '../widgets/live_ekg_graph.dart';
import '../widgets/metrics_mini_row.dart';
import '../widgets/session_summary_sheet.dart';
import '../widgets/signal_rank_badge.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'saved_locations_page.dart';


class SignalFinderPage extends StatefulWidget {
  const SignalFinderPage({Key? key}) : super(key: key);

  @override
  State<SignalFinderPage> createState() => _SignalFinderPageState();
}

class _SignalFinderPageState extends State<SignalFinderPage> with WidgetsBindingObserver {
  final SignalFinderController controller = Get.find<SignalFinderController>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // تأكيد إيقاف المسح والاهتزاز عند الخروج من الشاشة
    if (controller.isScanning.value) {
      controller.stopScanning();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // إيقاف الرادار في حال تصغير التطبيق أو ظهوره في الخلفية
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.hidden) {
      if (controller.isScanning.value) {
        controller.stopScanning();
      }
    }
  }

  Future<void> _checkTutorial() async {
    final hideTutorial = await _storage.read(key: 'hide_signal_finder_tutorial');
    if (hideTutorial == 'true') {
      controller.startScanning();
    } else {
      _showTutorialDialog();
    }
  }

  void _showTutorialDialog() {
    bool dontShowAgain = false;

    Get.dialog(
      StatefulBuilder(builder: (context, setState) {
        return Dialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.radar, color: Colors.amberAccent, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'كيف تستخدم الرادار؟',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  '1. احمل الهاتف ومودم Sam4G وتجول ببطء في أرجاء المكان.\n\n'
                  '2. استمع لاهتزازات الهاتف (مثل كاشف المعادن)، فكلما اقتربت من نقطة بث قوية زادت سرعة النبضات.\n\n'
                  '3. للحصول على أفضل تغطية للمنزل، ابحث عن أقوى نقطة ممكنة لتضع المودم فيها.',
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: dontShowAgain,
                        onChanged: (val) {
                          setState(() => dontShowAgain = val ?? false);
                        },
                        checkColor: Colors.black,
                        activeColor: Colors.amberAccent,
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'لا تظهر هذه الرسالة مستقبلاً',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (dontShowAgain) {
                        await _storage.write(key: 'hide_signal_finder_tutorial', value: 'true');
                      } else {
                        await _storage.delete(key: 'hide_signal_finder_tutorial');
                      }
                      Get.back();
                      if (!controller.isScanning.value && controller.historyPoints.isEmpty) {
                        controller.startScanning();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('فهمت، ابدأ المسح!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        );
      }),
      barrierDismissible: false, // يجب أن يضغط فهمت ليغلق
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19), // Force dark mode aesthetic
      appBar: AppBar(
        title: const Text('رادار Sam4G', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.place, color: Colors.greenAccent),
            tooltip: 'المواقع المحفوظة',
            onPressed: () {
               if (controller.isScanning.value) {
                 controller.stopScanning();
               }
               Get.to(() => const SavedLocationsPage());
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.amberAccent),
            onPressed: () {
              // Pause scanning if active while they read
              if (controller.isScanning.value) {
                 controller.stopScanning();
              }
              _showTutorialDialog();
            },
            tooltip: 'كيفية الاستخدام',
          ),
          Obx(() => IconButton(
            icon: Icon(
              controller.isHapticsEnabled.value ? Icons.vibration : Icons.mobile_off,
              color: controller.isHapticsEnabled.value ? Colors.blueAccent : Colors.grey,
            ),
            onPressed: controller.toggleHaptics,
            tooltip: 'تبديل كاشف المعادن (الاهتزاز)',
          )),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Obx(() {
        final currentColor = _getRankColor(controller.currentRank.value);
        
        return Stack(
          children: [
            // Ambient Background Glow
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      currentColor.withValues(alpha: 0.15),
                      const Color(0xFF070B19),
                    ],
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          
                          // Central Score Gauge
                          CompositeScoreGauge(
                            score: controller.compositeScore.value,
                            baseColor: currentColor,
                          ),
                          const SizedBox(height: 5),

                          // Best Score Indicator
                          if (controller.bestScore.value > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'أعلى قراءة: ${controller.bestScore.value.toInt()}%',
                                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          
                          // Rank Badge
                          SignalRankBadge(rank: controller.currentRank.value),
                          
                          const SizedBox(height: 30),
                          
                          // Guidance Message
                          GuidanceMessageCard(message: controller.guidanceMessage.value),
                          
                          const SizedBox(height: 20),

                          // Live EKG Graph
                          LiveEkgGraph(
                            points: controller.historyPoints.toList(),
                            currentScore: controller.compositeScore.value,
                          ),
                          const SizedBox(height: 20),

                          // Mini Metrics Row
                          MetricsMiniRow(
                            rawRsrp: controller.rawRsrp.value,
                            rawSinr: controller.rawSinr.value,
                            rawRsrq: controller.rawRsrq.value,
                            normRsrp: controller.normalizedRsrp.value,
                            normSinr: controller.normalizedSinr.value,
                            normRsrq: controller.normalizedRsrq.value,
                          ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  // Control Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (controller.isScanning.value) {
                            controller.stopScanning();
                            _showSummarySheet(context);
                          } else {
                            controller.startScanning();
                          }
                        },
                        icon: Icon(controller.isScanning.value ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          controller.isScanning.value ? 'إيقاف المسح' : 'بدء المسح',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.isScanning.value ? Colors.redAccent.withValues(alpha: 0.8) : Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showSummarySheet(BuildContext context) {
    Get.bottomSheet(
      SessionSummarySheet(
        historyPoints: controller.historyPoints.toList(),
        durationSeconds: controller.sessionDuration.value,
        bestScore: controller.bestScore.value,
        onNewScan: () {
          controller.startScanning();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
