import 'package:week_plan_flutter/io.dart';
import 'package:week_plan_flutter/model.dart';
import 'package:week_plan_flutter/period.dart';
import 'package:week_plan_flutter/ticker.dart';
import 'package:week_plan_flutter/time.dart';

import 'package:week_plan_flutter/period_data.dart';
import 'package:week_plan_flutter/time_data.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

const _normalColor = Color(0xff3700b3);
const _textColor = Color(0xfffefefe);
const _highlightedColor = Color(0xff6200ee);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plan lekcji',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _normalColor),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _rowHeightMultiplier = 1.5;
  final _rowSeparatorMultiplier = 0.25;

  final DataProvider dataProvider = DataProviders.remote();
  bool shortenedTimeSlots = false;
  bool allTimeSlots = false;
  late PlanData weekPlanData;
  DateTime time = currentTime;
  late PeriodicRunner runner;
  DateTime? dataTimeStamp;

  String get dataVersion =>
      (dataTimeStamp?.toString() ?? "⸺").replaceFirst(RegExp(r"\.000Z"), "Z");

  @override
  void initState() {
    super.initState();
    weekPlanData = PlanProviders.dummy().getPlanData(on: _timeSlots);
    dataProvider.get().then(_handleDataResponse).onError(_handleError);
    runner = PeriodicRunner(
        _updateCurrentTime, Tickers.fixed(const Duration(minutes: 1)));
  }

  List<TimeSlot> get _timeSlots => getTimeSlots(shortened: shortenedTimeSlots);

  void _handleDataResponse(DataResponse response) => setState(() {
        dataTimeStamp = response.lastModified;
        weekPlanData =
            PlanProviders.parsing(response.content).getPlanData(on: _timeSlots);
      });

  void _updateCurrentTime() => setState(() => time = currentTime);

  void _handleError(Object? error, StackTrace stackTrace) {
    if (error is ClientException) {
      _reportError("Błąd podczas wczytywania danych z ${error.uri.toString()}");
    } else {
      _reportError("Nieznany błąd ($error)");
    }
  }

  @override
  void dispose() {
    runner.cancel();
    super.dispose();
  }

  void _reportError(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
      ));

  static DateTime get currentTime => DateTime.now();

  TextTheme get _textTheme => Theme.of(context).textTheme;

  TextStyle? _defaultTextStyle({bool bold = false}) =>
      _applyBold(_textTheme.titleLarge, bold);

  TextStyle? _smallerTextStyle({bool bold = false}) =>
      _applyBold(_textTheme.titleMedium, bold);

  TextStyle? _applyBold(TextStyle? style, bool bold) =>
      bold ? style?.copyWith(fontWeight: FontWeight.bold) : style;

  double _textHeight() {
    final textStyle = _defaultTextStyle();
    final fontSize = textStyle?.fontSize;
    final height = textStyle?.height;
    return fontSize! * height!;
  }

  double get _rowHeight => _rowHeightMultiplier * _textHeight();

  double get _rowSeparatorHeight => _rowHeight * _rowSeparatorMultiplier;

  TextStyle? _textStyle({bool smaller = false, bool bold = false}) =>
      (smaller ? _smallerTextStyle(bold: bold) : _defaultTextStyle(bold: bold))
          ?.apply(color: _textColor);

  Widget _text(String text, {bool smaller = false, bool bold = false}) =>
      Text(text, style: _textStyle(smaller: smaller, bold: bold));

  double get _defaultPadding => _rowHeight / 6.0;

  double get _verticalPadding => _rowHeight / 12.0;

  double get _smallerPadding => _rowHeight / 24.0;

  double get _columnPadding => _rowHeight / 8.0;

  EdgeInsets get _leftPadding => EdgeInsets.fromLTRB(
      _defaultPadding, _verticalPadding, _smallerPadding, _verticalPadding);

  EdgeInsets get _rightPadding => EdgeInsets.fromLTRB(
      _smallerPadding, _verticalPadding, _defaultPadding, _verticalPadding);

  EdgeInsets get _dayTimePadding => EdgeInsets.fromLTRB(
      _defaultPadding, _verticalPadding, _defaultPadding, _verticalPadding);

  Color _backgroundColor(bool highlighted) =>
      highlighted ? _highlightedColor : _normalColor;

  Widget _left(String text) => Expanded(
          child: Container(
        padding: _leftPadding,
        height: _rowHeight,
        alignment: Alignment.centerRight,
        child: _text(text),
      ));

  Widget _right(String text,
          {
          bool smaller = false,
          Alignment alignment = Alignment.bottomLeft}) =>
      Container(
        padding: _rightPadding,
        height: _rowHeight,
        alignment: alignment,
        child: _text(text, smaller: smaller),
      );

  Widget _dayTime(DayTime dayTime) => _text(formatDayTime(dayTime), bold: true);

  Widget _dayTimeContainer(
          DayTime dayTime, EdgeInsets padding, bool highlighted) =>
      Container(
        padding: padding,
        height: _rowHeight,
        color: _backgroundColor(highlighted),
        alignment: Alignment.centerLeft,
        child: _dayTime(dayTime),
      );

  Iterable<Widget> _dayTimeColumns(TimeSlot timeSlot, bool highlighted) => [
          _dayTimeContainer(timeSlot.from, _dayTimePadding, highlighted),
          _dayTimeContainer(timeSlot.until, _dayTimePadding, highlighted),
    ];

  Widget _row(String name, String location) => Row(
        children: [
          _left(name),
          _right(location, smaller: true),
        ],
      );

  Widget _emptyRow() => Container(height: _rowHeight);

  Widget _rowSeparator(bool highlighted) => Container(
        height: _rowSeparatorHeight,
        color: _backgroundColor(highlighted),
      );

  Widget _center(Widget widget) => Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(_defaultPadding),
        child: widget,
      );

  Widget _cellPadding(Widget widget, bool highlighted) => Container(
    color: _backgroundColor(highlighted),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: _columnPadding), child: widget));

  Widget _weekDayWidget(WeekDay weekDay, bool highlighted) =>
      _cellPadding(_center(_text(formatWeekDay(weekDay), bold: true)), highlighted);

  PopupMenuItem<int> _switchMenuOption(
          String title, bool Function() getState, Function(bool) onChange) =>
      PopupMenuItem<int>(
          child: Row(
        children: [
          Text(title),
          const Spacer(),
          StatefulBuilder(
            builder: (context, doSetState) => Switch(
                value: getState(),
                onChanged: (bool value) =>
                    doSetState(() => setState(() => onChange(value)))),
          ),
        ],
      ));

  Widget _popupButton() => PopupMenuButton(
        icon: const Icon(Icons.settings),
        tooltip: "Ustawienia",
        color: _textColor,
        itemBuilder: (context) => [
          _switchMenuOption("Skrócone lekcje", () => shortenedTimeSlots,
              (value) => shortenedTimeSlots = value),
          _switchMenuOption("Wszystkie dzwonki", () => allTimeSlots,
              (value) => allTimeSlots = value),
          PopupMenuItem<int>(
            child: Text(dataVersion, style: _textTheme.labelSmall),
          )
        ],
      );

  List<TableRow> _createRows() {
    final now = DateTime.now();
    final currentWeekDay = WeekDay.of(now);

    final weekPlan = WeekPlanProvider().from(
        weekPlanData, getTimeSlots(shortened: shortenedTimeSlots),
        allTimeSlots: allTimeSlots);
    final weekDays = weekPlan.weekDays;
    final List<TableRow> rows = [
      TableRow(children: [
        Wrap(children: [_popupButton()]),
        _emptyRow(),
        ...weekDays.map((e) => _weekDayWidget(e, e == currentWeekDay))
      ])
    ];

    for (final timeSlot in weekPlan.timeSlots) {
      final isActive = timeSlot.isActiveAt(now);
      if (timeSlot is RecessSlot) {
        // separator row
        rows.add(TableRow(children: [
          _rowSeparator(isActive),
          _rowSeparator(isActive),
          ...weekDays.map(
              (e) => _rowSeparator(isActive && e == currentWeekDay))
        ]));
      } else {
        // content row
        rows.add(TableRow(children: [
          ..._dayTimeColumns(timeSlot, isActive),
          ...weekDays.map((weekDay) {
            final content = weekPlan.get(on: weekDay, at: timeSlot);
            final highlight = isActive && weekDay == currentWeekDay;
            return _cellPadding(content != null
                ? _row(content.subject, content.location)
                : _emptyRow(), highlight);
          })
        ]));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _normalColor,
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SafeArea(child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
                border: TableBorder.all(color: _normalColor, width: 0.1),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: _createRows()),
          ),
        ),
      ),),
    );
  }
}
