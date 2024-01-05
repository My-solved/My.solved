import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/root/bloc/root_bloc.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RootBloc(),
      child: RootView(),
    );
  }
}

class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> bottomNavItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_filled),
        label: "Home",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: "Search",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month),
        label: "contest",
      ),
    ];
    List<Widget> bottomNaviScreen = [
      Text("Home"),
      Text("Search"),
      Text("Contest"),
    ];
    return BlocBuilder<RootBloc, RootState>(
      builder: (context, state) {
        return Scaffold(
          body: Center(
            child: bottomNaviScreen.elementAt(state.tabIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: bottomNavItems,
            currentIndex: state.tabIndex,
            selectedItemColor: MySolvedColor.main,
            selectedLabelStyle: MySolvedTextStyle.caption2,
            unselectedItemColor: MySolvedColor.bottomNavigationBarUnselected,
            unselectedLabelStyle: MySolvedTextStyle.caption2,
            onTap: (index) {
              context
                  .read<RootBloc>()
                  .add(NavigationBarItemTapped(tabIndex: index));
            },
          ),
        );
      },
    );
  }
}
