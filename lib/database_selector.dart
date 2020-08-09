import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginPage extends StatefulWidget {
  final FlutterSecureStorage storage;

  LoginPage({Key key, @required this.storage}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _LoginPageState();
}

class _LoginData {
  String host = '';
  String port = '';
  String user = '';
  String password = '';
  String databaseName = '';
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  _LoginData _data = new _LoginData();
  String dbType = 'sqlite';

  void sqliteChooseFile() async {
    // First validate form.
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      String dbPath;
      try {
        if (await Permission.storage.request().isGranted) {
          dbPath = await FilePicker.getFilePath(type: FileType.any);
        }
      } on PlatformException catch (e) {
        print("Unsupported operation" + e.toString());
      }

      widget.storage.write(key: 'dbType', value: dbType);
      if (dbPath != null) {
        widget.storage.write(key: 'dbPath', value: dbPath);
      }
    }

    Navigator.pop(context);
  }

  void postgresSubmit() {
    // First validate form.
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      widget.storage.write(key: 'dbType', value: dbType);
      widget.storage.write(key: 'host', value: _data.host);
      widget.storage.write(key: 'port', value: _data.port);
      widget.storage.write(key: 'user', value: _data.user);
      widget.storage.write(key: 'password', value: _data.password);
      widget.storage.write(key: 'databaseName', value: _data.databaseName);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Login'),
      ),
      body: new Container(
          padding: new EdgeInsets.all(20.0),
          child: new Form(
            key: this._formKey,
            child: new ListView(
              children: <Widget>[
                    new DropdownButtonFormField(
                        items: [
                          DropdownMenuItem(
                              child: Text('SQLite file'), value: 'sqlite'),
                          DropdownMenuItem(
                              child: Text('Postgresql database'),
                              value: 'postgresql'),
                        ],
                        hint: Text('Database type'),
                        onChanged: (value) {
                          setState(() {
                            dbType = value;
                          });
                        }),
                  ] +
                  formFields(dbType),
            ),
          )),
    );
  }

  List<Widget> formFields(String dbType) {
    final Size screenSize = MediaQuery.of(context).size;

    if (dbType == 'sqlite') {
      return <Widget>[
        new Container(
          width: screenSize.width,
          child: new RaisedButton(
            child: new Text(
              'Choose SQLite file',
              style: new TextStyle(color: Colors.white),
            ),
            onPressed: this.sqliteChooseFile,
            color: Colors.blue,
          ),
          margin: new EdgeInsets.only(top: 20.0),
        )
      ];
    } else if (dbType == 'postgresql') {
      return <Widget>[
        new TextFormField(
            decoration: new InputDecoration(
                hintText: 'hostname', labelText: 'Host URL'),
            onSaved: (String value) {
              this._data.host = value;
            }),
        new TextFormField(
            decoration:
                new InputDecoration(hintText: 'port', labelText: 'Port number'),
            onSaved: (String value) {
              this._data.port = value;
            }),
        new TextFormField(
            decoration: new InputDecoration(
                hintText: 'username', labelText: 'User name'),
            onSaved: (String value) {
              this._data.user = value;
            }),
        new TextFormField(
            obscureText: true, // Use secure text for passwords.
            decoration: new InputDecoration(
                hintText: 'Password', labelText: 'Enter your password'),
            onSaved: (String value) {
              this._data.password = value;
            }),
        new TextFormField(
            decoration: new InputDecoration(
                hintText: 'database', labelText: 'Database name'),
            onSaved: (String value) {
              this._data.databaseName = value;
            }),
        new Container(
          width: screenSize.width,
          child: new RaisedButton(
            child: new Text(
              'Login',
              style: new TextStyle(color: Colors.white),
            ),
            onPressed: this.postgresSubmit,
            color: Colors.blue,
          ),
          margin: new EdgeInsets.only(top: 20.0),
        )
      ];
    }

    return <Widget>[];
  }
}
