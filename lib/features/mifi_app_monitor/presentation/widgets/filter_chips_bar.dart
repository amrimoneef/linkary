import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_monitor_controller.dart';

class FilterChipsBar extends StatelessWidget {
  final AppMonitorController controller;

  const FilterChipsBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final subText = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white54 
        : const Color(0xFF6B7280);
    final cardBg = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF16213E) 
        : const Color(0xFFE5E7EB);
    final glow = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF4A90E2) 
        : const Color(0xFF60A5FA);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Obx(() {
        return Row(
          children: MonitorFilter.values.map((filter) {
            final isSelected = controller.selectedFilter.value == filter;
            String label = '';
            switch (filter) {
              case MonitorFilter.session: label = 'الجلسة'; break;
              case MonitorFilter.today: label = 'اليوم'; break;
              case MonitorFilter.week: label = 'الأسبوع'; break;
              case MonitorFilter.month: label = 'الشهر'; break;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ChoiceChip(
                  label: Text(
                    label, 
                    style: TextStyle(
                      color: isSelected ? Colors.white : subText, 
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )
                  ),
                  selected: isSelected,
                  onSelected: (_) => controller.changeFilter(filter),
                  backgroundColor: cardBg.withValues(alpha: 0.1),
                  selectedColor: glow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(
                    color: isSelected ? glow : cardBg.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  showCheckmark: false,
                  elevation: isSelected ? 4 : 0,
                  shadowColor: glow.withValues(alpha: 0.5),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}
