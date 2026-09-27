# Quick Search (Universal Spotlight) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a blazingly fast, elegant, and actionable Universal Spotlight & Command Palette feature (`quick_search`) for Linkary, integrating static navigation/settings, live connected devices, quick router actions, Arabic text normalization, voice input, and global swipe-up access.

**Architecture:** Clean Architecture with three layers (`domain`, `infrastructure`, `presentation`). Reactive state management via GetX. Hybrid search index combining static metadata with live in-memory router state, ranked via a weighted relevance scoring algorithm.

**Tech Stack:** Flutter 3, Dart 3, GetX (`.obs`, `GetxController`), `Iconsax`, `SharedPreferences`, `dart:ui` (BackdropFilter).

---

### Task 1: Domain Entities & Category Enums

**Files:**
- Create: `lib/features/quick_search/domain/entities/search_category.dart`
- Create: `lib/features/quick_search/domain/entities/search_item.dart`
- Create: `lib/features/quick_search/domain/repositories/quick_search_repository.dart`
- Test: `test/features/quick_search/domain/entities/search_item_test.dart`

**Step 1: Write the failing unit test**
Create `test/features/quick_search/domain/entities/search_item_test.dart`:
```dart
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
      keywords: ['wifi', 'واي فاي', 'باسورد', 'كلمة السر', 'اسم الشبكة', 'SSID', 'الشبكة', 'password', 'كلمة المرور'],
      onTap: () {},
      isDestructive: false,
    );

    expect(item.id, 'wifi_settings');
    expect(item.category, SearchCategory.settings);
    expect(item.keywords.length, 3);
    expect(item.isDestructive, false);
    expect(item.priority, 0);
  });
}
```

**Step 2: Run test to verify it fails**
Run: `cmd /c flutter test test/features/quick_search/domain/entities/search_item_test.dart`  
Expected: FAIL with compilation error (classes not found).

**Step 3: Write minimal implementation**
1. Create `lib/features/quick_search/domain/entities/search_category.dart`:
```dart
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
```

2. Create `lib/features/quick_search/domain/entities/search_item.dart`:
```dart
import 'package:flutter/material.dart';
import 'search_category.dart';

class SearchItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final SearchCategory category;
  final List<String> keywords;
  final VoidCallback onTap;
  final Widget? quickActionWidget;
  final bool isDestructive;
  final String? confirmationMessage;
  final int priority;

  const SearchItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.keywords,
    required this.onTap,
    this.quickActionWidget,
    this.isDestructive = false,
    this.confirmationMessage,
    this.priority = 0,
  });
}
```

3. Create `lib/features/quick_search/domain/repositories/quick_search_repository.dart`:
```dart
import '../entities/search_category.dart';
import '../entities/search_item.dart';

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
```

**Step 4: Run test to verify it passes**
Run: `cmd /c flutter test test/features/quick_search/domain/entities/search_item_test.dart`  
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/features/quick_search/domain/ test/features/quick_search/domain/
git commit -m "feat(quick_search): add domain entities and repository contract"
```

---

### Task 2: Infrastructure - Arabic Text Normalizer

**Files:**
- Create: `lib/features/quick_search/infrastructure/services/arabic_text_normalizer.dart`
- Test: `test/features/quick_search/infrastructure/services/arabic_text_normalizer_test.dart`

**Step 1: Write the failing unit test**
Create `test/features/quick_search/infrastructure/services/arabic_text_normalizer_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/quick_search/infrastructure/services/arabic_text_normalizer.dart';

void main() {
  group('ArabicTextNormalizer', () {
    test('normalizes hamzas correctly', () {
      expect(ArabicTextNormalizer.normalize('إعدادات'), 'اعدادات');
      expect(ArabicTextNormalizer.normalize('أجهزة'), 'اجهزة');
      expect(ArabicTextNormalizer.normalize('آمن'), 'امن');
    });

    test('strips diacritics / tashkeel', () {
      expect(ArabicTextNormalizer.normalize('إِعْدَادَاتُ الشَّبَكَةِ'), 'اعدادات الشبكه');
    });

    test('normalizes ta marbuta and alif maqsura', () {
      expect(ArabicTextNormalizer.normalize('سرعة'), 'سرعه');
      expect(ArabicTextNormalizer.normalize('مستشفى'), 'مستشفي');
    });

    test('handles case and whitespace for mixed languages', () {
      expect(ArabicTextNormalizer.normalize('  Wi-Fi  Password  '), 'wi-fi password');
    });
  });
}
```

**Step 2: Run test to verify it fails**
Run: `cmd /c flutter test test/features/quick_search/infrastructure/services/arabic_text_normalizer_test.dart`  
Expected: FAIL.

**Step 3: Write minimal implementation**
Create `lib/features/quick_search/infrastructure/services/arabic_text_normalizer.dart`:
```dart
class ArabicTextNormalizer {
  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');

  /// Normalizes Arabic text by removing diacritics, unifying hamzas,
  /// converting ta marbuta to ha, and alif maqsura to ya.
  static String normalize(String text) {
    if (text.isEmpty) return '';

    String cleaned = text.trim().toLowerCase();

    // 1. Remove Tashkeel (diacritics)
    cleaned = cleaned.replaceAll(_tashkeelRegex, '');

    // 2. Unify Hamzas (أ, إ, آ, ء -> ا)
    cleaned = cleaned
        .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ء', '');

    // 3. Unify Ta Marbuta (ة -> ه)
    cleaned = cleaned.replaceAll('ة', 'ه');

    // 4. Unify Alif Maqsura (ى -> ي)
    cleaned = cleaned.replaceAll('ى', 'ي');

    // 5. Replace multiple spaces with single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned;
  }
}
```

**Step 4: Run test to verify it passes**
Run: `cmd /c flutter test test/features/quick_search/infrastructure/services/arabic_text_normalizer_test.dart`  
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/features/quick_search/infrastructure/services/arabic_text_normalizer.dart test/features/quick_search/infrastructure/services/arabic_text_normalizer_test.dart
git commit -m "feat(quick_search): implement Arabic text normalization utility"
```

---

### Task 3: Infrastructure - Search Index Registry

**Files:**
- Create: `lib/features/quick_search/infrastructure/services/search_index_registry.dart`
- Test: `test/features/quick_search/infrastructure/services/search_index_registry_test.dart`

**Step 1: Write the failing unit test**
Create `test/features/quick_search/infrastructure/services/search_index_registry_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/infrastructure/services/search_index_registry.dart';

void main() {
  test('SearchIndexRegistry returns rich static items covering settings and tools', () {
    final registry = SearchIndexRegistry();
    final items = registry.getStaticItems();

    expect(items.isNotEmpty, true);
    expect(items.any((i) => i.id == 'wifi_settings'), true);
    expect(items.any((i) => i.id == 'speed_test'), true);
    expect(items.any((i) => i.id == 'reboot_modem'), true);
  });
}
```

**Step 2: Run test to verify it fails**
Run: `cmd /c flutter test test/features/quick_search/infrastructure/services/search_index_registry_test.dart`  
Expected: FAIL.

**Step 3: Write implementation**
Create `lib/features/quick_search/infrastructure/services/search_index_registry.dart`:
- Implement `getStaticItems()` containing comprehensive definitions of all Linkary screens, settings, and tools:
  - Wi-Fi Settings (`wifi_settings`): tags [واي فاي, wifi, باسورد, كلمة السر, اسم الشبكة, تردد, 5ghz, 2.4ghz]
  - Connected Devices (`connected_devices`): tags [اجهزة, متصلة, هواتف, ip, mac, المتصلين]
  - Speed Test (`speed_test`): tags [سرعة, قياس, نت, اختبار, فحص, speed, fast]
  - Speed Limit (`speed_limit`): tags [تحديد السرعة, سرعة, خنق, limit, باندويث]
  - Data Usage (`data_usage`): tags [استهلاك, باقة, بيانات, رصيد, جيجا, usage]
  - Parental Control (`parental_control`): tags [رقابة ابوية, حظر, اطفال, مواقع, parental]
  - MAC Filter (`mac_filter`): tags [ماك ادرس, حظر, تصفية, mac, blacklist]
  - Signal Finder (`signal_finder`): tags [اشارة, ابراج, شبكة, افضل مكان, تغطية, signal]
  - Modem Finder (`modem_finder`): tags [البحث عن الراوتر, اين المودم, فايندر, finder]
  - Recharge & Bill (`bill`): tags [فاتورة, شحن, سداد, رصيد, دفع, bill]
  - LCD Settings (`lcd_settings`): tags [شاشة, اضاءة, سكون, lcd, display]
  - Battery Settings (`battery_settings`): tags [بطارية, شحن, توفير الطاقة, battery]
  - Quick Tools & Widgets (`widgets_settings`): tags [ودجات, اختصارات, شريط اشعارات, widgets]
  - Admin Password (`admin_settings`): tags [كلمة سر المودم, ادمن, تسجيل الدخول, admin]
  - Voice Assistant (`voice_assistant`): tags [مساعد صوتي, صوت, اوامر صوتية, voice]
  - Quick Reboot (`reboot_modem`): tags [اعادة تشغيل, ريستارت, reboot, restart], isDestructive: true
  - Quick Power Off (`power_off`): tags [ايقاف, اغلاق, اطفاء, shutdown, power off], isDestructive: true
- Implement `getDynamicItems()`:
  - If `Get.isRegistered<ConnectedDevicesController>()`: map each device into a `SearchItem` with direct copy IP/MAC actions and block navigation.
  - If `Get.isRegistered<DashboardController>()`: generate live network and modem status items.

**Step 4: Run test to verify it passes**
Run: `cmd /c flutter test test/features/quick_search/infrastructure/services/search_index_registry_test.dart`  
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/features/quick_search/infrastructure/services/search_index_registry.dart test/features/quick_search/infrastructure/services/search_index_registry_test.dart
git commit -m "feat(quick_search): implement search index registry with static and dynamic items"
```

---

### Task 4: Infrastructure - Quick Search Repository Implementation

**Files:**
- Create: `lib/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl.dart`
- Test: `test/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl_test.dart`

**Step 1: Write the failing unit test**
Create `test/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl.dart';
import 'package:linkary/features/quick_search/infrastructure/services/search_index_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('search ranks exact title matches higher than tag matches', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = QuickSearchRepositoryImpl(
      registry: SearchIndexRegistry(),
      sharedPreferences: prefs,
    );

    final results = repo.search(query: 'واي فاي');
    expect(results.isNotEmpty, true);
    expect(results.first.id, 'wifi_settings');
  });

  test('search handles Arabic synonyms like باسورد', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = QuickSearchRepositoryImpl(
      registry: SearchIndexRegistry(),
      sharedPreferences: prefs,
    );

    final results = repo.search(query: 'باسورد');
    expect(results.any((r) => r.id == 'wifi_settings'), true);
  });
}
```

**Step 2: Run test to verify it fails**
Run: `cmd /c flutter test test/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl_test.dart`  
Expected: FAIL.

**Step 3: Write implementation**
Create `lib/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl.dart`:
- Incorporates `ArabicTextNormalizer`.
- Calculates match score:
  - Exact or normalized title match: +100 points
  - Title starts with query: +50 points
  - Normalized keyword match: +30 points each
  - Subtitle match: +15 points
  - Add item.priority
- Filters by `SearchCategory` if not `SearchCategory.all`.
- Implements `getRecentSearches()`, `saveRecentSearch()`, `removeRecentSearch()`, `clearRecentSearches()` via `SharedPreferences`.

**Step 4: Run test to verify it passes**
Run: `cmd /c flutter test test/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl_test.dart`  
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl.dart test/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl_test.dart
git commit -m "feat(quick_search): implement quick search repository with weighted ranking"
```

---

### Task 5: Presentation - QuickSearchController & DI Registration

**Files:**
- Create: `lib/features/quick_search/presentation/controllers/quick_search_controller.dart`
- Modify: `lib/core/di/injection_container.dart`
- Test: `test/features/quick_search/presentation/controllers/quick_search_controller_test.dart`

**Step 1: Write the failing unit test**
Create `test/features/quick_search/presentation/controllers/quick_search_controller_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/quick_search/presentation/controllers/quick_search_controller.dart';
import 'package:linkary/features/quick_search/infrastructure/repositories_impl/quick_search_repository_impl.dart';
import 'package:linkary/features/quick_search/infrastructure/services/search_index_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('QuickSearchController updates results on query change', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = QuickSearchRepositoryImpl(
      registry: SearchIndexRegistry(),
      sharedPreferences: prefs,
    );
    final controller = QuickSearchController(repository: repo);

    controller.onQueryChanged('سرعة');
    expect(controller.searchQuery.value, 'سرعة');
    expect(controller.searchResults.isNotEmpty, true);
  });
}
```

**Step 2: Run test to verify it fails**
Run: `cmd /c flutter test test/features/quick_search/presentation/controllers/quick_search_controller_test.dart`  
Expected: FAIL.

**Step 3: Write implementation**
1. Create `lib/features/quick_search/presentation/controllers/quick_search_controller.dart`:
   - `searchQuery = ''.obs`
   - `selectedCategory = SearchCategory.all.obs`
   - `searchResults = <SearchItem>[].obs`
   - `recentSearches = <String>[].obs`
   - `isVoiceListening = false.obs`
   - `onQueryChanged(String text)`
   - `setCategory(SearchCategory category)`
   - `executeAction(BuildContext context, SearchItem item)`: checks `item.isDestructive` -> shows `QuickConfirmDialog`, otherwise runs `item.onTap()` and saves recent search.
   - `startVoiceSearch()`: integrates with Speech Recognition if available.
2. In `lib/core/di/injection_container.dart`:
   - Register `SearchIndexRegistry`, `QuickSearchRepository`, and `QuickSearchController` with `fenix: true`.

**Step 4: Run test to verify it passes**
Run: `cmd /c flutter test test/features/quick_search/presentation/controllers/quick_search_controller_test.dart`  
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/features/quick_search/presentation/controllers/quick_search_controller.dart lib/core/di/injection_container.dart test/features/quick_search/presentation/controllers/quick_search_controller_test.dart
git commit -m "feat(quick_search): implement controller and register in DI container"
```

---

### Task 6: Presentation - UI Components (Tiles, Filter Chips, Confirm Dialog)

**Files:**
- Create: `lib/features/quick_search/presentation/widgets/search_filter_chips.dart`
- Create: `lib/features/quick_search/presentation/widgets/search_result_tile.dart`
- Create: `lib/features/quick_search/presentation/widgets/quick_confirm_dialog.dart`

**Step 1: Write minimal widget implementation**
- `search_filter_chips.dart`:
  - Horizontal scrolling row of chips for `[الكل, الإعدادات, الأجهزة, إجراءات سريعة, أدوات المودم, أدوات ذكية]`.
  - Glassmorphic active state with blue highlight and smooth animated selection.
- `search_result_tile.dart`:
  - Modern card with dark/light adaptive styling.
  - Icon container with gradient background corresponding to category.
  - Highlighted title matching query.
  - Subtitle with category badge.
  - Trailing action button (e.g., Copy button for IP/MAC, arrow for navigation).
- `quick_confirm_dialog.dart`:
  - Elegant modal dialog with warning icon, title, description, and [تأكيد / إلغاء] buttons with destructive color (Red/Orange).

**Step 2: Verify with flutter analyze**
Run: `cmd /c flutter analyze lib/features/quick_search/presentation/widgets/`  
Expected: 0 issues.

**Step 3: Commit**
```bash
git add lib/features/quick_search/presentation/widgets/
git commit -m "feat(quick_search): implement search result tiles, filter chips, and confirmation dialog"
```

---

### Task 7: Presentation - Hero Search Bar & Modal Sheet

**Files:**
- Create: `lib/features/quick_search/presentation/widgets/hero_search_bar.dart`
- Create: `lib/features/quick_search/presentation/widgets/quick_search_modal_sheet.dart`

**Step 1: Write implementation**
- `hero_search_bar.dart`:
  - Glassmorphic container with `BackdropFilter` (blur: 10).
  - Search icon with subtle pulse/glow.
  - Animated hint text switching periodically between:
    - *"ابحث عن إعداد، جهاز، أو كلمة سر..."*
    - *"اكتب 192 أو اسم الجهاز للوصول الفوري..."*
    - *"اسحب للأعلى من أي مكان للبحث السريع..."*
  - Microphone icon that triggers voice search.
  - `onTap`: calls `QuickSearchModalSheet.show(context)`.
- `quick_search_modal_sheet.dart`:
  - Full-height interactive modal sheet (`showModalBottomSheet` or custom overlay) with `BackdropFilter` (blur: 25).
  - Drag handle bar at the top.
  - Search `TextField` with auto-focus, clear button, and voice search button.
  - Filter chips row.
  - Dynamic body:
    - If query is empty: show **Recent Searches** with clear all button + **Suggested Shortcuts** (Most used items).
    - If query has results: animated `ListView.separated` of `SearchResultTile`.
    - If query has no results: Empty state with friendly illustration, suggested keyword chips, and voice assistant prompt.

**Step 2: Verify with flutter analyze**
Run: `cmd /c flutter analyze lib/features/quick_search/`  
Expected: 0 issues.

**Step 3: Commit**
```bash
git add lib/features/quick_search/presentation/widgets/hero_search_bar.dart lib/features/quick_search/presentation/widgets/quick_search_modal_sheet.dart
git commit -m "feat(quick_search): implement hero search bar and full spotlight modal sheet"
```

---

### Task 8: App Integration - Dashboard & Main Layout Swipe-Up Gesture

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Modify: `lib/features/main_layout/presentation/pages/main_layout_page.dart`

**Step 1: Modify `DashboardPage`**
- Import `hero_search_bar.dart`.
- Place `HeroSearchBar` right below the header section or seamlessly inside the top section for high visibility and immediate access.

**Step 2: Modify `MainLayoutPage`**
- Wrap the page body with a `GestureDetector` or `NotificationListener<ScrollNotification>`:
  - Detect upward swipe gesture (e.g., `onVerticalDragEnd` with negative velocity < -500).
  - When triggered, call `QuickSearchModalSheet.show(context)`.

**Step 3: Run Theme Migration Script**
As specified in Linkary guidelines:
Run: `cmd /c python replace_theme.py`

**Step 4: Verify with flutter analyze**
Run: `cmd /c flutter analyze`  
Expected: 0 issues.

**Step 5: Commit**
```bash
git add lib/features/dashboard/presentation/pages/dashboard_page.dart lib/features/main_layout/presentation/pages/main_layout_page.dart
git commit -m "feat(quick_search): integrate hero search bar into dashboard and global swipe-up gesture"
```

---

### Task 9: End-to-End Verification & Quality Audit

**Files:**
- Run full test suite: `cmd /c flutter test`
- Run static analysis: `cmd /c flutter analyze`
- Verify Arabic normalization, search responsiveness, theme switching (Light/Dark mode), and DI lifecycle.

**Step 1: Run all tests**
Run: `cmd /c flutter test`  
Expected: All tests pass.

**Step 2: Commit final changes**
```bash
git commit --allow-empty -m "chore(quick_search): complete verification and test audit"
```
