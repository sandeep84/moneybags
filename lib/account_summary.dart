import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dartcash/gnc_book.dart';
import 'package:dartcash/gnc_account.dart';

import 'account_expansion_tile.dart';
import 'account_detail.dart';

import 'expense_report.dart';
import 'expense_bar_chart.dart';

import 'license.dart';

class AccountSummary extends StatefulWidget {
  @override
  _AccountSummaryState createState() => new _AccountSummaryState();
}

class _AccountSummaryState extends State<AccountSummary> {
  String _path;
  GncBook _book = GncBook();
  List<GncAccount> accountList = [];

  @override
  void initState() {
    super.initState();
    openDatabase();
  }

  @override
  void dispose() {
    _book.close();
    accountList = [];
    super.dispose();
  }

  Future<void> _openFileExplorer() async {
    print("Called _openFileExplorer");
    _book.close();
    setState(() {
      accountList = [];
    });

    try {
      _path = await FilePicker.getFilePath(type: FileType.any);
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
    if (!mounted) {
      print("Not mounted, returning null");
      return null;
    }

    // save for next time
    if (_path != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('gnc_local_file_path', _path);
    }
  }

  Future<void> openDatabase() async {
    if (_book.isOpen) return;

    // if _database is null we instantiate it
    final prefs = await SharedPreferences.getInstance();
    _path = prefs.getString('gnc_local_file_path');
    if (_path == null) await _openFileExplorer();

    await _book.open(_path);
    setState(() {
      accountList = _book.accounts();
    });
  }

  Future<void> reopenDatabase() async {
    setState(() {
      accountList = [];
    });
    _openFileExplorer();
    openDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Accounts'),
      ),
      body: ListView.builder(
        itemCount: accountList.length,
        itemBuilder: (context, index) =>
            AccountWidget(accountList[index], context),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/images/drawer_header.jpg"),
                      fit: BoxFit.cover)),
              child: Text("Moneybags"),
            ),
            ListTile(
              title: Text('Select file'),
              onTap: () {
                reopenDatabase();
                Navigator.pop(context);
              },
            ),
            ExpansionTile(
              title: Text('Reports'),
              children: <Widget>[
                ListTile(
                  title: Text('Expenses'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExpenseReportScreen(book: _book),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: Text('Expenses over time'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExpenseBarChart(book: _book),
                      ),
                    );
                  },
                ),
              ],
            ),
            ListTile(
              title: Text('Licenses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LicenseScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Displays one Account. If the entry has children then it's displayed
// with an ExpansionTile.
class AccountWidget extends StatelessWidget {
  const AccountWidget(this.entry, this.context);
  final GncAccount entry;
  final BuildContext context;

  Widget _buildTiles(GncAccount account) {
    var subtitle;
    if (account.commodity.guid != account.baseCurrency.guid) {
      subtitle = Text(account.commodity
          .format(account.getBalance(reportCommodity: account.commodity)));
    }
    if (account.children.isEmpty) {
      return ListTile(
        leading: Text(""), // Needed for alignment
        title: Text(account.name),
        subtitle: subtitle,
        trailing: Text(account.baseCurrency.format(account.getBalance())),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccountDetailScreen(account: account),
            ),
          );
        },
      );
    }
    return AccountExpansionTile(
      key: PageStorageKey<GncAccount>(account),
      title: Text(account.name),
      subtitle: subtitle,
      trailing: Text(account.baseCurrency.format(account.getBalance())),
      children: account.children.map(_buildTiles).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(entry);
  }
}
