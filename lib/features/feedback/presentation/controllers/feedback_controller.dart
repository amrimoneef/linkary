import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/device_diagnostic_info.dart';
import '../../domain/entities/feedback_category.dart';
import '../../domain/entities/feedback_submission.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../../infrastructure/services/system_diagnostic_collector.dart';

class FeedbackController extends GetxController {
  final FeedbackRepository repository;
  final SystemDiagnosticCollector diagnosticCollector;
  final ImagePicker imagePicker;

  FeedbackController({
    required this.repository,
    required this.diagnosticCollector,
    ImagePicker? imagePicker,
  }) : imagePicker = imagePicker ?? ImagePicker();

  // 📝 Form State
  final selectedCategory = FeedbackCategory.featureRequest.obs;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final contactController = TextEditingController();
  final includeDiagnostics = true.obs;
  final isDiagnosticsExpanded = false.obs;
  final selectedImage = Rxn<File>();

  // 📊 Diagnostic Cache
  final diagnosticInfo = Rxn<DeviceDiagnosticInfo>();

  // ⚡ Submission & Sync Flags
  final isSubmitting = false.obs;
  final isSyncing = false.obs;
  final currentTabIndex = 0.obs;

  // 🕒 History List
  final submissions = <FeedbackSubmission>[].obs;

  int get pendingCount =>
      submissions.where((s) => s.status == FeedbackStatus.pendingOffline).length;

  @override
  void onInit() {
    super.onInit();
    loadDiagnostics();
    loadHistory();
    // Attempt auto-sync silently in background
    syncPending();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    contactController.dispose();
    super.onClose();
  }

  Future<void> loadDiagnostics() async {
    try {
      final diag = await diagnosticCollector.collectDiagnostics();
      diagnosticInfo.value = diag;
    } catch (_) {}
  }

  Future<void> loadHistory() async {
    try {
      final list = await repository.getSubmissionHistory();
      submissions.assignAll(list);
    } catch (_) {}
  }

  void selectCategory(FeedbackCategory category) {
    selectedCategory.value = category;
  }

  void toggleDiagnostics(bool value) {
    includeDiagnostics.value = value;
  }

  void toggleDiagnosticsExpanded() {
    isDiagnosticsExpanded.toggle();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );
      if (picked != null) {
        selectedImage.value = File(picked.path);
      }
    } catch (e) {
      Get.rawSnackbar(
        message: 'تعذر اختيار الصورة: $e',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  void removeImage() {
    selectedImage.value = null;
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    contactController.clear();
    selectedImage.value = null;
    selectedCategory.value = FeedbackCategory.featureRequest;
  }

  Future<void> submitFeedback() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      Get.rawSnackbar(
        title: 'تنبيه',
        message: 'يرجى كتابة عنوان مختصر للملاحظة أو الاقتراح',
        backgroundColor: Colors.amber.shade800,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (title.length < 3) {
      Get.rawSnackbar(
        title: 'تنبيه',
        message: 'يجب أن يكون العنوان 3 أحرف على الأقل',
        backgroundColor: Colors.amber.shade800,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (description.isEmpty) {
      Get.rawSnackbar(
        title: 'تنبيه',
        message: 'يرجى كتابة تفاصيل وشرح الاقتراح',
        backgroundColor: Colors.amber.shade800,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (description.length < 10) {
      Get.rawSnackbar(
        title: 'تنبيه',
        message: 'يرجى كتابة شرح وافٍ (10 أحرف على الأقل)',
        backgroundColor: Colors.amber.shade800,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    isSubmitting.value = true;

    final submission = FeedbackSubmission(
      id: '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.abs()}',
      category: selectedCategory.value,
      title: title,
      description: description,
      contactInfo: contactController.text.trim().isNotEmpty
          ? contactController.text.trim()
          : null,
      includeDiagnostics: true,
      diagnosticInfo: diagnosticInfo.value,
      attachmentPath: selectedImage.value?.path,
      createdAt: DateTime.now(),
      status: FeedbackStatus.pendingOffline,
    );

    try {
      final result = await repository.submitFeedback(submission);
      await loadHistory();
      clearForm();
      isSubmitting.value = false;

      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تم إرسال اقتراحك بنجاح!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  result.serverMessage ?? 'شكراً لمساهمتك القيمة في تطوير وتوسيع ميزات Linkary.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('حسناً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ [FeedbackController] submitFeedback failed: $e');
      // Saved in offline queue!
      await loadHistory();
      isSubmitting.value = false;

      final isNetwork = e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('HandshakeException');

      final cleanMsg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('HttpException: ', '');

      Get.rawSnackbar(
        title: isNetwork ? 'تم الحفظ محلياً (وضع عدم الاتصال)' : 'تنبيه',
        message: isNetwork
            ? 'تم حفظ اقتراحك بأمان في التطبيق، وسيتم إرساله تلقائياً فور توفر الإنترنت.'
            : cleanMsg,
        backgroundColor: isNetwork ? Colors.blueGrey.shade800 : Colors.redAccent.shade700,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      clearForm();
    }
  }

  Future<void> retrySubmission(FeedbackSubmission submission) async {
    isSyncing.value = true;
    try {
      await repository.submitFeedback(submission);
      await loadHistory();
      Get.rawSnackbar(
        message: 'تم إرسال الاقتراح (${submission.title}) بنجاح!',
        backgroundColor: Colors.green.shade700,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      debugPrint('❌ [FeedbackController] retrySubmission failed: $e');
      final cleanMsg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('HttpException: ', '');
      Get.rawSnackbar(
        message: 'تعذر إعادة الإرسال: $cleanMsg',
        backgroundColor: Colors.red.shade700,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> syncPending() async {
    if (isSyncing.value || pendingCount == 0) return;
    isSyncing.value = true;
    try {
      final count = await repository.syncPendingSubmissions();
      if (count > 0) {
        await loadHistory();
      }
    } catch (_) {} finally {
      isSyncing.value = false;
    }
  }

  Future<void> deleteSubmission(String id) async {
    await repository.deleteSubmission(id);
    await loadHistory();
  }
}
