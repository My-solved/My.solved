import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/models/User.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/view_models/profile_view_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<ProfileViewModel>(context);

    return CupertinoPageScaffold(
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
                      return Container(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            titleHeader(),
                            backgroundImage(snapshot),
                            profileImage(snapshot),
                            userClass(snapshot),
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

extension ProfileViewExtension on ProfileView {
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
        child: Image.network(
          snapshot.data?.background['backgroundImageUrl']?? '',
        ),
      )
    );
  }

  Widget profileImage(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Image.network(
            snapshot.data?.profileImageUrl?? '',
            width: 100,
            height: 100,
          ),
        )
    );
  }

  Widget userClass(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '유저의 클래스 단계: ${snapshot.data?.userClass}',
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

  Widget tier(AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
        child: Container(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            '유저의 티어 단계: ${snapshot.data?.tier}',
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

