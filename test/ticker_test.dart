import 'package:week_plan_flutter/ticker.dart';
import 'package:week_plan_flutter/time.dart';

import 'package:test/test.dart';

void main() {
  test('test fixed ticker', () {
    final ticker = Tickers.fixed(const Duration(hours: 1));
    expect(ticker.nextTickAt(DateTime(2023, 9, 23, 13)),
        DateTime(2023, 9, 23, 14));
  });

  test('test day times ticker', () {
    final dayTimes = {
      WeekDay.monday: [const DayTime(12, 00), const DayTime(14, 00)],
    };

    final ticker = Tickers.byDayTimes(dayTimes);

    final saturday14 = DateTime(2023, 9, 23, 14);
    final monday00 = DateTime(2023, 9, 25);
    expect(ticker.nextTickAt(saturday14), monday00);

    final monday10 = DateTime(2023, 9, 25, 10);
    final monday12 = DateTime(2023, 9, 25, 12);
    expect(ticker.nextTickAt(monday10), monday12);

    final monday13 = DateTime(2023, 9, 25, 13);
    final monday14 = DateTime(2023, 9, 25, 14);
    expect(ticker.nextTickAt(monday13), monday14);
  });
}
