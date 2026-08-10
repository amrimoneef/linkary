import 'dart:async';
import 'package:get/get.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/proximity_level.dart';
import '../../domain/entities/rssi_reading.dart';
import '../../domain/entities/calibration_data.dart';
import '../../domain/services/rssi_smoother.dart';
import '../../domain/services/proximity_classifier.dart';
import '../../domain/services/geiger_rhythm_calculator.dart';
import '../../domain/services/distance_estimator.dart';
import '../../domain/services/trend_analyzer.dart';
import '../../infrastructure/services/wifi_rssi_reader.dart';
import '../../infrastructure/services/geiger_audio_service.dart';
import '../../infrastructure/services/finder_haptic_service.dart';
import '../../domain/services/calibration_service.dart';
import '../widgets/modem_welcome_dialog.dart';

class ModemFinderController extends GetxController {
  final WifiRssiReader rssiReader;
  final RssiSmoother smoother;
  final ProximityClassifier classifier;
  final GeigerRhythmCalculator rhythmCalculator;
  final DistanceEstimator distanceEstimator;
  final TrendAnalyzer trendAnalyzer;
  final GeigerAudioService audioService;
  final FinderHapticService hapticService;
  final CalibrationService calibrationService;

  ModemFinderController({
    required this.rssiReader,
    required this.smoother,
    required this.classifier,
    required this.rhythmCalculator,
    required this.distanceEstimator,
    required this.trendAnalyzer,
    required this.audioService,
    required this.hapticService,
    required this.calibrationService,
  });

  // State
  var currentRssi = (-100).obs;
  var smoothedRssi = (-100.0).obs;
  var proximityLevel = ProximityLevel.freezing.obs;
  var proximityPercentage = 0.0.obs;
  
  var isScanning = false.obs;
  var isGeigerMode = true.obs;
  var isSoundEnabled = true.obs;
  var isCalibrated = false.obs;
  
  var connectedSSID = ''.obs;
  var wifiFrequency = 0.obs;
  var isConnectedToWifi = true.obs;
  
  var guidanceMessage = 'اضغط على ابدأ للبحث عن المودم'.obs;

  // Internal
  Timer? _scanTimer;
  CalibrationData? _calibrationData;
  final List<RssiReading> _history = [];

  static const Duration scanInterval = Duration(milliseconds: 300);

  @override
  void onInit() {
    super.onInit();
    _checkInitialWifiState();
    reloadCalibration();
  }

  @override
  void onReady() {
    super.onReady();
    _checkWelcomeMessage();
  }

  Future<void> _checkWelcomeMessage() async {
    final hide = await calibrationService.getHideWelcomeMessage();
    if (!hide) {
      ModemWelcomeDialog.show();
    }
  }

  Future<void> reloadCalibration() async {
    final maxRssi = await calibrationService.getMaxRssi();
    if (maxRssi != null) {
      _calibrationData = CalibrationData(
        maxRssi: maxRssi.toDouble(),
        frequency: wifiFrequency.value > 0 ? wifiFrequency.value : 2400,
        timestamp: DateTime.now(),
      );
      isCalibrated.value = true;
    } else {
      _calibrationData = null;
      isCalibrated.value = false;
    }
  }

  Future<void> _checkInitialWifiState() async {
    final rawSsid = await rssiReader.getSSID();
    connectedSSID.value = _cleanSsid(rawSsid);
    isConnectedToWifi.value = rawSsid.isNotEmpty;
    if (isConnectedToWifi.value) {
      wifiFrequency.value = await rssiReader.getFrequency();
    }
  }

  String _cleanSsid(String raw) {
    String clean = raw.replaceAll('"', '');
    if (clean == '<unknown ssid>' || clean == 'unknown ssid' || clean.isEmpty) {
      try {
        final dashboardSsid = Get.find<DashboardController>().wifiSsid.value;
        if (dashboardSsid.isNotEmpty && dashboardSsid != 'جاري التحميل...') {
          return dashboardSsid;
        }
      } catch (e) {
        // ignore
      }
      return 'الشبكة الحالية';
    }
    return clean;
  }

  void startScanning() {
    if (isScanning.value) return;
    isScanning.value = true;
    smoother.reset();
    classifier.reset();
    _history.clear();
    
    if (isGeigerMode.value) {
      hapticService.startTicking(proximityLevel.value, rhythmCalculator);
      audioService.startTicking(proximityLevel.value, rhythmCalculator);
    }

    _scanTimer = Timer.periodic(scanInterval, (_) => _fetchAndProcess());
  }

  void stopScanning() {
    isScanning.value = false;
    _scanTimer?.cancel();
    _scanTimer = null;
    hapticService.stop();
    audioService.stop();
    guidanceMessage.value = 'تم إيقاف البحث';
  }

  var estimatedDistance = 0.0.obs;
  var distanceMin = 0.0.obs;
  var distanceMax = 0.0.obs;

  void _calculateDistance(double rssi, int freq) {
    final result = distanceEstimator.estimateDistance(rssi, freq, calibration: _calibrationData);
    estimatedDistance.value = result.distance;
    distanceMin.value = result.minDistance;
    distanceMax.value = result.maxDistance;
  }

  Future<void> _fetchAndProcess() async {
    final wifiInfo = await rssiReader.getWifiInfo();
    if (wifiInfo.isEmpty) return;

    final String ssid = wifiInfo['ssid'] ?? '';
    final int raw = wifiInfo['rssi'] ?? -100;
    final int freq = wifiInfo['frequency'] ?? 0;

    if (ssid.isEmpty) {
      isConnectedToWifi.value = false;
      stopScanning();
      guidanceMessage.value = 'غير متصل بالشبكة';
      return;
    }
    
    isConnectedToWifi.value = true;
    connectedSSID.value = _cleanSsid(ssid);
    wifiFrequency.value = freq;
    
    currentRssi.value = raw;
    final is5G = freq >= 5000;
    
    final smoothed = smoother.smooth(raw, is5GHz: is5G);
    smoothedRssi.value = smoothed;

    _calculateDistance(smoothed, freq);

    final newLevel = classifier.classify(smoothed, calibration: _calibrationData);
    if (newLevel != proximityLevel.value) {
      _onProximityChanged(newLevel);
      proximityLevel.value = newLevel;
    }

    proximityPercentage.value = classifier.calculatePercentage(smoothed, calibration: _calibrationData);
    
    _updateHistory(raw, smoothed);
    _updateGuidanceMessage();
  }

  void _onProximityChanged(ProximityLevel newLevel) {
    if (isGeigerMode.value) {
      hapticService.updateLevel(newLevel, rhythmCalculator);
      audioService.updateLevel(newLevel, rhythmCalculator);
    }
    
    // Found Celebration!
    if (newLevel == ProximityLevel.burning && 
        proximityLevel.value != ProximityLevel.burning) {
      hapticService.playFoundCelebration();
    }
  }

  void _updateHistory(int raw, double smoothed) {
    _history.add(RssiReading(rawDbm: raw, smoothedDbm: smoothed));
    if (_history.length > 25) {
      _history.removeAt(0);
    }
  }

  void _updateGuidanceMessage() {
    if (proximityLevel.value == ProximityLevel.burning) {
      guidanceMessage.value = 'المودم قريب منك! أنت تقف بالقرب منه!';
      return;
    }
    
    final trend = trendAnalyzer.analyze(_history);
    
    switch (trend) {
      case SignalTrend.improving:
        guidanceMessage.value = 'الإشارة تقوى! استمر في هذا الاتجاه';
        break;
      case SignalTrend.worsening:
        guidanceMessage.value = 'الاتجاه خاطئ... الإشارة تضعف';
        break;
      case SignalTrend.stable:
      case SignalTrend.unknown:
        guidanceMessage.value = _getDefaultMessage(proximityLevel.value);
        break;
    }
  }

  String _getDefaultMessage(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing: return 'المودم بعيد جداً... جرب غرفة أخرى';
      case ProximityLevel.cold: return 'الإشارة ضعيفة... تحرك ببطء وراقب التغيير';
      case ProximityLevel.warm: return 'منطقة متوسطة... ابحث في الأنحاء';
      case ProximityLevel.hot: return 'أنت قريب جداً... ابحث تحت الوسائد!';
      case ProximityLevel.burning: return 'المودم هنا!';
    }
  }

  void toggleGeigerMode() {
    isGeigerMode.value = !isGeigerMode.value;
    if (!isGeigerMode.value) {
      hapticService.stop();
      audioService.stop();
    } else if (isScanning.value) {
      hapticService.startTicking(proximityLevel.value, rhythmCalculator);
      audioService.startTicking(proximityLevel.value, rhythmCalculator);
    }
  }
  
  void toggleSound() {
    isSoundEnabled.value = !isSoundEnabled.value;
    audioService.toggleMute(!isSoundEnabled.value);
  }

  @override
  void onClose() {
    stopScanning();
    super.onClose();
  }
}
