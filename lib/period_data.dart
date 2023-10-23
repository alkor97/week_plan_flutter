import 'package:week_plan_flutter/period.dart';
import 'package:week_plan_flutter/time.dart';

import 'package:flutter/foundation.dart';

List<TimeSlot> getTimeSlots({bool shortened = false}) =>
    parseTimeSlots(shortened ? _shortenedTimeSlots : _normalTimeSlots)
        .toList(growable: false);

// implementation

@visibleForTesting
typedef IntPair = (int, int);

@visibleForTesting
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

@visibleForTesting
Iterable<TimeSlot> parseTimeSlots(Iterable<IntPairPair> input) => input.indexed
    .map((e) => IndexedTimeSlot(DayTime.fromTuple(e.$2.$1), DayTime.fromTuple(e.$2.$2), e.$1))
    .toList(growable: false);
