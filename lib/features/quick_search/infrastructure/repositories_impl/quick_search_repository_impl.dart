import 'package:shared_preferences/shared_preferences.dart';

import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/domain/entities/search_item.dart';
import 'package:linkary/features/quick_search/domain/repositories/quick_search_repository.dart';
import 'package:linkary/features/quick_search/infrastructure/services/arabic_text_normalizer.dart';
import 'package:linkary/features/quick_search/infrastructure/services/search_index_registry.dart';

class QuickSearchRepositoryImpl implements QuickSearchRepository {
  static const String _recentSearchesKey = 'quick_search_recent_queries';
  static const int _maxRecentSearches = 8;

  final SearchIndexRegistry registry;
  final SharedPreferences sharedPreferences;

  QuickSearchRepositoryImpl({
    required this.registry,
    required this.sharedPreferences,
  });

  @override
  List<SearchItem> getAllSearchItems() {
    final staticItems = registry.getStaticItems();
    final dynamicItems = registry.getDynamicItems();
    return [...dynamicItems, ...staticItems];
  }

  @override
  List<SearchItem> search({
    required String query,
    SearchCategory category = SearchCategory.all,
  }) {
    final allItems = getAllSearchItems();
    final normalizedQuery = ArabicTextNormalizer.normalize(query);

    if (normalizedQuery.isEmpty) {
      if (category == SearchCategory.all) {
        return allItems..sort((a, b) => b.priority.compareTo(a.priority));
      }
      return allItems.where((item) => item.category == category).toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
    }

    final queryWords = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();
    final scoredItems = <_ScoredItem>[];

    for (final item in allItems) {
      // 1. Check category filter
      if (category != SearchCategory.all && item.category != category) {
        continue;
      }

      final normalizedTitle = ArabicTextNormalizer.normalize(item.title);
      final normalizedSubtitle = ArabicTextNormalizer.normalize(item.subtitle);
      final normalizedKeywords = item.keywords
          .map((k) => ArabicTextNormalizer.normalize(k))
          .toList();

      int score = 0;

      // 2. Exact / Full match on title
      if (normalizedTitle == normalizedQuery) {
        score += 100;
      } else if (normalizedTitle.startsWith(normalizedQuery)) {
        score += 60;
      } else if (normalizedTitle.contains(normalizedQuery)) {
        score += 40;
      }

      // 3. Keyword / Synonym matches
      for (final keyword in normalizedKeywords) {
        if (keyword == normalizedQuery) {
          score += 55;
        } else if (keyword.startsWith(normalizedQuery)) {
          score += 35;
        } else if (keyword.contains(normalizedQuery)) {
          score += 20;
        }
      }

      // 4. Subtitle match
      if (normalizedSubtitle.contains(normalizedQuery)) {
        score += 15;
      }

      // 5. Multi-word partial matching
      if (queryWords.length > 1) {
        int wordsMatched = 0;
        for (final word in queryWords) {
          final inTitle = normalizedTitle.contains(word);
          final inKeywords = normalizedKeywords.any((k) => k.contains(word));
          final inSubtitle = normalizedSubtitle.contains(word);

          if (inTitle || inKeywords || inSubtitle) {
            wordsMatched++;
          }
        }
        if (wordsMatched == queryWords.length) {
          score += 50;
        } else if (wordsMatched > 0) {
          score += wordsMatched * 10;
        }
      }

      // 6. Factor in default priority
      if (score > 0) {
        score += item.priority * 2;
        scoredItems.add(_ScoredItem(item: item, score: score));
      }
    }

    // Sort by highest score first
    scoredItems.sort((a, b) => b.score.compareTo(a.score));

    return scoredItems.map((s) => s.item).toList();
  }

  @override
  Future<List<String>> getRecentSearches() async {
    final list = sharedPreferences.getStringList(_recentSearchesKey);
    return list ?? [];
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = await getRecentSearches();
    final updated = List<String>.from(current);

    // Remove if already present so it moves to front
    updated.remove(trimmed);
    updated.insert(0, trimmed);

    // Keep within max limit
    if (updated.length > _maxRecentSearches) {
      updated.removeRange(_maxRecentSearches, updated.length);
    }

    await sharedPreferences.setStringList(_recentSearchesKey, updated);
  }

  @override
  Future<void> removeRecentSearch(String query) async {
    final current = await getRecentSearches();
    final updated = List<String>.from(current);
    updated.remove(query);
    await sharedPreferences.setStringList(_recentSearchesKey, updated);
  }

  @override
  Future<void> clearRecentSearches() async {
    await sharedPreferences.remove(_recentSearchesKey);
  }
}

class _ScoredItem {
  final SearchItem item;
  final int score;

  _ScoredItem({required this.item, required this.score});
}
