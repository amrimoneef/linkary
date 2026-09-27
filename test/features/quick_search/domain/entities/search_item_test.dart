import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/domain/entities/search_item.dart';

void main() {
  test('SearchItem entity instantiates with correct fields and defaults', () {
    final item = SearchItem(
      id: 'wifi_settings',
      title: 'إعدادات الواي فاي',
      subtitle: 'تغيير الاسم وكلمة السر',
      icon: Icons.wifi,
      category: SearchCategory.settings,
      keywords: const ['wifi', 'واي فاي', 'باسورد', 'كلمة السر', 'اسم الشبكة', 'SSID', 'الشبكة', 'password', 'كلمة المرور'],
      onTap: () {},
      isDestructive: false,
    );

    expect(item.id, 'wifi_settings');
    expect(item.category, SearchCategory.settings);
    expect(item.keywords.length, 9);
    expect(item.isDestructive, false);
    expect(item.priority, 0);
  });

  test('SearchCategory includes smartTools with correct Arabic label', () {
    expect(SearchCategory.smartTools.labelAr, 'أدوات ذكية');
  });
}
