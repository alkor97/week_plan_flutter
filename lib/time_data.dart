import 'package:week_plan_flutter/time.dart';

String formatWeekDay(WeekDay weekDay) => _weekDaysPL[weekDay.index];

const _weekDaysPL = [
  "poniedziałek",
  "wtorek",
  "środa",
  "czwartek",
  "piątek",
  "sobota",
  "niedziela"
];
