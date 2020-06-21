import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'package:dartcash/gnc_book.dart';
import 'package:dartcash/gnc_utils.dart';
import 'indicator.dart';

class ExpenseReportScreen extends StatefulWidget {
  final GncBook book;

  ExpenseReportScreen({Key key, @required this.book}) : super(key: key);

  @override
  _ExpenseReportState createState() => new _ExpenseReportState();
}

class ExpenseCategory {
  final String category;
  final double expense;
  final charts.Color color;

  ExpenseCategory(this.category, this.expense, this.color);
}

class _ExpenseReportState extends State<ExpenseReportScreen> {
  DateTime selectedDate;
  Map<String, double> dataMap;
  List<charts.Series> seriesList;
  final bool animate = false;
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

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    updateDataMap();
  }

  void updateDataMap() {
    colorIndex = 0;
    final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
    final endDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
    setState(() {
      dataMap = accountSummaryByType(
          accountType: 'EXPENSE',
          startDate: startDate,
          endDate: endDate,
          reportCommodity: widget.book.baseCurrency,
          rootAccount: widget.book.rootAccount);

      List<ExpenseCategory> data = [];
      for (final acc in dataMap.entries) {
        data.add(ExpenseCategory(acc.key, acc.value,
            sliceColors[(colorIndex++) % sliceColors.length]));
      }

      seriesList = [
        new charts.Series<ExpenseCategory, String>(
          id: 'expense',
          domainFn: (ExpenseCategory expense, _) => expense.category,
          measureFn: (ExpenseCategory expense, _) => expense.expense,
          data: data,
          // Set a label accessor to control the text of the arc label.
          labelAccessorFn: (ExpenseCategory row, _) =>
              widget.book.baseCurrency.format(row.expense),
          colorFn: (ExpenseCategory expense, _) => expense.color,
        )
      ];
    });
  }

  int touchedIndex;

  @override
  Widget build(BuildContext context) {
    final chartTitle = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_left),
          iconSize: 40,
          tooltip: 'Previous month',
          onPressed: () => setState(() {
            selectedDate =
                DateTime(selectedDate.year, selectedDate.month - 1, 1);
            updateDataMap();
          }),
        ),
        Text(
          'Expenses - ' + DateFormat.MMMM().format(selectedDate),
          style: TextStyle(fontSize: 25),
        ),
        IconButton(
          icon: Icon(Icons.arrow_right),
          iconSize: 40,
          tooltip: 'Next month',
          onPressed: () => (selectedDate.month == DateTime.now().month)
              ? null
              : setState(() {
                  selectedDate =
                      DateTime(selectedDate.year, selectedDate.month + 1, 1);
                  updateDataMap();
                }),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense report'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[chartTitle] + pieChart(),
        ),
      ),
    );
  }

  List<Widget> pieChart() {
    if (dataMap.length == 0) {
      return [
        SizedBox(
          height: 50,
          child: Center(
            child: Text(
              'No expenses found.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ];
    } else {
      return [
        AspectRatio(
          aspectRatio: 1,
          child: charts.PieChart(
            seriesList,
            animate: animate,
            defaultRenderer: charts.ArcRendererConfig(
                arcWidth: 60,
                arcRendererDecorators: [charts.ArcLabelDecorator()]),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Table(
          border: TableBorder.all(),
          children: legendEntries(),
        ),
      ];
    }
  }

  List<TableRow> legendEntries() {
    List<TableRow> legend = [
      TableRow(children: [
        Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
        Text("Expenses", style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
    ];
    var i = 0;
    for (final entry in dataMap.entries) {
      legend.add(
        TableRow(children: [
          Indicator(
            color: charts.ColorUtil.toDartColor(sliceColors[i]),
            text: entry.key,
            isSquare: true,
          ),
          Text(widget.book.baseCurrency.format(entry.value)),
        ]),
      );
      i++;
    }
    legend.add(
      TableRow(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 16,
              ),
              Text('Total expenses',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Text(
              widget.book.baseCurrency.format(
                  dataMap.values.reduce((value, element) => value + element)),
              style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );

    return legend;
  }
}
