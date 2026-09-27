import 'package:flutter/material.dart';
import 'package:linkary/features/quick_search/domain/entities/search_category.dart';

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
