import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:dartcash/gnc_account.dart';

class AccountDetailScreen extends StatelessWidget {
  // Declare a field that holds the Todo.
  final GncAccount account;

  // In the constructor, require a Todo.
  AccountDetailScreen({Key key, @required this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
      ),
      body: ListView.builder(
        itemCount: account.splits.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(account.splits[index].description),
            subtitle: Text(DateFormat.yMd().format(account.splits[index].date)),
            trailing: Text(
              account.commodity
                  .format(account.splits[index].quantity * account.sign),
              style: account.splits[index].quantity < 0
                  ? TextStyle(color: Colors.red)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
