import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:my_solved/views/setting_view.dart';
import 'package:my_solved/widgets/user_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../models/User.dart';
import '../models/user/Badges.dart';
import '../models/user/TagRatings.dart';
import '../models/user/Top_100.dart';

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
    String handle = userService.name;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: FutureBuilder(
              future: networkService.requestUser(handle),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _profileHeader(context, snapshot),
                      _profileDetail(context, snapshot),
                      _zandi(context, snapshot),
                      _top100(context, snapshot,
                          networkService.requestTop100(handle)),
                      _badges(context, networkService.requestBadges(handle)),
                      _tagChart(context, snapshot),
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

extension _HomeStateExtension on _HomeViewState {
  Widget _profileHeader(BuildContext context, AsyncSnapshot<User> snapshot) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        backgroundImage(context, snapshot),
        Align(
          alignment: Alignment.topRight,
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
        Positioned(
          bottom: -50,
          left: 20,
          child: profileImage(context, snapshot),
        ),
      ],
    );
  }

  Widget _profileDetail(BuildContext context, AsyncSnapshot<User> snapshot) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              solvedCount(context, snapshot),
              voteCount(context, snapshot),
              reverseRivalCount(context, snapshot)
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.start,
            children: [
              handle(context, snapshot),
              badge(context, snapshot),
              classes(context, snapshot),
            ],
          ),
          bio(context, snapshot),
        ],
      ),
    );
  }

  Widget _zandi(BuildContext context, AsyncSnapshot<User> snapshot) {
    return Consumer<UserService>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05),
          child: zandi(context, snapshot),
        );
      },
    );
  }

  Widget _top100(BuildContext context, AsyncSnapshot<User> snapshot,
      Future<Top_100> future) {
    int rating = snapshot.data?.rating ?? 0;
    int tier = snapshot.data?.tier ?? 0;
    int rank = snapshot.data?.rank ?? 0;

    String tierStr(int tier) {
      if (tier == 1) {
        return 'Bronze V';
      } else if (tier == 2) {
        return 'Bronze IV';
      } else if (tier == 3) {
        return 'Bronze III';
      } else if (tier == 4) {
        return 'Bronze II';
      } else if (tier == 5) {
        return 'Bronze I';
      } else if (tier == 6) {
        return 'Silver V';
      } else if (tier == 7) {
        return 'Silver IV';
      } else if (tier == 8) {
        return 'Silver III';
      } else if (tier == 9) {
        return 'Silver II';
      } else if (tier == 10) {
        return 'Silver I';
      } else if (tier == 11) {
        return 'Gold V';
      } else if (tier == 12) {
        return 'Gold IV';
      } else if (tier == 13) {
        return 'Gold III';
      } else if (tier == 14) {
        return 'Gold II';
      } else if (tier == 15) {
        return 'Gold I';
      } else if (tier == 16) {
        return 'Platinum V';
      } else if (tier == 17) {
        return 'Platinum IV';
      } else if (tier == 18) {
        return 'Platinum III';
      } else if (tier == 19) {
        return 'Platinum II';
      } else if (tier == 20) {
        return 'Platinum I';
      } else if (tier == 21) {
        return 'Diamond V';
      } else if (tier == 22) {
        return 'Diamond IV';
      } else if (tier == 23) {
        return 'Diamond III';
      } else if (tier == 24) {
        return 'Diamond II';
      } else if (tier == 25) {
        return 'Diamond I';
      } else if (tier == 26) {
        return 'Ruby V';
      } else if (tier == 27) {
        return 'Ruby IV';
      } else if (tier == 28) {
        return 'Ruby III';
      } else if (tier == 29) {
        return 'Ruby II';
      } else if (tier == 30) {
        return 'Ruby I';
      } else if (tier == 31) {
        return 'Master';
      } else {
        return 'Unrated';
      }
    }

    Widget top100Header(int rating, int tier, int rank, BuildContext context) {
      Color rankBoxColor(int rankNum) {
        if (rankNum == 1) {
          return Color(0xFFFFB028);
        } else if (rankNum < 11) {
          return Color(0xFF435F7A);
        } else if (rankNum < 101) {
          return Color(0xFFAD5600);
        } else {
          return Color(0xFFDDDFE0);
        }
      }

      Widget masterHandle(int rating, BuildContext context) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7cf9ff), Color(0xFFb491ff), Color(0xFFff7ca8)],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.srcATop,
          child: Text(
            'Master $rating',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.4 * 0.14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      return Container(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.015,
          top: MediaQuery.of(context).size.width * 0.4 * 0.05,
          right: MediaQuery.of(context).size.width * 0.015,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('lib/assets/icons/rating.svg',
                        color: Color(0xff8a8f95),
                        width: MediaQuery.of(context).size.width * 0.4 * 0.1),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      '레이팅',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.4 * 0.1,
                        color: Color(0xff8a8f95),
                      ),
                    ),
                  ],
                ),
                rating < 3000
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('${tierStr(tier)} ',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width *
                                    0.4 *
                                    0.14,
                                fontFamily: 'Pretendard',
                                color: ratingColor(rating),
                              )),
                          Text(
                            rating.toString(),
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width *
                                  0.4 *
                                  0.14,
                              fontFamily: 'Pretendard-ExtraBold',
                              fontWeight: FontWeight.bold,
                              color: ratingColor(rating),
                            ),
                          ),
                        ],
                      )
                    : masterHandle(rating, context),
              ],
            ),
            Spacer(),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: rankBoxColor(rank),
              ),
              padding: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
              child: Text(
                rank < 1000
                    ? '#$rank'
                    : '#${(rank / 1000).floor()},${rank % 1000}',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.4 * 0.11,
                  fontFamily: 'Pretendard-Regular',
                  fontWeight: FontWeight.bold,
                  color: rank == 1 || 100 < rank ? Colors.black : Colors.white,
                ),
              ),
            )
          ],
        ),
      );
    }

    Widget top100Box(BuildContext context, dynamic cur) {
      return CupertinoButton(
          padding: EdgeInsets.zero,
          color: Colors.transparent,
          onPressed: () {
            launchUrlString(
                'https://www.acmicpc.net/problem/${cur['problemId']}',
                mode: LaunchMode.externalApplication);
          },
          child: Tooltip(
              preferBelow: false,
              message: cur['titleKo'],
              textStyle: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.4 * 0.1,
                fontFamily: 'Pretendard-Regular',
                color: Colors.white,
              ),
              child: SvgPicture.asset('lib/assets/tiers/${cur['level']}.svg',
                  width: MediaQuery.of(context).size.width * 0.041)));
    }

    return FutureBuilder<Top_100>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          int count = snapshot.data?.count ?? 0;
          return Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.04,
              right: MediaQuery.of(context).size.width * 0.04,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey, width: 0.5),
            ),
            child: Column(
              children: [
                SizedBox(height: 5),
                top100Header(rating, tier, rank, context),
                SizedBox(height: 5),
                GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10,
                      childAspectRatio: 1,
                    ),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: count,
                    itemBuilder: (BuildContext context, int index) {
                      return top100Box(context, snapshot.data!.items[index]);
                    }),
                SizedBox(height: 10),
              ],
            ),
          );
        } else {
          return CupertinoActivityIndicator();
        }
      },
    );
  }

  Widget _badges(BuildContext context, Future<Badges> future) {
    return FutureBuilder<Badges>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            margin: EdgeInsets.only(top: 10),
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05),
            child: badges(context, snapshot),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget _tagChart(BuildContext context, AsyncSnapshot<User> userSnapshot) {
    return FutureBuilder<List<TagRatings>>(
      future: networkService.requestTagRatings(userSnapshot.data?.handle ?? ''),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            margin: EdgeInsets.only(top: 10),
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05),
            child: tagChart(context, snapshot, userSnapshot),
          );
        } else {
          return Container();
        }
      },
    );
  }
}
