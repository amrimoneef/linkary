import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/mac_filter_controller.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';

class MacFilterPage extends StatelessWidget {
  MacFilterPage({super.key});

  final MacFilterController controller = Get.find<MacFilterController>();

  // 🎨 الألوان الديناميكية (الهوية الموحدة)
  Color get bgColor => Get.isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFFAFAFC);
  Color get cardColor => Get.isDarkMode ? const Color(0xFF16213E) : Colors.white;
  Color get textColor => Get.isDarkMode ? Colors.white : const Color(0xFF111827);
  Color get subTextColor => Get.isDarkMode ? Colors.white54 : const Color(0xFF6B7280);
Color get glowColor => Get.isDarkMode ? const Color(0xFF4A90E2) : const Color(0xFF92C0F6);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // 🌌 1. الدائرة السحرية المتدرجة في الزاوية العلوية (Radial Glow)
            Positioned(
              top: -120,
              right: -100, // وضعها في الزاوية اليمنى كما في الصورة (يمكنك جعلها left إذا أردت العكس)
              child: Container(
                width: 370,
                height: 370,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: Get.isDarkMode ? 0.3 : 0.4), // لون الدائرة من المنتصف
                      glowColor.withValues(alpha: 0.01), // التلاشي الشفاف في الأطراف
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
              ),
            ),

            // 📝 2. المحتوى الرئيسي
            SafeArea(
              child: controller.isLoading.value
                  ? Center(child: CircularProgressIndicator(color: glowColor))
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // زر العودة واللوجو
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, color: textColor),
                            onPressed: () => Get.back(),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          Image.asset(
                            Get.isDarkMode ? 'assets/images/الشعار ابيض.png' : 'assets/images/الشعار اسود.png',
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // العنوان الرئيسي
                      Text('حظر الأجهزة', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('تحكم بمن يتصل بشبكتك؟ ', style: TextStyle(color: subTextColor, fontSize: 14)),
                          Text('جدار ناري', style: TextStyle(color: glowColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // ==========================================
                      // 1. اختيار الوضع (Mode Selector)
                      Text('وضع الجدار الناري:', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      _buildModeSelector(),
                      const SizedBox(height: 30),

                      // 2. القائمة النشطة (تتغير حسب الوضع)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: controller.selectedMode.value == 'disable'
                            ? _buildInfoCard('الحظر معطل', 'جميع الأجهزة التي تمتلك كلمة المرور الحالية يمكنها الاتصال بالشبكة بكل حرية.', Iconsax.unlock, Colors.grey)
                            : _buildActiveList(context),
                      ),
                      const SizedBox(height: 40),

                      // 3. زر الحفظ المتدرج
                      _buildSaveButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ==========================================
  // 🧩 دوال بناء الواجهة
  // ==========================================

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedMode.value,
          dropdownColor: cardColor,
          icon: Icon(Icons.keyboard_arrow_down, color: subTextColor),
          style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'disable', child: Text('معطل (إيقاف الحماية)')),
            DropdownMenuItem(value: 'deny', child: Text('القائمة السوداء (حظر المحددين)')),
            DropdownMenuItem(value: 'allow', child: Text('القائمة البيضاء (حصر الاتصال بالمحددين)')),
          ],
          onChanged: (val) => controller.selectedMode.value = val!,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String desc, IconData icon, Color color) {
    return Container(
      key: const ValueKey('disable'),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(desc, style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActiveList(BuildContext context) {
    bool isDeny = controller.selectedMode.value == 'deny';
    List<String> currentList = isDeny ? controller.denyList : controller.allowList;
    Color accentColor = isDeny ? Colors.redAccent : Colors.green; // الألوان تعكس الخطر أو الأمان
    String title = isDeny ? 'قائمة الأجهزة المحظورة' : 'قائمة الأجهزة الموثوقة';
    IconData iconType = isDeny ? Iconsax.minus_cirlce : Iconsax.tick_circle;

    return Column(
      key: ValueKey(controller.selectedMode.value),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showSmartMacSheet(context),
              icon: Icon(Iconsax.add_square, color: glowColor),
              label: Text('إضافة جهاز', style: TextStyle(color: glowColor, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 15),

        currentList.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('القائمة فارغة حالياً.', style: TextStyle(color: subTextColor))))
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentList.length,
          itemBuilder: (context, index) {
            final mac = currentList[index];
            String deviceName = 'جهاز غير معروف';
            
            // محاولة جلب الاسم المخزن أو اسم الجهاز المتصل
            try {
              final devController = Get.find<ConnectedDevicesController>();
              final customName = devController.customNames[mac.toUpperCase()];
              if (customName != null && customName.isNotEmpty) {
                deviceName = customName;
              } else {
                final connectedDev = devController.devices.firstWhereOrNull((d) => d.mac.toUpperCase() == mac.toUpperCase());
                if (connectedDev != null && connectedDev.name.isNotEmpty) {
                  deviceName = connectedDev.name;
                }
              }
            } catch (_) {}

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5), // لون الإطار يعكس الحالة
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(iconType, color: accentColor, size: 24),
                ),
                title: Text(deviceName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text(mac, style: TextStyle(color: subTextColor, fontFamily: 'monospace', fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.grey, size: 20),
                  onPressed: () => controller.removeMac(mac),
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildSaveButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: glowColor,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          shadowColor: glowColor.withValues(alpha: 0.5),
        ),
        onPressed: controller.isSaving.value ? null : () => controller.saveSettings(),
        child: controller.isSaving.value
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تطبيق التغييرات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Iconsax.arrow_right_1, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🚀 النافذة السفلية الذكية (Smart BottomSheet) بهوية التصميم الجديد
  // ==========================================
  void _showSmartMacSheet(BuildContext context) {
    ConnectedDevicesController? devicesController;
    try {
      devicesController = Get.find<ConnectedDevicesController>();
      if (devicesController.devices.isEmpty) devicesController.fetchDevices();
    } catch (_) {}

    final macCtrl = TextEditingController();
    var selectedMac = ''.obs;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.85, // لمنع أخطاء الكيبورد
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Text('إضافة جهاز للقائمة', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('اختر جهازاً من المتصلين حالياً أو أدخل الـ MAC يدوياً', style: TextStyle(color: subTextColor, fontSize: 14)),
            const SizedBox(height: 25),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 1. شريط الأجهزة المتصلة
                    SizedBox(
                      height: 140,
                      child: devicesController == null
                          ? Center(child: Text('ميزة الأجهزة غير مفعلة', style: TextStyle(color: subTextColor)))
                          : Obx(() {
                        if (devicesController!.isLoading.value) return Center(child: CircularProgressIndicator(color: glowColor));
                        final devicesList = devicesController.devices;
                        if (devicesList.isEmpty) return Center(child: Text('لا توجد أجهزة متصلة سوى جهازك', style: TextStyle(color: subTextColor)));

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: devicesList.length,
                          itemBuilder: (context, index) {
                            final dev = devicesList[index];
                            final devMac = dev.mac;
                            final devName = dev.name.isEmpty ? 'جهاز مجهول' : dev.name;

                            return Obx(() {
                              bool isSelected = selectedMac.value == devMac;
                              return GestureDetector(
                                onTap: () {
                                  selectedMac.value = devMac;
                                  macCtrl.text = devMac; // تعبئة الحقل تلقائياً
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 120,
                                  margin: const EdgeInsets.only(left: 15),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? glowColor.withValues(alpha: 0.1) : cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isSelected ? glowColor : Colors.grey.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Iconsax.mobile, color: isSelected ? glowColor : subTextColor, size: 30),
                                      const SizedBox(height: 10),
                                      Text(devName, style: TextStyle(color: isSelected ? glowColor : textColor, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 5),
                                      Text(devMac, style: TextStyle(color: subTextColor, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 25),

                    // 2. حقل إدخال الماك
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: TextField(
                        controller: macCtrl,
                        style: TextStyle(color: glowColor, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        onChanged: (val) => selectedMac.value = val,
                        decoration: InputDecoration(
                          labelText: 'عنوان MAC (مثال: AA:BB:CC:DD:EE:FF)',
                          labelStyle: TextStyle(color: subTextColor, fontSize: 12),
                          prefixIcon: Icon(Iconsax.scan_barcode, color: subTextColor, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // 3. زر الإضافة
            SizedBox(
              width: double.infinity,
              height: 60,
              child: Obx(() {
                bool isReady = selectedMac.value.isNotEmpty;
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReady ? glowColor : Colors.grey.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: isReady ? 5 : 0,
                    shadowColor: glowColor.withValues(alpha: 0.5),
                  ),
                  icon: Icon(Iconsax.add_square, color: isReady ? Colors.white : Colors.white54),
                  label: Text('إدراج الجهاز للقائمة', style: TextStyle(color: isReady ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: isReady ? () {
                    controller.addMac(macCtrl.text.toUpperCase());
                    Get.back();
                  } : null,
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}