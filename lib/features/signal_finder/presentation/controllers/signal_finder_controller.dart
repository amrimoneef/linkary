import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../domain/entities/signal_point.dart';
import '../../domain/entities/signal_rank.dart';
import '../../domain/entities/signal_trend.dart';
import '../../domain/services/signal_score_calculator.dart';
import '../../infrastructure/services/haptic_feedback_service.dart';
import '../../../dashboard/domain/usecases/get_engineering_info_usecase.dart';

class SignalFinderController extends GetxController {
  final GetEngineeringInfoUseCase getEngineeringInfoUseCase;
  final SignalScoreCalculator scoreCalculator;
  final HapticFeedbackService hapticService;

  SignalFinderController({
    required this.getEngineeringInfoUseCase,
    required this.scoreCalculator,
    required this.hapticService,
  });

  // Reactive State
  var compositeScore = 0.0.obs;
  var currentRank = SignalRank.deadZone.obs;
  var currentTrend = SignalTrend.stable.obs;
  var guidanceMessage = 'انطلق للبحث عن أفضل إشارة!'.obs;
  var bestScore = 0.0.obs;
  var bestScoreTimestamp = Rxn<DateTime>();
  var isScanning = false.obs;
  var sessionDuration = 0.obs;
  var historyPoints = <SignalPoint>[].obs;
  var isHapticsEnabled = true.obs;

  // Raw values for display
  var rawRsrp = ''.obs;
  var rawSinr = ''.obs;
  var rawRsrq = ''.obs;
  var normalizedRsrp = 0.0.obs;
  var normalizedSinr = 0.0.obs;
  var normalizedRsrq = 0.0.obs;

  Timer? _scanTimer;
  Timer? _durationTimer;
  
  // To avoid keeping too many points in memory (keep last 15 points = 30 seconds)
  static const int maxHistoryPoints = 15;

  @override
  void onClose() {
    stopScanning();
    hapticService.dispose();
    super.onClose();
  }

  void startScanning() {
    if (isScanning.value) return;
    
    isScanning.value = true;
    sessionDuration.value = 0;
    historyPoints.clear();
    bestScore.value = 0.0;
    bestScoreTimestamp.value = null;
    compositeScore.value = 0.0;
    
    // Duration timer (every second)
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      sessionDuration.value++;
    });

    // Scan timer (every 2 seconds)
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchAndProcessSignal();
    });
    
    // Fetch immediately
    _fetchAndProcessSignal();
  }

  void stopScanning() {
    isScanning.value = false;
    _scanTimer?.cancel();
    _scanTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    
    if (isHapticsEnabled.value) {
      hapticService.stopPulsing();
    }
  }

  void toggleHaptics() {
    isHapticsEnabled.value = !isHapticsEnabled.value;
    if (!isHapticsEnabled.value) {
      hapticService.stopPulsing();
    } else if (isScanning.value) {
      hapticService.startPulsing(compositeScore.value);
    }
  }

  Future<void> _fetchAndProcessSignal() async {
    try {
      final engInfo = await getEngineeringInfoUseCase.execute();
      
      rawRsrp.value = engInfo.rsrp;
      rawSinr.value = engInfo.sinr;
      rawRsrq.value = engInfo.rsrq;

      final parsedRsrp = scoreCalculator.parseValue(engInfo.rsrp);
      final parsedSinr = scoreCalculator.parseValue(engInfo.sinr);
      final parsedRsrq = scoreCalculator.parseValue(engInfo.rsrq);

      normalizedRsrp.value = scoreCalculator.normalizeRSRP(parsedRsrp);
      normalizedSinr.value = scoreCalculator.normalizeSINR(parsedSinr);
      normalizedRsrq.value = scoreCalculator.normalizeRSRQ(parsedRsrq);

      final score = scoreCalculator.calculateComposite(parsedRsrp, parsedSinr, parsedRsrq);
      
      // Store in a temporary list to calculate smoothing
      List<double> recentScores = historyPoints.map((e) => e.compositeScore).toList();
      recentScores.add(score);
      
      final smoothedScore = scoreCalculator.smoothScore(recentScores);
      final newRank = scoreCalculator.classifyRank(smoothedScore);

      // Check for legendary celebration
      if (newRank == SignalRank.legendary && currentRank.value != SignalRank.legendary) {
        if (isHapticsEnabled.value) {
          hapticService.playFoundSpotCelebration();
        }
      }

      compositeScore.value = smoothedScore;
      currentRank.value = newRank;

      final newPoint = SignalPoint(
        compositeScore: smoothedScore,
        rsrp: parsedRsrp,
        sinr: parsedSinr,
        rsrq: parsedRsrq,
        timestamp: DateTime.now(),
      );

      historyPoints.add(newPoint);
      if (historyPoints.length > maxHistoryPoints) {
        historyPoints.removeAt(0);
      }

      currentTrend.value = scoreCalculator.calculateTrend(historyPoints);

      _updateHaptics();
      _checkBestScore(smoothedScore);
      _updateGuidance(parsedRsrp, parsedSinr, parsedRsrq);

    } catch (e) {
      // Ignored for now to avoid disrupting the UI, could log or show a small error indicator
      if (kDebugMode) print('Signal Finder fetch error: $e');
    }
  }

  void _updateHaptics() {
    if (!isHapticsEnabled.value) return;
    
    // Instead of start/stop, we just update the score because the service uses an internal timer that constantly runs based on the score
    hapticService.startPulsing(compositeScore.value);
  }

  bool _isNewBestScore = false;

  void _checkBestScore(double score) {
    if (score > bestScore.value && score > 0) {
      bestScore.value = score;
      bestScoreTimestamp.value = DateTime.now();
      _isNewBestScore = true;
      if (isHapticsEnabled.value && score > 50) { // Don't celebrate if the best score is still in the dead zone
        hapticService.playNewRecordPulse();
      }
    } else {
      _isNewBestScore = false;
    }
  }

  void _updateGuidance(double rsrp, double sinr, double rsrq) {
    guidanceMessage.value = scoreCalculator.generateGuidance(
      currentRank.value,
      currentTrend.value,
      rsrp,
      sinr,
      rsrq,
      isBestScore: _isNewBestScore && currentRank.value == SignalRank.legendary,
    );
  }
}
