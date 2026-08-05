import 'package:flutter/material.dart';

class EngineeringInfoEntity {
  final String band;
  final String rsrp;
  final String rsrq;
  final String sinr;
  final String pci;
  final String bandwidth;

  EngineeringInfoEntity({
    required this.band,
    required this.rsrp,
    required this.rsrq,
    required this.sinr,
    required this.pci,
    required this.bandwidth,
  });

  // 📊 الحصول على التقييمات الفردية
  SignalStatus get rsrpStatus => _evalRSRP(rsrp);
  SignalStatus get rsrqStatus => _evalRSRQ(rsrq);
  SignalStatus get sinrStatus => _evalSINR(sinr);

  // ==========================================
  // 🧠 محرك الذكاء الاصطناعي للتحليل الشامل (مخصص للـ MiFi)
  // ==========================================
  SmartDiagnosis getSmartDiagnosis() {
    final rsrpVal = double.tryParse(rsrp.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
    final rsrqVal = double.tryParse(rsrq.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
    final sinrVal = double.tryParse(sinr.replaceAll(RegExp(r'[^0-9.\-\+]'), '')) ?? 0;

    // 🚨 1. الحالة المركبة الخطيرة: (SINR ضعيف + RSRP ضعيف)
    if ((sinrVal < 7 && sinrVal != 0) && (rsrpVal < -100 && rsrpVal != 0)) {
      return SmartDiagnosis(
        overallQuality: 'سيئة جداً (حرارة واستهلاك طاقة)',
        color: Colors.red,
        issue: 'المودم يعاني من ضعف شديد في الإشارة وتشويش عالي في نفس الوقت! هذا يجعله يستهلك طاقة قصوى للبحث عن شبكة، مما يسبب ارتفاع حرارته ونفاذ البطارية بسرعة.',
        causes: ['عوازل قوية جداً (قبو أو مبنى داخلي)', 'تشويش عالي مع مسافة بعيدة عن البرج'],
        solutions: [
          'أطفئ المودم قليلاً ليبرد، ثم ضعه في مكان مرتفع ومفتوح بجوار نافذة.',
          'تجنب استخدام المودم وهو داخل الحقيبة في هذه المنطقة لحمايته من الحرارة.'
        ],
      );
    }

    // 2. حالة التشويش والازدحام الشديد (SINR منخفض جداً)
    if (sinrVal < 5 && sinrVal != 0) {
      return SmartDiagnosis(
        overallQuality: 'سيئة (ازدحام/تشويش)',
        color: Colors.redAccent,
        issue: 'البرج الذي تتصل به مزدحم جداً أو يوجد تشويش عالي، مما يسبب بطئاً شديداً في الإنترنت.',
        causes: ['ازدحام المستخدمين على نفس البرج', 'وجود المودم بالقرب من أجهزة إلكترونية تصدر تشويشاً كهرومغناطيسياً'],
        solutions: [
          'غيّر مكانك قليلاً للاتصال ببرج آخر',
          'إذا كنت ثابتاً في مكانك، جرب تغيير التردد (Band) يدوياً إلى نطاق أقل ازدحاماً',
          'ملاحظة: لا تقم بتثبيت التردد إذا كنت تتنقل كثيراً لتجنب فقدان التغطية' // [cite: 33]
        ],
      );
    }

    // 3. حالة التداخل بين الأبراج (RSRQ منخفض)
    if (rsrqVal < -14 && rsrqVal != 0) {
      return SmartDiagnosis(
        overallQuality: 'ضعيفة (تداخل إشارات)',
        color: Colors.orangeAccent,
        issue: 'يوجد تداخل في الإشارات، المودم يلتقط إشارتين من برجين مختلفين مما يسبب تقطعاً متكرراً في الاتصال.',
        causes: ['التواجد في منطقة تقع بين برجي تغطية', 'خلل في توجيه المودم بسبب العوازل'],
        solutions: [
          'انتقل إلى جهة أخرى من المبنى أو الغرفة',
          'ضع المودم بالقرب من نافذة لتقوية إشارة برج واحد على حساب الآخر'
        ],
      );
    }

    // 4. حالة ضعف التغطية العام (RSRP منخفض)
    if (rsrpVal < -100 && rsrpVal != 0) {
      return SmartDiagnosis(
        overallQuality: 'ضعيفة (تغطية سيئة)',
        color: Colors.deepOrange,
        issue: 'الإشارة ضعيفة جداً! الجهاز يستهلك البطارية بشكل أعلى من الطبيعي لتعويض ضعف الإشارة مما يسبب شحن بطيء.',
        causes: ['وضع المودم داخل حقيبة أو جيب عميق أثناء التنقل', 'التواجد في قبو أو مكان معزول بجدران سميكة'],
        solutions: [
          'أخرج المودم وضعه في مكان مفتوح أو مرتفع',
          'ضعه بالقرب من نافذة لتخفيف الجهد عن البطارية'
        ],
      );
    }

    // 5. حالة الإشارة المتوسطة / الجيدة
    if (rsrpVal >= -100 && rsrpVal <= -81 && rsrpVal != 0) {
      return SmartDiagnosis(
        overallQuality: 'جيدة إلى متوسطة',
        color: Colors.blueAccent,
        issue: 'الشبكة مستقرة وتعمل بشكل جيد، لكن يمكن تحسين جودة النقل.',
        causes: ['وجود عوازل بسيطة (جدران) أو مسافة متوسطة عن البرج'],
        solutions: [
          'للحصول على سرعة أعلى، ضع المودم في مساحة مفتوحة وتجنب تغطيته',
          'إذا كنت بالخارج، تأكد أن المودم ليس مكتوماً داخل حقيبة ممتلئة'
        ],
      );
    }

    // 6. الحالة المثالية
    if (rsrpVal > -81 || rsrqVal >= -9 || sinrVal >= 15) {
      return SmartDiagnosis(
        overallQuality: 'ممتازة 🚀',
        color: Colors.greenAccent,
        issue: 'اتصالك مستقر، سريع، ومثالي! لا توجد أي مشاكل.',
        causes: ['موقع المودم ممتاز وتغطيته قوية', 'لا يوجد ازدحام مؤثر على البرج الحالي'],
        solutions: [
          'استمتع بالسرعة الخارقة! حافظ على المودم في مكانه الحالي إذا كنت تحمل ملفات كبيرة.'
        ],
      );
    }

    // 7. حالة عدم توفر بيانات
    return SmartDiagnosis(
      overallQuality: 'جاري التحليل...',
      color: Colors.grey,
      issue: 'البيانات غير كافية حالياً لإعطاء تقرير دقيق.',
      causes: ['المودم قيد الاتصال بالشبكة', 'البيانات قيد التحديث من البرج'],
      solutions: ['يرجى الانتظار بضع ثوانٍ ثم تحديث الشاشة.'],
    );
  }
  // ==========================================
  // 📏 التقييمات بـ 4 مستويات
  // ==========================================
  static SignalStatus _evalRSRP(String val) {
    final v = double.tryParse(val.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
    if (v == 0) return SignalStatus('N/A', Colors.grey, 0.0);
    if (v >= -80) return SignalStatus('ممتازة', Colors.greenAccent, 1.0);
    if (v >= -90) return SignalStatus('جيدة', Colors.lightBlueAccent, 0.75);
    if (v >= -100) return SignalStatus('متوسطة', Colors.orangeAccent, 0.5);
    return SignalStatus('ضعيفة', Colors.redAccent, 0.25);
  }

  static SignalStatus _evalRSRQ(String val) {
    final v = double.tryParse(val.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
    if (v == 0) return SignalStatus('N/A', Colors.grey, 0.0);
    if (v >= -9) return SignalStatus('ممتازة', Colors.greenAccent, 1.0);
    if (v >= -10) return SignalStatus('جيدة', Colors.lightBlueAccent, 0.75);
    if (v >= -14) return SignalStatus('متوسطة', Colors.orangeAccent, 0.5);
    return SignalStatus('ضعيفة', Colors.redAccent, 0.25);
  }

  static SignalStatus _evalSINR(String val) {
    final v = double.tryParse(val.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
    if (v == 0 && !val.contains('0')) return SignalStatus('N/A', Colors.grey, 0.0);
    if (v >= 15) return SignalStatus('ممتازة', Colors.greenAccent, 1.0);
    if (v >= 10) return SignalStatus('جيدة', Colors.lightBlueAccent, 0.75);
    if (v >= 7) return SignalStatus('متوسطة', Colors.orangeAccent, 0.5);
    return SignalStatus('تشويش', Colors.redAccent, 0.25);
  }
}

// كلاسات مساعدة
class SignalStatus {
  final String label;
  final Color color;
  final double progress;
  SignalStatus(this.label, this.color, this.progress);
}

class SmartDiagnosis {
  final String overallQuality;
  final Color color;
  final String issue;
  final List<String> causes;
  final List<String> solutions;

  SmartDiagnosis({
    required this.overallQuality,
    required this.color,
    required this.issue,
    required this.causes,
    required this.solutions,
  });
}