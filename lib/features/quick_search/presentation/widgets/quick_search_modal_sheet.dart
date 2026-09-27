import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:linkary/features/quick_search/domain/entities/search_item.dart';
import 'package:linkary/features/quick_search/presentation/controllers/quick_search_controller.dart';
import 'package:linkary/features/quick_search/presentation/widgets/quick_confirm_dialog.dart';
import 'package:linkary/features/quick_search/presentation/widgets/search_filter_chips.dart';
import 'package:linkary/features/quick_search/presentation/widgets/search_result_tile.dart';

class QuickSearchModalSheet extends StatefulWidget {
  final bool startListening;

  const QuickSearchModalSheet({super.key, this.startListening = false});

  static Future<void> show(BuildContext context, {bool startListening = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => QuickSearchModalSheet(startListening: startListening),
    );
  }

  @override
  State<QuickSearchModalSheet> createState() => _QuickSearchModalSheetState();
}

class _QuickSearchModalSheetState extends State<QuickSearchModalSheet> {
  late final QuickSearchController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<QuickSearchController>();

    if (widget.startListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.startVoiceSearch();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.88;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        height: sheetHeight,
        margin: EdgeInsets.only(bottom: keyboardHeight),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Search Input Header
            _buildSearchInputHeader(context, isDark),
            const SizedBox(height: 12),

            // 3. Category Filter Chips
            Obx(() => SearchFilterChips(
                  selectedCategory: controller.selectedCategory.value,
                  onCategorySelected: controller.setCategory,
                )),
            const SizedBox(height: 10),

            // 4. Dynamic Content
            Expanded(
              child: Obx(() {
                final query = controller.searchQuery.value.trim();
                final results = controller.searchResults;

                if (query.isEmpty) {
                  return _buildRecentAndShortcuts(context, isDark);
                }

                if (results.isEmpty) {
                  return _buildEmptyState(context, query, isDark);
                }

                return _buildResultsList(context, results, query);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInputHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.search_normal_1,
                    size: 20,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller.textEditingController,
                      autofocus: true,
                      onChanged: controller.onQueryChanged,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن إعداد، جهاز، أو إجراء سريع...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  // Clear button when query not empty
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
                          size: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),

                  // Voice Search Button with listening pulse
                  Obx(() {
                    final isListening = controller.isVoiceListening.value;
                    return GestureDetector(
                      onTap: controller.startVoiceSearch,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isListening
                              ? Colors.redAccent.withValues(alpha: 0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isListening ? Icons.mic : Iconsax.microphone_2,
                          size: 20,
                          color: isListening
                              ? Colors.redAccent
                              : (isDark ? Colors.white70 : const Color(0xFF4A90E2)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Close modal button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAndShortcuts(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. Recent Searches Section
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: controller.clearAllRecentSearches,
                    child: const Text(
                      'مسح الكل',
                      style: TextStyle(
                        color: Color(0xFF4A90E2),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recents.map((item) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => controller.selectRecentSearch(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.clock,
                              size: 13,
                              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF334155),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => controller.removeRecentSearch(item),
                              child: Icon(
                                Icons.close,
                                size: 13,
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
              const SizedBox(height: 20),
            ],
          );
        }),

        // 2. Suggested Shortcuts (Top Popular Items)
        Text(
          'الوصول السريع المقترح',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...controller.searchResults.take(6).map((item) {
          return SearchResultTile(
            item: item,
            query: '',
            onTap: () => _handleItemTap(context, item),
          );
        }),
      ],
    );
  }

  Widget _buildResultsList(BuildContext context, List<SearchItem> results, String query) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
  }

  Widget _buildEmptyState(BuildContext context, String query, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.search_status,
                size: 36,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لم نتمكن من العثور على "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تأكد من كتابة الكلمة بشكل صحيح، أو جرب اختيار إحدى الكلمات المقترحة:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'واي فاي',
                'سرعة',
                'بطارية',
                'الأجهزة',
                'ريستارت',
                'فاتورة',
              ].map((suggestion) {
                return ActionChip(
                  label: Text(suggestion),
                  labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                  side: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                  ),
                  onPressed: () => controller.selectRecentSearch(suggestion),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Voice Assistant Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Iconsax.microphone_2, color: Colors.white, size: 18),
              label: const Text(
                'تحدث مع المساعد الصوتي',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            Get.back(); // close modal sheet
            item.onTap();
          },
        );
      },
    );
  }
}
