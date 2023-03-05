import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/widgets/user_widget.dart';

class UserView extends StatefulWidget {
  const UserView({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  _UserViewState createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final NetworkService networkService = NetworkService();
  int _selectedSegment = 0;

  void _updateSelectedSegment(int value) {
    setState(() {
      _selectedSegment = value;
    });
  }

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
                final Widget _zandi = zandi(context, snapshot);
                final Widget _top100 = top100(
                    context, snapshot, networkService.requestTop100(username));
                final Widget _tagChart = tagChart(context, snapshot);
                final Widget _badges =
                    badges(context, networkService.requestBadges(username));

                return Column(
                  children: <Widget>[
                    profileHeader(context, snapshot),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05),
                      margin: EdgeInsets.only(bottom: 10),
                      child: profileDetail(context, snapshot),
                    ),
                    CupertinoTabBar(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                            style: BorderStyle.solid),
                      ),
                      items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                            icon: SvgPicture.asset(
                              'lib/assets/icons/streak.svg',
                              color: _selectedSegment == 0
                                  ? CupertinoTheme.of(context).main
                                  : Colors.grey,
                              height: 30,
                            ),
                            label: 'Profile'),
                        BottomNavigationBarItem(
                            icon: SvgPicture.asset(
                              'lib/assets/icons/rating.svg',
                              color: _selectedSegment == 1
                                  ? CupertinoTheme.of(context).main
                                  : Colors.grey,
                              height: 30,
                            ),
                            label: 'AC Rating'),
                        BottomNavigationBarItem(
                            icon: SvgPicture.asset(
                              'lib/assets/icons/tag.svg',
                              color: _selectedSegment == 2
                                  ? CupertinoTheme.of(context).main
                                  : Colors.grey,
                              height: 30,
                            ),
                            label: 'Tags'),
                        BottomNavigationBarItem(
                            icon: SvgPicture.asset(
                              'lib/assets/icons/badge.svg',
                              color: _selectedSegment == 3
                                  ? CupertinoTheme.of(context).main
                                  : Colors.grey,
                              height: 30,
                            ),
                            label: 'Badges'),
                      ],
                      onTap: (value) {
                        _updateSelectedSegment(value);
                      },
                      currentIndex: _selectedSegment,
                      backgroundColor: Colors.white,
                      activeColor: CupertinoTheme.of(context).main,
                      inactiveColor: Colors.grey,
                    ),
                    Container(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.05,
                            vertical: 20),
                        child: Builder(
                          builder: (context) {
                            switch (_selectedSegment) {
                              case 0:
                                return _zandi;
                              case 1:
                                return _top100;
                              case 2:
                                return _tagChart;
                              case 3:
                                return _badges;
                              default:
                                return Container();
                            }
                          },
                        ))
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
