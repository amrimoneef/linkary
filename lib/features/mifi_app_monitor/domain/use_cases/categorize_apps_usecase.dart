import '../entities/app_category.dart';
import '../entities/app_usage_entity.dart';
import '../../infrastructure/mappers/app_category_mapper.dart';

class CategorizeAppsUseCase {
  /// Enriches a list of AppUsageEntity with categories and system flags.
  List<AppUsageEntity> execute(List<AppUsageEntity> apps) {
    return apps.map((app) {
      final category = AppCategoryMapper.categorize(app.packageName);
      return AppUsageEntity(
        packageName: app.packageName,
        appName: app.appName,
        totalBytes: app.totalBytes,
        rxBytes: app.rxBytes,
        txBytes: app.txBytes,
        rxSpeed: app.rxSpeed,
        txSpeed: app.txSpeed,
        iconData: app.iconData,
        category: category,
        isSystemApp: category == AppCategory.system,
        lastActiveTime: app.lastActiveTime ?? (app.isCurrentlyActive ? DateTime.now() : null),
        usageTime: app.usageTime,

      );
    }).toList();
  }
}
