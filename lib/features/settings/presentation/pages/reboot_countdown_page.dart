import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class RebootCountdownPage extends StatefulWidget {
  const RebootCountdownPage({super.key});

  @override
  State<RebootCountdownPage> createState() => _RebootCountdownPageState();
}

class _RebootCountdownPageState extends State<RebootCountdownPage> with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _secondsRemaining = 60;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
        _onFinished();
      }
    });
  }

  void _onFinished() {
    HapticFeedback.heavyImpact();
    Get.offAllNamed('/'); // العودة لشاشة البداية للفحص التلقائي للاتصال
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF4F7FC),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1E3C72).withValues(alpha: 0.2), const Color(0xFF0A0E21)]
              : [const Color(0xFF4A90E2).withValues(alpha: 0.1), const Color(0xFFF4F7FC)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أنيميشن الأيقونة
            RotationTransition(
              turns: _animationController,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Iconsax.refresh, size: 60, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 40),
            
            const Text(
              'جاري إعادة تشغيل المودم',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'يرجى الانتظار حتى يعود الاتصال بالإنترنت',
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey),
            ),
            
            const SizedBox(height: 60),
            
            // دائرة العداد
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: _secondsRemaining / 60,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                Text(
                  '$_secondsRemaining',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Text(
              'ثانية متبقية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
