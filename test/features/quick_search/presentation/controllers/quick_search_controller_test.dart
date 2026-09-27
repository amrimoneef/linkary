import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl.dart';
import 'package:linkary/features/quick_search/infrastructure/services/search_index_registry.dart';
import 'package:linkary/features/quick_search/presentation/controllers/quick_search_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuickSearchController', () {
    late SharedPreferences prefs;
    late QuickSearchRepositoryImpl repo;
    late QuickSearchController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = QuickSearchRepositoryImpl(
        registry: SearchIndexRegistry(),
        sharedPreferences: prefs,
      );
      controller = QuickSearchController(repository: repo);
    });

    test('onQueryChanged filters results immediately and updates searchQuery', () {
      controller.onQueryChanged('سرعة', immediate: true);
      expect(controller.searchQuery.value, 'سرعة');
      expect(controller.searchResults.isNotEmpty, true);
    });

    test('setCategory updates category and refreshes results', () {
      controller.onQueryChanged('سرعة');
      controller.setCategory(SearchCategory.smartTools);
      expect(controller.selectedCategory.value, SearchCategory.smartTools);
      expect(controller.searchResults.any((item) => item.id == 'speed_test'), true);
      expect(controller.searchResults.any((item) => item.id == 'speed_limit'), false);
    });

    test('recent searches can be added, selected, and cleared', () async {
      await controller.saveQueryToRecent('مودم');
      expect(controller.recentSearches.contains('مودم'), true);

      controller.selectRecentSearch('مودم');
      expect(controller.searchQuery.value, 'مودم');

      await controller.clearAllRecentSearches();
      expect(controller.recentSearches.isEmpty, true);
    });
  });
}
