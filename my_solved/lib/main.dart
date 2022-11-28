import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:my_solved/pages/login_page.dart';

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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return CupertinoApp(
      home: LoginPage(),
    );
  }
}
