import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';
import '../view_models/profile_detail_view_model.dart';
import '../widgets/user_widget.dart';

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

extension ProfileDetailViewExtension on ProfileDetailView {
  Widget profileHeader(BuildContext context, AsyncSnapshot<User> snapshot) {
    return CupertinoPageScaffold(
      child: Stack(
        children: <Widget>[
          backgroundImage(snapshot),
          profileImage(snapshot),
        ],
      ),
    );
  }
}

