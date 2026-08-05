import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/modem_auth/presentation/controllers/auth_controller.dart';

class ExpandablePowerMenu extends StatefulWidget {
  final bool showLabel;
  const ExpandablePowerMenu({super.key, this.showLabel = true});

  @override
  State<ExpandablePowerMenu> createState() => _ExpandablePowerMenuState();
}

class _ExpandablePowerMenuState extends State<ExpandablePowerMenu> {
  bool _isExpanded = false;

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _isExpanded ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: _isExpanded ? 0.35 : 0.2)),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. الزر الرئيسي (Header Button)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 18),
                  if (widget.showLabel) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'الطـاقـة',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                  ),
                ],
              ),
            ),
          ),

          // 2. الدرج المنزلق تحت الزر الرئيسي (Dropdown Items)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            child: _isExpanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 4),

                      // خيار 1: إعادة التشغيل
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _toggleMenu();
                          authController.reboot();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAE5A1).withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.rotate_right_rounded, color: Color(
                                    0xFFF6E2A0), size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'إعادة تشغيل',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // خيار 2: إيقاف التشغيل
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _toggleMenu();
                          authController.powerOff();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB2B2).withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFFF7043), size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'إيقاف التشغيل',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
