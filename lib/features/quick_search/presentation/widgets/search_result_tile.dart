import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:linkary/features/quick_search/domain/entities/search_category.dart';
import 'package:linkary/features/quick_search/domain/entities/search_item.dart';

class SearchResultTile extends StatelessWidget {
  final SearchItem item;
  final String query;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.item,
    required this.query,
    required this.onTap,
  });

  List<Color> get categoryGradient {
    switch (item.category) {
      case SearchCategory.settings:
        return const [Color(0xFF3B82F6), Color(0xFF1D4ED8)];
      case SearchCategory.devices:
        return const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
      case SearchCategory.quickActions:
        return const [Color(0xFFEF4444), Color(0xFFB91C1C)];
      case SearchCategory.tools:
        return const [Color(0xFF10B981), Color(0xFF047857)];
      case SearchCategory.smartTools:
        return const [Color(0xFFF59E0B), Color(0xFFD97706)];
      case SearchCategory.all:
        return const [Color(0xFF64748B), Color(0xFF334155)];
    }
  }

  Color get categoryBadgeColor {
    switch (item.category) {
      case SearchCategory.settings:
        return const Color(0xFF3B82F6);
      case SearchCategory.devices:
        return const Color(0xFF8B5CF6);
      case SearchCategory.quickActions:
        return const Color(0xFFEF4444);
      case SearchCategory.tools:
        return const Color(0xFF10B981);
      case SearchCategory.smartTools:
        return const Color(0xFFF59E0B);
      case SearchCategory.all:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            child: Row(
              children: [
                // 1. Category Icon Box
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: categoryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: categoryGradient.first.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 19),
                ),
                const SizedBox(width: 12),

                // 2. Texts (Title & Subtitle with Badge)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: categoryBadgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.category.labelAr,
                              style: TextStyle(
                                color: categoryBadgeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Trailing Quick Action or Arrow
                if (item.quickActionWidget != null) ...[
                  const SizedBox(width: 8),
                  item.quickActionWidget!,
                ] else ...[
                  const SizedBox(width: 8),
                  Icon(
                    Iconsax.arrow_left_2,
                    size: 14,
                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
