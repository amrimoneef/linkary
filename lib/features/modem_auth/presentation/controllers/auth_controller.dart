import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:linkary/features/main_layout/presentation/pages/main_layout_page.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../core/network/session_heartbeat_service.dart';
import '../../../quick_setup/presentation/pages/quick_setup_page.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_retry_times_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reboot_usecase.dart';
import '../../domain/usecases/power_off_usecase.dart';
import '../../domain/usecases/factory_reset_usecase.dart';
import '../../../../core/services/biometric_service.dart';
import 'package:flutter/services.dart';
import '../pages/login_page.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/network/network_info.dart' as project_net;
import 'package:network_info_plus/network_info_plus.dart' as plugin_net;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/constants.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  final LoginUseCase loginUseCase;
  final GetRetryTimesUseCase getRetryTimesUseCase;
  final BiometricService biometricService;
  final LogoutUseCase logoutUseCase;
  final RebootUseCase rebootUseCase;
  final PowerOffUseCase powerOffUseCase;
  final FactoryResetUseCase factoryResetUseCase;

  // حقن الـ UseCase عبر الـ Constructor للحفاظ على الـ Clean Architecture
  AuthController({
    required this.loginUseCase,
    required this.getRetryTimesUseCase,
    required this.biometricService,
    required this.logoutUseCase,
    required this.rebootUseCase,
    required this.powerOffUseCase,
    required this.factoryResetUseCase,
  });

  Timer? _networkMonitorTimer;
  final String _targetGateway = '192.168.8.1';
  int _consecutiveNetworkFailures = 0; // عداد الفشل المتتالي

  // خدمة نبض الجلسة
  SessionHeartbeatService? _heartbeatService;

  // متغيرات الحالة (State Variables) باستخدام ميزة الـ Reactive في GetX
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var retryTimes = 5.obs;
  var isBiometricAvailable = false.obs;
  var isBiometricEnabled = false.obs;
  var isPasswordVisible = false.obs;
  
  // الرقم التسلسلي للمودم لتمييز السجلات
  var currentSN = RxnString();

  // القفل الزمني عند استنفاد المحاولات
  var lockRemainingSeconds = 0.obs;
  Timer? _lockTimer;

  // حماية من التجديد المتزامن
  bool _isRenewing = false;

  // التحقق من حالة الجلسة وصلاحيتها فعلياً من المودم
  Future<bool> checkSession() async {
    final sessionId = await SessionManager.getSessionId(currentSN.value);
    if (sessionId == null || sessionId.isEmpty) return false;

    try {
      // محاولة استدعاء API بسيط يتطلب جلسة للتأكد من صلاحيتها
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.Client().get(
        Uri.parse('${AppConstants.modemBaseUrl}/api.cgi?path=router&method=get_sys_time&timeout=5&_=$timestamp'),
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'Cookie': 'CGISID=$sessionId',
        },
      ).timeout(const Duration(seconds: 5));

      final bodyStr = response.body.toLowerCase().replaceAll(' ', '');
      if (bodyStr.contains('sessionnoexist') || 
          bodyStr.contains('sessionfail') ||
          bodyStr.contains('login.html')) {
        await SessionManager.clearSession(currentSN.value);
        return false;
      }

      // الجلسة صالحة — نسجل Heartbeat
      await SessionManager.setLastHeartbeat(DateTime.now(), currentSN.value);
      return true;
    } catch (e) {
      debugPrint('⚠️ Session validation failed: $e');
      if (e.toString().contains('SESSION_EXPIRED') || e.toString().contains('100005')) {
         await SessionManager.clearSession(currentSN.value);
      }
      return false;
    }
  }

  /// تجديد الجلسة تلقائياً باستخدام كلمة المرور المحفوظة
  /// يُستخدم عند اكتشاف انتهاء الجلسة بدون تدخل المستخدم
  Future<bool> renewSession() async {
    if (_isRenewing) return false;
    _isRenewing = true;

    try {
      // 1. جلب كلمة المرور المحفوظة (من البصمة أو آخر تسجيل دخول)
      String? password = await SessionManager.getLastLoginPassword(currentSN.value);
      password ??= await SessionManager.getPassword(currentSN.value);

      if (password == null || password.isEmpty) {
        debugPrint('🔑 [Renewal] No saved password — cannot auto-renew');
        return false;
      }

      // 2. التحقق من أننا ما زلنا على شبكة المودم
      try {
        final netInfo = Get.find<project_net.NetworkInfo>();
        final isConnected = await netInfo.isConnectedToModem();
        if (!isConnected) {
          debugPrint('🔌 [Renewal] Not connected to modem — skipping renewal');
          return false;
        }
      } catch (_) {
        // إذا فشل التحقق من الشبكة، نحاول التجديد على أي حال
      }

      // 3. محاولات تجديد مع فترات انتظار
      for (int attempt = 1; attempt <= AppConstants.sessionMaxRenewalAttempts; attempt++) {
        try {
          debugPrint('🔄 [Renewal] Attempt $attempt/${AppConstants.sessionMaxRenewalAttempts}');
          
          final result = await loginUseCase.execute(password);
          currentUser = result;

          if (result.isAuthenticated && result.sessionId != null) {
            await SessionManager.saveSessionId(result.sessionId!, currentSN.value);
            await SessionManager.setLastHeartbeat(DateTime.now(), currentSN.value);
            debugPrint('✅ [Renewal] Session renewed successfully');
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ [Renewal] Attempt $attempt failed: $e');
          if (attempt < AppConstants.sessionMaxRenewalAttempts) {
            await Future.delayed(Duration(seconds: AppConstants.sessionRenewalCooldownSeconds));
          }
        }
      }

      debugPrint('❌ [Renewal] All attempts failed');
      return false;
    } finally {
      _isRenewing = false;
    }
  }

  /// تجديد الجلسة عبر البصمة أولاً، وفي حال الإلغاء/الفشل يتم إظهار حوار كلمة المرور (3 محاولات)
  Future<bool> renewSessionWithBiometricsOrPassword() async {
    if (_isRenewing) return false;
    _isRenewing = true;

    try {
      // 1. التأكد من الاتصال بالمودم
      try {
        final netInfo = Get.find<project_net.NetworkInfo>();
        final isConnected = await netInfo.isConnectedToModem();
        if (!isConnected) {
          debugPrint('🔌 [Renewal] Not connected to modem');
          return false;
        }
      } catch (_) {}

      // 2. التحقق من توفر وتفعيل البصمة للمودم
      final available = await biometricService.canAuthenticate();
      final enabled = isBiometricEnabled.value;

      if (available && enabled) {
        debugPrint('🔒 [Renewal] Prompting biometric authentication...');
        final authenticated = await biometricService.authenticate();
        if (authenticated) {
          String? password = await SessionManager.getLastLoginPassword(currentSN.value);
          password ??= await SessionManager.getPassword(currentSN.value);

          if (password != null && password.isNotEmpty) {
            final result = await loginUseCase.execute(password);
            if (result.isAuthenticated && result.sessionId != null) {
              currentUser = result;
              await SessionManager.saveSessionId(result.sessionId!, currentSN.value);
              await SessionManager.setLastHeartbeat(DateTime.now(), currentSN.value);
              debugPrint('✅ [Renewal] Session renewed via Biometrics');
              return true;
            }
          }
        }
        debugPrint('⚠️ [Renewal] Biometric auth failed or canceled — falling back to password dialog');
      } else {
        debugPrint('ℹ️ [Renewal] Biometrics not enabled or not available — showing password dialog');
      }

      // 3. البديل: نافذة كلمة المرور المنبثقة مع 3 محاولات
      return await promptPasswordForRenewal();
    } catch (e) {
      debugPrint('❌ [Renewal] Error in renewSessionWithBiometricsOrPassword: $e');
      return false;
    } finally {
      _isRenewing = false;
    }
  }

  /// نافذة منبثقة لإدخال كلمة المرور مع 3 محاولات لتجديد الجلسة
  Future<bool> promptPasswordForRenewal() async {
    final pwdController = TextEditingController();
    int attemptsLeft = 3;
    bool isSubmitting = false;
    String? dialogError;
    bool obscureText = true;

    final result = await Get.dialog<bool>(
      PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('تجديد الجلسة', style: Get.textTheme.titleMedium),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'انتهت صلاحية الجلسة. يرجى إدخال كلمة مرور الدخول لتجديد الجلسة.',
                      style: Get.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pwdController,
                      obscureText: obscureText,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'المحاولات المتبقية: $attemptsLeft',
                      style: TextStyle(
                        color: attemptsLeft == 1 ? Colors.red : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Get.back(result: false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final pwd = pwdController.text.trim();
                          if (pwd.isEmpty) {
                            setState(() {
                              dialogError = 'يرجى إدخال كلمة المرور';
                            });
                            return;
                          }

                          setState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });

                          try {
                            final res = await loginUseCase.execute(pwd);
                            if (res.isAuthenticated && res.sessionId != null) {
                              currentUser = res;
                              await SessionManager.saveSessionId(res.sessionId!, currentSN.value);
                              await SessionManager.saveLastLoginPassword(pwd, currentSN.value);
                              await SessionManager.setLastHeartbeat(DateTime.now(), currentSN.value);
                              Get.back(result: true);
                            } else {
                              attemptsLeft--;
                              if (attemptsLeft <= 0) {
                                Get.back(result: false);
                              } else {
                                setState(() {
                                  isSubmitting = false;
                                  dialogError = 'كلمة المرور غير صحيحة';
                                });
                              }
                            }
                          } catch (e) {
                            attemptsLeft--;
                            if (attemptsLeft <= 0) {
                              Get.back(result: false);
                            } else {
                              setState(() {
                                isSubmitting = false;
                                dialogError = e.toString().replaceAll('Exception:', '').trim();
                              });
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تأكيد'),
                ),
              ],
            );
          },
        ),
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }


  /// بدء خدمة الـ Heartbeat (تُستدعى بعد تسجيل الدخول الناجح)
  void startHeartbeat() {
    _heartbeatService ??= Get.find<SessionHeartbeatService>();
    _heartbeatService?.start();
  }

  /// إيقاف خدمة الـ Heartbeat (تُستدعى عند تسجيل الخروج)
  void stopHeartbeat() {
    _heartbeatService?.stop();
  }
  
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // حفظ بيانات المستخدم الحالي (يتضمن الـ Session ID)
  AuthEntity? currentUser;

  Future<void>? authInitFuture;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    
    // بدء سلسلة العمليات الذكية
    authInitFuture = _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // 1. جلب الهوية الفريدة للمودم أولاً
    await fetchSerialNumber();
    
    // 2. العمليات التي تعتمد على الـ SN
    fetchRetryTimes();
    _checkBiometricSupport();
    _startNetworkMonitoring();
    _checkExistingLock();
  }

  Future<void> fetchSerialNumber() async {
    try {
      final authRepo = Get.find<AuthRepository>();
      final sn = await authRepo.getSerialNumber();
      currentSN.value = sn;
      if (sn != null && sn.isNotEmpty) {
        await SessionManager.saveLastSN(sn);
      }
      debugPrint('🔍 Current Modem SN: ${sn ?? "Unknown"}');
    } catch (e) {
      debugPrint('Error fetching SN: $e');
    }
  }

  Future<void> _checkExistingLock() async {
    final endTime = await SessionManager.getLockEndTime(currentSN.value);
    if (endTime != null) {
      final now = DateTime.now();
      if (endTime.isAfter(now)) {
        final remaining = endTime.difference(now).inSeconds;
        _startLockCountdown(remaining);
      } else {
        await SessionManager.setLockEndTime(null, currentSN.value);
      }
    }
  }

  void _startLockCountdown(int seconds) {
    lockRemainingSeconds.value = seconds;
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (lockRemainingSeconds.value > 0) {
        lockRemainingSeconds.value--;
      } else {
        timer.cancel();
        SessionManager.setLockEndTime(null, currentSN.value);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startNetworkMonitoring();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _networkMonitorTimer?.cancel();
      _networkMonitorTimer = null;
    }
  }

  void _startNetworkMonitoring() {
    _networkMonitorTimer?.cancel();
    _consecutiveNetworkFailures = 0;
    _networkMonitorTimer = Timer.periodic(
      Duration(seconds: AppConstants.networkMonitorIntervalSeconds),
      (timer) async {
        // فقط نراقب إذا كان المستخدم مسجلاً للدخول بالفعل
        if (currentUser != null && currentUser!.isAuthenticated) {
          try {
            final info = plugin_net.NetworkInfo();
            var currentGateway = await info.getWifiGatewayIP();
            
            if (currentGateway != null) {
              // 1. تطبيع الأرقام العربية إلى إنجليزية لضمان صحة المقارنة
              currentGateway = AppFormatters.normalizeArabicDigits(currentGateway);

              // 2. إذا كان العنوان مختلفاً عن المتوقع، نتحقق بشكل تدريجي
              if (currentGateway != _targetGateway) {
                _consecutiveNetworkFailures++;
                debugPrint('🚨 Network mismatch #$_consecutiveNetworkFailures '
                    '(Expected: $_targetGateway, Got: $currentGateway)');
                
                // ننتظر عتبة الفشل المتتالي قبل الطرد
                if (_consecutiveNetworkFailures >= AppConstants.networkDisconnectThreshold) {
                  // نتحقق هل ما زال المودم متاحاً فعلياً؟
                  final netInfo = Get.find<project_net.NetworkInfo>();
                  final isStillConnected = await netInfo.isConnectedToModem();
                  
                  if (!isStillConnected) {
                    forceLogout(
                      'انقطع الاتصال',
                      'تم تغيير الشبكة أو فصل الواي فاي. يرجى إعادة الاتصال بالمودم.',
                    );
                  } else {
                    debugPrint('✅ Modem reachable despite Gateway change. Resetting counter.');
                    _consecutiveNetworkFailures = 0;
                  }
                }
              } else {
                // الشبكة صحيحة — نعيد العداد
                _consecutiveNetworkFailures = 0;
              }
            }
          } catch (e) {
            debugPrint('Network monitoring error: $e');
          }
        }
      },
    );
  }

  Future<void> _checkBiometricSupport() async {
    isBiometricAvailable.value = await biometricService.canAuthenticate();
    bool enabled = await SessionManager.isBiometricEnabled(currentSN.value);
    
    if (enabled) {
      try {
        final info = plugin_net.NetworkInfo();
        final currentBssid = await info.getWifiBSSID();
        final savedBssid = await SessionManager.getTargetBssid(currentSN.value);
        
        if (savedBssid != null && currentBssid != null && savedBssid != currentBssid) {
          debugPrint('🚨 BSSID mismatch! Saved: $savedBssid, Current: $currentBssid');
          enabled = false;
        }
      } catch (e) {
        debugPrint('Error checking BSSID: $e');
      }
    }
    
    isBiometricEnabled.value = enabled;
  }

  Future<void> fetchRetryTimes() async {
    final times = await getRetryTimesUseCase.execute();
    retryTimes.value = times;
    
    // إذا وصلت المحاولات لـ 0 ولم نكن في حالة قفل بالفعل، نبدأ القفل
    if (times == 0 && lockRemainingSeconds.value == 0) {
      const cooldownSeconds = 300; // 5 دقائق
      final endTime = DateTime.now().add(const Duration(seconds: cooldownSeconds));
      await SessionManager.setLockEndTime(endTime, currentSN.value);
      _startLockCountdown(cooldownSeconds);
    }
  }

  Future<void> login(String password) async {
    if (!formKey.currentState!.validate()) return;
    
    // 1. تفعيل حالة التحميل وتفريغ الأخطاء السابقة
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // التأكد من وجود SN لتسجيل البيانات عليه
      if (currentSN.value == null) await fetchSerialNumber();

      // 2. استدعاء طبقة الـ Domain لتنفيذ منطق العمل
      final result = await loginUseCase.execute(password);

      // 3. تحديث الحالة عند النجاح
      currentUser = result;

      if (result.isAuthenticated) {
        if (result.sessionId != null) {
          await SessionManager.saveSessionId(result.sessionId!, currentSN.value);
        }
        // حفظ كلمة المرور للتجديد التلقائي
        await SessionManager.saveLastLoginPassword(password, currentSN.value);
        await fetchRetryTimes();

        // بدء Heartbeat
        startHeartbeat();

        // في حال نجاح الدخول بكلمة المرور، نتحقق من تفعيل البصمة
        await _checkAndPromptBiometric(password);

        // هنا يمكنك التوجيه إلى شاشة لوحة التحكم أو الإعداد السريع:
        // الاعتماد الآن على متغير isSetupRequired الصادر من المودم
        if (result.isSetupRequired) {
          Get.offAll(() => QuickSetupPage());
        } else {
          Get.offAll(() => MainLayoutPage());
        }
      }
    } catch (e) {
      // 4. التقاط الأخطاء وعرضها في الواجهة
      errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
      await fetchRetryTimes();

    } finally {
      // 5. إيقاف حالة التحميل في كل الأحوال
      isLoading.value = false;
    }
  }

  /// تسجيل دخول صامت (بدون UI) - يُستخدم من SplashController للإعداد التلقائي
  Future<bool> silentLogin(String password) async {
    try {
      final result = await loginUseCase.execute(password);
      currentUser = result;

      if (result.isAuthenticated && result.sessionId != null) {
        await SessionManager.saveSessionId(result.sessionId!, currentSN.value);
        await SessionManager.saveLastLoginPassword(password, currentSN.value);
        startHeartbeat();
      }

      return result.isAuthenticated && result.isSetupRequired;
    } catch (e) {
      debugPrint('⚠️ silentLogin failed: $e');
      return false;
    }
  }

  /// تسجيل الدخول عبر البصمة
  Future<void> loginWithBiometric() async {
    if (!await biometricService.canAuthenticate()) return;

    final authenticated = await biometricService.authenticate();
    if (authenticated) {
      final savedPassword = await SessionManager.getPassword(currentSN.value);
      if (savedPassword != null) {
        isLoading.value = true;
        errorMessage.value = '';
        try {
          final result = await loginUseCase.execute(savedPassword);
          currentUser = result;
          if (result.isAuthenticated) {
            if (result.sessionId != null) {
              await SessionManager.saveSessionId(result.sessionId!, currentSN.value);
              await SessionManager.saveLastLoginPassword(savedPassword, currentSN.value);
            }
            startHeartbeat();
            // نعتمد على رد المودم (guide_step1_pass) وليس كلمة المرور
            if (result.isSetupRequired) {
              Get.offAll(() => QuickSetupPage());
            } else {
              Get.offAll(() => MainLayoutPage());
            }
          }
        } catch (e) {
          errorMessage.value = "فشل تسجيل الدخول التلقائي: ${e.toString()}";
        } finally {
          isLoading.value = false;
        }
      } else {
        errorMessage.value = "لم يتم حفظ كلمة مرور للبصمة بعد";
      }
    }
  }

  /// التحقق مما إذا كان يجب سؤال المستخدم عن تفعيل البصمة
  Future<void> _checkAndPromptBiometric(String password) async {
    final available = await biometricService.canAuthenticate();
    final enabled = await SessionManager.isBiometricEnabled(currentSN.value);

    if (available && !enabled) {
      // إظهار حوار للمستخدم
      await Get.dialog(
        AlertDialog(
          title: Text('تفعيل البصمة', textAlign: TextAlign.right, style: Get.textTheme.titleMedium),
          content: Text('هل تريد تفعيل الدخول بالبصمة للمرات القادمة؟', textAlign: TextAlign.right, style: Get.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('ليس الآن'),
            ),
            TextButton(
              onPressed: () async {
                await SessionManager.savePassword(password, currentSN.value);
                await SessionManager.setBiometricEnabled(true, currentSN.value);
                try {
                  final info = plugin_net.NetworkInfo();
                  final currentBssid = await info.getWifiBSSID();
                  if (currentBssid != null) {
                    await SessionManager.saveTargetBssid(currentBssid, currentSN.value);
                  }
                } catch (e) {
                  debugPrint('Error saving BSSID: $e');
                }
                isBiometricEnabled.value = true;
                Get.back();
                CustomSnackbar.showSuccess('نجاح', 'تم تفعيل الدخول بالبصمة بنجاح');
              },
              child: const Text('تفعيل'),
            ),
          ],
        ),
      );
    }
  }

  /// تسجيل الخروج الاحترافي
  Future<void> logout() async {
    await Get.dialog(
      AlertDialog(
        title: Text('تسجيل الخروج', textAlign: TextAlign.right, style: Get.textTheme.titleMedium),
        content: Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟ سيتم إنهاء الجلسة الحالية.', textAlign: TextAlign.right, style: Get.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _performLogout();
            },
            child: const Text('خروج', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    isLoading.value = true;
    try {
      // 0. إيقاف Heartbeat فوراً
      stopHeartbeat();

      // 1. إنهاء الجلسة في المودم (تتطلب Session ID)
      final sessionId = await SessionManager.getSessionId(currentSN.value);
      if (sessionId != null) {
        await logoutUseCase.execute(sessionId);
      }
      // 2. مسح الجلسة محلياً فقط (نحتفظ بكملة المرور للبصمة حسب رغبة المستخدم السابقة)
      await SessionManager.clearSession(currentSN.value);
      
      // 3. التوجه لصفحة الدخول
      Get.offAll(() => LoginPage());
      
      CustomSnackbar.showInfo('وداعاً', 'تم تسجيل الخروج بنجاح');
    } catch (e) {
      errorMessage.value = "خطأ أثناء تسجيل الخروج: $e";
    } finally {
      isLoading.value = false;
    }
  }

  /// تسجيل الخروج بدون حوار (للمساعد الصوتي)
  Future<void> logoutDirect() => _performLogout();

  /// تسجيل الخروج الإجباري (عند انتهاء الجلسة أو الدخول من جهاز آخر) أو لتنفيذ طلبات معينة
  Future<void> forceLogout([String title = 'انتهت الجلسة ⚠️', String message = 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.']) async {
    try {
      // 0. إيقاف Heartbeat
      stopHeartbeat();

      // 1. مسح الجلسة محلياً فوراً لمنع أي طلبات مستقبلية
      await SessionManager.clearSession(currentSN.value);
      currentUser = null;

      // 2. التوجه لصفحة الدخول فوراً
      // نستخدم scheduleMicrotask لضمان أن الملاحة تتم خارج سياق الـ Build الحالي إذا استدعي من UI
      Future.microtask(() {
        Get.offAll(() => LoginPage());
        
        if (title.contains('⚠️')) {
          CustomSnackbar.showError(title, message);
        } else {
          CustomSnackbar.showWarning(title, message);
        }
      });
    } catch (e) {
      errorMessage.value = "خطأ أثناء تسجيل الخروج الإجباري: $e";
    }
  }

  /// إعادة تشغيل المودم برمجياً
  Future<void> reboot() async {
    await Get.dialog(
      AlertDialog(
        title: Text('إعادة تشغيل المودم', textAlign: TextAlign.right, style: Get.textTheme.titleMedium),
        content: Text('هل أنت متأكد من رغبتك في إعادة تشغيل المودم؟ ستفقد الاتصال بالإنترنت لفترة وجيزة.', textAlign: TextAlign.right, style: Get.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _performReboot();
            },
            child: const Text('إعادة تشغيل', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _performReboot() async {
    isLoading.value = true;
    try {
      // إضافة اهتزاز فيزيائي (Haptic Feedback)
      HapticFeedback.mediumImpact();

      // 1. تنفيذ إعادة التشغيل في المودم (تتطلب Session ID)
      final sessionId = await SessionManager.getSessionId(currentSN.value);
      if (sessionId != null) {
        await rebootUseCase.execute(sessionId);
      }
      
      // 2. مسح الجلسة محلياً 
      await SessionManager.clearSession(currentSN.value);
      
      // 3. التوجه لصفحة تسجيل الدخول وإظهار رسالة
      forceLogout('إعادة التشغيل', 'يتم الآن إعادة تشغيل المودم. يرجى تسجيل الدخول مجدداً لاحقاً.');
    } catch (e) {
      errorMessage.value = "خطأ أثناء إعادة المودم تشغيل: $e";
    } finally {
      isLoading.value = false;
    }
  }

  /// إعادة تشغيل بدون حوار (للمساعد الصوتي)
  Future<void> rebootDirect() => _performReboot();

  /// إيقاف تشغيل المودم الاحترافي
  Future<void> powerOff() async {
    await Get.dialog(
      AlertDialog(
        title: Text('إيقاف تشغيل المودم', textAlign: TextAlign.right, style: Get.textTheme.titleMedium?.copyWith(color: Colors.orange)),
        content: Text('هل أنت متأكد من رغبتك في إيقاف تشغيل المودم؟ سيتوجب عليك تشغيله يدوياً من زر الطاقة عند الحاجة لاستخدامه مجدداً.', textAlign: TextAlign.right, style: Get.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _performPowerOff();
            },
            child: const Text('إيقاف التشغيل', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performPowerOff() async {
    isLoading.value = true;
    try {
      HapticFeedback.mediumImpact();
      final sessionId = await SessionManager.getSessionId(currentSN.value);
      if (sessionId != null) {
        await powerOffUseCase.execute(sessionId);
      }
      await SessionManager.clearSession(currentSN.value);
      forceLogout('إيقاف التشغيل', 'يتم الآن إيقاف تشغيل المودم. يرجى تشغيله يدوياً عند الحاجة.');
    } catch (e) {
      errorMessage.value = "خطأ أثناء إيقاف تشغيل المودم: $e";
    } finally {
      isLoading.value = false;
    }
  }

  /// إيقاف تشغيل بدون حوار (للمساعد الصوتي)
  Future<void> powerOffDirect() => _performPowerOff();

  /// إعادة ضبط المصنع
  Future<void> factoryReset() async {
    await Get.dialog(
      AlertDialog(
        title: Text('إعادة ضبط المصنع', textAlign: TextAlign.right, style: Get.textTheme.titleMedium?.copyWith(color: Colors.red)),
        content: Text('هل أنت متأكد من رغبتك في إعادة ضبط المودم لحالة المصنع؟ سيتم مسح جميع الإعدادات ولن تتمكن من التراجع عن هذه الخطوة.', textAlign: TextAlign.right, style: Get.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              isLoading.value = true;
              try {
    HapticFeedback.heavyImpact();

    // 🔑 تمرير الرقم التسلسلي لجلب الجلسة الصحيحة
    final sessionId = await SessionManager.getSessionId(currentSN.value);
    if (sessionId != null) {
      await factoryResetUseCase.execute(sessionId);
    }
    
    // مسح البيانات المرتبطة بهذا المودم تحديداً
    await SessionManager.clearSession(currentSN.value);
    await SessionManager.clearPassword(currentSN.value);
    await SessionManager.setBiometricEnabled(false, currentSN.value);
    isBiometricEnabled.value = false;
    
    forceLogout('إعادة ضبط المصنع', 'يتم الآن إعادة ضبط المودم. يرجى الانتظار لحين اكتمال العملية.');
              } catch (e) {
                errorMessage.value = "خطأ أثناء إعادة ضبط المصنع: $e";
              } finally {
                isLoading.value = false;
              }
            },
            child: const Text('إعادة ضبط', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _networkMonitorTimer?.cancel();
    stopHeartbeat();
    passwordController.dispose();
    super.onClose();
  }
}