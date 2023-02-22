import 'package:flutter/cupertino.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/views/contest_view.dart';
import 'package:my_solved/views/home_view.dart';
import 'package:my_solved/views/search_view.dart';

class MainTabView extends StatelessWidget {
  MainTabView({Key? key}) : super(key: key);

  final List<Widget> options = <Widget>[
    const HomeView(),
    const SearchView(),
    const ContestView(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      resizeToAvoidBottomInset: false,
      tabBar: CupertinoTabBar(
        activeColor: CupertinoTheme.of(context).main,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar), label: 'Contest'),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            return options[index];
          },
        );
      },
    );
  }
}
