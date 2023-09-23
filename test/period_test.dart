import 'package:week_plan_flutter/period.dart';
import 'package:week_plan_flutter/time.dart';

import 'package:test/test.dart';

void main() {
  test('test time slot', () {
    const slot = TimeSlot(DayTime(08, 00), DayTime(08, 45));
    final now = DateTime.now();
    DateTime today(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);
    expect(slot.isActiveAt(today(07, 00)), false);
    expect(slot.isActiveAt(today(08, 30)), true);
    expect(slot.isActiveAt(today(09, 00)), false);
  });

  test('test time slot extending', () {
    const slot = TimeSlot(DayTime(12, 00), DayTime(13, 00));
    final extended = deduceRecessSlots([slot]);

    expect(extended.length, 3);
    expect(extended.elementAt(1), slot);

    expect(extended.first.from, const DayTime(00, 00));
    expect(extended.first.until, slot.from);

    expect(extended.last.from, slot.until);
    expect(extended.last.until, const DayTime(23, 60));
  });
}
