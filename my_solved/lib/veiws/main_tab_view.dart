import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/view_models/main_tab_view_model.dart';

class MainTabView extends StatelessWidget {
  const MainTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<MainTabViewModel>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: viewModel.widgetOptions.elementAt(viewModel.selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "Search",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: "Recommand",
            )
          ],
          currentIndex: viewModel.selectedIndex,
          selectedItemColor: Colors.green,
          onTap: viewModel.onItemTapped,
        ),
      ),
    );
  }
}
