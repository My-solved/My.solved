import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_solved/veiws/search_view.dart';

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
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: TextButton(
            child: Text('Search View Test'),
            onPressed: () {
              Navigator.push(context,
                  CupertinoPageRoute(builder: (context) => SearchView()));
            },
          ),
        ),
      ),
    );
  }
}
