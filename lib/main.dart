import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';

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
  String _fileName;
  String _path = null;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = false;
  bool _hasValidMime = false;
  FileType _pickingType;
  TextEditingController _controller = new TextEditingController();
  static Database _database;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _extension = _controller.text);
  }

  Future<String> _openFileExplorer() async {
      print("Called _openFileExplorer");
      print("0");
      print("1");
      try {
          if (_multiPick) {
              _path = null;
              _paths = await FilePicker.getMultiFilePath(type: _pickingType, fileExtension: _extension);
          } else {
              _paths = null;
              _path = await FilePicker.getFilePath(type: _pickingType, fileExtension: _extension);
          }
      } on PlatformException catch (e) {
          print("Unsupported operation" + e.toString());
      }
      if (!mounted) {
          print("Not mounted Returning null");
          return null;
      }

      print("Returning path: " + _path);
      return _path;
  }

  Future<String> get dbPath async {
      print("Getting dbPath");
      if (_path != null)
          return _path;

      _path = await _openFileExplorer();
      return _path;
  }

  Future<Database> _openDatabase() async {
      final _dbPath = await dbPath;
      print("Opening database: " + _dbPath);
      return await openDatabase(_dbPath, version: 1, 
              onOpen: (db) { }, 
              onCreate: (Database db, int version) async {
                print("Created database connection");
              });
  }

  Future<Database> get database async {
    if (_database != null)
    return _database;

    // if _database is null we instantiate it
    _database = await _openDatabase();
    return _database;
  }

  Future<List<Map>> _processDatabase() async {
      final db = await database;
      print("Querying database");
      Future<List<Map>>  accountSummaryList;
      accountSummaryList = db.query("accounts");
      return accountSummaryList;
  }


  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('File Picker example app'),
        ),
        body: new Center(
            child: new Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: new SingleChildScrollView(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: new DropdownButton(
                          hint: new Text('LOAD PATH FROM'),
                          value: _pickingType,
                          items: <DropdownMenuItem>[
                            new DropdownMenuItem(
                              child: new Text('FROM AUDIO'),
                              value: FileType.audio,
                            ),
                            new DropdownMenuItem(
                              child: new Text('FROM IMAGE'),
                              value: FileType.image,
                            ),
                            new DropdownMenuItem(
                              child: new Text('FROM VIDEO'),
                              value: FileType.video,
                            ),
                            new DropdownMenuItem(
                              child: new Text('FROM ANY'),
                              value: FileType.any,
                            ),
                            new DropdownMenuItem(
                              child: new Text('CUSTOM FORMAT'),
                              value: FileType.custom,
                            ),
                          ],
                          onChanged: (value) => setState(() {
                            _pickingType = value;
                            if (_pickingType != FileType.custom) {
                              _controller.text = _extension = '';
                            }
                          })),
                    ),
                    new ConstrainedBox(
                      constraints: BoxConstraints.tightFor(width: 100.0),
                      child: _pickingType == FileType.custom
                          ? new TextFormField(
                        maxLength: 15,
                        autovalidate: true,
                        controller: _controller,
                        decoration: InputDecoration(labelText: 'File extension'),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          RegExp reg = new RegExp(r'[^a-zA-Z0-9]');
                          if (reg.hasMatch(value)) {
                            _hasValidMime = false;
                            return 'Invalid format';
                          }
                          _hasValidMime = true;
                          return null;
                        },
                      )
                          : new Container(),
                    ),
                    new ConstrainedBox(
                      constraints: BoxConstraints.tightFor(width: 200.0),
                      child: new SwitchListTile.adaptive(
                        title: new Text('Pick multiple files', textAlign: TextAlign.right),
                        onChanged: (bool value) => setState(() => _multiPick = value),
                        value: _multiPick,
                      ),
                    ),
                    new Padding(
                      padding: const EdgeInsets.only(top: 50.0, bottom: 20.0),
                      child: new RaisedButton(
                        onPressed: () => _openFileExplorer(),
                        child: new Text("Open file picker"),
                      ),
                    ),
                    new Builder(
                      builder: (BuildContext context) => _loadingPath
                          ? Padding(padding: const EdgeInsets.only(bottom: 10.0), child: const CircularProgressIndicator())
                          : _path != null || _paths != null
                          ? new Container(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: new Scrollbar(
                            child: new ListView.separated(
                              itemCount: _paths != null && _paths.isNotEmpty ? _paths.length : 1,
                              itemBuilder: (BuildContext context, int index) {
                                final bool isMultiPath = _paths != null && _paths.isNotEmpty;
                                final String name = 'File $index: ' + (isMultiPath ? _paths.keys.toList()[index] : _fileName ?? '...');
                                final path = isMultiPath ? _paths.values.toList()[index].toString() : _path;

                                return new ListTile(
                                  title: new Text(
                                    name,
                                  ),
                                  subtitle: new Text(path),
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => new Divider(),
                            )),
                      )
                          : new Container(),
                    ),
                    new Builder(
                      builder: (BuildContext context) => new Container(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: FutureBuilder<List<Map>>(
                                future: _processDatabase(),
                                builder: (BuildContext context, AsyncSnapshot<List<Map>> snapshot) {
                                    if (snapshot.hasData) {
                                        return ListView.builder(
                                                itemCount: snapshot.data.length,
                                                itemBuilder: (BuildContext context, int index) {
                                                    Map item = snapshot.data[index];
                                                    return ListTile(
                                                            title: Text(item["name"]),
                                                            //leading: Text(item.id.toString()),
                                                            //trailing: Checkbox(
                                                            //        onChanged: (bool value) {
                                                            //            DBProvider.db.blockClient(item);
                                                            //            setState(() {});
                                                            //        },
                                                            //        value: item.blocked,
                                                            //),
                                                    );
                                                },
                                        );
                                    } else {
                                        return Center(child: CircularProgressIndicator());
                                    }
                                },
                            ),
                        )
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }
}
