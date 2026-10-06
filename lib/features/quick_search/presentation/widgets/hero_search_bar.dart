import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:linkary/features/quick_search/presentation/pages/quick_search_page.dart';

class HeroSearchBar extends StatefulWidget {
  const HeroSearchBar({super.key});

  @override
  State<HeroSearchBar> createState() => _HeroSearchBarState();
}

class _HeroSearchBarState extends State<HeroSearchBar> {
  final List<String> _hints = const [
    'ابحث عن إعداد، جهاز، أو كلمة سر...',
    'اكتب 192 أو اسم الجهاز للوصول الفوري...',
    'اسحب لليمين من أي مكان للبحث السريع...',
    'جرب البحث الصوتي بالضغط على الميكروفون...',
  ];

  int _currentHintIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _hints.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => QuickSearchPage.open(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.20)
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 1. Search Icon with vibrant glowing gradient circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A90E2).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Iconsax.search_normal_1,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 2. Animated Switching Placeholder
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.3),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Align(
                          key: ValueKey<int>(_currentHintIndex),
                          alignment: Alignment.centerRight,
                          child: Text(
                            _hints[_currentHintIndex],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 3. Microphone Action Button
                    GestureDetector(
                      onTap: () {
                        QuickSearchPage.open(context, startListening: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.microphone_2,
                          size: 18,
                          color: isDark ? Colors.white70 : const Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
