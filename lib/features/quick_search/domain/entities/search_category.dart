enum SearchCategory {
  all,
  settings,
  devices,
  quickActions,
  tools,
  smartTools,
}

extension SearchCategoryExtension on SearchCategory {
  String get labelAr {
    switch (this) {
      case SearchCategory.all:
        return 'الكل';
      case SearchCategory.settings:
        return 'الإعدادات';
      case SearchCategory.devices:
        return 'الأجهزة';
      case SearchCategory.quickActions:
        return 'إجراءات سريعة';
      case SearchCategory.tools:
        return 'أدوات المودم';
      case SearchCategory.smartTools:
        return 'أدوات ذكية';
    }
  }
}
