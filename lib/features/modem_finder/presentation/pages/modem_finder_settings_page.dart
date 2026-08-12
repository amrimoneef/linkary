import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/services/calibration_service.dart';
import '../../infrastructure/services/anti_loss_service.dart';
import '../../infrastructure/services/wifi_rssi_reader.dart';
import '../controllers/modem_finder_controller.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/network/session_manager.dart';

class ModemFinderSettingsPage extends StatefulWidget {
  const ModemFinderSettingsPage({super.key});

  @override
  State<ModemFinderSettingsPage> createState() => _ModemFinderSettingsPageState();
}

class _ModemFinderSettingsPageState extends State<ModemFinderSettingsPage> {
  final CalibrationService _calibrationService = Get.find<CalibrationService>();
  
  bool _isAntiLossEnabled = false;
  bool _isCalibrating = false;
  int _calibrationProgress = 0;
  int? _currentMaxRssi;
  String _selectedSound = 'alarm1';

  final Map<String, String> _soundOptions = {
    'alarm1': 'إنذار 1',
    'alarm2': 'إنذار 2',
    'alarm3': 'إنذار 3',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final antiLoss = await _calibrationService.getAntiLossEnabled();
    final maxRssi = await _calibrationService.getMaxRssi();
    final sound = await _calibrationService.getAlarmSound();
    
    // Validate actual service state with our saved state
    final isServiceRunning = await Get.find<AntiLossService>().isAntiLossRunning();
    
    if (mounted) {
      setState(() {
        // Only show enabled if both prefs and actual service say it's enabled
        _isAntiLossEnabled = antiLoss && isServiceRunning;
        _currentMaxRssi = maxRssi;
        _selectedSound = sound;
      });
    }
  }

  void _toggleAntiLoss(bool value) async {
    if (value) {
      final sn = await SessionManager.getLastSN();
      if (sn == null || !(sn.toUpperCase().startsWith('M5610') || sn.toUpperCase().startsWith('M5010'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('عذراً، هذه الميزة مخصصة لمودمات SAM4G فقط.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        debugPrint("🆘 sn: $sn");
        setState(() => _isAntiLossEnabled = false);
        return;
      }
    }

    setState(() => _isAntiLossEnabled = value);
    await _calibrationService.saveAntiLossEnabled(value);
    
    final antiLossService = Get.find<AntiLossService>();

    if (value) {
      await antiLossService.startAntiLoss(soundName: _selectedSound);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تفعيل حماية المودم')),
      );
    } else {
      await antiLossService.stopAntiLoss();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إيقاف حماية المودم')),
      );
    }
  }

  void _onSoundChanged(String? newSound) async {
    if (newSound != null) {
      setState(() => _selectedSound = newSound);
      await _calibrationService.saveAlarmSound(newSound);
      
      final antiLossService = Get.find<AntiLossService>();
      
      // Play a quick preview of the sound
      await antiLossService.previewAlarmSound(newSound);

      // If service is running, restart it to apply new sound
      if (_isAntiLossEnabled) {
        await antiLossService.startAntiLoss(soundName: newSound);
      }
    }
  }

  Future<void> _startCalibration() async {
    setState(() {
      _isCalibrating = true;
      _calibrationProgress = 0;
    });

    final reader = Get.find<WifiRssiReader>();
    int maxFound = -100;

    for (int i = 0; i <= 10; i++) {
      if (!mounted) return;
      
      try {
        final rssi = await reader.getRssi();
        if (rssi > maxFound) maxFound = rssi;
        
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50, amplitude: 100);
        }
      } catch (e) {
        // ignore
      }

      setState(() => _calibrationProgress = (i * 10));
      await Future.delayed(const Duration(milliseconds: 300));
    }

    await _calibrationService.saveMaxRssi(maxFound);
    
    // Update the controller if it's active
    if (Get.isRegistered<ModemFinderController>()) {
      Get.find<ModemFinderController>().reloadCalibration(); // Reloads calibration
    }

    if (mounted) {
      setState(() {
        _isCalibrating = false;
        _currentMaxRssi = maxFound;
      });
      
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500, amplitude: 255);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت المعايرة بنجاح! قوة الإشارة: $maxFound dBm'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  Future<void> _resetCalibration() async {
    await _calibrationService.resetCalibration();
    if (Get.isRegistered<ModemFinderController>()) {
      Get.find<ModemFinderController>().reloadCalibration();
    }
    setState(() {
      _currentMaxRssi = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم مسح المعايرة السابقة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('إعدادات البحث عن المودم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Calibration Section
            Row(
              children: [
                const Icon(Icons.devices_other_sharp, size: 24, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text('المعايرة الذكية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.radar5, color: AppColors.primaryBlue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'تحسين دقة الرادار',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تختلف قوة بث الواي فاي من مودم لآخر. إذا كان الرادار غير دقيق، قم بمعايرته للحصول على دقة 100%.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  
                  if (_currentMaxRssi != null && !_isCalibrating)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20),
                              const SizedBox(width: 8),
                              Text('المعايرة مفعلة: $_currentMaxRssi dBm', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            ],
                          ),
                          InkWell(
                            onTap: _resetCalibration,
                            child: const Icon(Icons.delete_outline, color: AppColors.errorRed, size: 20),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.accentOrange, size: 20),
                            const SizedBox(width: 8),
                            Text('تعليمات المعايرة:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('1. اقترب جداً من المودم.\n2. ضع هاتفك فوق المودم مباشرة.\n3. اضغط على الزر بالأسفل وانتظر 3 ثوانٍ.',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isCalibrating ? null : _startCalibration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isCalibrating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    value: _calibrationProgress / 100,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('جاري المعايرة... $_calibrationProgress%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : const Text('بدء المعايرة الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. Anti-Loss Section
            Row(
              children: [
                const Icon(Iconsax.shield_tick, size: 24, color: AppColors.errorRed),
                const SizedBox(width: 8),
                Text('الحماية الاستباقية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active, color: AppColors.errorRed),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إنذار نسيان المودم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            const SizedBox(height: 4),
                            Text('تنبيه فوري إذا ابتعدت عن المودم', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAntiLossEnabled,
                        onChanged: _toggleAntiLoss,
                        activeColor: AppColors.errorRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'عند تفعيل هذه الميزة، سيعمل التطبيق في الخلفية ليراقب إشارة المودم. إذا أوشكت الإشارة على الانقطاع، سيطلق الهاتف إنذاراً عالياً لتنبيهك قبل أن تبتعد.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.music_note, color: AppColors.primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            Text('نغمة الإنذار', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSound,
                            dropdownColor: isDark ? const Color(0xFF1E2235) : Colors.white,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                            items: _soundOptions.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              );
                            }).toList(),
                            onChanged: _onSoundChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
