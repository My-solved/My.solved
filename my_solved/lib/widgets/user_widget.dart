import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/models/user/Top_100.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../models/User.dart';
import '../models/user/Badges.dart';
import '../models/user/Grass.dart';
import '../widgets/ImageShadow.dart';

Widget backgroundImage(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      child: ExtendedImage.network(
    snapshot.data?.background['backgroundImageUrl'] ?? '',
    cache: true,
    fit: BoxFit.fitWidth,
  ));
}

Widget profileImage(BuildContext context, AsyncSnapshot<User> snapshot) {
  return Card(
    elevation: 20,
    shadowColor: levelColor(snapshot.data?.tier ?? 0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(100),
    ),
    child: SizedBox(
      width: 100,
      height: 100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: ExtendedImage.network(
          snapshot.data?.profileImageUrl ??
              'https://static.solved.ac/misc/360x360/default_profile.png',
          cache: true,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

Widget handle(BuildContext context, AsyncSnapshot<User> snapshot) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        snapshot.data?.handle ?? '',
        style: TextStyle(
          color: CupertinoColors.black,
          // color: CupertinoTheme.of(context).textTheme.textStyle.color,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(
        height: 5,
      ),
      bio(context, snapshot),
    ],
  );
}

// 소속
Widget organizations(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Row(children: [
        SvgPicture.asset(
          'lib/assets/icons/hat.svg',
          width: 15,
          height: 15,
        ),
        SizedBox(width: 5),
        Container(
          width: 180,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: snapshot.data!.organizations.isEmpty
                      ? '소속 없음'
                      : snapshot.data?.organizations[0]['name'] ?? '',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        )
      ]));
}

// 자기소개
Widget bio(BuildContext context, AsyncSnapshot<User> snapshot) {
  return snapshot.data?.bio?.isEmpty ?? true
      ? SizedBox(
          height: 1,
        )
      : Text(
          snapshot.data?.bio ?? '',
        );
}

// 클래스
Widget classes(BuildContext context, AsyncSnapshot<User> snapshot) {
  String userClass = snapshot.data?.userClass.toString() ?? '';
  if (snapshot.data?.classDecoration == "silver") {
    userClass += 's';
  } else if (snapshot.data?.classDecoration == "gold") {
    userClass += 'g';
  }

  return SvgPicture.asset(
    'lib/assets/classes/c$userClass.svg',
    width: 50,
    height: 50,
  );
}

// 티어
Widget tiers(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: SvgPicture.asset(
          'lib/assets/tiers/${snapshot.data?.tier}.svg',
          width: 40,
          height: 40,
        ),
      ));
}

// 레이팅
Widget rating(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Text(
      snapshot.data?.rating.toString() ?? '',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        color: Colors.grey,
      ),
    ),
  );
}

// 푼 문제 수
Widget solvedCount(BuildContext context, AsyncSnapshot<User> snapshot) {
  return Container(
    width: MediaQuery.of(context).size.width / 5,
    clipBehavior: Clip.none,
    child: Column(
      children: [
        Text(
          snapshot.data?.solvedCount.toString() ?? '',
          style: TextStyle(
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.width * 0.048,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '해결',
          style: TextStyle(
            color: Colors.grey,
            fontSize: MediaQuery.of(context).size.width * 0.038,
          ),
        ),
      ],
    ),
  );
}

// 기여 수
Widget voteCount(BuildContext context, AsyncSnapshot<User> snapshot) {
  return Container(
    width: MediaQuery.of(context).size.width / 5,
    clipBehavior: Clip.none,
    child: Column(
      children: [
        Text(
          snapshot.data?.voteCount.toString() ?? '',
          style: TextStyle(
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.width * 0.048,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '기여',
          style: TextStyle(
            color: Colors.grey,
            fontSize: MediaQuery.of(context).size.width * 0.038,
          ),
        ),
      ],
    ),
  );
}

// 라이벌 수
Widget reverseRivalCount(BuildContext context, AsyncSnapshot<User> snapshot) {
  return Container(
    width: MediaQuery.of(context).size.width / 5,
    clipBehavior: Clip.none,
    child: Column(
      children: [
        Text(
          snapshot.data?.reverseRivalCount.toString() ?? '',
          style: TextStyle(
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.width * 0.048,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '라이벌',
          style: TextStyle(
            color: Colors.grey,
            fontSize: MediaQuery.of(context).size.width * 0.038,
          ),
        ),
      ],
    ),
  );
}

// 랭크
Widget rank(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          snapshot.data?.rank.toString() ?? '',
        ),
      ));
}

// 잔디 테마
String zandiUrl(String handle) {
  int zandiTheme = UserService().getZandiTheme();
  String theme = '';
  if (zandiTheme == 0) {
    theme = 'warm';
  } else if (zandiTheme == 1) {
    theme = 'cold';
  } else if (zandiTheme == 2) {
    theme = 'dark';
  }
  return 'http://mazandi.herokuapp.com/api?handle=$handle&theme=$theme';
}

// 잔디
Widget zandi(BuildContext context, AsyncSnapshot<User> snapshot) {
  int zandiTheme = UserService().getZandiTheme();
  return Stack(
    children: [
      SvgPicture.asset(
        zandiTheme == 2 ? 'lib/assets/zandi_dark.svg' : 'lib/assets/zandi.svg',
        width: MediaQuery.of(context).size.width,
      ),
      SvgPicture.network(
        zandiUrl(snapshot.data?.handle ?? ''),
        width: MediaQuery.of(context).size.width,
      ),
      Positioned(
        left: MediaQuery.of(context).size.width * 0.8 * 0.07,
        bottom: MediaQuery.of(context).size.width * 0.4 * 0.91,
        child: Container(
            color: zandiTheme == 2 ? Color(0xFF3f3f3f) : Colors.white,
            width: MediaQuery.of(context).size.width * 0.82,
            height: MediaQuery.of(context).size.width * 0.4 * 0.15,
            child: Row(
              children: [
                SvgPicture.asset(
                  'lib/assets/icons/streak.svg',
                  width: MediaQuery.of(context).size.width * 0.4 * 0.10,
                  height: MediaQuery.of(context).size.width * 0.4 * 0.10,
                  color: zandiTheme == 2 ? Colors.white : Color(0xff8a8f95),
                ),
                SizedBox(width: 5),
                Text(
                  // 'Rating: ${snapshot.data?.rating}',
                  '스트릭',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.4 * 0.10,
                    // fontWeight: FontWeight.bold,
                    color: zandiTheme == 2 ? Colors.white : Color(0xff8a8f95),
                  ),
                ),
                Spacer(),
                maxStreak(context, snapshot),
                SizedBox(width: MediaQuery.of(context).size.width * 0.4 * 0.1),
              ],
            )),
      ),
    ],
  );
}

// 최대 연속 문제 해결일 수
Widget maxStreak(BuildContext context, AsyncSnapshot<User> snapshot) {
  int zandiTheme = UserService().getZandiTheme();
  return Text(
    '최장 ${snapshot.data?.maxStreak.toString()}일',
    style: TextStyle(
      fontSize: MediaQuery.of(context).size.width * 0.4 * 0.1,
      // fontWeight: FontWeight.bold,
      color: zandiTheme == 2 ? Colors.white : Color(0xff8a8f95),
    ),
  );
}

// 현재 연속 문제 해결일 수
Widget currentStreak(BuildContext context, AsyncSnapshot<Grass> snapshot) {
  int zandiTheme = UserService().getZandiTheme();
  return Text(
    '현재 ${snapshot.data?.currentStreak}일',
    style: TextStyle(
      fontSize: MediaQuery.of(context).size.width * 0.4 * 0.1,
      // fontWeight: FontWeight.bold,
      color: zandiTheme == 2 ? Colors.white : Color(0xff8a8f95),
    ),
  );
}

// 경험치
Widget exp(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          snapshot.data?.exp.toString() ?? '',
        ),
      ));
}

// 배지
Widget badge(BuildContext context, AsyncSnapshot<User> snapshot) {
  return snapshot.data?.badge == null
      ? SizedBox()
      : ImageShadow(
          opacity: 0.2,
          child: ExtendedImage.network(
            snapshot.data?.badge['badgeImageUrl']
                .replaceAll('profile_badge/', 'profile_badge/120x120/'),
            width: 50,
            height: 50,
            cache: true,
            loadStateChanged: (ExtendedImageState state) {
              switch (state.extendedImageLoadState) {
                case LoadState.loading:
                  return CupertinoActivityIndicator();
                case LoadState.completed:
                  return null;
                case LoadState.failed:
                  return Icon(Icons.error);
              }
            },
          ));
}

Widget top100(
    BuildContext context, AsyncSnapshot<Top_100> snapshot, User? user) {
  int rating = user?.rating ?? 0;
  int tier = user?.tier ?? 0;
  int rank = user?.rank ?? 0;
  int count = snapshot.data!.count;

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
                            fontSize:
                                MediaQuery.of(context).size.width * 0.4 * 0.14,
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
        color: Colors.white,
        onPressed: () {
          launchUrlString('https://www.acmicpc.net/problem/${cur['problemId']}',
              mode: LaunchMode.externalApplication);
        },
        child: Tooltip(
            message: cur['titleKo'],
            textStyle: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.4 * 0.1,
              fontFamily: 'Pretendard-Regular',
              color: Colors.white,
            ),
            child: SvgPicture.asset('lib/assets/tiers/${cur['level']}.svg',
                width: MediaQuery.of(context).size.width * 0.041)));
  }

  return Container(
    width: MediaQuery.of(context).size.width,
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
}

Widget badges(BuildContext context, AsyncSnapshot<Badges> snapshot) {
  int count = snapshot.data!.count;

  List<dynamic> achievements = [];
  List<dynamic> seasons = [];
  List<dynamic> events = [];
  List<dynamic> contests = [];

  for (int i = 0; i < count; i++) {
    if (snapshot.data!.items[i]['badgeCategory'] == 'achievement') {
      achievements.add(snapshot.data!.items[i]);
    } else if (snapshot.data!.items[i]['badgeCategory'] == 'season') {
      seasons.add(snapshot.data!.items[i]);
    } else if (snapshot.data!.items[i]['badgeCategory'] == 'event') {
      events.add(snapshot.data!.items[i]);
    } else if (snapshot.data!.items[i]['badgeCategory'] == 'contest') {
      contests.add(snapshot.data!.items[i]);
    }
  }

  achievements.sort((a, b) => a['badgeId'].compareTo(b['badgeId']));

  Widget badgeTier(BuildContext context, dynamic badge, int idx) {
    String tier = badge['badgeTier'];
    Color tierColor = Colors.white;
    if (tier == 'bronze') {
      tierColor = Color(0xffad5600);
    } else if (tier == 'silver') {
      tierColor = Color(0xff435f7a);
    } else if (tier == 'gold') {
      tierColor = Color(0xffec9a00);
    } else if (tier == 'master') {
      tierColor = Color(0xffff99d8);
    }

    return Tooltip(
      textAlign: TextAlign.start,
      richMessage: TextSpan(children: [
        TextSpan(
            text: '${badge['displayName']}\n',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              fontFamily: 'Pretendard-Regular',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        TextSpan(
            text: '${badge['displayDescription']}',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              fontFamily: 'Pretendard',
              color: Colors.white,
            )),
      ]),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ImageShadow(
              opacity: 0.2,
              child: ExtendedImage.network(
                'https://static.solved.ac/profile_badge/120x120/${badge['badgeId']}.png',
                width: MediaQuery.of(context).size.width * 0.13,
                fit: BoxFit.cover,
                cache: true,
                loadStateChanged: (ExtendedImageState state) {
                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    case LoadState.completed:
                      return null;
                    case LoadState.failed:
                      return Center(
                        child: Icon(Icons.error),
                      );
                  }
                },
              )),
          Positioned(
              bottom: -5,
              right: -1,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.02,
                  height: MediaQuery.of(context).size.width * 0.02,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.014,
                    height: MediaQuery.of(context).size.width * 0.014,
                    decoration: BoxDecoration(
                      color: tierColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget badgeAchievements(
      BuildContext context, AsyncSnapshot<Badges> snapshot) {
    if (achievements.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
        margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.width * 0.4 * 0.1,
            bottom: MediaQuery.of(context).size.width * 0.4 * 0.1),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4 * 0.65,
            height: MediaQuery.of(context).size.width * 0.4 * 0.2,
            child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Color(0xff8a8f95), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SvgPicture.asset('lib/assets/icons/badge.svg',
                        width: MediaQuery.of(context).size.width * 0.4 * 0.1,
                        color: Color(0xff8a8f95)),
                    SizedBox(
                      width: 2,
                    ),
                    Text(
                      '업적',
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width * 0.4 * 0.08,
                        fontFamily: 'Pretendard-Regular',
                        color: Color(0xff8a8f95),
                      ),
                    )
                  ],
                )),
          ),
          GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
              ),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: achievements.length,
              itemBuilder: (BuildContext context, int index) {
                return badgeTier(context, achievements[index], index);
              }),
        ]));
  }

  Widget badgeSeasons(BuildContext context, AsyncSnapshot<Badges> snapshot) {
    if (seasons.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
        margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.width * 0.4 * 0.1,
            bottom: MediaQuery.of(context).size.width * 0.4 * 0.1),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4 * 0.65,
            height: MediaQuery.of(context).size.width * 0.4 * 0.2,
            child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Color(0xff8a8f95), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SvgPicture.asset('lib/assets/icons/badge.svg',
                        width: MediaQuery.of(context).size.width * 0.4 * 0.1,
                        color: Color(0xff8a8f95)),
                    SizedBox(
                      width: 2,
                    ),
                    Text(
                      '시즌',
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width * 0.4 * 0.08,
                        fontFamily: 'Pretendard-Regular',
                        color: Color(0xff8a8f95),
                      ),
                    )
                  ],
                )),
          ),
          GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
              ),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: seasons.length,
              itemBuilder: (BuildContext context, int index) {
                return badgeTier(context, seasons[index], index);
              }),
        ]));
  }

  Widget badgeEvents(BuildContext context, AsyncSnapshot<Badges> snapshot) {
    if (events.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
        margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.width * 0.4 * 0.1,
            bottom: MediaQuery.of(context).size.width * 0.4 * 0.1),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4 * 0.65,
            height: MediaQuery.of(context).size.width * 0.4 * 0.2,
            child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Color(0xff8a8f95), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SvgPicture.asset('lib/assets/icons/badge.svg',
                        width: MediaQuery.of(context).size.width * 0.4 * 0.1,
                        color: Color(0xff8a8f95)),
                    SizedBox(
                      width: 2,
                    ),
                    Text(
                      '이벤트',
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width * 0.4 * 0.08,
                        fontFamily: 'Pretendard-Regular',
                        color: Color(0xff8a8f95),
                      ),
                    )
                  ],
                )),
          ),
          GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
              ),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (BuildContext context, int index) {
                return badgeTier(context, events[index], index);
              }),
        ]));
  }

  Widget badgeContests(BuildContext context, AsyncSnapshot<Badges> snapshot) {
    if (contests.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
        margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.width * 0.4 * 0.1,
            bottom: MediaQuery.of(context).size.width * 0.4 * 0.1),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4 * 0.65,
            height: MediaQuery.of(context).size.width * 0.4 * 0.2,
            child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Color(0xff8a8f95), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SvgPicture.asset('lib/assets/icons/badge.svg',
                        width: MediaQuery.of(context).size.width * 0.4 * 0.1,
                        color: Color(0xff8a8f95)),
                    SizedBox(
                      width: 2,
                    ),
                    Text(
                      '대회',
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width * 0.4 * 0.08,
                        fontFamily: 'Pretendard-Regular',
                        color: Color(0xff8a8f95),
                      ),
                    )
                  ],
                )),
          ),
          GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
              ),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: contests.length,
              itemBuilder: (BuildContext context, int index) {
                return Tooltip(
                  textAlign: TextAlign.start,
                  richMessage: TextSpan(children: [
                    TextSpan(
                        text: '${contests[index]['displayName']}\n',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontFamily: 'Pretendard-Regular',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    TextSpan(
                        text: '${contests[index]['displayDescription']}',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontFamily: 'Pretendard',
                          color: Colors.white,
                        )),
                  ]),
                  child: Stack(
                    children: [
                      ImageShadow(
                          opacity: 0.2,
                          child: ExtendedImage.network(
                            'https://static.solved.ac/profile_badge/120x120/${contests[index]['badgeId']}.png',
                            width: MediaQuery.of(context).size.width * 0.13,
                            fit: BoxFit.cover,
                            cache: true,
                            loadStateChanged: (ExtendedImageState state) {
                              switch (state.extendedImageLoadState) {
                                case LoadState.loading:
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                case LoadState.completed:
                                  return null;
                                case LoadState.failed:
                                  return Center(
                                    child: Icon(Icons.error),
                                  );
                              }
                            },
                          )),
                    ],
                  ),
                );
              }),
        ]));
  }

  return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.05,
        right: MediaQuery.of(context).size.width * 0.05,
        top: MediaQuery.of(context).size.width * 0.05,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            SvgPicture.asset('lib/assets/icons/badge.svg',
                color: Color(0xff8a8f95),
                width: MediaQuery.of(context).size.width * 0.05),
            SizedBox(width: 5),
            Text(
              '뱃지',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                color: Color(0xff8a8f95),
              ),
            ),
          ],
        ),
        RichText(
            text: TextSpan(children: [
          TextSpan(
              text: count.toString(),
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontFamily: 'Pretendard-Regular',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              )),
          TextSpan(
              text: '개',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontFamily: 'Pretendard',
                color: Colors.black,
              )),
        ])),
        badgeAchievements(context, snapshot),
        badgeSeasons(context, snapshot),
        badgeEvents(context, snapshot),
        badgeContests(context, snapshot),
      ]));
}

Color levelColor(int level) {
  if (level == 0) {
    return Color(0xFF2D2D2D);
  } else if (level < 6) {
    // bronze
    return Color(0xffad5600);
  } else if (level < 11) {
    // silver
    return Color(0xFF425E79);
  } else if (level < 16) {
    // gold
    return Color(0xffec9a00);
  } else if (level < 21) {
    // platinum
    return Color(0xff00c78b);
  } else if (level < 26) {
    // diamond
    return Color(0xff00b4fc);
  } else if (level < 31) {
    // ruby
    return Color(0xffff0062);
  } else {
    // master
    return Color(0xffB491FF);
  }
}

Color ratingColor(int rating) {
  if (rating < 30) {
    return Color(0xFF2D2D2D);
  } else if (rating < 200) {
    // bronze
    return Color(0xffad5600);
  } else if (rating < 800) {
    // silver
    return Color(0xFF425E79);
  } else if (rating < 1600) {
    // gold
    return Color(0xffec9a00);
  } else if (rating < 2200) {
    // platinum
    return Color(0xff00c78b);
  } else if (rating < 2700) {
    // diamond
    return Color(0xff00b4fc);
  } else if (rating < 3000) {
    // ruby
    return Color(0xffff0062);
  } else {
    // master
    return Color(0xffB491FF);
  }
}
