import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/infrastructure/services/search_index_registry.dart';

void main() {
  test('SearchIndexRegistry returns rich static items covering settings, tools and smartTools', () {
    final registry = SearchIndexRegistry();
    final items = registry.getStaticItems();

    expect(items.isNotEmpty, true);
    expect(items.any((i) => i.id == 'wifi_settings'), true);
    expect(items.any((i) => i.id == 'speed_test' && i.category == SearchCategory.smartTools), true);
    expect(items.any((i) => i.id == 'signal_finder' && i.category == SearchCategory.smartTools), true);
    expect(items.any((i) => i.id == 'reboot_modem' && i.isDestructive == true), true);
    expect(items.any((i) => i.id == 'connected_devices'), true);
  });
}
