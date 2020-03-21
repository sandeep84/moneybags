class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
}

static Database _database;

Future<Database> get database async {
    if (_database != null)
        return _database;

    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
}
