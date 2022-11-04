import 'package:flutter/material.dart';
import 'package:my_solved/pages/main_tab_page.dart';

void main() {
  runApp(MaterialApp(
    title: 'MY.SOLVED',
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: null,
        body: MainTabPage(),
      ),
    );
  }
}
