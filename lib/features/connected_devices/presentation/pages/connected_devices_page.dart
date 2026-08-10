import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/connected_devices_controller.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../device_management/presentation/widgets/device_detail_sheet.dart';
import '../../../device_management/presentation/models/managed_device.dart';
import '../../../device_data_limit/presentation/pages/device_data_limit_page.dart';

class ConnectedDevicesPage extends StatelessWidget {
  ConnectedDevicesPage({super.key});

  final ConnectedDevicesController controller =
      Get.find<ConnectedDevicesController>();

  // 🎨 الألوان الديناميكية (الهوية الموحدة للتطبيق)
  Color get bgColor =>
      Get.isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFFAFAFC);
  Color get cardColor =>
      Get.isDarkMode ? const Color(0xFF16213E) : Colors.white;
  Color get textColor =>
      Get.isDarkMode ? Colors.white : const Color(0xFF111827);
  Color get subTextColor =>
      Get.isDarkMode ? Colors.white54 : const Color(0xFF6B7280);
  Color get glowColor =>
      Get.isDarkMode ? const Color(0xFF4A90E2) : const Color(0xFF92C0F6);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // 🌌 1. الدائرة السحرية المتدرجة في الزاوية العلوية (Radial Glow)
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: Get.isDarkMode ? 0.3 : 0.4),
                      glowColor.withValues(alpha: 0.0),
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),

            // 📝 2. المحتوى الرئيسي
            SafeArea(
              child: Column(
                children: [
                  // --- الترويسة العلوية ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // النص وزر العودة في اليمين (Start)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios,
                                  color: textColor, size: 18),
                              onPressed: () => Get.back(),
                            ),
                            Text('الأجهزة المتصلة',
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),

                        // الشعار وزر التحديث في الطرف الآخر (End)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Iconsax.refresh_circle,
                                  color: glowColor, size: 26),
                              onPressed: () => controller.fetchDevices(),
                            ),
                            const SizedBox(width: 5),
                            Image.asset(
                              Get.isDarkMode
                                  ? 'assets/images/الشعار ابيض.png'
                                  : 'assets/images/الشعار اسود.png',
                              height: 25,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- محتوى الصفحة ---
                  Expanded(
                    child: controller.isLoading.value
                        ? Center(
                            child: CircularProgressIndicator(color: glowColor))
                        : controller.errorMessage.value.isNotEmpty
                            ? _buildErrorState()
                            : RefreshIndicator(
                                onRefresh: () => controller.fetchDevices(),
                                color: glowColor,
                                backgroundColor: cardColor,
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics()),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0, vertical: 10.0),
                                  children: [
                                    // 🔔 مفتاح تفعيل مراقبة الأجهزة الجديدة
                                    _buildMonitorToggle(),
                                    const SizedBox(height: 15),

                                    // 📊 بطاقة الإحصائيات الأنيقة
                                    _buildOverviewCard(),
                                    const SizedBox(height: 30),

                                    // 📑 عنوان القائمة مع تلميح السحب
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('قائمة الأجهزة',
                                            style: TextStyle(
                                                color: textColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        InkWell(
                                          onTap: () => _showGuideBottomSheet(context),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: cardColor,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: glowColor.withValues(alpha: 0.25),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: glowColor.withValues(alpha: 0.2),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Iconsax.info_circle,
                                              color: glowColor,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    // 📱 قائمة الأجهزة
                                    if (controller.devices.isEmpty)
                                      _buildEmptyState()
                                    else
                                      ...controller.devices
                                          .map((device) =>
                                              _buildDeviceCard(context, device))
                                          .toList(),

                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                  ),
                ],
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

  // 1. بطاقة النظرة العامة (الإحصائيات)
  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [glowColor.withValues(alpha: 0.8), glowColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: glowColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إجمالي الأجهزة النشطة',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${controller.devices.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('أجهزة',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Iconsax.mobile, color: Colors.white, size: 35),
          ),
        ],
      ),
    );
  }

  // 2. بطاقة الجهاز المتصل (مع زر التسمية)
  Widget _buildDeviceCard(BuildContext context, dynamic device) {
    final bool isWifi = device.type.toUpperCase() == 'WIFI';
    final bool isMyDevice = device.ip == controller.myDeviceIp.value;

    // تحديد الأيقونة واللون بناءً على نوع الاتصال
    final IconData connectionIcon = isWifi ? Iconsax.wifi : Iconsax.link;
    final Color connectionColor =
        isWifi ? Colors.green : Colors.blueAccent;

    // الاسم المعروض: المخصص أولاً، ثم الافتراضي
    final String displayName = controller.getDisplayName(device);
    final bool hasCustomName =
        controller.customNames[device.mac.toUpperCase()] != null &&
            controller.customNames[device.mac.toUpperCase()]!.isNotEmpty;

    return Dismissible(
      key: ValueKey(device.mac),
      direction: isMyDevice ? DismissDirection.none : DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: const Icon(Iconsax.slash, color: Colors.white, size: 30),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: const Icon(Iconsax.setting_2, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right -> Block
          _showBlockConfirmDialog(context, device);
        } else if (direction == DismissDirection.endToStart) {
          // Swipe Left -> Device Management
          Get.bottomSheet(
            DeviceDetailSheet(
              device: ManagedDevice(
                mac: device.mac,
                name: displayName,
                ip: device.ip,
                type: device.type,
              )
            ),
            isScrollControlled: true,
          );
        }
        return false; // Prevent removing from list
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
            color: isMyDevice
                ? glowColor.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.1),
            width: isMyDevice ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          // أيقونة الجهاز
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: isMyDevice
                    ? glowColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.05),
                shape: BoxShape.circle),
            child: Icon(
                isMyDevice ? Iconsax.mobile : Iconsax.monitor,
                color: isMyDevice ? glowColor : subTextColor,
                size: 26),
          ),
          const SizedBox(width: 15),

          // معلومات الجهاز (الاسم، IP، MAC)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ✏️ مؤشر الاسم المخصص
                          if (hasCustomName)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Iconsax.edit_2,
                                  color: glowColor.withValues(alpha: 0.7), size: 12),
                            ),
                        ],
                      ),
                    ),
                    if (controller.isBgMonitorEnabled.value)
                      GestureDetector(
                        onTap: () {
                          if (controller.knownMacs.contains(device.mac)) {
                            _showUntrustDialog(context, device);
                          } else {
                            _showTrustDialog(context, device);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: controller.knownMacs.contains(device.mac)
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.redAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: controller.knownMacs.contains(device.mac)
                                  ? Colors.green.withValues(alpha: 0.4)
                                  : Colors.redAccent.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            controller.knownMacs.contains(device.mac)
                                ? Iconsax.shield_tick
                                : Iconsax.shield_cross,
                            color: controller.knownMacs.contains(device.mac)
                                ? Colors.green
                                : Colors.redAccent,
                            size: 16,
                          ),
                        ),
                      ),
                    if (isMyDevice)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: glowColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('جهازي',
                            style: TextStyle(
                                color: glowColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('IP: ${device.ip}',
                    style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontFamily: 'monospace')),
                const SizedBox(height: 2),
                Text('MAC: ${device.mac}',
                    style: TextStyle(
                        color: subTextColor.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontFamily: 'monospace')),
              ],
            ),
          ),

          // أيقونة نوع الاتصال + زر التسمية
          Column(
            children: [
              // 🏷️ زر تعديل الاسم
              GestureDetector(
                onTap: () => _showRenameDialog(context, device),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: glowColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.edit,
                      color: glowColor, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              // 📶 شارة نوع الاتصال
              Icon(connectionIcon, color: connectionColor, size: 16),
              const SizedBox(height: 2),
              Text(
                device.type.toUpperCase(),
                style: TextStyle(
                    color: connectionColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    ));
  }

  // ==========================================
  // 🚫 نافذة تأكيد حظر الجهاز
  // ==========================================
  void _showBlockConfirmDialog(BuildContext context, dynamic device) {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Text('تأكيد الحظر', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'حظر الجهاز (${controller.getDisplayName(device)}) سيؤدي إلى تطبيق القواعد وإعادة تشغيل بث الـ Wi-Fi تلقائياً (تسجيل الخروج).\n\nهل أنت متأكد؟',
          style: TextStyle(color: subTextColor, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.blockDevice(device);
            },
            child: const Text('نعم، احظر الجهاز', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }



  // ==========================================
  // 💬 نافذة تغيير اسم الجهاز
  // ==========================================
  void _showRenameDialog(BuildContext context, dynamic device) {
    final currentCustomName =
        controller.customNames[device.mac.toUpperCase()] ?? '';
    final apiName = device.name.isEmpty ? 'جهاز غير معروف' : device.name;
    final nameCtrl = TextEditingController(text: currentCustomName);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 25,
          right: 25,
          top: 25,
          bottom: MediaQuery.of(context).viewInsets.bottom + 25,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معالج السحب
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 25),

            // العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: glowColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(Iconsax.tag, color: glowColor, size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تسمية الجهاز',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('MAC: ${device.mac}',
                          style: TextStyle(
                              color: subTextColor,
                              fontSize: 11,
                              fontFamily: 'monospace'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // حقل الإدخال
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: glowColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                      color: glowColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: TextField(
                controller: nameCtrl,
                autofocus: true,
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: apiName,
                  hintStyle:
                      TextStyle(color: subTextColor.withValues(alpha: 0.5), fontSize: 14),
                  labelText: 'الاسم المخصص',
                  labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                  prefixIcon:
                      Icon(Iconsax.mobile, color: glowColor, size: 20),
                  suffixIcon: currentCustomName.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: subTextColor, size: 18),
                          onPressed: () => nameCtrl.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // تلميح
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                'اترك الحقل فارغاً لحذف الاسم المخصص والعودة للاسم الافتراضي',
                style: TextStyle(
                    color: subTextColor.withValues(alpha: 0.7), fontSize: 12),
              ),
            ),
            const SizedBox(height: 25),

            // أزرار الإجراء
            Row(
              children: [
                // زر الإلغاء
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text('إلغاء',
                        style: TextStyle(color: subTextColor, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 15),

                // زر الحفظ
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: glowColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                      shadowColor: glowColor.withValues(alpha: 0.4),
                    ),
                    icon: const Icon(Iconsax.tick_circle,
                        color: Colors.white, size: 18),
                    label: const Text('حفظ الاسم',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      Get.back();
                      await controller.renameDevice(device.mac, newName);

                      final msg = newName.isEmpty
                          ? 'تم حذف الاسم المخصص والعودة للاسم الافتراضي'
                          : 'تم حفظ الاسم "$newName" بنجاح ✓';

                      if (newName.isEmpty) {
                        CustomSnackbar.showWarning('تسمية الجهاز', msg);
                      } else {
                        CustomSnackbar.showSuccess('تسمية الجهاز', msg);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // 3. حالة الخطأ
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2,
              color: Colors.redAccent.withValues(alpha: 0.8), size: 60),
          const SizedBox(height: 20),
          Text('حدث خطأ أثناء جلب الأجهزة',
              style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(controller.errorMessage.value,
                style: TextStyle(color: subTextColor, fontSize: 14),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: glowColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15))),
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            label: const Text('إعادة المحاولة',
                style: TextStyle(color: Colors.white)),
            onPressed: () => controller.fetchDevices(),
          )
        ],
      ),
    );
  }

  // 4. حالة القائمة الفارغة
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Iconsax.devices,
              color: subTextColor.withValues(alpha: 0.3), size: 60),
          const SizedBox(height: 20),
          Text('لا توجد أجهزة متصلة حالياً',
              style: TextStyle(color: subTextColor, fontSize: 16)),
        ],
      ),
    );
  }



  // ==========================================
  // 🔔 مفتاح تفعيل مراقبة الأجهزة الجديدة
  // ==========================================
  Widget _buildMonitorToggle() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: controller.isBgMonitorEnabled.value
              ? Colors.tealAccent.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: SwitchListTile(
        title: Text(
          'مراقبة الأجهزة الجديدة',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          controller.isBgMonitorEnabled.value
              ? 'تحت المراقبة...'
              : 'تنبيهك عند اتصال جهاز غير معروف بالشبكة.',
          style: TextStyle(color: subTextColor, fontSize: 11),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: controller.isBgMonitorEnabled.value
                ? Colors.tealAccent.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.shield_tick,
            color: controller.isBgMonitorEnabled.value
                ? Colors.tealAccent
                : Colors.grey,
            size: 22,
          ),
        ),
        value: controller.isBgMonitorEnabled.value,
        activeColor: Colors.tealAccent,
        onChanged: (value) => controller.toggleBgMonitor(value),
      ),
    );
  }

  // ==========================================
  // ❌ نافذة إلغاء توثيق الجهاز
  // ==========================================
  void _showUntrustDialog(BuildContext context, dynamic device) {
    final displayName = controller.getDisplayName(device);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF16213E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.shield_cross,
                  color: Colors.orangeAccent, size: 35),
            ),
            const SizedBox(height: 20),
            Text('إلغاء توثيق الجهاز',
                style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(displayName,
                style: TextStyle(color: glowColor, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text('MAC: ${device.mac}',
                style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontFamily: 'monospace')),
            const SizedBox(height: 25),
            Text(
              'عند إلغاء التوثيق، سيصبح هذا الجهاز غير موثوق وسيتم تنبيهك عند اتصاله بالشبكة.',
              style: TextStyle(color: subTextColor, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text('إلغاء',
                        style: TextStyle(color: subTextColor, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      controller.removeTrustedDevice(device.mac);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    icon: const Icon(Iconsax.shield_cross,
                        color: Colors.white, size: 18),
                    label: const Text('إلغاء التوثيق',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ==========================================
  // ✅ نافذة توثيق/تجاهل الجهاز الجديد
  // ==========================================
  void _showTrustDialog(BuildContext context, dynamic device) {
    final displayName = controller.getDisplayName(device);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF16213E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // معالج السحب
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
            
            // أيقونة التنبيه
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.warning_2,
                  color: Colors.redAccent, size: 35),
            ),
            const SizedBox(height: 20),
            
            Text('جهاز جديد اتصل بالشبكة!',
                style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(displayName,
                style: TextStyle(color: glowColor, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text('MAC: ${device.mac}',
                style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontFamily: 'monospace')),
            const SizedBox(height: 25),
            
            Text(
              'هل تعرف هذا الجهاز؟ إذا كنت تعرفه، أضفه للأجهزة الموثوقة. وإلا، يمكنك تجاهله.',
              style: TextStyle(color: subTextColor, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            
            // أزرار الإجراء
            Row(
              children: [
                // زر التجاهل
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      controller.dismissDevice(device.mac);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    icon: const Icon(Iconsax.close_circle,
                        color: Colors.grey, size: 18),
                    label: Text('تجاهل',
                        style: TextStyle(color: subTextColor, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                // زر التوثيق
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      controller.trustDevice(device.mac);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    icon: const Icon(Iconsax.shield_tick,
                        color: Colors.white, size: 18),
                    label: const Text('وثّق الجهاز',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ==========================================
  // ℹ️ نافذة دليل الشاشة والرموز (التلميحات)
  // ==========================================
  void _showGuideBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF16213E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              children: [
                Icon(Iconsax.info_circle, color: glowColor, size: 24),
                const SizedBox(width: 10),
                Text('دليل الأجهزة وتلميحات الشاشة',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            
            // 1. التلميح الأساسي: السحب للحظر أو تحديد السرعة
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: glowColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: glowColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swipe, color: glowColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السحب السريع على البطاقة',
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                          'اسحب بطاقة الجهاز لليمين لحظر الجهاز، أو اسحب لليسار لإدارة إعدادات الجهاز.',
                          style: TextStyle(color: subTextColor, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // 2. تلميح الأيقونة الخضراء (موثوق)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.shield_tick, color: Colors.green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('أيقونة درع صح (جهاز موثوق)',
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                          'جهاز معروف ومُعتمد، مسموح له بالاتصال بالشبكة دون إرسال إشعارات تنبيهية.',
                          style: TextStyle(color: subTextColor, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // 3. تلميح الأيقونة الحمراء (غير موثوق)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.shield_cross, color: Colors.redAccent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('أيقونة درع خطأ (جهاز غير موثوق)',
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                          'جهاز جديد أو غير معروف. يتم إرسال تنبيه في شريط الإشعارات فور اتصاله بالشبكة.',
                          style: TextStyle(color: subTextColor, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. تلميح الأيقونة الحمراء (غير موثوق)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.shield, color: Colors.grey, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('اجعله موثوقاً او غير موثوق',
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                          'يمكنك الضغط على أيقونة الدرع لتغيير حالة الجهاز بين موثوق وغير موثوق. هذا مفيد لإدارة الأجهزة الجديدة أو غير المعروفة.',
                          style: TextStyle(color: subTextColor, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: glowColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => Get.back(),
                child: const Text('حسناً، فهمت',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}