import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/domain/entities/search_item.dart';
import 'package:linkary/features/quick_search/presentation/controllers/quick_search_controller.dart';
import 'package:linkary/features/quick_search/presentation/widgets/quick_confirm_dialog.dart';
import 'package:linkary/features/quick_search/presentation/widgets/search_result_tile.dart';

class QuickSearchPage extends StatefulWidget {
  final bool startListening;

  const QuickSearchPage({super.key, this.startListening = false});

  /// Opens the QuickSearchPage with an ultra-smooth transition
  static void open(BuildContext context, {bool startListening = false}) {
    Get.to(
      () => QuickSearchPage(startListening: startListening),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 220),
    );
  }

  static bool isOpen = false;

  @override
  State<QuickSearchPage> createState() => _QuickSearchPageState();
}

class _QuickSearchPageState extends State<QuickSearchPage> {
  late final QuickSearchController controller;

  @override
  void initState() {
    super.initState();
    QuickSearchPage.isOpen = true;
    controller = Get.find<QuickSearchController>();

    if (widget.startListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.startVoiceSearch();
      });
    }
  }

  @override
  void dispose() {
    QuickSearchPage.isOpen = false;
    super.dispose();
  }

  List<Color> headerGradient(bool isDark) => isDark
      ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
      : [const Color(0xFF4A90E2), const Color(0xFF50E3C2)];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E21) : const Color(0xFFF4F7FC);
    final inputBgColor = isDark ? const Color(0xFF16213E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // 🌌 1. Header Section with Gradient and Search Input
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 18,
              right: 18,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient(isDark),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Action Bar (Back button, Title, Theme toggle)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      onPressed: () => Get.back(),
                    ),
                    Column(
                      children: [
                        const Text(
                          'البحث السريع الشامل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Obx(() => Text(
                              '${controller.searchResults.length} خيار وأداة متاحة',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10.5,
                              ),
                            )),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => Get.changeThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Search Bar Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.search_normal_1,
                        color: Color(0xFF4A90E2),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller.textEditingController,
                          autofocus: true,
                          onChanged: controller.onQueryChanged,
                          textInputAction: TextInputAction.search,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن إعداد، جهاز، أو أمر مباشر...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              fontSize: 12.5,
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                      // Clear button
                      Obx(() {
                        if (controller.searchQuery.value.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return GestureDetector(
                          onTap: controller.clearQuery,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.black12,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 4),

                      // Voice Search Button with red glow when listening
                      Obx(() {
                        final isListening = controller.isVoiceListening.value;
                        return GestureDetector(
                          onTap: controller.startVoiceSearch,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isListening ? Colors.redAccent.withValues(alpha: 0.2) : const Color(0xFF4A90E2).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isListening ? Icons.mic : Iconsax.microphone_2,
                              size: 16,
                              color: isListening ? Colors.redAccent : const Color(0xFF4A90E2),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 📊 2. Filter Chips Bar with Item Counts
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: SearchCategory.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = SearchCategory.values[index];
                  return Obx(() {
                    final isSelected = controller.selectedCategory.value == cat;
                    return GestureDetector(
                      onTap: () => controller.setCategory(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (isDark ? const Color(0xFF16213E) : Colors.white),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4A90E2)
                                : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1)),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            cat.labelAr,
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),

          // 📜 3. Dynamic Results or Dashboard
          Expanded(
            child: Obx(() {
              final query = controller.searchQuery.value.trim();
              final results = controller.searchResults;

              if (query.isEmpty) {
                return _buildDashboardView(context, isDark);
              }

              if (results.isEmpty) {
                return _buildEmptyState(context, query, isDark);
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24, top: 4),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  return SearchResultTile(
                    item: item,
                    query: query,
                    onTap: () => _handleItemTap(context, item),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Dashboard view shown when query is empty: Direct actions + Recents + Top shortcuts
  Widget _buildDashboardView(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        // ⚡ 1. Direct Quick Action Cards (4 Essential Tools)
        Text(
          'إجراءات فورية سريعة',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                title: 'نسخ كلمة السر',
                icon: Iconsax.copy,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
                onTap: () => _triggerActionById('action_copy_wifi_password'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                context,
                title: 'مشاركة QR',
                icon: Iconsax.scan_barcode,
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                onTap: () => _triggerActionById('action_wifi_qr'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                title: 'فحص السرعة',
                icon: Iconsax.flash_circle,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () => _triggerActionById('speed_test'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                context,
                title: 'إعادة التشغيل',
                icon: Iconsax.refresh,
                color: const Color(0xFFEF4444),
                isDark: isDark,
                onTap: () => _triggerActionById('reboot_modem'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🕒 2. Recent Searches
        Obx(() {
          final recents = controller.recentSearches;
          if (recents.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'عمليات البحث الأخيرة',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: controller.clearAllRecentSearches,
                    child: const Text(
                      'مسح السجل',
                      style: TextStyle(
                        color: Color(0xFF4A90E2),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: recents.map((query) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16213E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => controller.selectRecentSearch(query),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Iconsax.clock, size: 12, color: Color(0xFF4A90E2)),
                            const SizedBox(width: 5),
                            Text(
                              query,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () => controller.removeRecentSearch(query),
                              child: Icon(
                                Icons.close,
                                size: 11,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),

        // 🌟 3. Top Shortcuts List
        Text(
          'أقسام مقترحة للوصول السريع',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...controller.searchResults.take(10).map((item) {
          return SearchResultTile(
            item: item,
            query: '',
            onTap: () => _handleItemTap(context, item),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String query, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.search_status,
                size: 28,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'لم نتمكن من العثور على "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تأكد من كتابة الكلمة بشكل صحيح، أو اختر من الكلمات الأكثر استخداماً:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                'واي فاي',
                'باسورد',
                'سرعة',
                'الأجهزة',
                'ترددات الشبكة',
                'بطارية',
                'ريستارت',
              ].map((s) {
                return ActionChip(
                  label: Text(s),
                  labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
                  side: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  ),
                  onPressed: () => controller.selectRecentSearch(s),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Iconsax.microphone_2, color: Colors.white, size: 16),
              label: const Text(
                'تحدث مع المساعد الصوتي',
                style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Get.back();
                controller.startVoiceSearch();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _triggerActionById(String id) {
    final item = controller.searchResults.firstWhereOrNull((i) => i.id == id);
    if (item != null) {
      _handleItemTap(context, item);
    }
  }

  void _handleItemTap(BuildContext context, SearchItem item) {
    controller.executeAction(
      context: context,
      item: item,
      onConfirmDestructive: () {
        QuickConfirmDialog.show(
          context,
          title: item.title,
          message: item.confirmationMessage ?? 'هل أنت متأكد من رغبتك في متابعة هذا الإجراء؟',
          onConfirm: () {
            item.onTap();
          },
        );
      },
    );
  }
}
