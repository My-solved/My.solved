import 'package:flutter/cupertino.dart';
import 'package:my_solved/models/user/Top_100.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';
import '../models/user/Badges.dart';
import '../models/user/TagRatings.dart';
import '../view_models/profile_detail_view_model.dart';
import '../widgets/user_widget.dart';

class ProfileDetailView extends StatelessWidget {
  const ProfileDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<ProfileDetailViewModel>(context);
    User? user;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(viewModel.handle),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FutureBuilder<User>(
                  future: viewModel.future,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      user = snapshot.data;
                      return Column(
                        children: <Widget>[
                          profileHeader(context, snapshot),
                          // organizations(context, snapshot),
                          Container(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.05,
                                right:
                                    MediaQuery.of(context).size.width * 0.05),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 80),
                                Wrap(
                                  direction: Axis.horizontal,
                                  children: [
                                    handle(context, snapshot),
                                    Wrap(
                                      direction: Axis.horizontal,
                                      children: [
                                        badge(context, snapshot),
                                        classes(context, snapshot),
                                      ],
                                    )
                                  ],
                                ),
                                SizedBox(height: 5),
                                zandi(context, snapshot),
                                FutureBuilder<Top_100>(
                                  future: viewModel.futureTop,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return top100(context, snapshot, user);
                                    } else if (snapshot.hasError) {
                                      return Text("asdfsadfasd",
                                          style: TextStyle(
                                              color: CupertinoColors
                                                  .destructiveRed));
                                    }
                                    return CupertinoActivityIndicator();
                                  },
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                FutureBuilder<Badges>(
                                  future: viewModel.futureBadges,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return badges(context, snapshot);
                                    } else if (snapshot.hasError) {
                                      return Text(
                                          "home_view.dart: ${snapshot.error}",
                                          style: TextStyle(
                                              color: CupertinoColors
                                                  .destructiveRed));
                                    }
                                    return CupertinoActivityIndicator();
                                  },
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                FutureBuilder<List<TagRatings>>(
                                    future: viewModel.futureTagRatings,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return tagChart(
                                            context, snapshot, user!);
                                      } else if (snapshot.hasError) {
                                        return Text(
                                            "home_view.dart: ${snapshot.error}",
                                            style: TextStyle(
                                                color: CupertinoColors
                                                    .destructiveRed));
                                      }
                                      return CupertinoActivityIndicator();
                                    }),
                                SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return profileHeader(context, snapshot);
                    }
                  }),
            ],
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
        clipBehavior: Clip.none,
        children: <Widget>[
          backgroundImage(context, snapshot),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.05,
            bottom: -50,
            child: Stack(clipBehavior: Clip.none, children: <Widget>[
              profileImage(context, snapshot),
              Positioned(
                  left: 38,
                  top: 65,
                  child: Row(
                    children: [
                      tiers(context, snapshot),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.12),
                      solvedCount(context, snapshot),
                      voteCount(context, snapshot),
                      reverseRivalCount(context, snapshot),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                    ],
                  )),
            ]),
          ),
        ],
      ),
    );
  }
}
