import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/app_monitor_controller.dart';

class SearchBarWidget extends StatelessWidget {
  final AppMonitorController controller;

  const SearchBarWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF111827);
    final subText = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white54 
        : const Color(0xFF6B7280);
    final cardBg = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF16213E) 
        : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardBg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBg.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller.searchTextController,
        focusNode: controller.searchFocusNode,
        autofocus: false,
        onChanged: (v) => controller.updateSearch(v),
        style: TextStyle(color: text, fontSize: 14),
        cursorColor: Theme.of(context).primaryColor,
        decoration: InputDecoration(
          hintText: 'ابحث عن تطبيق معين...',
          hintStyle: TextStyle(color: subText, fontSize: 13),
          prefixIcon: Icon(Iconsax.search_normal, color: subText, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(Iconsax.close_circle, color: subText.withValues(alpha: 0.5), size: 18),
            onPressed: () {
              controller.clearSearch();
            },
          ),
        ),
      ),
    );
  }
}
