class TimeSlot {
  final int index;
  final int startTime; // بالدقائق
  final int endTime; // بالدقائق
  final int repeatMode; // Bitmask (0-127)

  TimeSlot({required this.index, required this.startTime, required this.endTime, required this.repeatMode});

  // 🚀 دالة ذكية لتحويل الدقائق إلى نص مفهوم (مثال: 02:30 م)
  String get formattedTimeRange {
    String formatMinutes(int totalMins) {
      int h = totalMins ~/ 60;
      int m = totalMins % 60;
      String period = h >= 12 ? 'م' : 'ص';
      if (h == 0) h = 12;
      if (h > 12) h -= 12;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    }
    return '${formatMinutes(startTime)} - ${formatMinutes(endTime)}';
  }

  // 🚀 دالة لفك تشفير الأيام من الـ Bitmask
  String get activeDays {
    if (repeatMode == 127 || repeatMode == 0) return 'طوال أيام الأسبوع';
    if (repeatMode == 62) return 'أيام العمل (الإثنين - الجمعة)';

    const dayMap = {
      6: 'السبت',
      0: 'الأحد',
      1: 'الاثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
    };

    // الترتيب الطبيعي للأسبوع بالعربية: السبت أولاً
    const arabicWeekOrder = [6, 0, 1, 2, 3, 4, 5];
    final active = arabicWeekOrder
        .where((bit) => (repeatMode & (1 << bit)) != 0)
        .map((bit) => dayMap[bit]!)
        .toList();

    if (active.isEmpty) return 'طوال أيام الأسبوع';
    return active.join('، ');
  }
}

class ParentalDevice {
  final String mac;
  final String name;
  final List<TimeSlot> timeSlots;

  ParentalDevice({required this.mac, required this.name, required this.timeSlots});
}