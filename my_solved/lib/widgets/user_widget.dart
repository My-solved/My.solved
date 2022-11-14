// 닉네임
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../models/User.dart';

Widget handle(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            snapshot.data?.handle?? '',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

// 소속
Widget organizations(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            snapshot.data!.organizations.isEmpty ? '소속 없음' : snapshot.data?.organizations[0]['name']?? '',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

// 자기소개
Widget bio(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
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
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: SvgPicture.asset(
          'lib/assets/tiers/${snapshot.data?.tier}_.svg',
          width: 50,
          height: 50,
        ),
      )
  );
}

// 레이팅
Widget rating(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
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
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          snapshot.data?.solvedCount.toString()?? '',
        ),
      )
  );
}

// 라이벌 수
Widget reverseRivalCount(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          snapshot.data?.reverseRivalCount.toString()?? '',
        ),
      )
  );
}

// 랭크
Widget rank(AsyncSnapshot<User> snapshot) {
  return CupertinoPageScaffold(
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
      child: Container(
        padding: EdgeInsets.only(top: 20),
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
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          snapshot.data?.badge.toString()?? '',
        ),
      )
  );
}