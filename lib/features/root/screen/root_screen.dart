import 'package:contest_notification_repository/contest_notification_repository.dart';
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
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:user_repository/user_repository.dart';

class RootScreen extends StatelessWidget {
  final String handle;

  const RootScreen({super.key, required this.handle});

  @override
  Widget build(BuildContext context) {
    final rootBloc = RootBloc();
    rootBloc.add(VersionInfoInit());
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: rootBloc),
        BlocProvider(
          create: (context) => HomeBloc(
            userRepository: UserRepository(),
            sharedPreferencesRepository: SharedPreferencesRepository(),
            handle: handle,
          ),
        ),
        BlocProvider(
          create: (context) => SearchBloc(
            searchRepository: SearchRepository(),
            sharedPreferencesRepository: SharedPreferencesRepository(),
          ),
        ),
        BlocProvider(
          create: (context) => ContestBloc(
            contestNotificationRepository: ContestNotificationRepository(),
            contestRepository: ContestRepository(),
            sharedPreferencesRepository: SharedPreferencesRepository(),
          ),
        ),
      ],
      child: RootView(handle: handle),
    );
  }
}

class RootView extends StatefulWidget {
  const RootView({super.key, required this.handle});

  final String handle;

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
          endDrawer: HomeDrawer(
            handle: widget.handle,
            homeBloc: context.read<HomeBloc>(),
          ),
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
  final String handle;
  final HomeBloc homeBloc;

  const HomeDrawer({
    super.key,
    required this.handle,
    required this.homeBloc,
  });

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
                  handle,
                  style: MySolvedTextStyle.title3,
                ),
              ),
              Divider(color: MySolvedColor.divider),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SettingScreen(homeBloc: homeBloc),
                        ),
                      ),
                      style: ButtonStyle(
                        elevation: WidgetStateProperty.all(0),
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        minimumSize: WidgetStateProperty.all(Size.zero),
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                        splashFactory: NoSplash.splashFactory,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "설정",
                            style: MySolvedTextStyle.body2.copyWith(
                              color: MySolvedColor.font,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.read<AppBloc>().add(Logout()),
                      style: ButtonStyle(
                        elevation: WidgetStateProperty.all(0),
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        minimumSize: WidgetStateProperty.all(Size.zero),
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                        splashFactory: NoSplash.splashFactory,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "로그아웃",
                            style: MySolvedTextStyle.body2.copyWith(
                              color: MySolvedColor.font,
                            ),
                          ),
                        ],
                      ),
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
                    BlocBuilder<RootBloc, RootState>(
                      builder: (context, state) {
                        return Text(
                          (state is RootSuccess) ? state.version : "",
                          style: MySolvedTextStyle.body2.copyWith(
                            color: MySolvedColor.secondaryFont,
                          ),
                        );
                      },
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
