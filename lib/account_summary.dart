import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:dartcash/gnc_book.dart';
import 'package:dartcash/gnc_account.dart';

import 'package:moneybags/database_selector.dart';
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
  GncBook _book = GncBook();
  List<GncAccount> accountList = [];
  final _storage = FlutterSecureStorage();

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

  Future<void> openDatabase() async {
    if (_book.isOpen) return;

    String dbType = await _storage.read(key: 'dbType');
    if (dbType == null) {
      // Ask user the database storage type and location
      await getDatabaseStorage();
    }

    // Re-read the dbType after the user interaction
    dbType = await _storage.read(key: 'dbType');

    if (dbType == 'sqlite') {
      String dbPath = await _storage.read(key: 'dbPath');
      await _book.sqliteOpen(dbPath);

      setState(() {
        accountList = _book.accounts();
      });
    } else {
      String host = await _storage.read(key: 'host');
      String port = await _storage.read(key: 'port');
      String user = await _storage.read(key: 'user');
      String password = await _storage.read(key: 'password');
      String databaseName = await _storage.read(key: 'databaseName');

      await _book.postgreOpen(
        host: host,
        port: int.parse(port),
        user: user,
        password: password,
        databaseName: databaseName,
      );

      setState(() {
        accountList = _book.accounts();
      });
    }
  }

  Future<void> getDatabaseStorage() async {
    _book.close();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(storage: _storage),
      ),
    );

    openDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Accounts'),
      ),
      body: (accountList.length == 0)
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
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
              title: Text('Open database'),
              onTap: () {
                Navigator.pop(context);
                getDatabaseStorage();
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
