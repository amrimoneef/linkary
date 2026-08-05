import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/infrastructure/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/controllers/notifications_controller.dart';
import '../../core/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/connected_devices/domain/repositories/connected_devices_repository.dart';
import '../../features/connected_devices/domain/usecases/get_connected_devices_usecase.dart';
import '../../features/connected_devices/infrastructure/data_sources/connected_devices_remote_data_source.dart';
import '../../features/connected_devices/infrastructure/repositories_impl/connected_devices_repository_impl.dart';
import '../../features/connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import '../../features/dashboard/domain/usecases/get_engineering_info_usecase.dart';
import '../../features/dashboard/infrastructure/data_sources/dashboard_remote_data_source.dart';
import '../../features/dashboard/infrastructure/repositories_impl/dashboard_repository_impl.dart';
import '../../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../features/data_usage/domain/entities/data_usage_entity.dart';
import '../../features/data_usage/domain/repositories/data_usage_repository.dart';
import '../../features/data_usage/domain/usecases/data_usage_usecases.dart';
import '../../features/data_usage/infrastructure/data_sources/data_usage_remote_data_source.dart';
import '../../features/data_usage/infrastructure/repositories_impl/data_usage_repository_impl.dart';
import '../../features/data_usage/presentation/controllers/data_usage_controller.dart';
import '../../features/mac_filter/domain/repositories/mac_filter_repository.dart';
import '../../features/mac_filter/domain/usecases/mac_filter_usecases.dart';
import '../../features/mac_filter/infrastructure/data_sources/mac_filter_remote_data_source.dart';
import '../../features/mac_filter/infrastructure/repositories_impl/mac_filter_repository_impl.dart';
import '../../features/mac_filter/presentation/controllers/mac_filter_controller.dart';
import '../../features/url_filter/domain/repositories/url_filter_repository.dart';
import '../../features/url_filter/domain/usecases/get_url_filter_usecase.dart';
import '../../features/url_filter/domain/usecases/save_url_filter_usecase.dart';
import '../../features/url_filter/infrastructure/data_sources/url_filter_remote_data_source.dart';
import '../../features/url_filter/infrastructure/repositories_impl/url_filter_repository_impl.dart';
import '../../features/url_filter/presentation/controllers/url_filter_controller.dart';
import '../../features/mifi_app_monitor/domain/services/notification_service.dart';
import '../../features/mifi_app_monitor/domain/services/usage_aggregator.dart';
import '../../features/mifi_app_monitor/domain/services/usage_data_engine.dart';
import '../../features/mifi_app_monitor/domain/services/usage_pattern_analyzer.dart';
import '../../features/mifi_app_monitor/infrastructure/data_sources/blocked_apps_storage.dart';
import '../../features/modem_auth/domain/repositories/auth_repository.dart';
import '../../features/modem_auth/domain/usecases/get_retry_times_usecase.dart';
import '../../features/modem_auth/domain/usecases/login_usecase.dart';
import '../../features/modem_auth/domain/usecases/logout_usecase.dart';
import '../../features/modem_auth/domain/usecases/reboot_usecase.dart';
import '../../features/modem_auth/domain/usecases/power_off_usecase.dart';
import '../../features/modem_auth/domain/usecases/factory_reset_usecase.dart';
import '../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../../features/settings/domain/repositories/admin_settings_repository.dart';
import '../../features/settings/domain/usecases/get_admin_settings_usecase.dart';
import '../../features/settings/domain/usecases/update_admin_settings_usecase.dart';
import '../../features/settings/infrastructure/data_sources/admin_remote_data_source.dart';
import '../../features/settings/infrastructure/repositories_impl/admin_settings_repository_impl.dart';
import '../../features/settings/presentation/controllers/admin_settings_controller.dart';
import '../../features/modem_auth/infrastructure/data_sources/auth_remote_data_source.dart';
import '../../features/modem_auth/infrastructure/repositories_impl/auth_repository_impl.dart';
import '../../features/parental_control/domain/repositories/parental_control_repository.dart';
import '../../features/parental_control/domain/usecases/parental_control_usecases.dart';
import '../../features/parental_control/infrastructure/data_sources/parental_control_remote_data_source.dart';
import '../../features/parental_control/infrastructure/repositories_impl/parental_control_repository_impl.dart';
import '../../features/parental_control/presentation/controllers/parental_control_controller.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/change_admin_password_usecase.dart';
import '../../features/settings/domain/usecases/get_wifi_settings_usecase.dart';
import '../../features/settings/domain/usecases/save_wifi_settings_usecase.dart';
import '../../features/settings/infrastructure/data_sources/settings_remote_data_source.dart';
import '../../features/settings/infrastructure/repositories_impl/settings_repository_impl.dart';
import '../../features/settings/presentation/controllers/wifi_settings_controller.dart';
import '../../features/speed_limit/domain/repositories/speed_limit_repository.dart';
import '../../features/speed_limit/domain/usecases/speed_limit_usecases.dart';
import '../../features/speed_limit/infrastructure/data_sources/speed_limit_remote_data_source.dart';
import '../../features/speed_limit/infrastructure/repositories_impl/speed_limit_repository_impl.dart';
import '../../features/speed_limit/presentation/controllers/speed_limit_controller.dart';
import '../../features/quick_setup/presentation/controllers/quick_setup_controller.dart' as linkary_quick_setup;
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../network/session_heartbeat_service.dart';
import '../../features/bill/domain/repositories/bill_repository.dart';
import '../../features/bill/domain/usecases/fetch_bill_usecase.dart';
import '../../features/bill/domain/usecases/submit_bill_usecase.dart';
import '../../features/bill/infrastructure/data_sources/bill_remote_data_source.dart';
import '../../features/bill/infrastructure/repositories_impl/bill_repository_impl.dart';
import '../../features/bill/presentation/controllers/bill_controller.dart';

import '../../features/voice_assistant/infrastructure/services/speech_recognition_service.dart';
import '../../features/voice_assistant/infrastructure/services/tts_service.dart';
import '../../features/voice_assistant/domain/services/voice_command_interpreter.dart';
import '../../features/voice_assistant/domain/services/voice_command_executor.dart';
import '../../features/voice_assistant/presentation/controllers/voice_assistant_controller.dart';

import '../../features/signal_finder/infrastructure/services/haptic_feedback_service.dart' as linkary_haptic;
import '../../features/signal_finder/domain/services/signal_score_calculator.dart' as linkary_signal;
import '../../features/signal_finder/presentation/controllers/signal_finder_controller.dart' as linkary_signal_controller;
import '../../features/signal_finder/infrastructure/services/saved_locations_service.dart';
import '../../features/signal_finder/presentation/controllers/saved_locations_controller.dart';
import '../../features/speed_test/infrastructure/data_sources/speed_test_data_source.dart' as speed_test;
import '../../features/speed_test/presentation/controllers/speed_test_controller.dart' as speed_test_controller;

import '../../features/mifi_app_monitor/infrastructure/data_sources/native_stats_data_source.dart';
import '../../features/mifi_app_monitor/infrastructure/data_sources/local_storage_data_source.dart';
import '../../features/mifi_app_monitor/domain/repositories/app_monitor_repository.dart';
import '../../features/mifi_app_monitor/infrastructure/repositories/app_monitor_repository_impl.dart';
import '../../features/mifi_app_monitor/domain/use_cases/calculate_usage_delta_usecase.dart';
import '../../features/mifi_app_monitor/domain/use_cases/categorize_apps_usecase.dart';
import '../../features/mifi_app_monitor/domain/use_cases/check_usage_alerts_usecase.dart';

import '../../features/mifi_app_monitor/domain/services/modem_session_service.dart';
import '../../features/mifi_app_monitor/presentation/controllers/app_monitor_controller.dart';
import '../../features/mifi_app_monitor/domain/repositories/app_blocking_repository.dart';
import '../../features/mifi_app_monitor/infrastructure/repositories/app_blocking_repository_impl.dart';
import '../../features/mifi_app_monitor/infrastructure/data_sources/firewall_native_data_source.dart';
import '../../features/mifi_app_monitor/infrastructure/data_sources/monitor_native_data_source.dart';
import '../../features/modem_finder/infrastructure/services/wifi_rssi_reader.dart';
import '../../features/modem_finder/domain/services/rssi_smoother.dart';
import '../../features/modem_finder/domain/services/proximity_classifier.dart';
import '../../features/modem_finder/domain/services/geiger_rhythm_calculator.dart';
import '../../features/modem_finder/domain/services/calibration_service.dart';
import '../../features/modem_finder/domain/services/distance_estimator.dart';
import '../../features/modem_finder/domain/services/trend_analyzer.dart';
import '../../features/modem_finder/infrastructure/services/geiger_audio_service.dart';
import '../../features/modem_finder/infrastructure/services/finder_haptic_service.dart';
import '../../features/modem_finder/infrastructure/services/anti_loss_service.dart';
import '../../features/modem_finder/presentation/controllers/modem_finder_controller.dart';

import '../../features/banners/infrastructure/data_sources/banners_remote_data_source.dart';
import '../../features/banners/domain/repositories/banners_repository.dart';
import '../../features/banners/infrastructure/repositories_impl/banners_repository_impl.dart';
import '../../features/banners/domain/usecases/get_banners_usecase.dart';
import '../../features/banners/presentation/controllers/banners_controller.dart';

import '../../features/device_data_limit/domain/repositories/device_data_limit_repository.dart';
import '../../features/device_data_limit/domain/usecases/get_device_data_limit_enable_usecase.dart';
import '../../features/device_data_limit/domain/usecases/set_device_data_limit_enable_usecase.dart';
import '../../features/device_data_limit/domain/usecases/get_device_data_limit_list_usecase.dart';
import '../../features/device_data_limit/domain/usecases/add_device_data_limit_usecase.dart';
import '../../features/device_data_limit/domain/usecases/delete_device_data_limit_usecase.dart';
import '../../features/device_data_limit/infrastructure/data_sources/device_data_limit_remote_data_source.dart';
import '../../features/device_data_limit/infrastructure/repositories_impl/device_data_limit_repository_impl.dart';
import '../../features/device_data_limit/presentation/controllers/device_data_limit_controller.dart';

Future<void> initDI() async {
  // 0. التخزين المحلي
  final sharedPrefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(sharedPrefs, permanent: true);

  // ميزة الإشعارات الجديدة
  Get.lazyPut<NotificationsRepository>(() => NotificationsRepository(Get.find()), fenix: true);
  Get.lazyPut<NotificationsController>(() => NotificationsController(Get.find()), fenix: true);

  // 1. الحزم الخارجية (External)
  Get.lazyPut<http.Client>(() => ApiClient(inner: http.Client()), fenix: true);
  Get.lazyPut<NetworkInfo>(() => NetworkInfoImpl(http.Client()), fenix: true);
  Get.lazyPut<BiometricService>(() => BiometricService(), fenix: true);
  Get.lazyPut<SessionHeartbeatService>(() => SessionHeartbeatService(), fenix: true);

  // 2. مصادر البيانات (Data Sources)
  Get.lazyPut<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(client: Get.find()),
        fenix: true,
  );
  Get.lazyPut<DashboardRemoteDataSource>(
        () => DashboardRemoteDataSourceImpl(client: Get.find()),
      fenix: true
  );
  Get.lazyPut<ConnectedDevicesRemoteDataSource>(
        () => ConnectedDevicesRemoteDataSourceImpl(client: Get.find()),
    fenix: true,
  );
  Get.lazyPut<SettingsRemoteDataSource>(
        () => SettingsRemoteDataSourceImpl(client: Get.find()),
    fenix: true,
  );
  Get.lazyPut<SpeedLimitRemoteDataSource>(
          () => SpeedLimitRemoteDataSourceImpl(client: Get.find()),
      fenix: true,
  );
  Get.lazyPut<DeviceDataLimitRemoteDataSource>(
          () => DeviceDataLimitRemoteDataSourceImpl(client: Get.find()),
      fenix: true,
  );

  // 3. المستودعات (Repositories)
  Get.lazyPut<AuthRepository>(
        () => AuthRepositoryImpl(remoteDataSource: Get.find()),
        fenix: true,
  );
  Get.lazyPut<DashboardRepository>(
        () => DashboardRepositoryImpl(remoteDataSource: Get.find()),
      fenix: true
  );
  Get.lazyPut<ConnectedDevicesRepository>(
        () => ConnectedDevicesRepositoryImpl(remoteDataSource: Get.find()),
    fenix: true,
  );
  Get.lazyPut<SettingsRepository>(
        () => SettingsRepositoryImpl(remoteDataSource: Get.find()),
    fenix: true,
  );
  Get.lazyPut<SpeedLimitRepository>(
          () => SpeedLimitRepositoryImpl(remoteDataSource: Get.find()),
      fenix: true,
  );
  Get.lazyPut<DeviceDataLimitRepository>(
          () => DeviceDataLimitRepositoryImpl(remoteDataSource: Get.find()),
      fenix: true,
  );


  // 4. حالات الاستخدام (Use Cases)
  Get.lazyPut(() => LoginUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => GetRetryTimesUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => LogoutUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => RebootUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => PowerOffUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => FactoryResetUseCase(repository: Get.find()), fenix: true);
  Get.lazyPut(() => GetAdminSettingsUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => UpdateAdminSettingsUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => GetDashboardDataUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => GetEngineeringInfoUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => GetConnectedDevicesUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => GetWifiSettingsUseCase(Get.find()), fenix: true,);
  Get.lazyPut(() => SaveWifiSettingsUseCase(Get.find()), fenix: true,);
  Get.lazyPut(() => ChangeAdminPasswordUseCase(Get.find(), Get.find()), fenix: true);
  Get.lazyPut(() => GetSpeedLimitUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => SaveSpeedLimitUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => GetDeviceDataLimitEnableUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => SetDeviceDataLimitEnableUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => GetDeviceDataLimitListUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => AddDeviceDataLimitUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => DeleteDeviceDataLimitUseCase(Get.find()), fenix: true);


  // 5. المتحكمات (Controllers)
  Get.lazyPut(() => AuthController(
      loginUseCase: Get.find(),
      getRetryTimesUseCase: Get.find(),
      biometricService: Get.find(),
      logoutUseCase: Get.find(),
      rebootUseCase: Get.find(),
      powerOffUseCase: Get.find(),
      factoryResetUseCase: Get.find(),
  ), fenix: true);
  Get.lazyPut(() => DashboardController(
      getDashboardDataUseCase: Get.find(),
      getEngineeringInfoUseCase: Get.find(),
      getDataUsageUseCase: Get.find(),
      getWifiSettingsUseCase: Get.find(),
      getConnectedDevicesUseCase: Get.find(),
  ), fenix: true);
  Get.lazyPut(() => ConnectedDevicesController(
      getConnectedDevicesUseCase: Get.find()),
      fenix: true);
  Get.lazyPut(() => WifiSettingsController(
    getWifiSettingsUseCase: Get.find(),
    saveWifiSettingsUseCase: Get.find(),
  ), fenix: true);
  Get.lazyPut(() => SpeedLimitController(
      getUseCase: Get.find(), saveUseCase: Get.find()),
      fenix: true);
  Get.lazyPut(() => linkary_quick_setup.QuickSetupController(
        getWifiSettingsUseCase: Get.find(),
        saveWifiSettingsUseCase: Get.find(),
        updateAdminSettingsUseCase: Get.find(),
      ), fenix: true);
  Get.lazyPut(() => DeviceDataLimitController(
      Get.find(), Get.find(), Get.find(), Get.find(), Get.find()
  ), fenix: true);

  // ==========================================
  // --- ميزة استهلاك البيانات (Data Usage) ---
  // ==========================================
  Get.lazyPut<AdminRemoteDataSource>(() => AdminRemoteDataSourceImpl(client: Get.find()), fenix: true);
  Get.lazyPut<AdminSettingsRepository>(() => AdminSettingsRepositoryImpl(remoteDataSource: Get.find()), fenix: true);
  Get.lazyPut<DataUsageRemoteDataSource>(() => DataUsageRemoteDataSourceImpl(client: Get.find()), fenix: true);
  Get.lazyPut<DataUsageRepository>(() => DataUsageRepositoryImpl(remoteDataSource: Get.find()), fenix: true);
  Get.lazyPut(() => GetDataUsageUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => SaveDataUsageUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => CalibrateDataUsageUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => DataUsageController(
    getUseCase: Get.find(),
    saveUseCase: Get.find(),
    calibrateUseCase: Get.find(),
  ), fenix: true);

  // ==========================================
  // --- ميزة مرشح الماك (MAC Filter) ---
  // ==========================================
  Get.lazyPut<MacFilterRemoteDataSource>(() => MacFilterRemoteDataSourceImpl(client: Get.find()), fenix: true);
  Get.lazyPut<MacFilterRepository>(() => MacFilterRepositoryImpl(remoteDataSource: Get.find()), fenix: true);
  Get.lazyPut(() => GetMacFilterUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => SaveMacFilterUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => MacFilterController(getUseCase: Get.find(), saveUseCase: Get.find()), fenix: true);

  // ==========================================
  // --- ميزة مرشح الروابط (URL Filter) ---
  // ==========================================
  Get.lazyPut<UrlFilterRemoteDataSource>(() => UrlFilterRemoteDataSourceImpl(client: Get.find()), fenix: true);
  Get.lazyPut<UrlFilterRepository>(() => UrlFilterRepositoryImpl(remoteDataSource: Get.find()), fenix: true);
  Get.lazyPut(() => GetUrlFilterUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => SaveUrlFilterUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => UrlFilterController(getUseCase: Get.find(), saveUseCase: Get.find()), fenix: true);

  // ==========================================
  // --- ميزة التحكم الأبوي (Parental Control) ---
  // ==========================================
  Get.lazyPut<ParentalControlRemoteDataSource>(() => ParentalControlRemoteDataSourceImpl(client: Get.find()), fenix: true);
  Get.lazyPut<ParentalControlRepository>(() => ParentalControlRepositoryImpl(remoteDataSource: Get.find()), fenix: true);

  // حالات الاستخدام الأربع
  Get.lazyPut(() => GetParentalControlStatusUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => SetParentalControlStatusUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => GetParentalDevicesUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => SaveParentalRuleUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => DeleteParentalRuleUseCase(Get.find()), fenix: true);

  // المتحكم
  Get.lazyPut(() => ParentalControlController(
    getStatusUseCase: Get.find<GetParentalControlStatusUseCase>(),
    setStatusUseCase: Get.find<SetParentalControlStatusUseCase>(),
    getListUseCase: Get.find<GetParentalDevicesUseCase>(),
    saveRuleUseCase: Get.find<SaveParentalRuleUseCase>(),
    deleteRuleUseCase: Get.find<DeleteParentalRuleUseCase>(),
  ), fenix: true);
  Get.lazyPut(() => AdminSettingsController(
      getAdminSettingsUseCase: Get.find(),
      updateAdminSettingsUseCase: Get.find(),
  ), fenix: true);

  // ==========================================
  // --- ميزة استعلام الرصيد والباقة (Bill) ---
  // ==========================================
  Get.lazyPut<BillRemoteDataSource>(
    () => BillRemoteDataSourceImpl(),
    fenix: true,
  );
  Get.lazyPut<BillRepository>(
    () => BillRepositoryImpl(remoteDataSource: Get.find()),
    fenix: true,
  );
  Get.lazyPut(() => FetchBillUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => SubmitBillUseCase(Get.find()), fenix: true);
  Get.lazyPut(
    () => BillController(
      fetchBillUseCase: Get.find(),
      submitBillUseCase: Get.find(),
    ),
    fenix: true,
  );

  // ==========================================
  // --- ميزة المساعد الصوتي (Voice Assistant) ---
  // ==========================================
  Get.lazyPut(() => SpeechRecognitionService(), fenix: true);
  Get.lazyPut(() => TtsService(), fenix: true);
  Get.lazyPut(() => VoiceCommandInterpreter(), fenix: true);
  Get.lazyPut(() => VoiceCommandExecutor(), fenix: true);
  Get.lazyPut(() => VoiceAssistantController(
    speechService: Get.find(),
    ttsService: Get.find(),
    interpreter: Get.find(),
    executor: Get.find(),
  ), fenix: true);
  
  // ==========================================
  // --- ميزة كاشف النقطة الذهبية (Signal Finder) ---
  // ==========================================
  Get.lazyPut(() => linkary_haptic.HapticFeedbackService(), fenix: true);
  Get.lazyPut(() => linkary_signal.SignalScoreCalculator(), fenix: true);
  Get.lazyPut(() => linkary_signal_controller.SignalFinderController(
      getEngineeringInfoUseCase: Get.find(),
      scoreCalculator: Get.find(),
      hapticService: Get.find(),
  ), fenix: true);
  Get.lazyPut(() => SavedLocationsService(const FlutterSecureStorage()), fenix: true);
  Get.lazyPut(() => SavedLocationsController(Get.find()), fenix: true);
  // ==========================================
  // --- ميزة فحص سرعة الإنترنت (Speed Test) ---
  // ==========================================
  Get.lazyPut(() => speed_test.SpeedTestDataSource(client: http.Client()), fenix: true);
  Get.lazyPut(() => speed_test_controller.SpeedTestController(dataSource: Get.find()), fenix: true);

  // ==========================================
  // --- ميزة مراقب التطبيقات (App Monitor) ---
  // ==========================================
  Get.lazyPut(() => NativeStatsDataSource(), fenix: true);
  Get.lazyPut(() => LocalStorageDataSource(), fenix: true);
  
  // App Blocking
  Get.lazyPut(() => FirewallNativeDataSource(), fenix: true);
  Get.lazyPut(() => MonitorNativeDataSource(), fenix: true);
  Get.lazyPut(() => BlockedAppsStorage(), fenix: true);
  Get.lazyPut<AppBlockingRepository>(
    () => AppBlockingRepositoryImpl(
      nativeSource: Get.find(),
      storage: Get.find(),
    ),
    fenix: true,
  );

  Get.lazyPut<AppMonitorRepository>(
    () => AppMonitorRepositoryImpl(
      nativeDataSource: Get.find(),
      localStorage: Get.find(),
    ),
    fenix: true,
  );
  Get.lazyPut(() => CalculateUsageDeltaUseCase(), fenix: true);
  Get.lazyPut(() => CategorizeAppsUseCase(), fenix: true);
  Get.lazyPut(() => CheckUsageAlertsUseCase(Get.find()), fenix: true);
  Get.lazyPut(() => ModemSessionService(), fenix: true);
  Get.lazyPut(() => NotificationService(), fenix: true);
  
  // New split services for Phase 3
  Get.lazyPut(() => UsageDataEngine(
    repository: Get.find(),
    deltaUseCase: Get.find(),
    sessionService: Get.find(),
  ), fenix: true);
  
  Get.lazyPut(() => UsageAggregator(
    repository: Get.find(),
  ), fenix: true);

  Get.lazyPut(() => UsagePatternAnalyzer(
    Get.find(),
  ), fenix: true);
  
  Get.put<AppMonitorController>(AppMonitorController(
    repository: Get.find(),
    dataEngine: Get.find(),
    aggregator: Get.find(),
    categorizeUseCase: Get.find(),
    alertsUseCase: Get.find(),
    blockingRepository: Get.find(),
    notificationService: Get.find(),
    patternAnalyzer: Get.find(),
    monitorDataSource: Get.find(),
  ), permanent: true);

  // ==========================================
  // --- ميزة البحث عن المودم (Modem Finder) ---
  // ==========================================
  Get.lazyPut(() => WifiRssiReader(), fenix: true);
  Get.lazyPut(() => RssiSmoother(), fenix: true);
  Get.lazyPut(() => ProximityClassifier(), fenix: true);
  Get.lazyPut(() => GeigerRhythmCalculator(), fenix: true);
  Get.lazyPut(() => DistanceEstimator(), fenix: true);
  Get.lazyPut(() => TrendAnalyzer(), fenix: true);
  Get.lazyPut(() => GeigerAudioService(), fenix: true);
  Get.lazyPut(() => FinderHapticService(), fenix: true);
  Get.lazyPut(() => CalibrationService(), fenix: true);
  Get.lazyPut(() => AntiLossService(), fenix: true);
  Get.lazyPut(() => ModemFinderController(
    rssiReader: Get.find(),
    smoother: Get.find(),
    classifier: Get.find(),
    rhythmCalculator: Get.find(),
    distanceEstimator: Get.find(),
    trendAnalyzer: Get.find(),
    audioService: Get.find(),
    hapticService: Get.find(),
    calibrationService: Get.find(),
  ), fenix: true);

  // ==========================================
  // --- ميزة العروض والإعلانات (Banners) ---
  // ==========================================
  Get.lazyPut<BannersRemoteDataSource>(
    () => BannersRemoteDataSource(client: Get.find()),
    fenix: true,
  );
  Get.lazyPut<BannersRepository>(
    () => BannersRepositoryImpl(remoteDataSource: Get.find()),
    fenix: true,
  );
  Get.lazyPut(() => GetBannersUseCase(repository: Get.find()), fenix: true);
  Get.put(BannersController(getBannersUseCase: Get.find()), permanent: true);
}
