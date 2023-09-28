import 'package:flutter/foundation.dart';
import 'package:week_plan_flutter/time.dart';
import 'package:week_plan_flutter/period.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:core';

class SlotContent {
  final String subject;
  final String location;
  SlotContent(this.subject, this.location);
  factory SlotContent.empty() => SlotContent('', '');
  @override
  bool operator ==(Object other) =>
      other is SlotContent &&
      subject == other.subject &&
      location == other.location;
  @override
  int get hashCode => Object.hash(subject, location);
}

abstract class WeekPlan {
  Iterable<WeekDay> get weekDays;
  Iterable<TimeSlot> get timeSlots;
  SlotContent? get({required WeekDay on, required TimeSlot at});
}

class WeekPlanProvider {
  WeekPlan from(PlanData data, List<TimeSlot> timeSlots,
          {bool allTimeSlots = false}) =>
      _WeekPlanImpl(timeSlots, data,
          includeRecess: true, allTimeSlots: allTimeSlots);
}

typedef PlanData = Map<WeekDay, Map<int, SlotContent>>;

abstract class PlanProvider {
  PlanData getPlanData({required List<TimeSlot> on});
}

class PlanProviders {
  static PlanProvider dummy() => _DefaultPlanProvider();
  static PlanProvider parsing(String text) => _ParsingPlanProvider(text);
}

// implementation

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

class _WeekPlanImpl implements WeekPlan {
  @override
  late final Iterable<WeekDay> weekDays;
  @override
  late final Iterable<TimeSlot> timeSlots;
  late final Map<_Key, SlotContent> _data;

  _WeekPlanImpl(
      List<TimeSlot> inputSlots, Map<WeekDay, Map<int, SlotContent>> plan,
      {bool includeRecess = false, bool allTimeSlots = false}) {
    assert(inputSlots.isNotEmpty);

    WeekDay minimal(WeekDay a, WeekDay b) => a.index < b.index ? a : b;
    WeekDay maximal(WeekDay a, WeekDay b) => a.index > b.index ? a : b;

    int minIndex = inputSlots.length - 1;
    int maxIndex = 0;

    WeekDay minDay = WeekDay.sunday;
    WeekDay maxDay = WeekDay.monday;

    Map<_Key, SlotContent> weekPlan = {};

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
        weekPlan[_Key(weekDay, inputSlots[index])] = value;
      }
    }

    // remove unused periods
    final limitedPeriods = allTimeSlots
        ? inputSlots
        : inputSlots.indexed
            .where(
                (element) => minIndex <= element.$1 && element.$1 <= maxIndex)
            .map((e) => e.$2);

    weekDays = WeekDay.values
        .where((element) => minDay <= element && element <= maxDay)
        .toList(growable: false);
    timeSlots =
        (includeRecess ? deduceRecessSlots(limitedPeriods) : limitedPeriods)
            .toList(growable: false);

    _data = weekPlan;
  }

  @override
  SlotContent? get({required WeekDay on, required TimeSlot at}) =>
      _data[_Key(on, at)];
}

class _DefaultPlanProvider extends PlanProvider {
  @override
  PlanData getPlanData({required List<TimeSlot> on}) {
    PlanData data = {};
    for (final weekDay in WeekDay.values) {
      data.putIfAbsent(weekDay, () => {});
      for (var i = 0; i < on.length; ++i) {
        data[weekDay]![i] = SlotContent.empty();
      }
    }
    return data;
  }
}

class _ParsingPlanProvider extends PlanProvider {
  final String _text;
  _ParsingPlanProvider(this._text);

  @override
  PlanData getPlanData({required List<TimeSlot> on}) {
    List<WeekDay> weekDays = [];
    PlanData data = {};

    final lines = const LineSplitter().convert(_text);
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
        final slotIndex = on.indexOf(slot);
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
}

@visibleForTesting
SlotContent? parseNameLocation(String text) {
  if (text.isEmpty) {
    return null;
  }
  final entries =
      text.split(' ').map((e) => e.trim()).where((e) => e.isNotEmpty);
  if (entries.length != 2) {
    throw FormatException(
        "Expected 2 entries, got ${entries.length} in $text!");
  }
  return SlotContent(entries.elementAt(0), entries.elementAt(1));
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
