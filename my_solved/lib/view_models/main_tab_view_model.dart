import 'package:flutter/material.dart';
import 'package:my_solved/pages/search_page.dart';

class MainTabViewModel with ChangeNotifier {
  int selectedIndex = 0;

  final List<Widget> widgetOptions = <Widget>[
    Text("WIP"),
    SearchPage(),
    Text("WIP"),
  ];

  void onItemTapped(int index) {
    selectedIndex = index;
    notifyListeners();
  }
}
