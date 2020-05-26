import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dartcash/gnc_book.dart';
import 'package:dartcash/gnc_account.dart';

import 'account_expansion_tile.dart';
import 'account_detail.dart';

class AccountSummary extends StatefulWidget {
  @override
  _AccountSummaryState createState() => new _AccountSummaryState();
}

class _AccountSummaryState extends State<AccountSummary> {
  String _path;
  GncBook _book = GncBook();

  @override
  void initState() {
    super.initState();
  }

  Future<void> openDatabase() async {
    if (_book.isOpen)
      return;

    // if _database is null we instantiate it
    final prefs = await SharedPreferences.getInstance();
    _path = prefs.getString('gnc_local_file_path');

    if (_path == null)
      _path = await _openFileExplorer();

    setState(() { _book.open(_path); });
  }

  Future<String> _openFileExplorer() async {
    print("Called _openFileExplorer");
    _book.close();

    try {
      _path = await FilePicker.getFilePath(type: FileType.any, fileExtension: '');
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

    print("Returning path: " + _path);
    return _path;
  }

  Future<List<GncAccount>> get accountSummary async {
    await openDatabase();
    return _book.accounts();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        home: new Scaffold(
            appBar: new AppBar(
                title: const Text('Accounts'),
            ),
            body: FutureBuilder<List<GncAccount>>(
                future: accountSummary,
                builder: (BuildContext context, AsyncSnapshot<List<GncAccount>> snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                        itemBuilder: (BuildContext context, int index) => 
                        AccountWidget(snapshot.data[index], context),
                        itemCount: snapshot.data.length
                    );
                  } else {
                    print("Spinner");
                    return Center(child: CircularProgressIndicator());
                  }
                },
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: _openFileExplorer,
                child: Icon(Icons.folder_open),
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
    if (account.children.isEmpty) {
      var subtitle;
      if (account.commodity.guid != account.baseCurrency.guid) {
        subtitle = Text(account.commodity.format(account.get_quantity()));
      }
      return ListTile(
            leading: Text(""),      // Needed for alignment
            title: Text(account.name),
            subtitle: subtitle,
            trailing: Text(account.baseCurrency.format(account.get_balance())),
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
      trailing: Text(account.baseCurrency.format(account.get_balance())),
      children: account.children.map(_buildTiles).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(entry);
  }
}
