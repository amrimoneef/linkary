import 'dart:async';
import 'package:vibration/vibration.dart';

class HapticFeedbackService {
  Timer? _pulseTimer;
  double _lastScore = 0;
  bool _isActive = false;

  /// بدء نظام الاهتزاز النابض
  void startPulsing(double score) {
    _lastScore = score;
    _isActive = true;
    _schedulePulse();
  }

  /// تحديث النبضات بقيمة جديدة
  void updateScore(double score) {
    _lastScore = score;
  }

  /// إيقاف الاهتزاز
  void stopPulsing() {
    _isActive = false;
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }

  /// جدولة النبضة التالية
  void _schedulePulse() {
    if (!_isActive) return;
    
    _pulseTimer?.cancel();
    
    final interval = _calculateInterval(_lastScore);
    final duration = _calculateDuration(_lastScore);
    
    if (interval == Duration.zero) return; // لا اهتزاز في المنطقة الميتة
    
    _pulseTimer = Timer(interval, () {
      if (!_isActive) return;
      _vibrateWithCheck(duration.inMilliseconds);
      _schedulePulse(); // جدولة النبضة التالية
    });
  }

  Future<void> _vibrateWithCheck(int duration) async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      bool? hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
      if (hasCustomVibrationsSupport == true) {
        Vibration.vibrate(duration: duration);
      } else {
        Vibration.vibrate();
        await Future.delayed(Duration(milliseconds: duration));
        Vibration.cancel();
      }
    }
  }

  /// حساب الفاصل الزمني بين النبضات
  Duration _calculateInterval(double score) {
    if (score <= 10) return Duration.zero; // صمت تام
    if (score <= 25) return const Duration(milliseconds: 2000);
    if (score <= 40) return const Duration(milliseconds: 1200);
    if (score <= 50) return const Duration(milliseconds: 800);
    if (score <= 65) return const Duration(milliseconds: 500);
    if (score <= 79) return const Duration(milliseconds: 350);
    if (score <= 89) return const Duration(milliseconds: 200);
    return const Duration(milliseconds: 100); // 90%+ → محموم!
  }

  /// حساب مدة النبضة الواحدة
  Duration _calculateDuration(double score) {
    if (score <= 25) return const Duration(milliseconds: 30);
    if (score <= 40) return const Duration(milliseconds: 50);
    if (score <= 50) return const Duration(milliseconds: 70);
    if (score <= 65) return const Duration(milliseconds: 80);
    if (score <= 79) return const Duration(milliseconds: 100);
    if (score <= 89) return const Duration(milliseconds: 120);
    return const Duration(milliseconds: 150);
  }

  /// 🎉 اهتزاز احتفالي عند اكتشاف النقطة الأسطورية!
  Future<void> playFoundSpotCelebration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;
    
    bool? hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
    if (hasCustomVibrationsSupport == true) {
      await Vibration.vibrate(
        pattern: [0, 200, 100, 200, 100, 400],
      );
    } else {
      Vibration.vibrate();
    }
  }

  /// 🏆 اهتزاز عند كسر الرقم القياسي (Best Score)
  Future<void> playNewRecordPulse() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;
    
    bool? hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
    if (hasCustomVibrationsSupport == true) {
      await Vibration.vibrate(
        pattern: [0, 100, 50, 100, 50, 300],
      );
    } else {
      Vibration.vibrate();
    }
  }

  /// تنظيف
  void dispose() {
    stopPulsing();
  }
}
