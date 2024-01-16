import 'package:contest_repository/contest_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/app/bloc/app_bloc.dart';
import 'package:my_solved/components/atoms/button/my_solved_text_button.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/contest/bloc/contest_bloc.dart';
import 'package:my_solved/features/contest/screen/contest_screen.dart';
import 'package:my_solved/features/home/bloc/home_bloc.dart';
import 'package:my_solved/features/home/screen/home_screen.dart';
import 'package:my_solved/features/root/bloc/root_bloc.dart';
import 'package:my_solved/features/search/bloc/search_bloc.dart';
import 'package:my_solved/features/search/screen/search_screen.dart';
import 'package:my_solved/features/setting/screen/setting_screen.dart';
import 'package:search_repository/search_repository.dart';

class RootScreen extends StatelessWidget {
  final String handle;

  const RootScreen({required this.handle, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RootBloc(handle: handle),
        ),
        BlocProvider(
          create: (context) => HomeBloc(),
        ),
        BlocProvider(
          create: (context) => SearchBloc(searchRepository: SearchRepository()),
        ),
        BlocProvider(
          create: (context) =>
              ContestBloc(contestRepository: ContestRepository()),
        ),
      ],
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      HomeScreen(
        scaffoldKey: _scaffoldKey,
      ),
      SearchScreen(),
      ContestScreen(),
    ];
    return BlocBuilder<RootBloc, RootState>(
      bloc: BlocProvider.of<RootBloc>(context),
      builder: (context, state) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: MySolvedColor.background,
          endDrawer: HomeDrawer(),
          body: bottomNaviScreen.elementAt(state.tabIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: bottomNavItems,
            currentIndex: state.tabIndex,
            backgroundColor: MySolvedColor.background,
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

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      backgroundColor: MySolvedColor.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 24,
            horizontal: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Text(
                  context.read<RootBloc>().handle,
                  style: MySolvedTextStyle.title3,
                ),
              ),
              Divider(color: MySolvedColor.divider),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MySolvedTextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingScreen()),
                      ),
                      text: "설정",
                    ),
                    SizedBox(height: 16),
                    MySolvedTextButton(
                      onPressed: () => context.read<AppBloc>().add(Logout()),
                      text: "로그아웃",
                    ),
                  ],
                ),
              ),
              Divider(color: MySolvedColor.divider),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("버전 정보", style: MySolvedTextStyle.body2),
                    Text(
                      "1.0.0",
                      style: MySolvedTextStyle.body2.copyWith(
                        color: MySolvedColor.secondaryFont,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
