import 'package:week_plan_flutter/model.dart';
import 'package:week_plan_flutter/time.dart';
import 'dart:async';

abstract class Ticker {
  final void Function() _callback;
  late Timer _timer;

  Ticker(void Function() callback) : _callback = callback {
    _timer = _createTimer(this);
  }

  void _onTick() {
    _callback();
    _timer.cancel();
    _timer = _createTimer(this);
  }

  Timer _createTimer(Ticker ticker) {
    return Timer(nextTick(), () => ticker._onTick());
  }

  void cancel() => _timer.cancel();

  DateTime nextTickAt(DateTime now);

  Duration nextTick() {
    final now = DateTime.now();
    return nextTickAt(now).difference(now);
  }
}

class Tickers {
  static Ticker periodic(void Function() callback, Duration period) =>
      _PeriodicTicker(callback, period);
  static Ticker dayTimesBased(
          void Function() callback, Iterable<DayTime> dayTimes) =>
      _DayTimesTicker(callback, dayTimes);
}

// implementation

class _PeriodicTicker extends Ticker {
  final Duration _period;

  _PeriodicTicker(void Function() callback, Duration period)
      : _period = period,
        super(callback);

  @override
  DateTime nextTickAt(DateTime now) => now.clampToMinutes().add(_period);
}

class _DayTimesTicker extends Ticker {
  final Set<DayTime> _dayTimes;

  _DayTimesTicker(void Function() callback, Iterable<DayTime> dayTimes)
      : _dayTimes = dayTimes.toSet(),
        super(callback);

  @override
  DateTime nextTickAt(DateTime now) {
    final currentDayTime = DayTime.of(now);
    final nextTick =
        _dayTimes.firstWhereOrNull((dayTime) => dayTime >= currentDayTime);
    return nextTick != null ? nextTick.toDateTimeAt(now) : now.nextMidnight();
  }
}
