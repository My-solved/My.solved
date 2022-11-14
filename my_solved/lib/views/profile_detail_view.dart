import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/models/User.dart';
import 'package:provider/provider.dart';

import '../view_models/profile_detail_view_model.dart';

class ProfileDetailView extends StatelessWidget {
  const ProfileDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<ProfileDetailViewModel>(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(viewModel.handle),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  FutureBuilder<User>(
                    future: viewModel.future,
                    builder: (context, snapshot) {
                      if(snapshot.hasData) {
                        return Container(
                          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              titleHeader(),
                              backgroundImage(snapshot),
                              profileImage(snapshot),
                              classes(snapshot),
                              tiers(snapshot),
                              solvedCount(snapshot),
                              reverseRivalCount(snapshot),
                              rating(snapshot),
                              rank(snapshot),
                              zandi(snapshot),
                              exp(snapshot),
                              maxStreak(snapshot),
                            ],
                          ),
                        );
                      } else {
                        return Container(
                          padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              titleHeader(),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension ProfileDetailViewExtension on ProfileDetailView {
  Widget titleHeader() {
    return CupertinoPageScaffold(
      child: Text(
        '프로필',
        style: TextStyle(fontSize: 12, color: Color(0xff767676)),
      ),
    );
  }

  Widget backgroundImage(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: ExtendedImage.network(
            snapshot.data?.background['backgroundImageUrl']?? '',
            height: 200,
            cache: true,
          ),
        )
    );
  }

  Widget profileImage(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: ExtendedImage.network(
            snapshot.data?.profileImageUrl?? 'https://static.solved.ac/misc/360x360/default_profile.png',
            width: 100,
            height: 100,
            cache: true,
          ),
        )
    );
  }

  Widget handle(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '닉네임: ${snapshot.data?.handle}',
          ),
        )
    );
  }

  Widget bio(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '소속: ${snapshot.data?.bio}',
          ),
        )
    );
  }

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

  Widget rating(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '유저의 레이팅: ${snapshot.data?.rating}',
          ),
        )
    );
  }

  Widget solvedCount(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '유저가 푼 문제 수: ${snapshot.data?.solvedCount}',
          ),
        )
    );
  }

  Widget reverseRivalCount(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '유저의 라이벌 수: ${snapshot.data?.reverseRivalCount.toString()}',
          ),
        )
    );
  }

  Widget rank(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '유저의 랭크: ${snapshot.data?.rank.toString()}',
          ),
        )
    );
  }

  Widget zandi(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
            padding: EdgeInsets.only(top: 20),
            child: SvgPicture.network(
              'http://mazandi.herokuapp.com/api?handle=${snapshot.data?.handle}&theme=warm',
            )
        )
    );
  }

  Widget maxStreak(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '유저의 최대 스트릭: ${snapshot.data?.maxStreak}',
          ),
        )
    );
  }

  Widget exp(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '유저의 경험치: ${snapshot.data?.exp}',
          ),
        )
    );
  }

  Widget badge(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '유저의 뱃지: ${snapshot.data?.badge.toString()}',
          ),
        )
    );
  }
}

