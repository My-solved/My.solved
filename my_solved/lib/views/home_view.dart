import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/pages/setting_page.dart';
import 'package:my_solved/view_models/home_view_model.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<HomeViewModel>(context);
    viewModel.onInit();

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FutureBuilder<User>(
                  future: viewModel.future,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          profileHeader(context, snapshot),
                          handle(snapshot),
                          // 자기소개 bio(snapshot),
                          organizations(snapshot),
                          // 클래스 classes(snapshot),
                          // 티어 tiers(snapshot),
                          // 레이팅 rating(snapshot),
                          // 푼 문제 수 solvedCount(snapshot),
                          // 라이벌 수 reverseRivalCount(snapshot),
                          // 랭크 rank(snapshot),
                          zandi(snapshot),
                          // 최대 연속 문제 해결일 수 maxStreak(snapshot),
                          // 경험치 exp(snapshot),
                        ],
                      );
                    } else {
                      return Container(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            profileHeader(context, snapshot),
                          ],
                        ),
                      );
                    }
                  }
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension HomeViewExtension on HomeView {
  Widget profileHeader(BuildContext context, AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
      child: Container(
        child: Stack(
          children: <Widget>[
            Align(
                alignment: Alignment.topLeft,
                child: ExtendedImage.network(
                  snapshot.data?.background['backgroundImageUrl']?? '',
                  height: 200,
                  cache: true,
                  fit: BoxFit.cover,
                )
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 20),
                  margin: EdgeInsets.only(top: 100, left: 20),
                  child: ExtendedImage.network(
                    snapshot.data?.profileImageUrl?? 'https://static.solved.ac/misc/360x360/default_profile.png',
                    width: 100,
                    height: 100,
                    cache: true,
                    shape: BoxShape.circle,
                  ),
                ),
                Spacer(),
                CupertinoButton(
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: ((context) => SettingPage()),
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.gear_alt_fill,
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 닉네임
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
              snapshot.data?.organizations[0]['name']?? '',
              style: TextStyle(
                fontSize: 15,
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
            child: SvgPicture.network(
              'http://mazandi.herokuapp.com/api?handle=${snapshot.data?.handle}&theme=warm',
            ),
          alignment: Alignment.center,
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
}

