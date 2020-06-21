import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'package:dartcash/gnc_book.dart';
import 'package:dartcash/gnc_utils.dart';
import 'indicator.dart';

class ExpenseBarChart extends StatefulWidget {
  final GncBook book;

  ExpenseBarChart({Key key, @required this.book}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ExpenseBarChartState();
}

class MonthlyExpenses {
  final String month;
  final double expenses;

  MonthlyExpenses(this.month, this.expenses);
}

class ExpenseBarChartState extends State<ExpenseBarChart> {
  DateTime selectedDate;
  List<String> monthNames = List(12);
  final List<charts.Color> sliceColors = [
    charts.MaterialPalette.blue.shadeDefault.lighter,
    charts.MaterialPalette.red.shadeDefault.lighter,
    charts.MaterialPalette.yellow.shadeDefault.lighter,
    charts.MaterialPalette.green.shadeDefault.lighter,
    charts.MaterialPalette.purple.shadeDefault.lighter,
    charts.MaterialPalette.deepOrange.shadeDefault.lighter,
    charts.MaterialPalette.cyan.shadeDefault.lighter,
    charts.MaterialPalette.lime.shadeDefault.lighter,
    charts.MaterialPalette.pink.shadeDefault.lighter,
    charts.MaterialPalette.teal.shadeDefault.lighter,
    charts.MaterialPalette.gray.shadeDefault.lighter,
    charts.MaterialPalette.indigo.shadeDefault.lighter,
  ];
  int colorIndex = 0;
  Map<String, charts.Color> colorMap = {};
  Map<String, List<MonthlyExpenses>> dataMap = {};

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    updateDataMap();
  }

  void updateDataMap() {
    dataMap = {};
    colorMap = {};
    colorIndex = 0;

    for (var month = 0; month < 12; month++) {
      final startDate = DateTime(selectedDate.year, month + 1, 1);
      final endDate = DateTime(selectedDate.year, month + 2, 1);

      setState(() {
        monthNames[month] = DateFormat.MMM().format(startDate);
        final accList = accountSummaryByType(
            accountType: 'EXPENSE',
            startDate: startDate,
            endDate: endDate,
            numDetailedAccounts: 5,
            reportCommodity: widget.book.baseCurrency,
            rootAccount: widget.book.rootAccount);
        for (final acc in accList.keys) {
          if (!dataMap.containsKey(acc)) dataMap[acc] = [];
          dataMap[acc].add(MonthlyExpenses(monthNames[month], accList[acc]));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense report'),
      ),
      body: getBarChart(),
    );
  }

  /// Create series list with multiple series
  List<charts.Series<MonthlyExpenses, String>> _createSampleData() {
    List<charts.Series<MonthlyExpenses, String>> bars = [];
    for (final acc in dataMap.entries) {
      if (!colorMap.containsKey(acc.key))
        colorMap[acc.key] = sliceColors[(colorIndex++) % sliceColors.length];
      bars.add(
        charts.Series<MonthlyExpenses, String>(
          id: acc.key,
          domainFn: (MonthlyExpenses expenses, _) => expenses.month,
          measureFn: (MonthlyExpenses expenses, _) => expenses.expenses,
          data: acc.value,
          colorFn: (_, __) => colorMap[acc.key],
        ),
      );
    }

    return bars;
  }

  Widget getBarChart() {
    Widget barChart = AspectRatio(
      aspectRatio: 1.8,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: charts.BarChart(
          _createSampleData(),
          animate: false,
          barGroupingType: charts.BarGroupingType.stacked,
        ),
      ),
    );

    List<Widget> indicators = [];

    for (final entry in colorMap.entries) {
      indicators.add(Indicator(
        color: charts.ColorUtil.toDartColor(entry.value),
        text: entry.key,
        isSquare: true,
      ));
    }

    final barChartTitle = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_left),
          iconSize: 40,
          tooltip: 'Previous year',
          onPressed: () => setState(() {
            selectedDate = DateTime(
                selectedDate.year - 1, selectedDate.month, selectedDate.day);
            updateDataMap();
          }),
        ),
        Text(
          'Expenses - ' + DateFormat.y().format(selectedDate),
          style: TextStyle(fontSize: 25),
        ),
        IconButton(
          icon: Icon(Icons.arrow_right),
          iconSize: 40,
          tooltip: 'Next year',
          onPressed: () => (selectedDate.year == DateTime.now().year)
              ? null
              : setState(() {
                  selectedDate = DateTime(selectedDate.year + 1,
                      selectedDate.month, selectedDate.day);
                  updateDataMap();
                }),
        ),
      ],
    );

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return Column(
        children: [
          barChartTitle,
          barChart,
          Wrap(
            children: indicators,
            spacing: 4,
            runSpacing: 4,
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Column(children: [
            barChartTitle,
            Expanded(child: barChart),
          ]),
          Wrap(
            direction: Axis.vertical,
            children: indicators,
            spacing: 4,
            runSpacing: 4,
          ),
        ],
      ),
    );
  }
}
