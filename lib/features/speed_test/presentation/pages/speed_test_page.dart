import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/speed_test_controller.dart';
import '../widgets/speedometer_gauge.dart';

class SpeedTestPage extends StatelessWidget {
  const SpeedTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SpeedTestController>();

    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      appBar: AppBar(
        title: const Text('فحص السرعة', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Image.asset(
              Get.isDarkMode ? 'assets/images/الشعار ابيض.png' : 'assets/images/الشعار اسود.png',
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Obx(() {
        final phase = controller.currentPhase.value;
        final glowColor = phase == SpeedTestPhase.download 
            ? Colors.blueAccent
            : (phase == SpeedTestPhase.upload ? Colors.greenAccent : Colors.white);
            
        return Stack(
          children: [
            // Ambient Background
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      glowColor.withValues(alpha: 0.1),
                      const Color(0xFF070B19),
                    ],
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // GAUGE
                  SpeedometerGauge(
                    speed: controller.currentSpeed.value,
                    phaseText: _getPhaseText(phase),
                    glowColor: glowColor,
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // RESULTS CARDS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: _buildResultCard('تنزيل', '${controller.downloadResult.value.toStringAsFixed(1)} Mbps', Iconsax.arrow_down_2, Colors.blueAccent)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildResultCard('رفع', '${controller.uploadResult.value.toStringAsFixed(1)} Mbps', Iconsax.arrow_up_1, Colors.greenAccent)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // تاريخ الفحوصات (HISTORY)
                  if (controller.history.isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Iconsax.clock, color: Colors.white54, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'أحدث النتائج (لآخر 3 فحوصات)',
                                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                itemCount: controller.history.length,
                                itemBuilder: (context, index) {
                                  final item = controller.history[index];
                                  final hour = item.timestamp.hour;
                                  final minute = item.timestamp.minute;
                                  final period = hour >= 12 ? 'م' : 'ص';
                                  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
                                  final timeStr = '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // الوقت
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            timeStr, 
                                            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        
                                        // التنزيل
                                        Row(
                                          children: [
                                            const Icon(Iconsax.arrow_down_2, color: Colors.greenAccent, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${item.download.toStringAsFixed(1)} Mbps', 
                                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        
                                        // الرفع
                                        Row(
                                          children: [
                                            const Icon(Iconsax.arrow_up_1, color: Colors.blueAccent, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${item.upload.toStringAsFixed(1)} Mbps', 
                                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  
                  // ACTION BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          if (phase == SpeedTestPhase.idle || phase == SpeedTestPhase.done) {
                            controller.startTest();
                          } else {
                            controller.stopTest();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (phase == SpeedTestPhase.idle || phase == SpeedTestPhase.done)
                              ? Colors.blueAccent
                              : Colors.redAccent.withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          (phase == SpeedTestPhase.idle || phase == SpeedTestPhase.done) ? 'بدء الفحص' : 'إيقاف',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _getPhaseText(SpeedTestPhase phase) {
    switch (phase) {
      case SpeedTestPhase.idle:
        return 'جاهز للبدء';
      case SpeedTestPhase.ping:
        return 'جاري الاتصال...';
      case SpeedTestPhase.download:
        return 'اختبار التنزيل';
      case SpeedTestPhase.upload:
        return 'اختبار الرفع';
      case SpeedTestPhase.done:
        return 'اكتمل الفحص';
    }
  }

  Widget _buildResultCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
