import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../pages/quick_search_page.dart';

class GlobalSearchNotchController extends GetxController with GetSingleTickerProviderStateMixin {
  /// Distance in pixels required to trigger QuickSearch
  static const double threshold = 75.0;

  /// Maximum visual drag displacement (rubber-band ceiling)
  static const double maxDrag = 125.0;

  final dragDistance = 0.0.obs;
  final isDragging = false.obs;
  final isThresholdReached = false.obs;
  final isEnabled = true.obs;
  final touchY = 350.0.obs;

  double _startX = 0.0;
  bool _hasVibrated = false;

  late AnimationController _springController;
  Animation<double>? _springAnim;

  @override
  void onInit() {
    super.onInit();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _springController.addListener(() {
      if (_springAnim != null) {
        dragDistance.value = _springAnim!.value;
      }
    });
  }

  void onDragStart(double globalX, [double? globalY]) {
    if (!isEnabled.value || QuickSearchPage.isOpen) return;

    _springController.stop();
    _startX = globalX;
    if (globalY != null) touchY.value = globalY;
    isDragging.value = true;
    _hasVibrated = false;
    isThresholdReached.value = false;
  }

  void onDragUpdate(double globalX, [double? globalY]) {
    if (!isDragging.value) return;
    if (globalY != null) touchY.value = globalY;

    // Dragging from Left to Right means globalX increases
    final rawDelta = globalX - _startX;
    if (rawDelta <= 0) {
      dragDistance.value = 0.0;
      if (isThresholdReached.value) {
        isThresholdReached.value = false;
        _hasVibrated = false;
        HapticFeedback.selectionClick();
      }
      return;
    }

    // Apply rubber-band dampening past the maximum
    double clamped = rawDelta;
    if (clamped > maxDrag) {
      clamped = maxDrag + (clamped - maxDrag) * 0.2;
    }
    dragDistance.value = clamped;

    if (dragDistance.value >= threshold) {
      if (!_hasVibrated) {
        HapticFeedback.mediumImpact();
        _hasVibrated = true;
        isThresholdReached.value = true;
      }
    } else {
      if (_hasVibrated) {
        _hasVibrated = false;
        isThresholdReached.value = false;
        HapticFeedback.selectionClick(); // Feedback when pulling back left to cancel
      }
    }
  }

  void onDragEnd([BuildContext? context]) {
    if (!isDragging.value) return;
    isDragging.value = false;

    if (dragDistance.value >= threshold) {
      // Confirmed action: open Quick Search
      HapticFeedback.lightImpact();
      _resetWithSpring();

      if (context != null) {
        QuickSearchPage.open(context);
      } else if (Get.context != null) {
        QuickSearchPage.open(Get.context!);
      } else {
        Get.to(
          () => const QuickSearchPage(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 220),
        );
      }
    } else {
      // User pulled down to cancel or released before reaching threshold
      _resetWithSpring();
    }
  }

  void onDragCancel() {
    isDragging.value = false;
    _resetWithSpring();
  }

  void _resetWithSpring() {
    _springAnim = Tween<double>(
      begin: dragDistance.value,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic,
    ));
    _springController.forward(from: 0.0);
    isThresholdReached.value = false;
    _hasVibrated = false;
  }

  @override
  void onClose() {
    _springController.dispose();
    super.onClose();
  }
}
