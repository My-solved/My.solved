import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html/dom.dart' as dom;
import 'package:my_solved/services/user_service.dart';

import '../models/User.dart';
import '../models/user/Badges.dart';

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
  return SvgPicture.asset(
    'lib/assets/classes/c${snapshot.data?.userClass}.svg',
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
  return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Container(
        alignment: Alignment.centerLeft,
        child: Column(
          children: [
            Text(
              snapshot.data?.solvedCount.toString() ?? '',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '해결',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ));
}

// 기여 수
Widget voteCount(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Container(
        alignment: Alignment.centerLeft,
        child: Column(
          children: [
            Text(
              snapshot.data?.voteCount.toString() ?? '',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '기여',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ));
}

// 라이벌 수
Widget reverseRivalCount(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Container(
        alignment: Alignment.centerLeft,
        child: Column(
          children: [
            Text(
              snapshot.data?.reverseRivalCount.toString() ?? '',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '라이벌',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ));
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
                  color: zandiTheme == 2 ? Colors.white : Colors.black54,
                ),
                SizedBox(width: 5),
                Text(
                  // 'Rating: ${snapshot.data?.rating}',
                  '스트릭',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.4 * 0.10,
                    // fontWeight: FontWeight.bold,
                    color: zandiTheme == 2 ? Colors.white : Colors.black54,
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
      color: zandiTheme == 2 ? Colors.white : Colors.black54,
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
      : ExtendedImage.network(
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
        );
}

Widget top100(BuildContext context, AsyncSnapshot<dom.Document> snapshot) {
  int idx = 0;
  if (snapshot.data!.body!
      .getElementsByClassName('css-1wnvjz2')[0]
      .getElementsByTagName('img')
      .first
      .attributes['src']
      .toString()
      .contains('profile_badge')) {
    idx = 1;
  }

  // 레이팅
  String rating = snapshot.data!.body!
      .getElementsByClassName('css-5vptc8')[0]
      .getElementsByTagName('span')[1]
      .text;

  // 티어
  String tier = snapshot.data!.body!
      .getElementsByClassName('css-5vptc8')[0]
      .getElementsByTagName('span')[0]
      .innerHtml
      .toString();

  // 등수
  String rank = snapshot.data!.body!
      .getElementsByClassName('css-1nvk81z')[0]
      .getElementsByTagName('b')[0]
      .text;

  // 전체 백분율
  String percent = snapshot.data!.body!
      .getElementsByClassName('css-1nvk81z')[0]
      .getElementsByTagName('small')[0]
      .text;

  return Container(
    width: MediaQuery.of(context).size.width,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey, width: 0.5),
    ),
    child: Column(
      children: [
        SizedBox(height: 10),
        top100Header(rating, tier, rank, percent, context),
        SizedBox(height: 10),
        for (var i = 0; i < 10; i++)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var j = 0; j < 10; j++)
              top100Box(idx + 10 * i + j, context, snapshot),
          ]),
        SizedBox(height: 20),
      ],
    ),
  );
}

Widget top100Header(String rating, String tier, String rank, String percent,
    BuildContext context) {
  return Container(
    padding: EdgeInsets.only(
      left: MediaQuery.of(context).size.width * 0.4 * 0.15,
      top: MediaQuery.of(context).size.width * 0.4 * 0.05,
      right: MediaQuery.of(context).size.width * 0.4 * 0.15,
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
                    color: Colors.black54,
                    width: MediaQuery.of(context).size.width * 0.4 * 0.1),
                SizedBox(
                  width: 5,
                ),
                Text(
                  '레이팅',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.4 * 0.1,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(tier,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.4 * 0.14,
                      fontFamily: 'Pretendard-Medium',
                      color: ratingColor(int.parse(rating)),
                    )),
                SizedBox(width: 5),
                Text(
                  rating,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.4 * 0.14,
                    fontFamily: 'Pretendard-Regular',
                    fontWeight: FontWeight.bold,
                    color: ratingColor(int.parse(rating)),
                  ),
                ),
              ],
            ),
          ],
        ),
        Spacer(),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.black12,
          ),
          padding: EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
          child: Column(children: [
            Text(
              rank,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.4 * 0.11,
                fontFamily: 'Pretendard-Bold',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              percent,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.4 * 0.08,
                color: Colors.black,
              ),
            ),
          ]),
        )
      ],
    ),
  );
}

Widget top100Box(
    int idx, BuildContext context, AsyncSnapshot<dom.Document> snapshot) {
  try {
    if (snapshot.data!.body!
        .getElementsByClassName('css-1wnvjz2')[idx]
        .getElementsByTagName('img')
        .first
        .attributes['src']
        .toString()
        .contains('https://static.solved.ac/tier_small/')) {
      return Container(
          margin: EdgeInsets.all(
            MediaQuery.of(context).size.width * 0.02,
          ),
          child: SvgPicture.asset(
              snapshot.data!.body!
                  .getElementsByClassName('css-1wnvjz2')[idx]
                  .getElementsByTagName('img')
                  .first
                  .attributes['src']
                  .toString()
                  .replaceAll('https://static.solved.ac/tier_small/',
                      'lib/assets/tiers/'),
              width: MediaQuery.of(context).size.width * 0.041));
    } else {
      return SizedBox.shrink();
    }
  } catch (e) {
    return SizedBox.shrink();
  }
}

Widget badges(BuildContext context, AsyncSnapshot<Badges> snapshot) {
  int count = snapshot.data!.count;

  return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.05,
        right: MediaQuery.of(context).size.width * 0.05,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 10),
        Row(
          children: [
            SvgPicture.asset('lib/assets/icons/badge.svg',
                color: Colors.black54,
                width: MediaQuery.of(context).size.width * 0.05),
            SizedBox(width: 5),
            Text(
              '뱃지',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                color: Colors.black54,
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
                fontFamily: 'Pretendard-Bold',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              )),
          TextSpan(
              text: '개',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontFamily: 'Pretendard-Regular',
                color: Colors.black,
              )),
        ])),
        Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < count; i++)
              ExtendedImage.network(
                snapshot.data!.items[i]['badgeImageUrl']
                    .toString()
                    .replaceAll('profile_badge/', 'profile_badge/120x120/'),
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
              ),
          ],
        ),
        SizedBox(height: 10),
      ]));
}

Color levelColor(int level) {
  if (level == 0) {
    return Color(0xFF2D2D2D);
  } else if (level < 6) {
    // bronze
    return Color(0xFFA25B36);
  } else if (level < 11) {
    // silver
    return Color(0xFF7B7574);
  } else if (level < 16) {
    // gold
    return Color(0xFFFEBE70);
  } else if (level < 21) {
    // platinum
    return Color(0xFF34E678);
  } else if (level < 26) {
    // diamond
    return Color(0xFF3F8EEA);
  } else if (level < 31) {
    // ruby
    return Color(0xFFE15C64);
  } else {
    // master
    return Color(0xFFCB7CEF);
  }
}

Color ratingColor(int rating) {
  if (rating < 30) {
    return Color(0xFF2D2D2D);
  } else if (rating < 200) {
    // bronze
    return Color(0xFFA25B36);
  } else if (rating < 800) {
    // silver
    return Color(0xFF7B7574);
  } else if (rating < 1600) {
    // gold
    return Color(0xFFFEBE70);
  } else if (rating < 2200) {
    // platinum
    return Color(0xFF34E678);
  } else if (rating < 2700) {
    // diamond
    return Color(0xFF3F8EEA);
  } else if (rating < 3000) {
    // ruby
    return Color(0xFFE15C64);
  } else {
    // master
    return Color(0xFFCB7CEF);
  }
}
