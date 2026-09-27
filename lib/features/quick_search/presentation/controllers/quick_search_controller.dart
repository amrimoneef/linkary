import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/domain/entities/search_item.dart';
import 'package:linkary/features/quick_search/domain/repositories/quick_search_repository.dart';
import 'package:linkary/features/voice_assistant/infrastructure/services/speech_recognition_service.dart';

class QuickSearchController extends GetxController {
  final QuickSearchRepository repository;

  QuickSearchController({required this.repository});

  final TextEditingController textEditingController = TextEditingController();

  // Observable state
  final RxString searchQuery = ''.obs;
  final Rx<SearchCategory> selectedCategory = SearchCategory.all.obs;
  final RxList<SearchItem> searchResults = <SearchItem>[].obs;
  final RxList<String> recentSearches = <String>[].obs;
  final RxBool isVoiceListening = false.obs;

  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    loadRecentSearches();
    _performSearch();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    textEditingController.dispose();
    super.onClose();
  }

  /// Handles search query change with a slight debounce (or immediate execution)
  void onQueryChanged(String query, {bool immediate = false}) {
    searchQuery.value = query;
    _debounceTimer?.cancel();
    if (immediate) {
      _performSearch();
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 100), () {
        _performSearch();
      });
    }
  }

  /// Changes the category filter and executes a refreshed search
  void setCategory(SearchCategory category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    _performSearch();
  }

  /// Clears the current search query
  void clearQuery() {
    textEditingController.clear();
    searchQuery.value = '';
    _performSearch();
  }

  /// Performs the actual search from the repository
  void _performSearch() {
    final results = repository.search(
      query: searchQuery.value,
      category: selectedCategory.value,
    );
    searchResults.assignAll(results);
  }

  /// Loads persisted recent searches
  Future<void> loadRecentSearches() async {
    final list = await repository.getRecentSearches();
    recentSearches.assignAll(list);
  }

  /// Saves a search query to recents
  Future<void> saveQueryToRecent(String query) async {
    if (query.trim().isEmpty) return;
    await repository.saveRecentSearch(query);
    await loadRecentSearches();
  }

  /// Selects a query from recents to fill the search bar and run
  void selectRecentSearch(String query) {
    textEditingController.text = query;
    textEditingController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    searchQuery.value = query;
    _performSearch();
  }

  /// Removes an individual recent search
  Future<void> removeRecentSearch(String query) async {
    await repository.removeRecentSearch(query);
    recentSearches.remove(query);
  }

  /// Clears all recent searches
  Future<void> clearAllRecentSearches() async {
    await repository.clearRecentSearches();
    recentSearches.clear();
  }

  /// Starts speech-to-text recognition to fill query
  Future<void> startVoiceSearch() async {
    if (!Get.isRegistered<SpeechRecognitionService>()) {
      Get.rawSnackbar(
        message: 'خدمة التعرف الصوتي غير متوفرة حالياً',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      final speechService = Get.find<SpeechRecognitionService>();

      if (speechService.isListening) {
        speechService.stopListening();
        isVoiceListening.value = false;
        return;
      }

      isVoiceListening.value = true;
      await speechService.startListening(
        onResult: (text, confidence, isFinal) {
          if (text.isNotEmpty) {
            textEditingController.text = text;
            textEditingController.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
            onQueryChanged(text);
          }
          if (isFinal) {
            isVoiceListening.value = false;
          }
        },
      );
    } catch (_) {
      isVoiceListening.value = false;
    }
  }

  /// Executes action: checks if destructive, saves search, and calls onTap
  void executeAction({
    required BuildContext context,
    required SearchItem item,
    required VoidCallback onConfirmDestructive,
  }) {
    if (searchQuery.value.trim().isNotEmpty) {
      saveQueryToRecent(searchQuery.value.trim());
    }

    if (item.isDestructive) {
      onConfirmDestructive();
    } else {
      Get.back(); // close modal sheet if open
      item.onTap();
    }
  }
}
