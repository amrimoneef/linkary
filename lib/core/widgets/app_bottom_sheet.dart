import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// مكون وطريقة استدعاء موحدة للنوافذ السفلية (BottomSheets)
/// تعالج مشكلة تداخل المحتوى مع شريط أزرار أندرويد (Android System Navigation Bar) من الجذور.
class AppBottomSheet {
  static Widget safeContent({required Widget child}) {
    return SafeArea(
      top: false,
      bottom: true,
      maintainBottomViewPadding: true,
      child: child,
    );
  }

  /// عرض BottomSheet آمن ومطابق للهوية البصرية لـ Linkary
  static Future<T?> show<T>({
    required Widget Function(BuildContext context) builder,
    BuildContext? context,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double borderRadius = 35.0,
    EdgeInsetsGeometry? padding,
    bool showDragHandle = true,
  }) {
    final ctx = context ?? Get.context;
    if (ctx == null) return Future.value(null);

    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final defaultBgColor =
        backgroundColor ?? (isDark ? const Color(0xFF0F172A) : Colors.white);
    return Get.bottomSheet<T>(
      Builder(
        builder: (bottomSheetContext) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(borderRadius),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: padding ?? const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: defaultBgColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(borderRadius),
                  ),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.1,
                    ),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  bottom: true,
                  maintainBottomViewPadding: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDragHandle) ...[
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                      Flexible(child: builder(bottomSheetContext)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  /// دالة تغليف آمنة (SafeArea Wrapper) لأي Container مخصص بداخل BottomSheet
  static Widget safeContainer(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
    Decoration? decoration,
    Color? backgroundColor,
    double borderRadius = 35.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor =
        backgroundColor ?? (isDark ? const Color(0xFF0F172A) : Colors.white);
    final basePadding = padding ?? const EdgeInsets.all(24);

    return Container(
      padding: basePadding,
      decoration:
          decoration ??
          BoxDecoration(
            color: defaultBgColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(borderRadius),
            ),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.1,
              ),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
      child: SafeArea(
        top: false,
        bottom: true,
        maintainBottomViewPadding: true,
        child: child,
      ),
    );
  }
}
