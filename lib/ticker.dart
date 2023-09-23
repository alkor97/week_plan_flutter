import 'package:week_plan_flutter/model.dart';
import 'package:week_plan_flutter/time.dart';
import 'dart:async';

abstract class AbstractTicker {
  final void Function() _callback;
  late Timer _timer;

  AbstractTicker(void Function() callback) : _callback = callback {
    _timer = _createTimer(this);
  }

  void _onTick() {
    _callback();
    _timer.cancel();
    _timer = _createTimer(this);
  }

  Timer _createTimer(AbstractTicker ticker) {
    return Timer(nextTick(), () => ticker._onTick());
  }

  void cancel() => _timer.cancel();

  DateTime nextTickAt(DateTime now);

  Duration nextTick() {
    final now = DateTime.now();
    return nextTickAt(now).difference(now);
  }
}

class PeriodicTicker extends AbstractTicker {
  final Duration _period;

  PeriodicTicker(void Function() callback,
      {Duration period = const Duration(minutes: 1)})
      : _period = period,
        super(callback);

  @override
  DateTime nextTickAt(DateTime now) => now.clampToMinutes().add(_period);
}

class DayTimesTicker extends AbstractTicker {
  final Set<DayTime> _dayTimes;

  DayTimesTicker(void Function() callback, Iterable<DayTime> dayTimes)
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
