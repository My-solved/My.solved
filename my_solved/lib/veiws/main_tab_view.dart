import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/view_models/main_tab_view_model.dart';

class MainTabView extends StatelessWidget {
  const MainTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<MainTabViewModel>(context);

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: Color(0xff11ce3c),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book_fill),
            label: 'Problem',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            return viewModel.widgetOptions[index];
          },
        );
      },
    );
  }
}
