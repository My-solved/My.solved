import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/models/user/Top_100.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:my_solved/views/setting_view.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  UserService userService = UserService();
  NetworkService networkService = NetworkService();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FutureBuilder(
                future: networkService.requestUser(userService.name),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _profileImage(context, snapshot),
                        profileInformation(userService.name, context, snapshot),
                        streak(context, snapshot),
                        // badge(context),
                        FutureBuilder(
                          future:
                              networkService.requestBadges(userService.name),
                          builder: (context, builder) {
                            if (snapshot.hasData) {
                              return _badge(context);
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Error'),
                              );
                            } else {
                              return Center(
                                child: CupertinoActivityIndicator(),
                              );
                            }
                          },
                        ),
                        _top100(),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error'),
                    );
                  } else {
                    return Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _HomeStateExtension on _HomeViewState {
  Widget _profileImage(BuildContext context, AsyncSnapshot<User> snapshot) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width,
          height: 150,
          child: backgroundImage(context, snapshot),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Container(
            child: CupertinoButton(
              child: Icon(
                CupertinoIcons.gear_solid,
                color: CupertinoColors.white,
              ),
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (BuildContext context) {
                    return SettingView();
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 100,
          left: 20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              shape: BoxShape.circle,
            ),
            child: foregroundImage(context, snapshot),
          ),
        ),
      ],
    );
  }

  Widget backgroundImage(BuildContext context, AsyncSnapshot<User> snapshot) {
    return ExtendedImage.network(
      snapshot.data?.background['backgroundImageUrl'] ?? '',
      cache: true,
      fit: BoxFit.fitHeight,
    );
  }

  Widget foregroundImage(BuildContext context, AsyncSnapshot<User> snapshot) {
    return ClipOval(
      child: ExtendedImage.network(
        snapshot.data?.profileImageUrl ??
            'https://static.solved.ac/misc/360x360/default_profile.png',
        cache: true,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget profileInformation(
      String name, BuildContext context, AsyncSnapshot<User> snapshot) {
    return Container(
      margin: EdgeInsets.only(top: 50),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            name,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 8),
          Text(
            // snapshot.data?.bio ?? '자기소개를 설정하지 않았습니다.',
            snapshot.data?.bio == ''
                ? '자기소개를 설정하지 않았습니다.'
                : snapshot.data?.bio ?? '자기소개를 설정하지 않았습니다.',
            style: TextStyle(
                fontSize: 14, color: CupertinoTheme.of(context).fontGray),
          ),
          SizedBox(height: 20),
          Text(
            getTier(snapshot.data?.tier ?? 0),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemYellow,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'cars0106@naver.com',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoTheme.of(context).fontGray,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                snapshot.data?.solvedCount.toString() ?? '',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                ' 문제 해결',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(width: 10),
              Text(
                snapshot.data?.reverseRivalCount.toString() ?? '',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '명의 라이벌',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 40),
          Container(
              padding: EdgeInsets.only(
                left: 20,
                top: 10,
                right: 20,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).dividerGray,
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              child: Text('#' + (snapshot.data?.rating.toString() ?? '')))
        ],
      ),
    );
  }

  Widget streak(BuildContext context, AsyncSnapshot<User> snapshot) {
    return Consumer<UserService>(
      builder: (context, provider, child) {
        // return Text(Provider.of<UserManager>(context).streakTheme.toString());
        return Stack(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20, right: 20),
              padding: EdgeInsets.only(bottom: 10),
              child: SvgPicture.network(
                getStreakUrl(Provider.of<UserService>(context).streakTheme),
                width: MediaQuery.of(context).size.width,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _badge(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).backgroundGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '뱃지',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoTheme.of(context).fontGray,
            ),
          ),
          SizedBox(height: 10),
          Text('4개'),
          SizedBox(height: 10),
          Row(
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                color: CupertinoColors.inactiveGray,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _top100() {
    return FutureBuilder<Top_100>(
      future: networkService.requestTop100(userService.name),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).backgroundGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Top 100',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoTheme.of(context).fontGray,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: <Widget>[
                    Text('전체 수'),
                    Spacer(),
                    Text((snapshot.data?.items.length ?? 0).toString() + '개'),
                  ],
                ),
                Wrap(
                  direction: Axis.horizontal,
                )
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error');
        } else {
          return Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }

  String getStreakUrl(int theme) {
    String nickname = userService.name;
    String themeString = '';
    if (theme == 0) {
      themeString = 'warm';
    } else if (theme == 1) {
      themeString = 'cold';
    } else if (theme == 2) {
      themeString = 'dark';
    }
    return 'http://mazandi.herokuapp.com/api?handle=$nickname&theme=$themeString';
  }

  String getTier(int tier) {
    if (tier < 6) {
      return 'Bronze ${6 - tier % 5}';
    } else if (tier < 11) {
      return 'Silver ${6 - tier % 5}';
    } else if (tier < 16) {
      return 'Gold ${6 - tier % 5}';
    } else if (tier < 21) {
      return 'Platinum ${6 - tier % 5}';
    } else if (tier < 26) {
      return 'Diamond ${6 - tier % 5}';
    } else if (tier < 31) {
      return 'Ruby ${6 - tier % 5}';
    } else {
      return 'Master';
    }
  }
}
