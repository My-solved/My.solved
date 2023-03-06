import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:my_solved/widgets/user_widget.dart';
import 'package:provider/provider.dart';

class UserView extends StatefulWidget {
  const UserView({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  _UserViewState createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final UserService userService = UserService();
  final NetworkService networkService = NetworkService();

  @override
  Widget build(BuildContext context) {
    String username = widget.username;
    var navigationBar = CupertinoNavigationBar(
      leading: CupertinoNavigationBarBackButton(
        color: CupertinoColors.label,
        onPressed: () => Navigator.of(context).pop(),
      ),
      middle: Text(widget.username),
    );

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      navigationBar: navigationBar,
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: FutureBuilder(
            future: networkService.requestUser(username),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final Widget _zandi = zandi(
                    context, snapshot, networkService.requestStreak(username));
                final Widget _top100 = top100(
                    context, snapshot, networkService.requestTop100(username));
                final Widget _tagChart = tagChart(context, snapshot);
                final Widget _badges =
                badges(context, networkService.requestBadges(username));

                final PageController _pageController = PageController(
                  initialPage: 0,
                );

                return Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    profileHeader(context, snapshot),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.08),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery
                              .of(context)
                              .size
                              .width * 0.05),
                      margin: EdgeInsets.only(bottom: 10),
                      child: profileDetail(context, snapshot),
                    ),
                    const SizedBox(height: 10),
                    Consumer<UserService>(
                      builder: (context, userService, child) {
                        return CupertinoSlidingSegmentedControl(
                          children: const <int, Widget>{
                            0: Text('스트릭'),
                            1: Text('레이팅'),
                            2: Text('태그'),
                            3: Text('뱃지'),
                          },
                          groupValue: userService.currentUserTab,
                          onValueChanged: (int? value) {
                            if (value != null) {
                              userService.setCurrentUserTab(value);
                              _pageController.animateToPage(value,
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
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.9,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (int index) {
                          userService.setCurrentUserTab(index);
                        },
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .width * 0.05),
                            child: _zandi,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .width * 0.05),
                            child: _top100,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .width * 0.05),
                            child: _tagChart,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .width * 0.05),
                            child: _badges,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              return Center(
                child: CupertinoActivityIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }
}
