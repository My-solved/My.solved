import 'package:flutter/cupertino.dart';
import 'package:html/dom.dart' as dom;
import 'package:my_solved/pages/setting_page.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:my_solved/view_models/home_view_model.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';
import '../models/user/Badges.dart';
import '../widgets/user_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<HomeViewModel>(context);
    String userName = UserService().getUserName();
    viewModel.onInit(userName);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
              // UserWidget
              FutureBuilder<User>(
                  future: viewModel.future,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
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
                                SizedBox(height: 60),
                                SizedBox(
                                  height: 20,
                                ),
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
                                SizedBox(
                                  height: 10,
                                ),
                                zandi(context, snapshot),
                                FutureBuilder<dom.Document>(
                                  future: viewModel.futureTop,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Column(
                                        children: [
                                          top100(context, snapshot),
                                        ],
                                      );
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

extension HomeViewExtension on HomeView {
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
                      SizedBox(width: MediaQuery.of(context).size.width * 0.2),
                      solvedCount(context, snapshot),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                      voteCount(context, snapshot),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                      reverseRivalCount(context, snapshot),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                    ],
                  )),
            ]),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
    );
  }
}
