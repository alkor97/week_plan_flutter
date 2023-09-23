import 'package:week_plan_flutter/time.dart';
import 'package:test/test.dart';

void main() {
  test('test DayTime', () {
    expect(const DayTime(23, 53), const DayTime(23, 53));
    expect(const DayTime(23, 51) < const DayTime(23, 52), true);
    expect(const DayTime(23, 51) <= const DayTime(23, 52), true);
    expect(const DayTime(23, 51) <= const DayTime(23, 51), true);
    expect(const DayTime(23, 52) > const DayTime(23, 51), true);
    expect(const DayTime(23, 52) >= const DayTime(23, 51), true);
    expect(const DayTime(23, 51) >= const DayTime(23, 51), true);

    expect(const DayTime(23, 53).hashCode, const DayTime(23, 53).hashCode);
    expect(
        const DayTime(23, 53).hashCode, isNot(const DayTime(23, 54).hashCode));

    expect(const DayTime(09, 01).toString(), "09:01");
    expect(const DayTime(23, 59).toString(), "23:59");

    final now = DateTime.now();
    expect(const DayTime(23, 60).toDateTimeAt(now),
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1)));
  });

  test('test WeekDay', () {
    expect(WeekDay.wednesday, WeekDay.wednesday);
    expect(WeekDay.tuesday < WeekDay.friday, true);
    expect(WeekDay.tuesday <= WeekDay.friday, true);
    expect(WeekDay.tuesday <= WeekDay.tuesday, true);
    expect(WeekDay.saturday > WeekDay.thursday, true);
    expect(WeekDay.saturday >= WeekDay.thursday, true);
    expect(WeekDay.saturday >= WeekDay.saturday, true);

    expect(WeekDay.tuesday.hashCode, WeekDay.tuesday.hashCode);
    expect(WeekDay.tuesday, isNot(WeekDay.thursday.hashCode));

    expect(WeekDay.of(DateTime(2023, 9, 1, 13)), WeekDay.friday);
  });
}
