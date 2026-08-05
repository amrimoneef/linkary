import 'package:get/get.dart';
import '../../domain/entities/notification_entity.dart';
import '../../infrastructure/repositories/notifications_repository.dart';

class NotificationsController extends GetxController {
  final NotificationsRepository _repository;

  NotificationsController(this._repository);

  // قائمة الإشعارات القابلة للملاحظة (Reactive)
  final RxList<NotificationEntity> notifications = <NotificationEntity>[].obs;
  
  // عدد الإشعارات غير المقروءة
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  void loadNotifications() {
    notifications.assignAll(_repository.getNotifications());
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  Future<void> addNotification(NotificationEntity notification) async {
    await _repository.saveNotification(notification);
    loadNotifications(); // تحديث القائمة
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    loadNotifications();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    loadNotifications();
  }
}
