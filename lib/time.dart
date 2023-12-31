class DayTime implements Comparable<DayTime> {
  const DayTime(this.hour, this.minute);
  DayTime.fromTuple((int, int) tuple)
      : hour = tuple.$1,
        minute = tuple.$2;

  factory DayTime.of(DateTime dateTime) =>
      DayTime(dateTime.hour, dateTime.minute);

  final int hour;
  final int minute;

  @override
  int compareTo(DayTime other) => inMinutes - other.inMinutes;

  int get inMinutes => (hour % 24) * 60 + (minute % 60);

  @override
  bool operator ==(Object other) =>
      other is DayTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() {
    final String hourLabel = hour < 10 ? "0$hour" : hour.toString();
    final String minuteLabel = minute < 10 ? "0$minute" : minute.toString();
    return '$hourLabel:$minuteLabel';
  }

  DateTime toDateTimeAt(DateTime now) =>
      DateTime(now.year, now.month, now.day, hour, minute);
}

enum WeekDay implements Comparable<WeekDay> {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  @override
  int compareTo(WeekDay other) => index - other.index;

  factory WeekDay.of(DateTime dateTime) => WeekDay.values[dateTime.weekday - 1];
}

String formatDayTime(DayTime dayTime) => dayTime.toString();

extension DateTimeExtensions on DateTime {
  DateTime previousMidnight() => DateTime(year, month, day);
  DateTime nextMidnight() => previousMidnight().add(const Duration(days: 1));
  DateTime clampToMinutes() => DateTime(year, month, day, hour, minute);
}

extension CompareOperators<T> on Comparable<T> {
  bool operator <=(T other) => compareTo(other) <= 0;
  bool operator >=(T other) => compareTo(other) >= 0;
  bool operator <(T other) => compareTo(other) < 0;
  bool operator >(T other) => compareTo(other) > 0;
}
