import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/widget_config_entity.dart';
import '../../domain/repositories/quick_tools_repository.dart';

class QuickToolsRepositoryImpl implements QuickToolsRepository {
  final SharedPreferences sharedPreferences;

  static const String _notificationKey = 'quick_notification_enabled_key';
  static const String _widgetConfigKey = 'widget_config_json_key';

  QuickToolsRepositoryImpl({required this.sharedPreferences});

  @override
  Future<bool> isNotificationEnabled() async {
    return sharedPreferences.getBool(_notificationKey) ?? false;
  }

  @override
  Future<void> setNotificationEnabled(bool enabled) async {
    await sharedPreferences.setBool(_notificationKey, enabled);
  }

  @override
  Future<WidgetConfigEntity> getWidgetConfig() async {
    final jsonStr = sharedPreferences.getString(_widgetConfigKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = json.decode(jsonStr);
        return WidgetConfigEntity.fromJson(decoded);
      } catch (_) {}
    }
    return const WidgetConfigEntity();
  }

  @override
  Future<void> saveWidgetConfig(WidgetConfigEntity config) async {
    await sharedPreferences.setString(
      _widgetConfigKey,
      json.encode(config.toJson()),
    );
  }
}
