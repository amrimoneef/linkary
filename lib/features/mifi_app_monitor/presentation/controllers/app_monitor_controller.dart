import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../domain/services/usage_data_engine.dart';
import '../../domain/services/usage_aggregator.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/usage_pattern_analyzer.dart';
import '../../domain/entities/app_category.dart';
import '../../domain/entities/app_usage_entity.dart';
import '../../domain/repositories/app_monitor_repository.dart';
import '../../domain/use_cases/categorize_apps_usecase.dart';
import '../../domain/use_cases/check_usage_alerts_usecase.dart';
import '../../domain/repositories/app_blocking_repository.dart';
import '../../domain/entities/blocked_app.dart';
import '../../infrastructure/data_sources/local_storage_data_source.dart';
import '../../infrastructure/data_sources/monitor_native_data_source.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../widgets/daily_infographic_widget.dart';
import 'package:intl/intl.dart';
import '../widgets/app_detail_infographic_widget.dart';
import '../../../../core/widgets/custom_snackbar.dart';

enum MonitorFilter { session, today, week, month }

class AppMonitorController extends GetxController with WidgetsBindingObserver {
  final AppMonitorRepository repository;
  final UsageDataEngine dataEngine;
  final UsageAggregator aggregator;
  final CategorizeAppsUseCase categorizeUseCase;
  final CheckUsageAlertsUseCase alertsUseCase;
  final AppBlockingRepository blockingRepository;
  final NotificationService notificationService;
  final UsagePatternAnalyzer patternAnalyzer;
  final MonitorNativeDataSource monitorDataSource;

  static const String TARGET_GATEWAY_IP = '192.168.8.1';

  AppMonitorController({
    required this.repository,
    required this.dataEngine,
    required this.aggregator,
    required this.categorizeUseCase,
    required this.alertsUseCase,
    required this.blockingRepository,
    required this.notificationService,
    required this.patternAnalyzer,
    required this.monitorDataSource,
  });

  // State
  var isLoading = true.obs;
  var hasPermission = false.obs;
  var isConnectedToTargetMiFi = false.obs;
  var selectedFilter = MonitorFilter.today.obs;
  
  // Stats
  var rxBytes = 0.obs;
  var txBytes = 0.obs;
  var totalUsage = 0.obs;
  var appsUsage = <AppUsageEntity>[].obs;
  var filteredAppsUsage = <AppUsageEntity>[].obs;
  
  // Real-time speed
  var totalRxSpeed = 0.obs;
  var totalTxSpeed = 0.obs;
  
  // UI Helpers
  var historyStats = <Map<String, dynamic>>[].obs;
  var maxYForChart = 100.0.obs;
  var searchQuery = ''.obs;
  var activeAlerts = <String>[].obs;
  var categoryTotals = <AppCategory, int>{}.obs;
  var appHistoryData = <Map<String, dynamic>>[].obs;
  var appGoals = <String, int>{}.obs;
  var appAutoBlockPrefs = <String, bool>{}.obs;
  var currentInsight = Rx<UsageInsight?>(null);
  
  // UI Controllers
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  
  // Firewall State
  var blockedApps = <BlockedApp>[].obs;
  var isFirewallEnabled = false.obs;
  var allInstalledApps = <AppUsageEntity>[].obs;
  var isLoadingApps = false.obs;

  List<AppUsageEntity> get userApps => _filterList(allInstalledApps.where((a) => !a.isSystemApp).toList());
  List<AppUsageEntity> get systemApps => _filterList(allInstalledApps.where((a) => a.isSystemApp).toList());

  List<AppUsageEntity> _filterList(List<AppUsageEntity> list) {
    if (searchQuery.isEmpty) return list;
    return list.where((app) => 
      app.appName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
      app.packageName.toLowerCase().contains(searchQuery.value.toLowerCase())
    ).toList();
  }

  final ScreenshotController screenshotController = ScreenshotController();

  Timer? _refreshTimer;
  Map<String, List<int>>? _sessionBaselineMap;
  Map<String, List<int>>? _previousStatsMap;
  Map<String, List<int>> _dailyBaselineMapAtConnect = {};
  int? _lastModemUptime;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initMonitor();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    searchTextController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (!hasPermission.value) {
        bool granted = await repository.checkUsagePermission();
        if (granted) {
          _initMonitor();
        }
      } else {
        // App came to foreground: restart polling and do one immediate refresh
        _startLiveTracking();
        refreshUsage();
        
        // 🔥 إعادة مزامنة حالة الجدار الناري من الخدمة الأصلية
        // قد يكون الخدمة قد حظرت تطبيقات جديدة في الخلفية
        await _syncFirewallStateFromNative();
      }
    } else if (state == AppLifecycleState.paused) {
      // App went to background: stop the polling timer.
      // Android's UsageStatsManager keeps accumulating in the OS;
      // we will pick up the real delta on next resume — no data is lost.
      _refreshTimer?.cancel();
      _refreshTimer = null;
      debugPrint('⏸️ Monitor paused — polling timer stopped.');
    }
  }

  /// إعادة مزامنة حالة الجدار الناري من SharedPreferences
  /// (قد تكون الخدمة الأصلية قد غيرت البيانات أثناء إغلاق التطبيق)
  Future<void> _syncFirewallStateFromNative() async {
    try {
      final freshBlockedApps = await blockingRepository.getBlockedApps();
      final freshEnabled = await blockingRepository.getFirewallEnabled();
      final isActuallyRunning = await blockingRepository.isFirewallRunning();
      
      // تحديث الحالة المحلية
      if (freshBlockedApps.length != blockedApps.length) {
        blockedApps.assignAll(freshBlockedApps);
        debugPrint('🔄 Synced blocked apps from native: ${freshBlockedApps.length} apps');
      }
      
      isFirewallEnabled.value = freshEnabled;
      
      // إذا كان يجب أن يكون الجدار نشطاً لكنه متوقف، نعيد تشغيله
      if (freshEnabled && freshBlockedApps.isNotEmpty && !isActuallyRunning) {
        await blockingRepository.startFirewall(_blockedPackages);
        debugPrint('🔥 Restarted firewall on resume - was supposed to be running');
      }
    } catch (e) {
      debugPrint('Error syncing firewall state: $e');
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    searchTextController.clear();
    searchFocusNode.unfocus();
    _applyFilter();
  }

  Future<void> _initMonitor() async {
    isLoading.value = true;
    hasPermission.value = await repository.checkUsagePermission();

    if (hasPermission.value) {
      await notificationService.initialize();

      // 🧹 Performance: Clean old data on start
      try {
        final storage = Get.find<LocalStorageDataSource>();
        await storage.cleanOldData(retentionDays: 60);
      } catch (e) {
        debugPrint('🧹 Monitor cleaning error: $e');
      }

      _sessionBaselineMap = await repository.getBaselineSnapshot();
      _lastModemUptime = await repository.getLastUptime();
      appGoals.value = await repository.getAppGoals();
      appAutoBlockPrefs.value = await repository.getAppAutoBlockPrefs();
      
      _startLiveTracking();
      await refreshUsage();
      await fetchAllInstalledApps();
      await _initFirewall();
    }
    isLoading.value = false;
  }

  Future<void> fetchAllInstalledApps() async {
    isLoadingApps.value = true;
    try {
      final apps = await repository.getInstalledApps();
      final categorized = categorizeUseCase.execute(apps);
      // Sort alphabetically
      categorized.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      allInstalledApps.assignAll(categorized);
    } catch (e) {
      debugPrint('Error fetching installed apps: $e');
    } finally {
      isLoadingApps.value = false;
    }
  }

  Future<void> _initFirewall() async {
    blockedApps.value = await blockingRepository.getBlockedApps();
    isFirewallEnabled.value = await blockingRepository.getFirewallEnabled();

    // 1. تشغيل الجدار الناري (VPN) إذا كان مفعلاً ولديه تطبيقات محظورة
    if (isFirewallEnabled.value && blockedApps.isNotEmpty) {
      final isActuallyRunning = await blockingRepository.isFirewallRunning();
      if (!isActuallyRunning) {
        await blockingRepository.startFirewall(_blockedPackages);
      }
    }

    // 2. تشغيل خدمة المراقبة المستقلة إذا كان هناك أي حظر تلقائي مفعل
    await _ensureMonitorState();
  }

  /// يتحقق ما إذا كان يجب تشغيل أو إيقاف خدمة المراقبة بناءً على إعدادات الحظر التلقائي
  Future<void> _ensureMonitorState() async {
    final hasAutoBlock = appAutoBlockPrefs.values.any((enabled) => enabled);
    final isMonitorRunning = await monitorDataSource.isMonitorRunning();

    if (hasAutoBlock && !isMonitorRunning) {
      await monitorDataSource.startMonitor();
      debugPrint('👁️ Usage monitor started - auto-block goals active');
    } else if (!hasAutoBlock && isMonitorRunning) {
      await monitorDataSource.stopMonitor();
      debugPrint('👁️ Usage monitor stopped - no auto-block goals');
    }
  }

  List<String> get _blockedPackages => blockedApps
      .map((b) => b.packageName)
      .where((pkg) => pkg != 'com.sam4g.app_settings')
      .toList();

  void changeFilter(MonitorFilter filter) {
    selectedFilter.value = filter;
    refreshUsage();
  }

  Future<void> requestPermission() async {
    await repository.requestUsagePermission();
    _initMonitor();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (searchQuery.isEmpty) {
      filteredAppsUsage.value = appsUsage;
    } else {
      filteredAppsUsage.value = appsUsage
          .where((app) => app.appName.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }
  }

  Future<void> refreshUsage() async {
    try {
      // 0. Update History (Used for charts)
      int chartDays = selectedFilter.value == MonitorFilter.month ? 30 : 7;
      final history = await repository.getHistory(chartDays);
      historyStats.value = history;

      // 1. Fetch & Process Raw Data via Engine
      final snapshot = await dataEngine.fetchAndProcess(
        sessionBaseline: _sessionBaselineMap,
        dailyBaseline: _dailyBaselineMapAtConnect,
        previousStats: _previousStatsMap,
        lastModemUptime: _lastModemUptime,
        isConnectedToTargetMiFi: isConnectedToTargetMiFi.value,
      );

      // 2. Update baselines and states from Engine
      _sessionBaselineMap = snapshot.newSessionBaseline;
      _dailyBaselineMapAtConnect = snapshot.newDailyBaseline;
      _previousStatsMap = {for (var app in snapshot.rawBootStats) app.packageName: [app.rxBytes, app.txBytes]};
      _lastModemUptime = snapshot.currentUptime;
      if (snapshot.modemRestarted) {
        notificationService.resetSession();
        debugPrint('📡 Modem restart detected via Service!');
      }
      await repository.saveLastUptime(snapshot.currentUptime);

      // 3. Aggregate Data based on Filter
      final aggregated = await aggregator.aggregate(
        filter: selectedFilter.value,
        sessionDelta: snapshot.sessionDelta,
        todayDelta: snapshot.todayDelta,
        rawBootStats: snapshot.rawBootStats,
      );

      // 4. Categorization
      final categorizedApps = categorizeUseCase.execute(aggregated.apps);

      // 5. Handle Discrepancies
      int sumOfAllAttributedApps = categorizedApps.fold(0, (sum, app) => sum + app.totalBytes);
      int totalCapByModem = aggregated.totalRx + aggregated.totalTx;

      if (totalCapByModem > sumOfAllAttributedApps && selectedFilter.value != MonitorFilter.session) {
        int diff = totalCapByModem - sumOfAllAttributedApps;
        if (diff > 5242880) { 
           categorizedApps.add(AppUsageEntity(
            packageName: 'com.linkary.internal.discrepancy',
            appName: 'بيانات مجهولة / نظام قديم',
            totalBytes: diff,
            rxBytes: (diff * 0.6).toInt(),
            txBytes: (diff * 0.4).toInt(),
            rxSpeed: 0,
            txSpeed: 0,
            iconData: null,
            isSystemApp: true,
          ));
        }
      }

      // 6. Filtering & UI Limits (Threshold: 500KB)
      const int uiThreshold = 512000;
      appsUsage.value = categorizedApps
          .where((app) => 
              app.packageName == 'com.linkary.internal.discrepancy' || 
              app.packageName == 'com.sam4g.app_settings' || 
              app.totalBytes >= uiThreshold)
          .toList();
      appsUsage.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));

      // 7. Persistence (Save clean LIVE Today metrics)
      if (isConnectedToTargetMiFi.value) {
         Map<String, List<int>> currentTodayTally = {};
         for (var appToday in snapshot.todayDelta) {
           currentTodayTally[appToday.packageName] = [appToday.rxBytes, appToday.txBytes];
         }
         await repository.saveDailyAppTotals(currentTodayTally);
         
         int liveTodayRx = snapshot.todayDelta.fold(0, (sum, app) => sum + app.rxBytes);
         int liveTodayTx = snapshot.todayDelta.fold(0, (sum, app) => sum + app.txBytes);
         await repository.saveDailyTotal(liveTodayRx, liveTodayTx);
      }

      // 8. Sync State to UI
      rxBytes.value = aggregated.totalRx;
      txBytes.value = aggregated.totalTx;
      totalUsage.value = totalCapByModem;
      totalRxSpeed.value = snapshot.sessionDelta.fold(0, (sum, app) => sum + app.rxSpeed);
      totalTxSpeed.value = snapshot.sessionDelta.fold(0, (sum, app) => sum + app.txSpeed);

      // Category visualization
      Map<AppCategory, int> catTally = {};
      for (var app in appsUsage) {
        catTally[app.category] = (catTally[app.category] ?? 0) + app.totalBytes;
      }
      categoryTotals.value = catTally;

      // History Chart Scale
      double maxVal = 10.0;
      for (var s in history) {
        double rxMb = s['rx'] / 1048576;
        double txMb = s['tx'] / 1048576;
        if (rxMb > maxVal) maxVal = rxMb;
        if (txMb > maxVal) maxVal = txMb;
      }
      maxYForChart.value = maxVal * 1.2;

      _checkUsageAlerts();
      _applyFilter();

      // Update Insight
      if (selectedFilter.value == MonitorFilter.today || selectedFilter.value == MonitorFilter.session) {
         currentInsight.value = await patternAnalyzer.generateDailyInsight(todayTotalBytes: totalCapByModem);
      } else {
         currentInsight.value = null;
      }      
    } catch (e) {
      debugPrint('Error updating monitor: $e');
    }
  }

  void _checkUsageAlerts() async {
    final alerts = await alertsUseCase.execute(
      currentSessionTotal: totalUsage.value,
      apps: appsUsage,
      appGoals: appGoals,
    );
    
    activeAlerts.assignAll(alerts.map((a) => a.message).toList());

    // Trigger push notifications and auto-blocking
    for (var alert in alerts) {
      if (alert.packageName != null) {
        // --- 1. Auto Blocking Logic ---
        if (alert.isGoalExceeded) {
          final isAutoBlockEnabled = appAutoBlockPrefs[alert.packageName!] ?? false;
          
          if (isAutoBlockEnabled && !isAppBlocked(alert.packageName!)) {
            debugPrint('🛡️ Auto-blocking ${alert.packageName} due to limit reach');
            await blockApp(alert.packageName!, alert.appName ?? 'Unknown App');
            if (!isFirewallEnabled.value) {
              await _activateFirewallSilently();
            }
          }
        }

        // --- 2. Generic Warning Notifications ---
        if (!alert.isSpammy) {
          notificationService.showUsageAlert(
            packageName: alert.packageName!,
            title: 'تحذير استهلاك البيانات ⚠️',
            body: alert.message,
          );
        }
      }
    }
  }

  /// Activates the firewall without showing the confirmation dialog
  Future<void> _activateFirewallSilently() async {
    try {
      final prepared = await blockingRepository.prepareVpn();
      if (prepared) {
        await blockingRepository.startFirewall(_blockedPackages);
        isFirewallEnabled.value = true;
        await blockingRepository.setFirewallEnabled(true);
        debugPrint('🛡️ Firewall activated silently due to auto-block');
      }
    } catch (e) {
      debugPrint('Error activating firewall: $e');
    }
  }

  Future<void> setAppGoal(String packageName, int limitMb, {bool autoBlock = false}) async {
    // 🛡️ Ensure VPN permission is granted BEFORE allowing auto-block
    if (autoBlock) {
      final prepared = await blockingRepository.prepareVpn();
      if (!prepared) {
        CustomSnackbar.showError('خطأ', 'يجب الموافقة على إذن الجدار الناري (VPN) لتفعيل الحظر التلقائي.');
        return;
      }
    }

    final bytes = limitMb * 1024 * 1024;
    await repository.saveAppGoal(packageName, bytes);
    await repository.saveAppAutoBlock(packageName, autoBlock);
    
    appGoals[packageName] = bytes;
    appAutoBlockPrefs[packageName] = autoBlock;

    // 🔥 تشغيل/إيقاف خدمة المراقبة المستقلة حسب حالة الحظر التلقائي
    await _ensureMonitorState();

    if (autoBlock) {
      // 🔥 إذا كان الاستهلاك قد تجاوز السقف بالفعل، نحظره فوراً
      final usage = appsUsage.firstWhereOrNull((a) => a.packageName == packageName);
      if (usage != null && usage.totalBytes >= bytes) {
        if (!isAppBlocked(packageName)) {
           if (!isFirewallEnabled.value) {
             isFirewallEnabled.value = true;
             await blockingRepository.setFirewallEnabled(true);
           }
           await blockApp(packageName, usage.appName);
           // تشغيل VPN فوراً لأن هناك تطبيق يحتاج حظر حقيقي
           final isVpnRunning = await blockingRepository.isFirewallRunning();
           if (!isVpnRunning) {
             await blockingRepository.startFirewall(_blockedPackages);
           }
        }
      }
    }
  }

  Future<void> removeAppGoal(String packageName) async {
    await repository.removeAppGoal(packageName);
    await repository.removeAppAutoBlock(packageName);
    appGoals.remove(packageName);
    appAutoBlockPrefs.remove(packageName);
    _checkUsageAlerts();
    // إيقاف خدمة المراقبة إذا لم يعد هناك أي حظر تلقائي
    await _ensureMonitorState();
  }

  Future<void> resetAppUsage(String packageName) async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      // 1. Fetch current usage (Since boot AND Since midnight)
      final sysStatsBoot = await repository.getCurrentSystemUsage();
      final sysStatsToday = await repository.getCurrentSystemUsage(startTime: midnight);

      final appBoot = sysStatsBoot.firstWhereOrNull((a) => a.packageName == packageName);
      final appToday = sysStatsToday.firstWhereOrNull((a) => a.packageName == packageName);
      
      if (appBoot != null) {
        // --- 1. Update Session Baseline ---
        if (_sessionBaselineMap != null) {
          _sessionBaselineMap![packageName] = [appBoot.rxBytes, appBoot.txBytes];
          await repository.saveBaselineSnapshot(_sessionBaselineMap!);
        }

        // --- 2. Update Daily Baseline ---
        final dailyBaseline = await repository.getDailyBaseline();
        if (appToday != null) {
          dailyBaseline[packageName] = [appToday.rxBytes, appToday.txBytes];
        } else {
          dailyBaseline[packageName] = [0, 0];
        }
        await repository.saveDailyBaseline(dailyBaseline);
        
        // --- 3. Sync in-memory states safely ---
        // We update the local maps only if they were already loaded, 
        // otherwise we let refreshUsage() load them from the repository.
        if (_dailyBaselineMapAtConnect.isNotEmpty) {
          _dailyBaselineMapAtConnect[packageName] = dailyBaseline[packageName]!;
        } else {
          // If empty, force reload from repo on next refresh
          _dailyBaselineMapAtConnect.clear(); 
        }

        if (_sessionBaselineMap != null && _sessionBaselineMap!.isNotEmpty) {
           _sessionBaselineMap![packageName] = [appBoot.rxBytes, appBoot.txBytes];
        }
        
        // --- 3. Clear Historical Records for Today ---
        await repository.resetAppUsage(packageName);
        
        // --- 4. Instant UI Feedback ---
        final index = appsUsage.indexWhere((a) => a.packageName == packageName);
        if (index != -1) {
          final oldApp = appsUsage[index];
          appsUsage[index] = AppUsageEntity(
            packageName: oldApp.packageName,
            appName: oldApp.appName,
            totalBytes: 0,
            rxBytes: 0,
            txBytes: 0,
            iconData: oldApp.iconData,
            category: oldApp.category,
            isSystemApp: oldApp.isSystemApp,
          );
        }

        // --- 5. Refresh app history specifically for this app so the chart updates
        await fetchAppHistory(packageName);

        // --- 6. Full Refresh of all stats
        await refreshUsage();
        
        // UI feedback is handled by the caller or by a snackbar here if desired
        debugPrint('✅ App usage reset successful for: $packageName');
      } else {
        debugPrint('⚠️ Cannot reset app usage: app stats not found in boot records');
      }
    } catch (e) {
      debugPrint('Error resetting app usage: $e');
    }
  }

  Future<void> shareDailyReport(BuildContext context) async {
    try {
      CustomSnackbar.showInfo(
        'جاري تحضير التقرير',
        'يرجى الانتظار قليلاً لتوليد الصورة بدقة عالية...',
      );

      final dateStr = DateFormat('EEEE, d MMMM yyyy', 'ar_AG').format(DateTime.now());
      
      final imageFile = await screenshotController.captureFromWidget(
        DailyInfographicWidget(
          topApps: appsUsage,
          categoryTotals: categoryTotals,
          totalBytes: totalUsage.value,
          dateStr: dateStr,
        ),
        delay: const Duration(milliseconds: 200),
        context: context,
      );

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/linkary_daily_report.png').create();
      await file.writeAsBytes(imageFile);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'تقرير استهلاك البيانات لليوم عبر تطبيق اعدادات مودم Sam4G الخاص بي!',
      );
    } catch (e) {
      debugPrint('Error sharing report: $e');
      CustomSnackbar.showError('خطأ', 'فشل توليد أو مشاركة التقرير: $e');
    }
  }

  Future<void> shareAppDetail(BuildContext context, String packageName) async {
    try {
      final app = appsUsage.firstWhereOrNull((a) => a.packageName == packageName) ??
                 allInstalledApps.firstWhereOrNull((a) => a.packageName == packageName);
      
      if (app == null) return;

      CustomSnackbar.showInfo(
        'جاري تحضير التقرير',
        'يرجى الانتظار قليلاً لتوليد صورة التفاصيل...',
      );

      final dateStr = DateFormat('EEEE, d MMMM yyyy', 'ar_AG').format(DateTime.now());
      final historyList = appHistoryData.toList();
      
      final imageFile = await screenshotController.captureFromWidget(
        AppDetailInfographicWidget(
          app: app,
          historyData: historyList,
          dateStr: dateStr,
        ),
        delay: const Duration(milliseconds: 500),
        context: context,
      );

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/linkary_app_report_${app.packageName}.png').create();
      await file.writeAsBytes(imageFile);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'تقرير استهلاك تطبيق ${app.appName} عبر تطبيق اعدادات مودم Sam4G!',
      );
    } catch (e) {
      debugPrint('Error sharing app detail: $e');
      CustomSnackbar.showError('خطأ', 'فشل توليد أو مشاركة التقرير: $e');
    }
  }

  void _startLiveTracking() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkNetworkAndProcess();
    });
  }

  Future<void> _checkNetworkAndProcess() async {
    try {
      final info = NetworkInfo();
      final gatewayIp = await info.getWifiGatewayIP();

      if (gatewayIp == TARGET_GATEWAY_IP) {
        if (!isConnectedToTargetMiFi.value) {
          isConnectedToTargetMiFi.value = true;
          // 🛡️ Bugfix: On reconnect, restore saved baseline from storage.
          // DO NOT take a fresh snapshot — that would include usage that
          // happened while we were disconnected, erasing it from the count.
          final savedBaseline = await repository.getBaselineSnapshot();
          if (savedBaseline.isNotEmpty) {
            _sessionBaselineMap = savedBaseline;
            debugPrint('✅ Restored session baseline from storage on reconnect.');
          } else {
            // First time ever connecting — take an initial snapshot
            final current = await repository.getCurrentSystemUsage();
            _sessionBaselineMap = {for (var app in current) app.packageName: [app.rxBytes, app.txBytes]};
            await repository.saveBaselineSnapshot(_sessionBaselineMap!);
            debugPrint('🆕 First connect — new baseline snapshot taken.');
          }
          _lastModemUptime = null;
        }
        await refreshUsage();
      } else {
        isConnectedToTargetMiFi.value = false;
        totalRxSpeed.value = 0;
        totalTxSpeed.value = 0;
        _previousStatsMap = null;
        // 🛡️ Bugfix: Do NOT wipe _sessionBaselineMap on disconnect.
        // It is preserved in memory and in storage so usage while minimized is always tracked.
        _lastModemUptime = null;
      }
    } catch (e) {
      debugPrint('Network check error: $e');
    }
  }

  void resetSession() async {
    final current = await repository.getCurrentSystemUsage();
    _sessionBaselineMap = {for (var app in current) app.packageName: [app.rxBytes, app.txBytes]};
    await repository.saveBaselineSnapshot(_sessionBaselineMap!);
    refreshUsage();
  }

  Future<void> fetchAppHistory(String packageName, {int days = 7}) async {
    appHistoryData.clear();
    final history = await repository.getAppHistory(packageName, days);
    appHistoryData.value = history;
  }

  // ==========================================
  // --- ميزة حظر التطبيقات (App Blocking) ---
  // ==========================================

  Future<void> blockApp(String packageName, String appName) async {
    if (blockedApps.any((b) => b.packageName == packageName)) return;

    blockedApps.add(BlockedApp(
      packageName: packageName,
      appName: appName,
      blockedAt: DateTime.now(),
    ));
    await blockingRepository.saveBlockedApps(blockedApps);

    if (isFirewallEnabled.value) {
      await blockingRepository.updateFirewall(_blockedPackages);
    }
  }

  Future<void> unblockApp(String packageName) async {
    blockedApps.removeWhere((b) => b.packageName == packageName);
    await blockingRepository.saveBlockedApps(blockedApps);

    if (isFirewallEnabled.value) {
      if (blockedApps.isEmpty) {
        await blockingRepository.stopFirewall();
        isFirewallEnabled.value = false;
        await blockingRepository.setFirewallEnabled(false);
      } else {
        await blockingRepository.updateFirewall(_blockedPackages);
      }
    }
  }

  Future<void> toggleFirewall(bool enabled) async {
    if (enabled) {
      if (blockedApps.isEmpty) {
        CustomSnackbar.showWarning('⚠️ تنبيه', 'أضف تطبيقاً واحداً على الأقل قبل تشغيل الجدار الناري');
        return;
      }

      // عرض رسالة تأكيد وشرح للمستخدم
      bool confirm = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: Get.isDarkMode ? const Color(0xFF16213E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Iconsax.shield_tick, color: Color(0xFF4A90E2)),
              SizedBox(width: 10),
              Text('تفعيل الجدار الناري؟', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Iconsax.info_circle, size: 18, color: Color(0xFF4A90E2)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم تفعيل جدار ناري داخلي لحظر التطبيقات التي اخترتها من الوصول إلى الإنترنت عبر مودم Sam4G. يمكنك تعديل قائمة التطبيقات المحظورة أو إيقاف الجدار الناري في أي وقت.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF4A90E2), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('تفعيل الآن'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) {
        isFirewallEnabled.value = false; // تحديث الواجهة لتعكس الإلغاء
        return;
      }

      final prepared = await blockingRepository.prepareVpn();
      if (!prepared) {
        CustomSnackbar.showError('خطأ', 'يجب الموافقة على إذن VPN لتفعيل الحظر');
        isFirewallEnabled.value = false;
        return;
      }

      await blockingRepository.startFirewall(_blockedPackages);
    } else {
      // عند إيقاف الجدار الناري يدوياً:
      // إذا كان هناك حظر تلقائي مفعل، ننتقل لوضع المراقبة (الخدمة تبقى حية)
      // إذا لم يكن هناك حظر تلقائي، نوقف الخدمة بالكامل
      final hasAutoBlock = appAutoBlockPrefs.values.any((enabled) => enabled);
      if (hasAutoBlock) {
        await monitorDataSource.startMonitor();
      } else {
        await blockingRepository.stopFirewall();
      }
    }

    isFirewallEnabled.value = enabled;
    await blockingRepository.setFirewallEnabled(enabled);
  }

  bool isAppBlocked(String packageName) => blockedApps.any((b) => b.packageName == packageName);

  bool isAppEffectivelyBlocked(String packageName) => isFirewallEnabled.value && isAppBlocked(packageName);

  String formatBytes(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '$bytes B';
  }

  String formatSpeed(int bytesPerInterval) {
    double bytesPerSecond = bytesPerInterval / 3.0; 
    if (bytesPerSecond >= 1048576) return '${(bytesPerSecond / 1048576).toStringAsFixed(1)} MB/s';
    if (bytesPerSecond >= 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${bytesPerSecond.toStringAsFixed(0)} B/s';
  }
}