import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:week_plan_flutter/io.dart';
import 'package:week_plan_flutter/model.dart';
import 'package:week_plan_flutter/period.dart';
import 'package:week_plan_flutter/ticker.dart';
import 'package:week_plan_flutter/time.dart';

const _normalColor = Color(0xff3700b3);
const _textColor = Color(0xfffefefe);
const _highlightedColor = Color(0xff6200ee);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plan lekcji',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: _normalColor),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Plan lekcji'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _rowHeightMultiplier = 1.5;
  final _rowSeparatorMultiplier = 0.25;

  bool shortenedTimeSlots = false;
  dynamic weekPlanData;
  DateTime time = _currentTime;
  late AbstractTicker ticker;
  DateTime? dataTimeStamp;
  String? dataSource;

  String get _dataVersion =>
      (dataTimeStamp?.toString() ?? "⸺").replaceFirst(RegExp(r"\.000Z"), "Z");

  @override
  void initState() {
    super.initState();
    weekPlanData = DefaultPlanProvider().getPlan();
    readPlanData().then(_handleDataResponse).onError(_handleError);
    ticker = PeriodicTicker(_updateCurrentTime);
  }

  void _handleDataResponse(DataResponse response) => setState(() {
        dataTimeStamp = response.lastModified;
        dataSource = switch (response.source) {
          DataSource.url => "zewnętrzne",
          DataSource.asset => "wewnętrzne"
        };
        weekPlanData = parsePlanFrom(
            response.content, getTimeSlots(shortened: shortenedTimeSlots));
      });

  void _updateCurrentTime() => setState(() => time = _currentTime);

  void _handleError(Object? error, StackTrace stackTrace) {
    if (error is ClientException) {
      _reportError("Błąd podczas wczytywania danych z ${error.uri.toString()}");
    } else {
      _reportError("Nieznany błąd ($error)");
    }
  }

  @override
  void dispose() {
    ticker.cancel();
    super.dispose();
  }

  void _reportError(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
      ));

  static DateTime get _currentTime => DateTime.now();

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

  double get _columnPadding => _rowHeight / 4.0;

  EdgeInsets get _leftPadding => EdgeInsets.fromLTRB(
      _defaultPadding, _verticalPadding, _smallerPadding, _verticalPadding);

  EdgeInsets get _rightPadding => EdgeInsets.fromLTRB(
      _smallerPadding, _verticalPadding, _defaultPadding, _verticalPadding);

  EdgeInsets get _dayTimePadding => EdgeInsets.fromLTRB(
      _defaultPadding, _verticalPadding, _defaultPadding, _verticalPadding);

  Color _backgroundColor(bool highlighted) =>
      highlighted ? _highlightedColor : _normalColor;

  Widget _left(String text, {bool highlighted = false}) => Expanded(
          child: Container(
        padding: _leftPadding,
        height: _rowHeight,
        color: _backgroundColor(highlighted),
        alignment: Alignment.centerRight,
        child: _text(text),
      ));

  Widget _right(String text,
          {bool highlighted = false,
          bool smaller = false,
          Alignment alignment = Alignment.bottomLeft}) =>
      Container(
        padding: _rightPadding,
        height: _rowHeight,
        color: _backgroundColor(highlighted),
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
        alignment: Alignment.centerRight,
        child: _dayTime(dayTime),
      );

  Widget _dayTimeRow(TimeSlot timeSlot, {bool highlighted = false}) => Row(
        children: [
          _dayTimeContainer(timeSlot.from, _dayTimePadding, highlighted),
          _dayTimeContainer(timeSlot.until, _dayTimePadding, highlighted),
        ],
      );

  Widget _row(String name, String location, {bool highlighted = false}) => Row(
        children: [
          _left(name, highlighted: highlighted),
          _right(location, highlighted: highlighted, smaller: true),
        ],
      );

  Widget _emptyRow({bool highlighted = false}) => Container(
        height: _rowHeight,
        color: _backgroundColor(highlighted),
      );

  Widget _rowSeparator({bool highligted = false}) => Container(
        height: _rowSeparatorHeight,
        color: _backgroundColor(highligted),
      );

  Widget _center(Widget widget) => Container(
        color: _normalColor,
        alignment: Alignment.center,
        padding: EdgeInsets.all(_defaultPadding),
        child: widget,
      );

  Widget _columnsPadding(Widget widget) => Padding(
      padding: EdgeInsets.symmetric(horizontal: _columnPadding), child: widget);

  Widget _weekDayWidget(WeekDay weekDay) =>
      _columnsPadding(_center(_text(formatWeekDay(weekDay), bold: true)));

  Widget _popupButton() => PopupMenuButton(
        color: _textColor,
        itemBuilder: (context) {
          return [
            PopupMenuItem<int>(
                child: Row(
              children: [
                const Text("Skrócone lekcje"),
                const Spacer(),
                StatefulBuilder(
                  builder: (context, doSetState) => Switch(
                      value: shortenedTimeSlots,
                      onChanged: (bool value) => doSetState(
                          () => setState(() => shortenedTimeSlots = value))),
                ),
              ],
            )),
            PopupMenuItem<int>(
              child: Text("Wersja danych\n$_dataVersion\n(dane $dataSource)"),
            )
          ];
        },
      );

  List<TableRow> _createRows() {
    if (weekPlanData == null) {
      return [];
    }
    final weekPlan = WeekPlan.create(
        getTimeSlots(shortened: shortenedTimeSlots), weekPlanData,
        includeRecess: true);
    final weekDays = weekPlan.weekDays;
    final List<TableRow> rows = [
      TableRow(children: [
        Wrap(children: [_popupButton()]),
        ...weekDays.map(_weekDayWidget)
      ])
    ];

    final now = DateTime.now();
    final currentWeekDay = WeekDay.of(now);
    for (final timeSlot in weekPlan.timeSlots) {
      final isActive = timeSlot.isActiveAt(now);
      if (timeSlot is RecessSlot) {
        // separator row
        rows.add(TableRow(children: [
          _rowSeparator(highligted: isActive),
          ...weekDays.map(
              (e) => _rowSeparator(highligted: isActive && e == currentWeekDay))
        ]));
      } else {
        // content row
        rows.add(TableRow(children: [
          _dayTimeRow(timeSlot, highlighted: isActive),
          ...weekDays.map((e) {
            final content = weekPlan.get(e, timeSlot);
            final highlight = isActive && e == currentWeekDay;
            return _columnsPadding(content != null
                ? _row(content.$1, content.$2, highlighted: highlight)
                : _emptyRow(highlighted: highlight));
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
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
              border: TableBorder.all(color: _normalColor),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: _createRows()),
        ),
      ),
    );
  }
}
