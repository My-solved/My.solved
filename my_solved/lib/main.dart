import 'package:flutter/cupertino.dart';
import 'package:my_solved/pages/main_tab_page.dart';

void main() {
  runApp(CupertinoApp(
    title: 'MY.SOLVED',
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: MainTabPage(),
    );
  }
}
