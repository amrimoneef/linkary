import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui';
import '../controllers/notifications_controller.dart';
import 'package:intl/intl.dart' as intl;

class NotificationsPage extends StatelessWidget {
  NotificationsPage({super.key});

  final NotificationsController controller = Get.find<NotificationsController>();

  Color bgColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  Color textColor(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
  Color subTextColor(BuildContext context) => Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'مركز الإشعارات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.notifications.isEmpty) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textColor(context)),
              onSelected: (value) {
                if (value == 'read_all') {
                  controller.markAllAsRead();
                } else if (value == 'clear_all') {
                  _showClearAllDialog(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('تحديد الكل كمقروء'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('حذف جميع الإشعارات', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            );
          })
        ],
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return _buildNotificationItem(context, notification);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.notification_bing, size: 100, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            'لا توجد إشعارات حالياً',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor(context).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ستظهر هنا أي رسائل أو تنبيهات جديدة تصلك.',
            style: TextStyle(
              fontSize: 14,
              color: subTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, dynamic notification) {
    final bool isUnread = !notification.isRead;
    
    // تنسيق التاريخ والوقت
    String formattedTime = '';
    try {
      formattedTime = intl.DateFormat('hh:mm a - yyyy/MM/dd', 'ar').format(notification.timestamp);
    } catch (e) {
      formattedTime = '${notification.timestamp.year}/${notification.timestamp.month}/${notification.timestamp.day}';
    }

    return GestureDetector(
      onTap: () {
        if (isUnread) controller.markAsRead(notification.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            // الظل الخارجي الناعم (Soft Outer Shadow)
            BoxShadow(
              color: Colors.black.withValues(alpha: Get.isDarkMode ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // تمويه عالي (Watery iOS Blur)
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // لون الخلفية مع تدرج شفاف جداً ليعطي انعكاس الزجاج
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Get.isDarkMode
                      ? [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.03),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                // الحدود البيضاء الشفافة تعطي لمعة الزجاج
                border: Border.all(
                  color: isUnread 
                      ? const Color(0xFF4A90E2).withValues(alpha: 0.6)
                      : (Get.isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.white),
                  width: isUnread ? 1.5 : 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الأيقونة المضيئة 
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUnread 
                            ? [const Color(0xFF4A90E2), const Color(0xFF50E3C2)]
                            : [Colors.grey.withValues(alpha: 0.2), Colors.grey.withValues(alpha: 0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: isUnread ? [
                        BoxShadow(
                          color: const Color(0xFF4A90E2).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Icon(
                      isUnread ? Iconsax.notification_bing5 : Iconsax.notification,
                      color: isUnread ? Colors.white : (Get.isDarkMode ? Colors.white54 : Colors.black54),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // المحتوى النصي
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  color: textColor(context),
                                  fontSize: 16,
                                  fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF50E3C2), // نقطة خضراء ساطعة
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF50E3C2).withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.body,
                          style: TextStyle(
                            color: subTextColor(context),
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Iconsax.clock, size: 14, color: subTextColor(context).withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: subTextColor(context).withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد أنك تريد حذف جميع الإشعارات نهائياً؟', style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              controller.clearAll();
              Get.back();
            },
            child: const Text('نعم، حذف الكل', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
