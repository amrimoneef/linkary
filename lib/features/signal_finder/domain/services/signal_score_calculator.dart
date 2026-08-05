import '../entities/signal_point.dart';
import '../entities/signal_rank.dart';
import '../entities/signal_trend.dart';

class SignalScoreCalculator {
  /// استخراج الرقم من القيمة الخام
  double parseValue(String raw) {
    if (raw.isEmpty || raw == 'N/A') return 0.0;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-\+]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// تطبيع RSRP (قوة الإشارة)
  /// x_max: -80 dBm, x_min: -120 dBm
  double normalizeRSRP(double rsrp) {
    if (rsrp == 0.0) return 0.0;
    const double min = -120.0;
    const double max = -80.0;
    return ((rsrp - min) / (max - min) * 100).clamp(0.0, 100.0);
  }

  /// تطبيع SINR (نقاء الإشارة)
  /// x_max: 25 dB, x_min: 0 dB
  double normalizeSINR(double sinr) {
    if (sinr == 0.0) return 0.0;
    const double min = 0.0;
    const double max = 25.0;
    return ((sinr - min) / (max - min) * 100).clamp(0.0, 100.0);
  }

  /// تطبيع RSRQ (جودة الإشارة المرجعية)
  /// x_max: -6 dB, x_min: -20 dB
  double normalizeRSRQ(double rsrq) {
    if (rsrq == 0.0) return 0.0;
    const double min = -20.0;
    const double max = -6.0;
    return ((rsrq - min) / (max - min) * 100).clamp(0.0, 100.0);
  }

  /// حساب النسبة المركبة
  double calculateComposite(double rsrp, double sinr, double rsrq) {
    if (rsrp == 0.0 && sinr == 0.0 && rsrq == 0.0) return 0.0;
    final pRsrp = normalizeRSRP(rsrp);
    final pSinr = normalizeSINR(sinr);
    final pRsrq = normalizeRSRQ(rsrq);

    // Weights: RSRP 30%, SINR 50%, RSRQ 20%
    return (pRsrp * 0.30) + (pSinr * 0.50) + (pRsrq * 0.20);
  }

  /// تصنيف المنطقة بناءً على النسبة
  SignalRank classifyRank(double score) {
    if (score == 0.0) return SignalRank.deadZone;
    if (score <= 25.0) return SignalRank.deadZone;
    if (score <= 50.0) return SignalRank.critical;
    if (score <= 79.0) return SignalRank.stable;
    return SignalRank.legendary;
  }

  /// حساب اتجاه الإشارة (التريند)
  SignalTrend calculateTrend(List<SignalPoint> lastPoints) {
    if (lastPoints.length < 3) return SignalTrend.stable;

    final recent = lastPoints.sublist(lastPoints.length - 3);
    final avg1 = recent[0].compositeScore;
    final avg2 = recent[2].compositeScore;
    final diff = avg2 - avg1;

    // Threshold = 5% لتجنب التذبذبات الطبيعية
    if (diff > 5.0) return SignalTrend.improving;
    if (diff < -5.0) return SignalTrend.declining;
    return SignalTrend.stable;
  }

  /// تنعيم القراءات لتجنب القفزات
  double smoothScore(List<double> recentScores) {
    if (recentScores.isEmpty) return 0.0;
    if (recentScores.length >= 3) {
      return recentScores[recentScores.length - 3] * 0.2 +
          recentScores[recentScores.length - 2] * 0.3 +
          recentScores.last * 0.5;
    }
    return recentScores.last;
  }

  /// توليد نصيحة ذكية بناءً على الحالة والاتجاه
  String generateGuidance(SignalRank rank, SignalTrend trend, double rsrp, double sinr, double rsrq, {bool isBestScore = false}) {
    if (isBestScore) return "مبروك! هذه أقوى نقطة اكتشفتها في هذه الجلسة.";

    // تحليل المؤشر الأضعف
    String weakPointGuidance = "";
    final pRsrp = normalizeRSRP(rsrp);
    final pSinr = normalizeSINR(sinr);
    final pRsrq = normalizeRSRQ(rsrq);
    
    if (rank != SignalRank.legendary) {
      if (pSinr < 40 && pRsrp > 50) {
        weakPointGuidance = "\n(تشويش عالي، ابتعد عن الأجهزة الإلكترونية)";
      } else if (pRsrq < 40 && pRsrp > 50) {
        weakPointGuidance = "\n(تداخل أبراج، جرب جهة أخرى من المبنى)";
      } else if (pRsrp < 40) {
         weakPointGuidance = "\n(إشارة ضعيفة، اقترب من نافذة أو مكان مرتفع)";
      }
    }

    String mainGuidance = "";
    switch (rank) {
      case SignalRank.deadZone:
        if (trend == SignalTrend.declining) {
          mainGuidance = "💀 ابتعد فوراً! هذه منطقة ميتة تماماً";
        } else {
          mainGuidance = "هذا المكان سيء جداً، حاول تغيير المكان، جرب اي اتجاه مختلف للحصول على اشارة جيدة";
        }
        break;
      case SignalRank.critical:
        if (trend == SignalTrend.declining) {
          mainGuidance = "⚠️ الإشارة تضعف... ارجع خطوة للوراء!";
        } else if (trend == SignalTrend.improving) {
          mainGuidance = "الإشارة تتحسن! استمر في هذا الاتجاه";
        } else {
          mainGuidance = "تغطية ضعيفة، جرب مكان آخر، اذا كنت في المنزل جرب الاقتراب من نافذة";
        }
        break;
      case SignalRank.stable:
        if (trend == SignalTrend.declining) {
          mainGuidance = "كانت النقطة السابقة أفضل... ارجع قليلاً";
        } else if (trend == SignalTrend.improving) {
          mainGuidance = "ممتاز! أنت تقترب من النقطة الذهبية!";
        } else {
          mainGuidance = "مكان جيد ومستقر! قم بتثبيت الجهاز في هذا المكان";
        }
        break;
      case SignalRank.legendary:
        mainGuidance = "أنت في النقطة الأسطورية! ثبّت المودم هنا فوراً!";
        break;
    }

    return mainGuidance + weakPointGuidance;
  }
}
