import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsRepository {
  static const String _storageKey = 'sam4g_notifications_list';
  final SharedPreferences _prefs;

  NotificationsRepository(this._prefs);

  List<NotificationEntity> getNotifications() {
    final List<String>? jsonList = _prefs.getStringList(_storageKey);
    if (jsonList == null) return [];
    
    return jsonList
        .map((jsonStr) => NotificationEntity.fromJson(jsonStr))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // الأحدث أولاً
  }

  Future<void> saveNotification(NotificationEntity notification) async {
    final List<NotificationEntity> current = getNotifications();
    current.add(notification);
    
    // الاحتفاظ بآخر 50 إشعار فقط لعدم استهلاك الذاكرة
    if (current.length > 50) {
      current.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      current.removeRange(50, current.length);
    }
    
    final List<String> jsonList = current.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_storageKey, jsonList);
  }

  Future<void> markAsRead(String id) async {
    final List<NotificationEntity> current = getNotifications();
    final index = current.indexWhere((e) => e.id == id);
    if (index != -1) {
      current[index].isRead = true;
      final List<String> jsonList = current.map((e) => e.toJson()).toList();
      await _prefs.setStringList(_storageKey, jsonList);
    }
  }
  
  Future<void> markAllAsRead() async {
    final List<NotificationEntity> current = getNotifications();
    for (var notif in current) {
      notif.isRead = true;
    }
    final List<String> jsonList = current.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_storageKey, jsonList);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_storageKey);
  }
}
