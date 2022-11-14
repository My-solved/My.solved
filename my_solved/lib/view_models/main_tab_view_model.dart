import 'package:flutter/material.dart';
import 'package:my_solved/pages/home_page.dart';
import 'package:my_solved/pages/search_page.dart';

class MainTabViewModel with ChangeNotifier {
  final List<Widget> widgetOptions = <Widget>[
    HomePage(),
    SearchPage(),
  ];
}
