import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../core/services/battery_monitor_service.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../connected_devices/infrastructure/services/background_device_monitor.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';

class BatterySettingsPage extends StatefulWidget {
  const BatterySettingsPage({super.key});

  @override
  State<BatterySettingsPage> createState() => _BatterySettingsPageState();
}

class _BatterySettingsPageState extends State<BatterySettingsPage> {
  // 📱 Device Monitor Settings
  bool _isDeviceMonitorEnabled = true;

  // 🔋 Battery Settings
  bool _isBatteryEnabled = true;
  double _batteryLowThreshold = 20.0;
  bool _notifyFull = true;

  // 📊 Quota Settings
  bool _isQuotaEnabled = true;
  double _quotaLowThreshold = 5.0; // GB
  
  // 📅 Expiry Settings
  bool _isExpiryEnabled = true;
  double _expiryAlertDays = 3.0; // Days

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceMon = await SessionManager.isBackgroundDeviceMonitorEnabled();

    setState(() {
      // 📱 New Devices Alert (Default: true)
      _isDeviceMonitorEnabled = deviceMon;

      // 🔋 Battery (Default: true)
      _isBatteryEnabled = prefs.getBool('battery_monitor_enabled') ?? true;
      _batteryLowThreshold = (prefs.getInt('battery_low_threshold') ?? 20).toDouble();
      _notifyFull = prefs.getBool('battery_notify_full') ?? true;
      
      // 📊 Quota (Default: true)
      _isQuotaEnabled = prefs.getBool('quota_monitor_enabled') ?? true;
      _quotaLowThreshold = (prefs.getInt('quota_low_threshold_gb') ?? 5).toDouble();
      
      // 📅 Expiry (Default: true)
      _isExpiryEnabled = prefs.getBool('expiry_monitor_enabled') ?? true;
      _expiryAlertDays = (prefs.getInt('expiry_alert_days') ?? 3).toDouble();
      
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 🔋 Battery
    await prefs.setBool('battery_monitor_enabled', _isBatteryEnabled);
    await prefs.setInt('battery_low_threshold', _batteryLowThreshold.toInt());
    await prefs.setBool('battery_notify_full', _notifyFull);
    
    // 📊 Quota
    await prefs.setBool('quota_monitor_enabled', _isQuotaEnabled);
    await prefs.setInt('quota_low_threshold_gb', _quotaLowThreshold.toInt());

    // 📅 Expiry
    await prefs.setBool('expiry_monitor_enabled', _isExpiryEnabled);
    await prefs.setInt('expiry_alert_days', _expiryAlertDays.toInt());

    // 📱 Device Monitor
    await SessionManager.setBackgroundDeviceMonitorEnabled(_isDeviceMonitorEnabled);
    if (Get.isRegistered<ConnectedDevicesController>()) {
      Get.find<ConnectedDevicesController>().isBgMonitorEnabled.value = _isDeviceMonitorEnabled;
    }
    if (_isDeviceMonitorEnabled) {
      await registerBackgroundDeviceMonitor();
    } else {
      await cancelBackgroundDeviceMonitor();
    }

    // Battery & Quota Background Task
    if (_isBatteryEnabled || _isQuotaEnabled || _isExpiryEnabled) {
      await BatteryMonitorService.startMonitoring();
    } else {
      await BatteryMonitorService.stopMonitoring();
    }
  }

  int get _activeCount {
    int count = 0;
    if (_isDeviceMonitorEnabled) count++;
    if (_isBatteryEnabled) count++;
    if (_isQuotaEnabled) count++;
    if (_isExpiryEnabled) count++;
    return count;
  }

  void _toggleAll(bool enable) {
    setState(() {
      _isDeviceMonitorEnabled = enable;
      _isBatteryEnabled = enable;
      _isQuotaEnabled = enable;
      _isExpiryEnabled = enable;
    });
    _saveSettings();
    CustomSnackbar.showSuccess(
      enable ? 'تم تفعيل جميع التنبيهات' : 'تم تعطيل جميع التنبيهات',
      enable ? 'ستصلك كافة الإشعارات الهامة فور حدوثها.' : 'تم إيقاف التنبيهات التلقائية.',
    );
  }

  void _showBalanceGuidanceDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTxtColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.info_circle, color: Color(0xFF8B5CF6), size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                'تنبيه هام للرصيد',
                style: TextStyle(
                  color: txtColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'يرجى عند إعادة تشغيل المودم أو إيقاف تشغيله أو عند الاشتراك في باقة جديدة الدخول إلى شاشة الرصيد والاستعلام لمرة واحدة، لكي يصلك التنبيه بدقة ودون أي مشاكل.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subTxtColor,
                  fontSize: 13.5,
                  height: 1.6,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('حسناً، فهمت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF0A0E21) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final glowColor = isDark ? const Color(0xFF4A90E2) : const Color(0xFF38BDF8);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: glowColor)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 🌌 Radial Glow Background
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: isDark ? 0.25 : 0.2),
                    glowColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🏷️ Top Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 18),
                              onPressed: () => Get.back(),
                            ),
                            Text(
                              'إدارة التنبيهات الذكية',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          isDark
                              ? 'assets/images/الشعار ابيض.png'
                              : 'assets/images/الشعار اسود.png',
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 🛡️ 1. Master Status Summary Card
                      _buildMasterSummaryCard(isDark, cardColor, textColor, subTextColor),
                      const SizedBox(height: 24),

                      // 📱 2. New Devices Monitor Section
                      _buildSectionCard(
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        title: 'مراقب الأجهزة الجديدة',
                        subtitle: 'إشعار فوري عند اتصال أي جهاز جديد أو غير موثوق بالشبكة.',
                        icon: Icons.devices,
                        gradientColors: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        isEnabled: _isDeviceMonitorEnabled,
                        onToggle: (val) {
                          setState(() => _isDeviceMonitorEnabled = val);
                          _saveSettings();
                        },
                        expandedContent: Padding(
                          padding: const EdgeInsets.only(top: 14.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0072FF).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF0072FF).withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Iconsax.shield_security, color: Color(0xFF0072FF), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'يقوم بتنبيهك عند اتصال أي جهاز جديد أو غير موثوق بالشبكة، لحماية شبكتك من الاختراق.',
                                    style: TextStyle(color: subTextColor, fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 🔋 3. Battery Monitor Section
                      _buildSectionCard(
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        title: 'مراقبة مستوى البطارية',
                        subtitle: 'تنبيهات ذكية لحماية بطارية المودم من النفاد والتلف.',
                        icon: Iconsax.battery_charging,
                        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                        isEnabled: _isBatteryEnabled,
                        onToggle: (val) {
                          setState(() => _isBatteryEnabled = val);
                          _saveSettings();
                        },
                        expandedContent: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Slider Low Battery
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Iconsax.battery_empty, color: Color(0xFF10B981), size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'تنبيه انخفاض الشحن',
                                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${_batteryLowThreshold.toInt()}%',
                                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'سيصلك إشعار عندما ينخفض شحن المودم إلى هذه النسبة.',
                                    style: TextStyle(color: subTextColor, fontSize: 12),
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: const Color(0xFF10B981),
                                      inactiveTrackColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      thumbColor: const Color(0xFF10B981),
                                      overlayColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _batteryLowThreshold,
                                      min: 5,
                                      max: 50,
                                      divisions: 9,
                                      label: '${_batteryLowThreshold.toInt()}%',
                                      onChanged: (value) => setState(() => _batteryLowThreshold = value),
                                      onChangeEnd: (value) => _saveSettings(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Switch Full Battery
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'تنبيه اكتمال الشحن (100%)',
                                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'ينبهك فور امتلاء الشحن لفصل المودم وحفظ عمر البطارية.',
                                  style: TextStyle(color: subTextColor, fontSize: 11),
                                ),
                                value: _notifyFull,
                                activeColor: const Color(0xFF10B981),
                                onChanged: (val) {
                                  setState(() => _notifyFull = val);
                                  _saveSettings();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 📊 4. Quota Monitor Section
                      _buildSectionCard(
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        title: 'مراقبة رصيد البيانات',
                        subtitle: 'تنبيه ذكي قبل نفاد رصيد الباقة لتفادي انقطاع الإنترنت.',
                        icon: Iconsax.chart_21,
                        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        isEnabled: _isQuotaEnabled,
                        onToggle: (val) {
                          setState(() => _isQuotaEnabled = val);
                          _saveSettings();
                          if (val) {
                            _showBalanceGuidanceDialog();
                          }
                        },
                        expandedContent: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Iconsax.danger, color: Color(0xFF8B5CF6), size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'الحد الأدنى للرصيد',
                                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${_quotaLowThreshold.toInt()} GB',
                                          style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'سيصلك إشعار عندما يقل رصيد الباقة المتوقع عن هذا الحد.',
                                    style: TextStyle(color: subTextColor, fontSize: 12),
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: const Color(0xFF8B5CF6),
                                      inactiveTrackColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                      thumbColor: const Color(0xFF8B5CF6),
                                      overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _quotaLowThreshold,
                                      min: 1,
                                      max: 10,
                                      divisions: 9,
                                      label: '${_quotaLowThreshold.toInt()} GB',
                                      onChanged: (value) => setState(() => _quotaLowThreshold = value),
                                      onChangeEnd: (value) => _saveSettings(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Iconsax.info_circle, color: Color(0xFF8B5CF6), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'تذكير: عند تجديد الباقة أو إعادة تشغيل المودم، افتح شاشة الرصيد للاستعلام لمرة واحدة لتحديث قراءة الاستهلاك بدقة.',
                                      style: TextStyle(color: subTextColor, fontSize: 11.5, height: 1.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 📅 5. Package Expiry Monitor Section
                      _buildSectionCard(
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        title: 'تنبيه موعد انتهاء الباقة',
                        subtitle: 'تذكير مسبق قبل انتهاء تاريخ صلاحية الباقة لتجديدها بالوقت المناسب.',
                        icon: Iconsax.calendar_tick,
                        gradientColors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                        isEnabled: _isExpiryEnabled,
                        onToggle: (val) {
                          setState(() => _isExpiryEnabled = val);
                          _saveSettings();
                          if (val) {
                            _showBalanceGuidanceDialog();
                          }
                        },
                        expandedContent: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Iconsax.clock, color: Color(0xFFF59E0B), size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'التنبيه قبل الانتهاء بـ',
                                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${_expiryAlertDays.toInt()} أيام',
                                          style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'سيتم إرسال إشعار تذكيري قبل تاريخ انتهاء الباقة بعدد الأيام المختار.',
                                    style: TextStyle(color: subTextColor, fontSize: 12),
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: const Color(0xFFF59E0B),
                                      inactiveTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                      thumbColor: const Color(0xFFF59E0B),
                                      overlayColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _expiryAlertDays,
                                      min: 1,
                                      max: 7,
                                      divisions: 6,
                                      label: '${_expiryAlertDays.toInt()} أيام',
                                      onChanged: (value) => setState(() => _expiryAlertDays = value),
                                      onChangeEnd: (value) => _saveSettings(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Iconsax.info_circle, color: Color(0xFFF59E0B), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'ملاحظة: تاريخ انتهاء الباقة يتم تحديثه ومزامنته تلقائياً عند استعلامك عن الرصيد من التطبيق.',
                                      style: TextStyle(color: subTextColor, fontSize: 11.5, height: 1.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterSummaryCard(bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    final int count = _activeCount;
    final bool allEnabled = count == 4;

    return GlassCard(
      surfaceColor: cardColor,
      borderColor: allEnabled ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
      opacity: 0.7,
      blur: 15,
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: allEnabled
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFF4A90E2), const Color(0xFF1E3C72)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (allEnabled ? const Color(0xFF10B981) : const Color(0xFF4A90E2)).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(
                  allEnabled ? Iconsax.shield_tick : Iconsax.notification_status,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allEnabled ? 'نظام المراقبة نشط بالكامل' : 'حالة نظام التنبيهات',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count من أصل 4 تنبيهات مفعلة',
                      style: TextStyle(color: subTextColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _toggleAll(!allEnabled),
                icon: Icon(allEnabled ? Iconsax.close_circle : Iconsax.tick_circle, size: 16),
                label: Text(allEnabled ? 'إيقاف الكل' : 'تفعيل الكل'),
                style: TextButton.styleFrom(
                  foregroundColor: allEnabled ? Colors.redAccent : const Color(0xFF10B981),
                  backgroundColor: (allEnabled ? Colors.redAccent : const Color(0xFF10B981)).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    Widget? expandedContent,
  }) {
    return GlassCard(
      surfaceColor: cardColor,
      borderColor: isEnabled ? gradientColors.first.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15),
      opacity: 0.7,
      blur: 15,
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isEnabled ? gradientColors : [Colors.grey.shade600, Colors.grey.shade700]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: gradientColors.first.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: subTextColor, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                activeColor: gradientColors.first,
                onChanged: onToggle,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: (isEnabled && expandedContent != null) ? expandedContent : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
