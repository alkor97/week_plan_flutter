import 'package:week_plan_flutter/time.dart';

class TimeSlot {
  final DayTime from;
  final DayTime until;

  const TimeSlot(this.from, this.until);

  bool isActiveAt(DateTime now) =>
      from.toDateTimeAt(now).isBefore(now) &&
      now.isBefore(until.toDateTimeAt(now));

  @override
  bool operator ==(Object other) =>
      other is TimeSlot && from == other.from && until == other.until;

  @override
  int get hashCode => Object.hash(from, until);

  @override
  String toString() => "$from - $until";
}

class RecessSlot extends TimeSlot {
  RecessSlot(super.from, super.until);
}

Iterable<TimeSlot> deduceRecessSlots(Iterable<TimeSlot> timeSlots) {
  assert(timeSlots.isNotEmpty);
  List<TimeSlot> result = [];
  var lastUntil = const DayTime(00, 00);
  for (final timeSlot in timeSlots) {
    result
      ..add(RecessSlot(lastUntil, timeSlot.from))
      ..add(timeSlot);
    lastUntil = timeSlot.until;
  }
  return result..add(RecessSlot(lastUntil, const DayTime(23, 60)));
}
