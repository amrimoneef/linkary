import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl.dart';
import 'package:linkary/features/quick_search/infrastructure/services/search_index_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuickSearchRepositoryImpl', () {
    late SharedPreferences prefs;
    late QuickSearchRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = QuickSearchRepositoryImpl(
        registry: SearchIndexRegistry(),
        sharedPreferences: prefs,
      );
    });

    test('search ranks exact title matches higher than tag matches', () {
      final results = repo.search(query: 'واي فاي');
      expect(results.isNotEmpty, true);
      expect(results.first.id, 'wifi_settings');
    });

    test('search handles Arabic synonyms like باسورد', () {
      final results = repo.search(query: 'باسورد');
      expect(results.any((r) => r.id == 'wifi_settings'), true);
    });

    test('search filters by category correctly', () {
      final settingsResults = repo.search(query: 'سرعة', category: SearchCategory.settings);
      expect(settingsResults.any((r) => r.id == 'speed_limit'), true);
      expect(settingsResults.any((r) => r.id == 'speed_test'), false);

      final smartToolsResults = repo.search(query: 'سرعة', category: SearchCategory.smartTools);
      expect(smartToolsResults.any((r) => r.id == 'speed_test'), true);
      expect(smartToolsResults.any((r) => r.id == 'speed_limit'), false);
    });

    test('recent searches persist and can be removed and cleared', () async {
      await repo.saveRecentSearch('واي فاي');
      await repo.saveRecentSearch('تحديد السرعة');

      var recents = await repo.getRecentSearches();
      expect(recents.length, 2);
      expect(recents.first, 'تحديد السرعة'); // Most recent first

      await repo.removeRecentSearch('واي فاي');
      recents = await repo.getRecentSearches();
      expect(recents.length, 1);
      expect(recents.first, 'تحديد السرعة');

      await repo.clearRecentSearches();
      recents = await repo.getRecentSearches();
      expect(recents.isEmpty, true);
    });
  });
}
