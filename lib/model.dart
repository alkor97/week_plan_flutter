import 'package:flutter/material.dart';
import 'package:week_plan_flutter/time.dart';
import 'package:week_plan_flutter/period.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:core';

typedef IntPair = (int, int);
typedef IntPairPair = (IntPair, IntPair);

const List<IntPairPair> _normalTimeSlots = [
  ((07, 10), (07, 55)),
  ((08, 00), (08, 45)),
  ((08, 50), (09, 35)),
  ((09, 45), (10, 30)),
  ((10, 40), (11, 25)),
  ((11, 35), (12, 20)),
  ((12, 40), (13, 25)),
  ((13, 45), (14, 30)),
  ((14, 40), (15, 25)),
  ((15, 35), (16, 20)),
  ((16, 25), (17, 10)),
  ((17, 15), (18, 00)),
];

const List<IntPairPair> _shortenedTimeSlots = [
  ((07, 25), (07, 55)),
  ((08, 00), (08, 30)),
  ((08, 35), (09, 05)),
  ((09, 10), (09, 40)),
  ((09, 50), (10, 20)),
  ((10, 30), (11, 00)),
  ((11, 20), (11, 50)),
  ((12, 10), (12, 40)),
  ((12, 50), (13, 20)),
  ((13, 25), (13, 55)),
  ((14, 00), (14, 30)),
  ((14, 35), (15, 05)),
];

Iterable<TimeSlot> parseTimeSlots(Iterable<IntPairPair> input) => input
    .map((e) => TimeSlot(DayTime.fromTuple(e.$1), DayTime.fromTuple(e.$2)))
    .toList(growable: false);

List<TimeSlot> getTimeSlots({bool shortened = false}) =>
    parseTimeSlots(shortened ? _shortenedTimeSlots : _normalTimeSlots)
        .toList(growable: false);

const _weekPlan = {
  WeekDay.monday: {
    1: ("Pol", "114"),
    2: ("Bio", "209"),
    3: ("Mat", "28"),
    4: ("Ang", "204"),
    5: ("WF", "Hala"),
  },
  WeekDay.tuesday: {
    2: ("Hist", "120"),
    3: ("Pol", "114"),
    4: ("GW", "209"),
    5: ("Mat", "28"),
    6: ("WF", "Hala"),
    7: ("Rel", "Mult"),
  },
  WeekDay.wednesday: {
    2: ("Pol", "114"),
    3: ("Ang", "207"),
    4: ("Hist", "120"),
    5: ("Mat", "28"),
  },
  WeekDay.thursday: {
    1: ("Geo", "209"),
    2: ("Pol", "114"),
    3: ("Inf", "204"),
    4: ("Mat", "28"),
    5: ("WF", "Hala"),
    6: ("Inn", "Mult"),
  },
  WeekDay.friday: {
    2: ("Tech", "101"),
    3: ("Plas", "101"),
    4: ("Pol", "114"),
    5: ("WF", "Hala"),
    6: ("Ang", "207"),
    7: ("Muz", "101"),
  },
};

/*const _weekPlanExt = {
  WeekDay.monday: {
    1: ("polski", "114"),
    2: ("biologia", "209"),
    3: ("matematyka", "28"),
    4: ("angielski", "204"),
    5: ("WF", "Hala"),
  },
  WeekDay.tuesday: {
    2: ("historia", "120"),
    3: ("polski", "114"),
    4: ("GW", "209"),
    5: ("matematyka", "28"),
    6: ("WF", "Hala"),
    7: ("religia", "Mult"),
  },
  WeekDay.wednesday: {
    2: ("polski", "114"),
    3: ("angielski", "207"),
    4: ("historia", "120"),
    5: ("matematyka", "28"),
  },
  WeekDay.thursday: {
    1: ("geografia", "209"),
    2: ("polski", "114"),
    3: ("informatyka", "204"),
    4: ("matematyka", "28"),
    5: ("WF", "Hala"),
    6: ("innowacja", "Mult"),
  },
  WeekDay.friday: {
    2: ("technika", "101"),
    3: ("plastyka", "101"),
    4: ("polski", "114"),
    5: ("WF", "Hala"),
    6: ("angielski", "207"),
    7: ("muzka", "101"),
  },
};*/

class _Key {
  final WeekDay weekDay;
  final TimeSlot timeSlot;

  const _Key(this.weekDay, this.timeSlot);
  @override
  bool operator ==(Object other) =>
      other is _Key && weekDay == other.weekDay && timeSlot == other.timeSlot;

  @override
  int get hashCode => Object.hash(weekDay, timeSlot);
}

typedef SlotContentType = (String, String);

class WeekPlan {
  final Iterable<WeekDay> weekDays;
  final Iterable<TimeSlot> timeSlots;
  final Map<_Key, SlotContentType> _data;

  const WeekPlan(this.weekDays, this.timeSlots, this._data);

  SlotContentType? get(WeekDay weekDay, TimeSlot timeSlot) =>
      _data[_Key(weekDay, timeSlot)];

  factory WeekPlan.create(
      List<TimeSlot> timeSlots, Map<WeekDay, Map<int, SlotContentType>> plan,
      {bool includeRecess = false}) {
    assert(timeSlots.isNotEmpty);

    WeekDay minimal(WeekDay a, WeekDay b) => a.index < b.index ? a : b;
    WeekDay maximal(WeekDay a, WeekDay b) => a.index > b.index ? a : b;

    int minIndex = timeSlots.length - 1;
    int maxIndex = 0;

    WeekDay minDay = WeekDay.sunday;
    WeekDay maxDay = WeekDay.monday;

    Map<_Key, SlotContentType> weekPlan = {};

    for (final weekDay in plan.keys) {
      // compute minimal and maximal day of week used in plan
      minDay = minimal(minDay, weekDay);
      maxDay = maximal(maxDay, weekDay);

      final day = plan[weekDay]!;

      for (final index in day.keys) {
        // compute minimal and maximal time slot index used in plan
        minIndex = min(minIndex, index);
        maxIndex = max(maxIndex, index);

        final value = day[index]!;
        weekPlan[_Key(weekDay, timeSlots[index])] = value;
      }
    }

    // remove unused periods
    final limitedPeriods = timeSlots.indexed
        .where((element) => minIndex <= element.$1 && element.$1 <= maxIndex)
        .map((e) => e.$2);

    return WeekPlan(
        // remove unused days
        WeekDay.values
            .where((element) => minDay <= element && element <= maxDay)
            .toList(growable: false),
        (includeRecess ? deduceRecessSlots(limitedPeriods) : limitedPeriods)
            .toList(growable: false),
        weekPlan);
  }
}

typedef Plan = Map<WeekDay, Map<int, SlotContentType>>;

abstract class PlanProvider {
  Plan getPlan();
}

class DefaultPlanProvider extends PlanProvider {
  final List<TimeSlot> _timeSlots = getTimeSlots();

  @override
  Plan getPlan() {
    Plan data = {};
    for (final weekDay in WeekDay.values) {
      data.putIfAbsent(weekDay, () => {});
      for (var i = 0; i < _timeSlots.length; ++i) {
        data[weekDay]![i] = ('', '');
      }
    }
    return data;
  }
}

class HardcodedPlanProvider extends PlanProvider {
  @override
  Plan getPlan() => _weekPlan;
}

/// Parse plan from given [text], matching time slots provided as [timeSlots].
Plan parsePlanFrom(String text, List<TimeSlot> timeSlots) {
  List<WeekDay> weekDays = [];
  Plan data = {};

  final lines = const LineSplitter().convert(text);
  for (final line in lines) {
    if (line.trim().isEmpty) {
      continue;
    }
    final entries = line.split('|').map((e) => e.trim());

    if (weekDays.isEmpty) {
      weekDays = entries
          .skip(1) // first entry is empty
          .map(parseWeekDay)
          .whereType<WeekDay>()
          .toList(growable: false);
    } else {
      final expectedColumns = 2 + weekDays.length;
      if (entries.length != expectedColumns) {
        throw FormatException(
            'Expected $expectedColumns columns in `$line`, got ${entries.length}!');
      }
      final from = parseDayTime(entries.elementAt(0));
      final until = parseDayTime(entries.elementAt(1));
      if (from >= until) {
        throw FormatException(
            'Left value `$from` is not less than right value `$until`!');
      }
      final slot = TimeSlot(from, until);
      final slotIndex = timeSlots.indexOf(slot);
      if (slotIndex < 0) {
        throw FormatException('Unexpected time slot $slot!');
      }

      for (var index = 2; index < entries.length; ++index) {
        final content = parseNameLocation(entries.elementAt(index));
        final weekDay = weekDays.elementAt(index - 2);
        if (content != null) {
          data.putIfAbsent(weekDay, () => {});
          data[weekDay]![slotIndex] = content;
        }
      }
    }
  }
  return data;
}

@visibleForTesting
SlotContentType? parseNameLocation(String text) {
  if (text.isEmpty) {
    return null;
  }
  final entries =
      text.split(' ').map((e) => e.trim()).where((e) => e.isNotEmpty);
  if (entries.length != 2) {
    throw FormatException(
        "Expected 2 entries, got ${entries.length} in $text!");
  }
  return (entries.elementAt(0), entries.elementAt(1));
}

@visibleForTesting
WeekDay parseWeekDay(String text) {
  final lowerCase = text.toLowerCase();
  final result = WeekDay.values
      .firstWhereOrNull((e) => e.name.toLowerCase().startsWith(lowerCase));
  if (result == null) {
    throw FormatException('Unable to parse week day from `$text`!');
  }
  return result;
}

@visibleForTesting
DayTime parseDayTime(String text) {
  final numbers = text.split(':');
  if (numbers.length == 2) {
    final hour = int.tryParse(numbers[0]);
    if (hour == null) {
      throw FormatException('Unable to parse hour from `${numbers[0]}`!');
    } else if (hour < 0 || hour > 23) {
      throw FormatException('Hour from `${numbers[0]}` is outside range!');
    }
    final minute = int.tryParse(numbers[1]);
    if (minute == null) {
      throw FormatException('Unable to parse minute from `${numbers[1]}`!');
    } else if (minute < 0 || minute > 59) {
      throw FormatException('Minute from `${numbers[1]}` is outside range!');
    }
    return DayTime(hour, minute);
  }
  throw FormatException('Unable to parse day time from `$text`!');
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
