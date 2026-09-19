import '../entities/widget_config_entity.dart';

abstract class QuickToolsRepository {
  Future<bool> isNotificationEnabled();
  Future<void> setNotificationEnabled(bool enabled);
  Future<WidgetConfigEntity> getWidgetConfig();
  Future<void> saveWidgetConfig(WidgetConfigEntity config);
}
