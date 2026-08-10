import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/battery_monitor_service.dart';

class BatterySettingsPage extends StatefulWidget {
  const BatterySettingsPage({super.key});

  @override
  State<BatterySettingsPage> createState() => _BatterySettingsPageState();
}

class _BatterySettingsPageState extends State<BatterySettingsPage> {
  // Battery Settings
  bool _isBatteryEnabled = false;
  double _batteryLowThreshold = 20.0;
  bool _notifyFull = true;

  // Quota Settings
  bool _isQuotaEnabled = true;
  double _quotaLowThreshold = 5.0; // GB
  
  // Expiry Settings
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
    setState(() {
      // Battery
      _isBatteryEnabled = prefs.getBool('battery_monitor_enabled') ?? false;
      _batteryLowThreshold = (prefs.getInt('battery_low_threshold') ?? 20).toDouble();
      _notifyFull = prefs.getBool('battery_notify_full') ?? true;
      
      // Quota
      _isQuotaEnabled = prefs.getBool('quota_monitor_enabled') ?? true;
      _quotaLowThreshold = (prefs.getInt('quota_low_threshold_gb') ?? 5).toDouble();
      
      // Expiry
      _isExpiryEnabled = prefs.getBool('expiry_monitor_enabled') ?? true;
      _expiryAlertDays = (prefs.getInt('expiry_alert_days') ?? 3).toDouble();
      
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Battery
    await prefs.setBool('battery_monitor_enabled', _isBatteryEnabled);
    await prefs.setInt('battery_low_threshold', _batteryLowThreshold.toInt());
    await prefs.setBool('battery_notify_full', _notifyFull);
    
    // Quota
    await prefs.setBool('quota_monitor_enabled', _isQuotaEnabled);
    await prefs.setInt('quota_low_threshold_gb', _quotaLowThreshold.toInt());

    // Expiry
    await prefs.setBool('expiry_monitor_enabled', _isExpiryEnabled);
    await prefs.setInt('expiry_alert_days', _expiryAlertDays.toInt());

    // Both use the same background task, so if either is enabled, we start it
    if (_isBatteryEnabled || _isQuotaEnabled || _isExpiryEnabled) {
      await BatteryMonitorService.startMonitoring();
    } else {
      await BatteryMonitorService.stopMonitoring();
    }
  }

  // 🎨 ألوان الهوية الديناميكية
  Color bgColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0E21) : const Color(0xFFF4F7FC);
  Color cardColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16213E) : Colors.white;
  Color textColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B);
  Color subTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF8E9AAA);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgColor(context),
      appBar: AppBar(
        title: const Text('إدارة التنبيهات'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor(context)),
        titleTextStyle: TextStyle(
          color: textColor(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo', // Assuming Cairo is used in the app
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔋 قسم تفعيل البطارية
            Container(
              decoration: BoxDecoration(
                color: cardColor(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: SwitchListTile(
                title: Text(
                  'مراقبة البطارية',
                  style: TextStyle(
                    color: textColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'تنبيهات ذكية لمستوى شحن المودم.',
                  style: TextStyle(color: subTextColor(context), fontSize: 13),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isBatteryEnabled ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.battery_charging,
                    color: _isBatteryEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                value: _isBatteryEnabled,
                activeColor: Colors.green,
                onChanged: (value) {
                  setState(() => _isBatteryEnabled = value);
                  _saveSettings();
                },
              ),
            ),
            
            // 🎚️ إعدادات البطارية
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _isBatteryEnabled ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    
                    // تنبيه البطارية المنخفضة
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor(context),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Iconsax.battery_empty, color: Colors.orange),
                              const SizedBox(width: 10),
                              Text(
                                'تنبيه انخفاض البطارية',
                                style: TextStyle(
                                  color: textColor(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_batteryLowThreshold.toInt()}%',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'سيتم إرسال إشعار لك عندما يصل شحن المودم إلى هذه النسبة.',
                            style: TextStyle(color: subTextColor(context), fontSize: 13),
                          ),
                          Slider(
                            value: _batteryLowThreshold,
                            min: 5,
                            max: 50,
                            divisions: 9,
                            activeColor: Colors.orange,
                            inactiveColor: Colors.orange.withOpacity(0.2),
                            label: '${_batteryLowThreshold.toInt()}%',
                            onChanged: (value) {
                              setState(() => _batteryLowThreshold = value);
                            },
                            onChangeEnd: (value) => _saveSettings(),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // تنبيه الامتلاء
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor(context),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'تنبيه اكتمال الشحن',
                          style: TextStyle(
                            color: textColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'تنبيهك عند وصول شحن المودم إلى 100% لفصل الشاحن.',
                          style: TextStyle(color: subTextColor(context), fontSize: 13),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.battery_full, color: Colors.blue),
                        ),
                        value: _notifyFull,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() => _notifyFull = value);
                          _saveSettings();
                        },
                      ),
                    ),
                  ],
                ) : const SizedBox.shrink(),
            ),

            const SizedBox(height: 25),

            // 📊 قسم تفعيل الرصيد
            Container(
              decoration: BoxDecoration(
                color: cardColor(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: SwitchListTile(
                title: Text(
                  'مراقبة رصيد البيانات',
                  style: TextStyle(
                    color: textColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'تنبيهات ذكية عندما يقارب رصيد باقة الإنترنت على الانتهاء.',
                  style: TextStyle(color: subTextColor(context), fontSize: 13),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isQuotaEnabled ? Colors.purple.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.chart,
                    color: _isQuotaEnabled ? Colors.purple : Colors.grey,
                  ),
                ),
                value: _isQuotaEnabled,
                activeColor: Colors.purple,
                onChanged: (value) {
                  setState(() => _isQuotaEnabled = value);
                  _saveSettings();
                  
                  if (value) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: cardColor(context),
                        title: Text(
                          'تنبيه هام',
                          style: TextStyle(color: textColor(context), fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          'يرجى عند اعادة تشغيل المودم او ايقاف تشغيله او عند الاشتراك في باقه جديده الدخول الى شاشة الرصيد والاستعلام عن الرصيد، لكي يصلك التنبيه دون مشاكل',
                          style: TextStyle(color: subTextColor(context), height: 1.5),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('حسناً', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),

            // 🎚️ إعدادات الرصيد
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _isQuotaEnabled 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      // تنبيه الرصيد المنخفض
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor(context),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Iconsax.danger, color: Colors.purple),
                                const SizedBox(width: 10),
                                Text(
                                  'تنبيه انخفاض الرصيد',
                                  style: TextStyle(
                                    color: textColor(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_quotaLowThreshold.toInt()} جيجا',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'سيصلك إشعار عندما يقل الرصيد المتوقع عن هذا الحد.',
                              style: TextStyle(color: subTextColor(context), fontSize: 13),
                            ),
                            Slider(
                              value: _quotaLowThreshold,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              activeColor: Colors.purple,
                              inactiveColor: Colors.purple.withOpacity(0.2),
                              label: '${_quotaLowThreshold.toInt()} جيجا',
                              onChanged: (value) {
                                setState(() => _quotaLowThreshold = value);
                              },
                              onChangeEnd: (value) => _saveSettings(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ) 
                : const SizedBox.shrink(),
            ),

            const SizedBox(height: 25),

            // 📅 قسم تفعيل انتهاء الباقة
            Container(
              decoration: BoxDecoration(
                color: cardColor(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: SwitchListTile(
                title: Text(
                  'تنبيه انتهاء الباقة',
                  style: TextStyle(
                    color: textColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'تنبيهك قبل انتهاء تاريخ الباقة المحددة.',
                  style: TextStyle(color: subTextColor(context), fontSize: 13),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isExpiryEnabled ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.calendar,
                    color: _isExpiryEnabled ? Colors.red : Colors.grey,
                  ),
                ),
                value: _isExpiryEnabled,
                activeColor: Colors.red,
                onChanged: (value) {
                  setState(() => _isExpiryEnabled = value);
                  _saveSettings();
                },
              ),
            ),

            // 🎚️ إعدادات الانتهاء
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _isExpiryEnabled 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      // تنبيه قبل الانتهاء
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor(context),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Iconsax.calendar_tick, color: Colors.red),
                                const SizedBox(width: 10),
                                Text(
                                  'تنبيه قبل الانتهاء',
                                  style: TextStyle(
                                    color: textColor(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_expiryAlertDays.toInt()} أيام',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'سيتم تنبيهك قبل انتهاء باقتك بهذا العدد من الأيام.',
                              style: TextStyle(color: subTextColor(context), fontSize: 13),
                            ),
                            Slider(
                              value: _expiryAlertDays,
                              min: 1,
                              max: 7,
                              divisions: 6,
                              activeColor: Colors.red,
                              inactiveColor: Colors.red.withOpacity(0.2),
                              label: '${_expiryAlertDays.toInt()} أيام',
                              onChanged: (value) {
                                setState(() => _expiryAlertDays = value);
                              },
                              onChangeEnd: (value) => _saveSettings(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ) 
                : const SizedBox.shrink(),
            ),

          ],
        ),
      ),
    );
  }
}
