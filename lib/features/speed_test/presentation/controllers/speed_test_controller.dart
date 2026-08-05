import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/session_manager.dart';
import '../../infrastructure/data_sources/speed_test_data_source.dart';

class SpeedTestHistoryItem {
  final double download;
  final double upload;
  final DateTime timestamp;
  SpeedTestHistoryItem(this.download, this.upload, this.timestamp);
}

enum SpeedTestPhase { idle, ping, download, upload, done }

class SpeedTestController extends GetxController {
  final SpeedTestDataSource dataSource;
  SpeedTestController({required this.dataSource});
  var currentPhase = SpeedTestPhase.idle.obs;
  
  // Real-time speed for the gauge
  var currentSpeed = 0.0.obs;
  var progress = 0.0.obs;
  
  // Final or accumulated results
  var pingResult = 0.obs;
  var downloadResult = 0.0.obs;
  var uploadResult = 0.0.obs;
  // History for recent tests
  var history = <SpeedTestHistoryItem>[].obs;
  StreamSubscription? _downloadSub;
  StreamSubscription? _uploadSub;

  @override
  void onClose() {
    _cancelSubscriptions();
    super.onClose();
  }

  void _cancelSubscriptions() {
    _downloadSub?.cancel();
    _uploadSub?.cancel();
  }

  void stopTest() {
    _cancelSubscriptions();
    currentPhase.value = SpeedTestPhase.idle;
    progress.value = 0.0;
    currentSpeed.value = 0.0;
  }

  Future<void> startTest() async {
    if (currentPhase.value != SpeedTestPhase.idle && currentPhase.value != SpeedTestPhase.done) return;

    // التحقق من حالة التحذير
    final isDismissed = await SessionManager.isSpeedTestWarningDismissed();
    if (!isDismissed) {
      bool shouldStart = false;
      bool dontShowAgain = false;

      await Get.dialog(
        StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text('تنبيه هام', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'لا تستخدم هذه الميزة بشكل متكرر. عند إجراء الفحص، يتم استهلاك رصيد  من باقة البيانات الخاصة بك. يرجى استخدامه عند الضرورة فقط.',
                  style: TextStyle(height: 1.5),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => setState(() => dontShowAgain = !dontShowAgain),
                  child: Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (val) => setState(() => dontShowAgain = val ?? false),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      const Expanded(
                        child: Text(
                          'لا تظهر هذه الرسالة مستقبلاً',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  shouldStart = true;
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('فهمت، ابدأ الفحص', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      if (!shouldStart) return;
      if (dontShowAgain) {
        await SessionManager.setSpeedTestWarningDismissed();
      }
    }

    _cancelSubscriptions();
    
    // Reset Data
    pingResult.value = 0;
    downloadResult.value = 0.0;
    uploadResult.value = 0.0;
    currentSpeed.value = 0.0;
    progress.value = 0.0;
    
    // 1. PING PHASE
    currentPhase.value = SpeedTestPhase.ping;
    try {
      final p = await dataSource.measurePing();
      if (p <= 0) {
        throw Exception('فشل الاتصال بالخادم. يرجى التأكد من توفر الإنترنت.');
      }
      pingResult.value = p;
    } catch (e) {
        debugPrint(e.toString());
      Get.snackbar(
        'خطأ في الفحص',
        'تعذر الوصول إلى خوادم الفحص ($e). تأكد من جودة اتصالك بالإنترنت.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      stopTest();
      return;
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    // 2. DOWNLOAD PHASE
    currentPhase.value = SpeedTestPhase.download;
    progress.value = 0.0;
    
    final downCompleter = Completer<void>();
    bool downError = false;
    _downloadSub = dataSource.testDownloadSpeed().listen(
      (data) {
        if (data['error'] == true) {
          downError = true;
          downCompleter.complete();
          return;
        }
        currentSpeed.value = data['speed'];
        progress.value = data['progress'];
        downloadResult.value = data['speed'];
      },
      onDone: () => downCompleter.complete(),
      onError: (err) {
        downError = true;
        downCompleter.complete();
      },
    );
    await downCompleter.future;

    if (downError) {
      Get.snackbar(
        'خطأ في التنزيل',
        'حدث خطأ أثناء اختبار سرعة التنزيل.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      stopTest();
      return;
    }
    
    currentSpeed.value = 0.0;
    await Future.delayed(const Duration(milliseconds: 500));
    // 3. UPLOAD PHASE
    currentPhase.value = SpeedTestPhase.upload;
    progress.value = 0.0;
    
    final upCompleter = Completer<void>();
    bool upError = false;
    _uploadSub = dataSource.testUploadSpeed().listen(
      (data) {
        if (data['error'] == true) {
          upError = true;
          upCompleter.complete();
          return;
        }
        currentSpeed.value = data['speed'];
        progress.value = data['progress'];
        uploadResult.value = data['speed'];
      },
      onDone: () => upCompleter.complete(),
      onError: (err) {
        upError = true;
        upCompleter.complete();
      },
    );
    await upCompleter.future;

    if (upError) {
      Get.snackbar(
        'خطأ في الرفع',
        'حدث خطأ أثناء اختبار سرعة الرفع.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      stopTest();
      return;
    }

    // 4. DONE
    currentPhase.value = SpeedTestPhase.done;
    progress.value = 1.0;
    currentSpeed.value = 0.0; // Reset gauge
    
    // Save to history list
    history.insert(0, SpeedTestHistoryItem(downloadResult.value, uploadResult.value, DateTime.now()));
    if (history.length > 3) {
      history.removeLast();
    }
  }
}
