import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/feedback_submission.dart';
import '../controllers/feedback_controller.dart';

class FeedbackHistoryCard extends StatefulWidget {
  final FeedbackSubmission submission;
  final FeedbackController controller;

  const FeedbackHistoryCard({
    super.key,
    required this.submission,
    required this.controller,
  });

  @override
  State<FeedbackHistoryCard> createState() => _FeedbackHistoryCardState();
}

class _FeedbackHistoryCardState extends State<FeedbackHistoryCard> {
  bool _isExpanded = false;

  String _formatDateTime(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');

    int hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final hr = hour12.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';

    return '$y/$m/$d $hr:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final submission = widget.submission;
    final controller = widget.controller;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final accentColor = const Color(0xFF4A90E2);
    final isPending = submission.status == FeedbackStatus.pendingOffline;

    final isLongText = submission.description.length > 100 || submission.description.contains('\n');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        surfaceColor: cardColor,
        borderColor: isPending
            ? Colors.amber.shade700.withValues(alpha: 0.4)
            : submission.category.color.withValues(alpha: 0.25),
        opacity: 0.7,
        blur: 15,
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category Badge + Date + Close
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: submission.category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: submission.category.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        submission.category.icon,
                        size: 14,
                        color: submission.category.color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        submission.category.labelAr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: submission.category.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(submission.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('حذف من السجل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        content: const Text('هل ترغب بحذف هذه الملاحظة من السجل المحلي؟', style: TextStyle(fontSize: 13)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              controller.deleteSubmission(submission.id);
                            },
                            child: const Text('حذف', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: subTextColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              submission.title,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),

            // Description with Animated CrossFade for smooth expand/collapse
            AnimatedCrossFade(
              firstChild: Text(
                submission.description,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                submission.description,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            // Show More / Show Less Button
            if (isLongText) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'عرض أقل' : 'عرض المزيد',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                        size: 14,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Tags & Status (Wrapped to prevent any horizontal overflow on small screens)
            Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (submission.includeDiagnostics || submission.attachmentPath != null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (submission.includeDiagnostics) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.cpu, size: 12, color: subTextColor),
                              const SizedBox(width: 4),
                              Text(
                                'بيانات المودم',
                                style: TextStyle(fontSize: 10.5, color: subTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (submission.attachmentPath != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.gallery, size: 12, color: subTextColor),
                              const SizedBox(width: 4),
                              Text(
                                'صورة مرفقة',
                                style: TextStyle(fontSize: 10.5, color: subTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                if (isPending) ...[
                  InkWell(
                    onTap: () => controller.retrySubmission(submission),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade700, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 14, color: Colors.amber.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'في الانتظار (إعادة الإرسال)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.tick_circle, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'تم الاستلام بنجاح',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
