import 'package:week_plan_flutter/model.dart';
import 'package:week_plan_flutter/time.dart';
import 'package:week_plan_flutter/period_data.dart';

import 'package:test/test.dart';
import 'dart:io';

void main() {
  test('week day parsing', () {
    expect(() => parseWeekDay('abc'), throwsFormatException);
    expect(parseWeekDay("tuesday"), WeekDay.tuesday);
    expect(parseWeekDay("TUESDAY"), WeekDay.tuesday);
    expect(parseWeekDay("Tuesday"), WeekDay.tuesday);
    expect(parseWeekDay("Tue"), WeekDay.tuesday);
  });
  test('day time parsing', () {
    expect(() => parseDayTime("abc"), throwsFormatException);
    expect(() => parseDayTime("a:b"), throwsFormatException);
    expect(() => parseDayTime("a:b:c"), throwsFormatException);
    expect(() => parseDayTime("a:"), throwsFormatException);
    expect(() => parseDayTime(":b"), throwsFormatException);
    expect(() => parseDayTime("-1:0"), throwsFormatException);
    expect(() => parseDayTime("0:-2"), throwsFormatException);
    expect(() => parseDayTime("24:0"), throwsFormatException);
    expect(() => parseDayTime("0:60"), throwsFormatException);
    expect(parseDayTime("23:59"), const DayTime(23, 59));
  });
  test('plan parsing', () async {
    final text = await File('data/plan.txt').readAsString();
    final weekPlan =
        PlanProviders.parsing(text).getPlanData(on: getTimeSlots());
    expect(weekPlan.keys.toSet(), WeekDay.values.take(5).toSet());
    expect(weekPlan[WeekDay.wednesday]![4], SlotContent('Hist', '120'));
  });
}
