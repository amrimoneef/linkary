import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/parental_control/domain/entities/parental_control_entity.dart';

void main() {
  group('ParentalControl TimeSlot Tests', () {
    test('Should correctly decode single day from repeatMode bitmask', () {
      // Wednesday is bit 3 (1 << 3 = 8)
      final slotWed = TimeSlot(index: 0, startTime: 0, endTime: 1439, repeatMode: 8);
      expect(slotWed.activeDays, 'الأربعاء');

      // Thursday is bit 4 (1 << 4 = 16)
      final slotThu = TimeSlot(index: 0, startTime: 0, endTime: 1439, repeatMode: 16);
      expect(slotThu.activeDays, 'الخميس');

      // Saturday is bit 6 (1 << 6 = 64)
      final slotSat = TimeSlot(index: 0, startTime: 0, endTime: 1439, repeatMode: 64);
      expect(slotSat.activeDays, 'السبت');

      // Sunday is bit 0 (1 << 0 = 1)
      final slotSun = TimeSlot(index: 0, startTime: 0, endTime: 1439, repeatMode: 1);
      expect(slotSun.activeDays, 'الأحد');
    });

    test('Should correctly decode multiple days in natural Arabic week order', () {
      // Wednesday (bit 3 = 8) and Thursday (bit 4 = 16) -> 24
      final slot = TimeSlot(index: 0, startTime: 0, endTime: 1439, repeatMode: 24);
      expect(slot.activeDays, 'الأربعاء، الخميس');

      // Saturday (bit 6 = 64) and Sunday (bit 0 = 1) -> 65
      final weekendSlot = TimeSlot(index: 0, startTime: 0, endTime: 1439, repeatMode: 65);
      expect(weekendSlot.activeDays, 'السبت، الأحد');
    });

    test('Should return special labels for all days and workdays', () {
      final allDaysSlot = TimeSlot(index: 0, startTime: 0, endTime: 1439, repeatMode: 127);
      expect(allDaysSlot.activeDays, 'طوال أيام الأسبوع');

      final workDaysSlot = TimeSlot(index: 0, startTime: 0, endTime: 1439, repeatMode: 62);
      expect(workDaysSlot.activeDays, 'أيام العمل (الإثنين - الجمعة)');
    });
  });
}
