import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../models/User.dart';
import '../models/user/ProblemStats.dart';

Widget backgroundImage(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    child: ExtendedImage.network(
      snapshot.data?.background['backgroundImageUrl']?? '',
      cache: true,
      fit: BoxFit.fitWidth,
    )
  );
}

Widget profileImage(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Card(
      elevation: 20,
      shadowColor: Colors.yellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      child: SizedBox(
        width: 100,
        height: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: ExtendedImage.network(
            snapshot.data?.profileImageUrl?? 'https://static.solved.ac/misc/360x360/default_profile.png',
            cache: true,
            fit: BoxFit.cover,
          ),
        ),
      ),
    ),
  );
}

Widget handle(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          snapshot.data?.handle?? '',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        classes(snapshot),
      ],
    ),
  );
}

// 소속
Widget organizations(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Row(
      children: [
        SvgPicture.asset('lib/assets/icons/hat.svg', width: 15, height: 15,),
        SizedBox(width: 5),
        Container(
          width: 180,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: snapshot.data!.organizations.isEmpty ? '소속 없음' : snapshot.data?.organizations[0]['name']?? '',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        )

      ]
    )
  );
}

// 자기소개
Widget bio(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        snapshot.data?.bio?? '',
      ),
    )
  );
}

// 클래스
Widget classes(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: SvgPicture.asset(
        'lib/assets/classes/c${snapshot.data?.userClass}_.svg',
        width: 50,
        height: 50,
    ),
  );
}

// 티어
Widget tiers(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: SvgPicture.asset(
        'lib/assets/tiers/${snapshot.data?.tier}_.svg',
        width: 40,
        height: 40,
      ),
    )
  );
}

// 레이팅
Widget rating(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Text(
      snapshot.data?.rating.toString()?? '',
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
Widget solvedCount(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      alignment: Alignment.centerLeft,
      width: 100,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: snapshot.data?.solvedCount.toString()?? '',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '문제 해결',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    )

  );
}

// 라이벌 수
Widget reverseRivalCount(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      alignment: Alignment.centerLeft,
      width: 100,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: snapshot.data?.reverseRivalCount.toString()?? '',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '명의 라이벌',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    )
  );
}

// 랭크
Widget rank(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        snapshot.data?.rank.toString()?? '',
      ),
    )
  );
}

// 잔디
Widget zandi(BuildContext context, AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Card(
      color: Colors.transparent,
      shadowColor: Colors.yellow,
      elevation: 15,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'lib/assets/zandi.svg',
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.4,
            color: Colors.white,
          ),
          SvgPicture.network(
            'http://mazandi.herokuapp.com/api?handle=${snapshot.data?.handle}&theme=warm',
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.4,
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.8 * 0.05,
            bottom: MediaQuery.of(context).size.width * 0.4 * 0.78,
            child: Container(
              clipBehavior: Clip.none,
              color: Colors.white,
              width: MediaQuery.of(context).size.width * 0.8 * 0.4,
              height: MediaQuery.of(context).size.width * 0.4 * 0.14,
              child: Row(
                children: [
                  SvgPicture.asset('lib/assets/icons/rating.svg',
                    color: Color(0xFFFBB758),
                    width: MediaQuery.of(context).size.width * 0.4 * 0.10,
                    height: MediaQuery.of(context).size.width * 0.4 * 0.10,
                  ),
                  SizedBox(width: 5),
                  Text('Rating: ${snapshot.data?.rating}',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.4 * 0.10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBB758),
                    ),
                  ),
                ],
              )
            ),
          )
        ],
      ),
    )
  );
}

// 최대 연속 문제 해결일 수
Widget maxStreak(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        snapshot.data?.maxStreak.toString()?? '',
      ),
    )
  );
}

// 경험치
Widget exp(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        snapshot.data?.exp.toString()?? '',
      ),
    )
  );
}

// 배지
Widget badge(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        snapshot.data?.badge.toString()?? '',
      ),
    )
  );
}

// QR
Widget rowQR(int i, AsyncSnapshot<ProblemStats> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Row(
      children: [
        for(int j = 0; j < 10; j++)
          SizedBox(
            width: 20,
            height: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: snapshot.data?.level == false? Colors.green: Colors.red,
              ),
            ),
          ),
      ],
    ),
  );
}

Widget genQR(AsyncSnapshot<ProblemStats> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Column(
      children: [
        for(int i = 0; i < 10; i++)
          rowQR(i, snapshot),
      ],
    )
  );
}