import 'package:flutter/cupertino.dart';
import 'package:my_solved/models/user.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:my_solved/widgets/user_widget.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final UserService userService = UserService();
  final NetworkService networkService = NetworkService();

  @override
  Widget build(BuildContext context) {
    String handle = userService.name;

    networkService.requestSiteStats().then((value) {
      userService.setUserCount(value.userCount);
    });

    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: FutureBuilder(
              future: networkService.requestUser(handle),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final User? user = snapshot.data;
                  final Widget widgetGrass = grass(context, snapshot,
                      networkService.requestStreak(user?.handle ?? ''));
                  final Widget widgetTop100 = top100(context, snapshot,
                      networkService.requestTop100(user?.handle ?? ''));
                  final Widget widgetTagChart = tagChart(context, snapshot);
                  final Widget widgetBadges = badges(context,
                      networkService.requestBadges(user?.handle ?? ''));

                  late Widget widgetBackground = backgroundImage(
                      context,
                      networkService
                          .requestBackground(user?.backgroundId ?? ''));

                  late Widget widgetBadge;
                  if (user?.badgeId != null) {
                    widgetBadge = badge(context,
                        networkService.requestBadge(user?.badgeId ?? ''));
                  } else {
                    widgetBadge = SizedBox.shrink();
                  }

                  final PageController pageController = PageController(
                    initialPage: userService.currentHomeTab,
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      profileHeader(context, snapshot, widgetBackground),
                      const SizedBox(height: 50),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.05),
                        margin: EdgeInsets.only(bottom: 20),
                        child: profileDetail(context, snapshot, widgetBadge),
                      ),
                      Consumer<UserService>(
                        builder: (context, userService, child) {
                          return CupertinoSlidingSegmentedControl(
                            children: const <int, Widget>{
                              0: Text('스트릭'),
                              1: Text('레이팅'),
                              2: Text('태그'),
                              3: Text('뱃지'),
                            },
                            groupValue: userService.currentHomeTab,
                            onValueChanged: (int? value) {
                              if (value != null) {
                                userService.setCurrentHomeTab(value);
                                pageController.animateToPage(value,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease);
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Container(
                        alignment: Alignment.topCenter,
                        height: MediaQuery.of(context).size.height,
                        child: PageView(
                          controller: pageController,
                          onPageChanged: (int index) {
                            userService.setCurrentHomeTab(index);
                          },
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.05),
                              child: widgetGrass,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.05),
                              child: widgetTop100,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.05),
                              child: widgetTagChart,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.05),
                              child: widgetBadges,
                            )
                          ],
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return Center(child: CupertinoActivityIndicator());
              },
            )),
      ),
    );
  }
}
