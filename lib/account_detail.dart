import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:dartcash/gnc_account.dart';

class AccountDetailScreen extends StatelessWidget {
  // Declare a field that holds the Todo.
  final GncAccount account;
  NumberFormat currencyFormat;

  // In the constructor, require a Todo.
  AccountDetailScreen({Key key, @required this.account}) : super(key: key)
  {
    String symbol = NumberFormat.currency().simpleCurrencySymbol(account.commodity.mnemonic);
    currencyFormat = new NumberFormat.currency(symbol:symbol);
  }

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
                      subtitle: Text(account.splits[index].getDateAsString()),
                      trailing: Text(account.splits[index].getQuantityAsString(currencyFormat)),
                  );
                },
      ),
    );
  }
}

