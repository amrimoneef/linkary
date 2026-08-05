import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/balance_tracking_service.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/usecases/fetch_bill_usecase.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../dashboard/domain/entities/dashboard_entity.dart';
import '../../../../core/widgets/custom_snackbar.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/submit_bill_usecase.dart';
import '../widgets/captcha_dialog.dart';

class BillController extends GetxController {
  final FetchBillUseCase fetchBillUseCase;
  final SubmitBillUseCase submitBillUseCase;

  BillController({
    required this.fetchBillUseCase,
    required this.submitBillUseCase,
  });

  // ─── الحالة التفاعلية ───────────────────────────────────────
  final isLoading = false.obs;
  final Rxn<BillEntity> billData = Rxn<BillEntity>();
  final errorMessage = ''.obs;
  final phoneNumber = ''.obs;
  final lastUpdated = Rxn<DateTime>(); // وقت آخر تحديث ناجح

  // ─── متغيرات الرصيد المتوقع ───────────────────────────────
  final RxnInt expectedBalanceBytes = RxnInt();
  final isRouterResetDetected = false.obs;
  BalanceTrackingData? _balanceTrackingData;

  // ─── إعدادات الـ Cache والـ Rate-Limit ──────────────────────
  /// مدة صلاحية الـ Cache (30 دقيقة) — لن نعيد الاستعلام قبل انتهائها
  static const _cacheDuration = Duration(minutes: 30);

  /// فترة الانتظار عند Rate Limit (دقيقتان)
  static const _rateLimitCooldown = Duration(minutes: 5);

  DateTime? _rateLimitUntil; // الوقت الذي ينتهي فيه الـ cooldown

  // ─── دورة الحياة ────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();

    final dashController = Get.find<DashboardController>();

    // محاولة جلب رقم الخط فقط دون الاستعلام التلقائي
    _syncPhoneNumber();
    
    // محاولة استعادة بيانات التتبع المخزنة
    _initBalanceTracking();

    // الاستماع للتغيرات: تحديث رقم الهاتف والرصيد المتوقع فقط
    ever(dashController.dashboardData, (dashData) {
      if (phoneNumber.value.isEmpty || phoneNumber.value == 'غير متوفر') {
        _syncPhoneNumber();
      }
      _updateExpectedBalance(dashData);
    });
  }

  /// يجلب رقم الخط من DashboardController لتخزينه فقط، دون الاستعلام التلقائي
  Future<void> _syncPhoneNumber() async {
    final dashController = Get.find<DashboardController>();
    final phone = dashController.dashboardData.value?.phoneNumber ?? '';

    if (phone.isEmpty || phone == 'غير متوفر') {
      if (dashController.isLoading.value) {
        errorMessage.value = 'جاري جلب رقم الخط من المودم...';
      } else {
        errorMessage.value = 'رقم الخط غير متوفر حاليًا، لتحديث الرصيد يرجى سحب الشاشة للأسفل.';
      }
      return;
    }

    // تنظيف الرقم للعرض
    final displayPhone = phone
        .replaceAll('+967', '')
        .replaceAll('00967', '')
        .replaceAll(' ', '')
        .trim();
    phoneNumber.value = displayPhone;
    if (kDebugMode) print('📱 [BillController] Phone from modem: "$phone" → display: "$displayPhone"');

    // مسح رسالة الخطأ لتوضيح للمستخدم أنه يمكنه الاستعلام الآن
    if (billData.value == null) {
      errorMessage.value = 'الرجاء النقر على زر استعلام الان، أو سحب الشاشة للأسفل لتحديث الرصيد.';
    }
  }

  /// هل البيانات المخزنة لا تزال صالحة؟
  bool _isCacheValid() {
    if (billData.value == null || lastUpdated.value == null) return false;
    return DateTime.now().difference(lastUpdated.value!) < _cacheDuration;
  }

  /// عمر الـ Cache الحالي كنص مقروء
  String _cacheAge() {
    if (lastUpdated.value == null) return 'غير محدد';
    final diff = DateTime.now().difference(lastUpdated.value!);
    if (diff.inMinutes < 1) return '${diff.inSeconds} ثانية';
    return '${diff.inMinutes} دقيقة';
  }

  /// نص "آخر تحديث" للعرض في UI
  String get lastUpdatedText {
    if (lastUpdated.value == null) return '';
    final diff = DateTime.now().difference(lastUpdated.value!);
    if (diff.inSeconds < 60) return 'آخر تحديث: الآن';
    if (diff.inMinutes < 60) return 'آخر تحديث: منذ ${diff.inMinutes} دقيقة';
    return 'آخر تحديث: منذ ${diff.inHours} ساعة';
  }

  /// هل نحن في فترة Rate-Limit cooldown؟
  bool get isRateLimited =>
      _rateLimitUntil != null && DateTime.now().isBefore(_rateLimitUntil!);

  /// الثواني المتبقية من الـ cooldown
  int get rateLimitRemainingSeconds {
    if (!isRateLimited) return 0;
    return _rateLimitUntil!.difference(DateTime.now()).inSeconds;
  }

  // ─── إعادة الاستعلام (عند السحب للتحديث) ───────────────────
  Future<void> fetchBill() async {
    // ── فحص Rate-Limit cooldown ────────────────────────────────
    if (isRateLimited) {
      final remaining = rateLimitRemainingSeconds;
      errorMessage.value =
          'تجاوزت عدد مرات الاستعلام. انتظر $remaining ثانية ثم حاول مجدداً.';
      if (kDebugMode) print('⏳ [BillController] Rate limit cooldown: $remaining sec remaining');
      return;
    }

    // ── فحص الـ Cache عند الضغط اليدوي ──────────────────────────
    // نسمح بالتجاوز إذا طلب المستخدم تحديثاً يدوياً (لكن نحذره)
    if (_isCacheValid()) {
      if (kDebugMode) print('ℹ️ [BillController] Cache still valid, but user requested refresh');
      // نتابع الاستعلام لأن المستخدم طلب يدوياً
    }

    // ── تحديث الرقم من المتحكم الرئيسي إذا كان فارغاً ──────────
    if (phoneNumber.value.isEmpty || phoneNumber.value == '...') {
      final dashController = Get.find<DashboardController>();
      final phone = dashController.dashboardData.value?.phoneNumber ?? '';
      if (phone.isNotEmpty && phone != 'غير متوفر') {
        phoneNumber.value = phone
            .replaceAll('+967', '')
            .replaceAll('00967', '')
            .replaceAll(' ', '')
            .trim();
      }
    }

    final phone = phoneNumber.value;
    if (phone.isEmpty || phone == '...') {
      errorMessage.value =
          'رقم الخط غير متوفر، يرجى سحب الشاشة للأسفل في الرئيسية لتحديث البيانات';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    // لا نمسح billData هنا لإبقاء البيانات القديمة ظاهرة أثناء التحديث

    try {
      final result = await fetchBillUseCase.execute(phone);
      billData.value = result;
      lastUpdated.value = DateTime.now(); // ✅ حفظ وقت آخر تحديث ناجح
      errorMessage.value = '';
      _rateLimitUntil = null; // مسح الـ cooldown عند النجاح
      if (kDebugMode) print('✅ [BillController] Bill fetched successfully');
      
      // ✅ حفظ نقطة الانطلاق لحساب الرصيد المتوقع
      _captureInitialTrackingData(result);
    } on CaptchaRequiredException catch (e) {
      if (kDebugMode) print('⏳ [BillController] Captcha Required');
      isLoading.value = false; // Stop loading spinner so dialog can take over
      _showCaptchaDialog(e, phone);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();

      // ── كشف Rate Limit وتفعيل الـ cooldown ───────────────────
      if (msg.contains('تجاوزت') || msg.contains('لايمكنك')) {
        _rateLimitUntil =
            DateTime.now().add(_rateLimitCooldown);
        errorMessage.value =
            'تجاوزت عدد مرات الاستعلام المسموح بها.\n'
            'سيتم السماح بالاستعلام مجدداً خلال ${_rateLimitCooldown.inMinutes} دقائق.';
        if (kDebugMode) print(
            '⏳ [BillController] Rate limit hit. Cooldown until: $_rateLimitUntil');
      } else {
        errorMessage.value = msg;
      }
    } finally {
      if (isLoading.value) { // Only set false if not already handled by Captcha
        isLoading.value = false;
      }
    }
  }

  void _showCaptchaDialog(CaptchaRequiredException info, String phone) {
    Get.dialog(
      CaptchaDialog(
        imageUrl: info.imageUrl,
        cookies: info.cookies,
        onRefresh: () {
          // If they need a new captcha, they can just refresh the image url
          // The image url handles its own cache busting, but the nonce might expire if it takes too long.
        },
        onSubmit: (String code) async {
          Get.back(); // Close dialog
          await _submitCaptcha(phone, code, info);
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _submitCaptcha(String phone, String code, CaptchaRequiredException info) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await submitBillUseCase.execute(
        phone: phone,
        captchaCode: code,
        nonce: info.nonce,
        cookies: info.cookies,
      );
      
      billData.value = result;
      lastUpdated.value = DateTime.now();
      errorMessage.value = '';
      _rateLimitUntil = null;
      if (kDebugMode) print('✅ [BillController] Bill fetched successfully with captcha');
      
      _captureInitialTrackingData(result);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      errorMessage.value = msg;
      if (kDebugMode) print('❌ [BillController] Captcha submit failed: $msg');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── وظائف حساب الرصيد المتوقع ──────────────────────────────

  Future<void> _initBalanceTracking() async {
    _balanceTrackingData = await BalanceTrackingService.getData();
  }

  void _updateExpectedBalance(DashboardEntity? dashData) {
    if (dashData == null || _balanceTrackingData == null) return;
    
    final currentUsage = dashData.totalUsage;
    final initialUsage = _balanceTrackingData!.initialRouterUsageBytes;
    
    if (currentUsage < initialUsage) {
      // إما إعادة تشغيل للمودم أو تغيير شريحة
      isRouterResetDetected.value = true;
      expectedBalanceBytes.value = null;
    } else {
      isRouterResetDetected.value = false;
      final consumedSinceFetch = currentUsage - initialUsage;
      expectedBalanceBytes.value = _balanceTrackingData!.lastFetchedBalanceBytes - consumedSinceFetch;
      _checkAlerts(expectedBalanceBytes.value!);
    }
  }

  void _checkAlerts(int remainingBytes) {
    if (_balanceTrackingData == null) return;
    bool needsSave = false;
    
    const oneGB = 1024 * 1024 * 1024;
    const fiveGB = 5 * oneGB;

    if (remainingBytes <= fiveGB && remainingBytes > oneGB && !_balanceTrackingData!.alert5GBFired) {
      CustomSnackbar.showWarning('تنبيه رصيد', 'المتبقي من باقة البيانات المتوقعة وصل إلى 5 جيجا تقريباً');
      _balanceTrackingData = BalanceTrackingData(
        lastFetchedBalanceBytes: _balanceTrackingData!.lastFetchedBalanceBytes,
        initialRouterUsageBytes: _balanceTrackingData!.initialRouterUsageBytes,
        alert5GBFired: true,
        alert1GBFired: _balanceTrackingData!.alert1GBFired,
        expiryDate: _balanceTrackingData!.expiryDate,
      );
      needsSave = true;
    } else if (remainingBytes <= oneGB && !_balanceTrackingData!.alert1GBFired) {
      CustomSnackbar.showError('تنبيه هام!', 'المتبقي من باقة البيانات المتوقعة وصل إلى 1 جيجا تقريباً');
      _balanceTrackingData = BalanceTrackingData(
        lastFetchedBalanceBytes: _balanceTrackingData!.lastFetchedBalanceBytes,
        initialRouterUsageBytes: _balanceTrackingData!.initialRouterUsageBytes,
        alert5GBFired: true,
        alert1GBFired: true,
        expiryDate: _balanceTrackingData!.expiryDate,
      );
      needsSave = true;
    }

    if (needsSave) {
      BalanceTrackingService.saveData(_balanceTrackingData!);
    }
  }


  void _captureInitialTrackingData(BillEntity result) {
    String? balanceStr;

    // 1- البحث بدقة أولاً عن الرصيد الذي يحتوي على كلمة بيانات أو انترنت مع الرصيد المتاح
    for (final key in result.data.keys) {
      if (key.contains('الرصيد المتاح') && (key.contains('البيانات') || key.contains('انترنت') || key.contains('الإنترنت') || key.contains('data'))) {
        balanceStr = result.data[key];
        break;
      }
    }

    // البحث عن تاريخ الانتهاء
    String? expiryDateStr;
    for (final key in result.data.keys) {
      final k = key.toLowerCase();
      if (k.contains('تاريخ') || k.contains('date') || k.contains('انتهاء')) {
        expiryDateStr = result.data[key];
        debugPrint('📅 [BillController] Extracted Expiry Date: $expiryDateStr from key: $key');
        break;
      }
    }

    // 2- إذا لم نجده كاسم صريح، نبحث عن أي "رصيد متاح" تحتوي قيمته على وحدات بايت
    if (balanceStr == null) {
      for (final key in result.data.keys) {
        if (key.contains('الرصيد المتاح') || key.contains('متوفر')) {
          final val = result.data[key]!.toLowerCase();
          if (val.contains('gb') || val.contains('mb') || val.contains('kb') || val.contains('جيجا') || val.contains('ميجا') || val.contains('كيلو')) {
            balanceStr = result.data[key];
            break;
          }
        }
      }
    }
    
    if (balanceStr != null) {
      final bytes = _parseBalanceStringToBytes(balanceStr);
      final dashController = Get.find<DashboardController>();
      final initialUsage = dashController.dashboardData.value?.totalUsage ?? 0;
      
      _balanceTrackingData = BalanceTrackingData(
        lastFetchedBalanceBytes: bytes,
        initialRouterUsageBytes: initialUsage,
        alert5GBFired: false,
        alert1GBFired: false,
        expiryDate: expiryDateStr,
      );
      BalanceTrackingService.saveData(_balanceTrackingData!);
      _updateExpectedBalance(dashController.dashboardData.value);
    }
  }

  int _parseBalanceStringToBytes(String balanceString) {
    final lower = balanceString.toLowerCase();
    // نستخرج الأرقام سواء كانت بفاصلة أو نقطة
    final valueRegExp = RegExp(r'([\d\,\.]+)');
    final match = valueRegExp.firstMatch(lower);
    if (match == null) return 0;
    
    final cleanValueStr = match.group(1)?.replaceAll(',', '.') ?? '0';
    final value = double.tryParse(cleanValueStr) ?? 0.0;
    
    if (lower.contains('gb') || lower.contains('جيجا')) {
      return (value * 1024 * 1024 * 1024).toInt();
    } else if (lower.contains('mb') || lower.contains('ميجا')) {
      return (value * 1024 * 1024).toInt();
    } else if (lower.contains('kb') || lower.contains('كيلو')) {
      return (value * 1024).toInt();
    }
    return value.toInt(); // إرجاع القيمة كما هي بالبايت في حال عدم وجود وحدة
  }
}

