// 닉네임
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../models/User.dart';

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
    child: ExtendedImage.network(
      snapshot.data?.profileImageUrl?? 'https://static.solved.ac/misc/360x360/default_profile.png',
      width: 100,
      height: 100,
      cache: true,
      shape: BoxShape.circle,
    ),
  );
}

Widget handle(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          snapshot.data?.handle?? '',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

// 소속
Widget organizations(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        SvgPicture.asset('lib/assets/icons/hat.svg', width: 15, height: 15,),
        Positioned(top: -3, left: 18, child: RichText(
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
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: SvgPicture.asset(
        'lib/assets/classes/c${snapshot.data?.userClass}_.svg',
        width: 50,
        height: 50,
      ),
    )
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
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        snapshot.data?.rating.toString()?? '',
      ),
    )
  );
}

// 푼 문제 수
Widget solvedCount(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: snapshot.data?.solvedCount.toString()?? '',
              style: TextStyle(
                color: Colors.white,
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
        padding: EdgeInsets.only(top: 20),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: snapshot.data?.reverseRivalCount.toString()?? '',
                style: TextStyle(
                  color: Colors.white,
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
Widget zandi(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Container(
      alignment: Alignment.center,
      child: SvgPicture.network(
        'http://mazandi.herokuapp.com/api?handle=${snapshot.data?.handle}&theme=warm',
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