import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:my_solved/pages/login_page.dart';
import 'package:my_solved/providers/user/user_name.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<UserName>(
      create: (_) => UserName(),
    ),
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return CupertinoApp(
      home: LoginPage(),
      theme: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          fontFamily: "Pretendard",
          color: CupertinoColors.black,
        ),
      )),
    );
  }
}
