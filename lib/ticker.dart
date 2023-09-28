import 'package:week_plan_flutter/time.dart';
import 'dart:async';

abstract class Ticker {
  DateTime nextTickAt(DateTime now);
}

class PeriodicRunner {
  final void Function() _callback;
  final Ticker _ticker;
  Timer? _timer;

  PeriodicRunner(this._callback, this._ticker) {
    _timer = _newTimer();
  }

  void cancel() => _timer?.cancel();

  void _onTick() {
    _callback();
    cancel();
    _timer = _newTimer();
  }

  Timer _newTimer() => Timer(_nextTick(DateTime.now()), _onTick);
  Duration _nextTick(DateTime now) => _ticker.nextTickAt(now).difference(now);
}

class Tickers {
  static Ticker fixed(Duration period) => _FixedTicker(period);
  static Ticker byDayTimes(Map<WeekDay, Iterable<DayTime>> dayTimes) =>
      _WeekPlanTicker(dayTimes);
}

// implementation

class _FixedTicker extends Ticker {
  final Duration _period;
  _FixedTicker(this._period);
  @override
  DateTime nextTickAt(DateTime now) => now.clampToMinutes().add(_period);
}

class _WeekPlanTicker extends Ticker {
  static const int minutesInDay = 24 * 60;
  final List<int> _timePoints = List.empty(growable: true);
  _WeekPlanTicker(Map<WeekDay, Iterable<DayTime>> timePoints) {
    timePoints.forEach((weekDay, dayTimes) {
      final base = weekDay.index * minutesInDay;
      _timePoints.add(base); // add midnights as well
      for (final dayTime in dayTimes) {
        _timePoints.add(base + dayTime.inMinutes);
      }
    });
    _timePoints.sort();
  }

  @override
  DateTime nextTickAt(DateTime now) {
    final epoch = _lastMondayMidnight(now);
    final minutes = now.difference(epoch).inMinutes;
    final nextTick = _timePoints.firstWhere((element) => element >= minutes,
        orElse: () => 7 * minutesInDay + _timePoints.first);
    return epoch.add(Duration(minutes: nextTick));
  }

  DateTime _lastMondayMidnight(DateTime now) =>
      now.previousMidnight().subtract(Duration(days: WeekDay.of(now).index));
}
