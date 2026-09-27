import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/domain/entities/search_item.dart';

abstract class QuickSearchRepository {
  List<SearchItem> getAllSearchItems();
  
  List<SearchItem> search({
    required String query,
    SearchCategory category = SearchCategory.all,
  });

  Future<List<String>> getRecentSearches();
  Future<void> saveRecentSearch(String query);
  Future<void> removeRecentSearch(String query);
  Future<void> clearRecentSearches();
}
