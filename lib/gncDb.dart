import 'package:sqflite/sqflite.dart';
import 'dart:collection'; 

class gncDb {
    Database _database;
    String _dbPath;

    gncDb(String _path) {
        _dbPath = _path;
    }

    Future<Database> get database async {
        if (_database == null) {
            _database = await initDB();
        }

        return _database;
    }

    Future<Database> initDB() async {
        print("Opening database: " + _dbPath);
        return openDatabase(_dbPath, version: 1, 
                onOpen: (db) { }, 
                onCreate: (Database db, int version) async {
                    print("Created database connection");
                });
    }

    Future<List<Account>> processDatabase() async {
        Database db = await database;
        print("Querying database");
        Account rootAccount;
        final Map<String, Account> accountMap = {}; // map with key=guid
        List<Map>  accountList = await db.query("accounts");

        accountList.forEach((account) {
          Account newAcc = Account.fromMap(account);
          accountMap[newAcc.guid] = newAcc;
        });

        print("Creating tree...");
        accountMap.forEach((guid, account) {
          if (account.parent_guid != null) {
            print("Processing account " + account.name + ": adding as child to account " + accountMap[account.parent_guid].name);
            accountMap[ account.parent_guid ].addChild(account);
          }
          else if (account.name == "Root Account") {
            rootAccount = account;
          }
        });
        print("Done creating tree...");

        print(rootAccount.name);
        print(rootAccount.children.length);

        List<Map>  accountSummaryList;
        accountSummaryList = await db.rawQuery('''
                Select
                  Sum(splits.value_num) / 100.0 as balance,
                  accounts.guid as guid
                From
                  accounts Left Outer Join
                  splits On accounts.guid = splits.account_guid
                Group By
                  accounts.guid
                ''');

        accountSummaryList.forEach((account) {
           if (account["balance"] != null) accountMap[account["guid"]].balance = account["balance"];
        });
        return rootAccount.children.toList();
    }

}

class Account 
{
  Account(this.guid, this.parent_guid, this.name, this.children, [this.balance=0]);

  final String guid;
  final String parent_guid;
  final String name;
  double balance = 0;
  final SplayTreeSet<Account> children;

  void addChild(Account child) 
  {
    this.children.add(child);
  }

  static Account fromMap(Map m) 
  {
    Account newAcc = Account(m["guid"], m["parent_guid"], m["name"], SplayTreeSet((Account a, Account b) => a.name.compareTo(b.name)));
    return newAcc;
  }

  double get hierBalance
  {
      double b = balance;
      this.children.forEach((c) => b += c.hierBalance);
      return b;
  }
}

