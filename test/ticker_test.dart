import 'dart:io';

import 'package:week_plan_flutter/ticker.dart';
import 'package:week_plan_flutter/time.dart';

import 'package:test/test.dart';

void main() {
  test('test periodic ticker', () {
    const period = Duration(seconds: 2);
    final earlier = DateTime.now();
    void callback() => expect(DateTime.now().difference(earlier), period);

    AbstractTicker? ticker;
    try {
      ticker = PeriodicTicker(callback, period: period);
      sleep(period);
    } finally {
      ticker?.cancel();
    }
  });

  test('test day times ticker', () {
    final now = DateTime.now();
    const diff = Duration(minutes: 1);
    final tick = now.clampToMinutes();

    AbstractTicker? ticker;
    try {
      ticker = DayTimesTicker(() {}, [DayTime.of(tick)]);
      expect(ticker.nextTickAt(tick.subtract(diff)), tick);
      expect(ticker.nextTickAt(tick), tick);
      expect(ticker.nextTickAt(tick.add(diff)), now.nextMidnight());
    } finally {
      ticker?.cancel();
    }
  });
}
