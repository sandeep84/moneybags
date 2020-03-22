import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gncDb.dart';
import 'accountExpansionTile.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
            // This is the theme of your application.
            //
            // Try running your application with "flutter run". You'll see the
            // application has a blue toolbar. Then, without quitting the app, try
            // changing the primarySwatch below to Colors.green and then invoke
            // "hot reload" (press "r" in the console where you ran "flutter run",
            // or simply save your changes to "hot reload" in a Flutter IDE).
            // Notice that the counter didn't reset back to zero; the application
            // is not restarted.
            primarySwatch: Colors.blue,
        ),
        home: FilePickerDemo(),
    );
  }
}

class FilePickerDemo extends StatefulWidget {
  @override
  _FilePickerDemoState createState() => new _FilePickerDemoState();
}

class _FilePickerDemoState extends State<FilePickerDemo> {
  String _path = null;
  gncDb _database;
  Future<List<Account>> accountTree;

  @override
  void initState() {
    super.initState();
  }

  Future<gncDb> get database async {
    if (_database != null)
      return _database;

    // if _database is null we instantiate it
    final prefs = await SharedPreferences.getInstance();
    _path = prefs.getString('gnc_local_file_path');

    if (_path == null)
      _path = await _openFileExplorer();

    _database = gncDb(_path);
    return _database;
  }

  Future<String> _openFileExplorer() async {
    print("Called _openFileExplorer");
    try {
      _path = await FilePicker.getFilePath(type: FileType.any, fileExtension: '');
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
    if (!mounted) {
      print("Not mounted Returning null");
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

  Future<List<Account>> get accountSummary async {
    gncDb db = await database;
    accountTree = db.processDatabase();
    return accountTree;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        home: new Scaffold(
            appBar: new AppBar(
                title: const Text('Account summary'),
            ),
            body: new Center(
                child: new Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    child: new SingleChildScrollView(
                        child: new Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              new Builder(
                                  builder: (BuildContext context) => new Container(
                                      padding: const EdgeInsets.only(bottom: 30.0),
                                      height: MediaQuery.of(context).size.height * 0.8,
                                      child: FutureBuilder<List<Account>>(
                                          future: accountSummary,
                                          builder: (BuildContext context, AsyncSnapshot<List<Account>> snapshot) {
                                            if (snapshot.hasData) {
                                              return ListView.builder(
                                                  itemBuilder: (BuildContext context, int index) => 
                                                      AccountWidget(snapshot.data[index]),
                                                  itemCount: snapshot.data.length
                                              );
                                            } else {
                                              print("Spinner");
                                              return Center(child: CircularProgressIndicator());
                                            }
                                          },
                                       ),
                                   )
                               ),
                            ],
                         ),
                       ),
                    )
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
  const AccountWidget(this.entry);
  final Account entry;

  Widget _buildTiles(Account root) {
    if (root.children.isEmpty) return ListTile(
            leading: Text(""),      // Needed for alignment
            title: Text(root.name),
            trailing: Text(root.hierBalance.toStringAsFixed(2)),
            );
    return accountExpansionTile(
      key: PageStorageKey<Account>(root),
      title: Text(root.name),
      trailing: Text(root.hierBalance.toStringAsFixed(2)),
      children: root.children.map(_buildTiles).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(entry);
  }
}
