import 'dart:developer' as developer;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html/dom.dart' as dom;

import '../models/User.dart';
import '../models/user/ProblemStats.dart';

Widget backgroundImage(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      child: ExtendedImage.network(
    snapshot.data?.background['backgroundImageUrl'] ?? '',
    cache: true,
    fit: BoxFit.fitWidth,
  ));
}

Widget profileImage(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Card(
      elevation: 20,
      shadowColor: Color(0xFF000000 + levelColor(snapshot.data?.tier ?? 0)),
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
    ),
  );
}

Widget handle(BuildContext context, AsyncSnapshot<User> snapshot) {
  return Column(
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

// 잔디
Widget zandi(BuildContext context, AsyncSnapshot<User> snapshot) {
  return Stack(
    children: [
      SvgPicture.asset(
        'lib/assets/zandi.svg',
        width: MediaQuery.of(context).size.width,
      ),
      SvgPicture.network(
        'http://mazandi.herokuapp.com/api?handle=${snapshot.data?.handle}&theme=warm',
        width: MediaQuery.of(context).size.width,
      ),
      Positioned(
        left: MediaQuery.of(context).size.width * 0.8 * 0.07,
        bottom: MediaQuery.of(context).size.width * 0.4 * 0.91,
        child: Container(
            color: Colors.white,
            width: MediaQuery.of(context).size.width * 0.82,
            height: MediaQuery.of(context).size.width * 0.4 * 0.15,
            child: Row(
              children: [
                SvgPicture.asset(
                  'lib/assets/icons/streak.svg',
                  width: MediaQuery.of(context).size.width * 0.4 * 0.10,
                  height: MediaQuery.of(context).size.width * 0.4 * 0.10,
                  color: CupertinoColors.black,
                ),
                SizedBox(width: 5),
                Text(
                  // 'Rating: ${snapshot.data?.rating}',
                  '스트릭',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.4 * 0.10,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            )),
      ),
    ],
  );
}

// 최대 연속 문제 해결일 수
Widget maxStreak(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          snapshot.data?.maxStreak.toString() ?? '',
        ),
      ));
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
          snapshot.data?.badge['badgeImageUrl'],
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

// QR 코드
Widget genQR(AsyncSnapshot<ProblemStats> snapshot) {
  return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Column(
        children: [
          for (int i = 0; i < 10; i++)
            Row(
              children: [
                for (int j = 0; j < 10; j++)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: snapshot.data?.level == false
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ));
}

Widget top100(BuildContext context, AsyncSnapshot<dom.Document> snapshot) {
  developer.log(
      snapshot.data
              ?.getElementsByClassName('css-1wnvjz2')[0]
              .getElementsByTagName('img')
              .first
              .attributes['src']
              .toString() ??
          '',
      name: 'top100');
  return Container(
    width: MediaQuery.of(context).size.width,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey, width: 0.1),
    ),
    child: Column(
      children: [
        SizedBox(height: 10),
        // AC RATING
        Padding(
          padding:
              EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
          child: Html(
            data: snapshot.data!.body!
                    .getElementsByClassName('css-5vptc8')[0]
                    .innerHtml ??
                '',
          ),
        ),

        // 프로필 뱃지가 있을 때
        if (snapshot.data!.body!
            .getElementsByClassName('css-1wnvjz2')[0]
            .getElementsByTagName('img')
            .first
            .attributes['src']
            .toString()
            .contains('profile_badge'))
          for (var i = 0; i < 10; i++)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var j = 1; j <= 10; j++)
                Container(
                  margin: EdgeInsets.only(
                    right: MediaQuery.of(context).size.width * 0.03,
                    top: MediaQuery.of(context).size.width * 0.03,
                  ),
                  child: SvgPicture.asset(
                      snapshot.data!.body!
                              .getElementsByClassName('css-1wnvjz2')[10 * i + j]
                              .getElementsByTagName('img')
                              .first
                              .attributes['src']
                              .toString()
                              .replaceAll(
                                  'https://static.solved.ac/tier_small/',
                                  'lib/assets/tiers/') ??
                          '',
                      width: 20,
                      height: 20),
                )
            ])
        // 프로필 뱃지가 없을 때
        else
          for (var i = 0; i < 10; i++)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var j = 0; j < 10; j++)
                Container(
                  margin: EdgeInsets.only(
                    right: MediaQuery.of(context).size.width * 0.03,
                    top: MediaQuery.of(context).size.width * 0.03,
                  ),
                  child: SvgPicture.asset(
                      snapshot.data!.body!
                          .getElementsByClassName('css-1wnvjz2')[10 * i + j]
                          .getElementsByTagName('img')
                          .first
                          .attributes['src']
                          .toString()
                          .replaceAll('https://static.solved.ac/tier_small/',
                              'lib/assets/tiers/'),
                      width: 20,
                      height: 20),
                )
            ]),
        SizedBox(height: 20),
      ],
    ),
  );
}

int levelColor(int level) {
  if (level == 0) {
    return 0x2D2D2D;
  } else if (level < 6) {
    // bronze
    return 0xA25B36;
  } else if (level < 11) {
    // silver
    return 0x7B7574;
  } else if (level < 16) {
    // gold
    return 0xFEBE70;
  } else if (level < 21) {
    // platinum
    return 0x34E678;
  } else if (level < 26) {
    // diamond
    return 0x3F8EEA;
  } else if (level < 31) {
    // ruby
    return 0xE15C64;
  } else {
    // master
    return 0xCB7CEF;
  }
}
