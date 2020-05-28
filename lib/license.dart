import 'package:flutter/material.dart';

class LicenseScreen extends StatelessWidget {
  final List<String> licenses = [
    '"New Pound Coins" by tim ellis is licensed under CC BY-NC 2.0'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Licenses'),
      ),
      body: ListView.builder(
        itemCount: licenses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(licenses[index]),
          );
        },
      ),
    );
  }
}
