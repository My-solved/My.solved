import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/pages/setting_page.dart';
import 'package:my_solved/view_models/home_view_model.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';
import '../widgets/user_widget.dart';

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
                      return Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.topCenter,
                            child: profileHeader(context, snapshot),
                          ),
                          Positioned(left: 30, bottom: -110, child:
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                handle(snapshot),
                                Positioned(bottom: -5, right: -60, child: classes(snapshot)),
                                Positioned(bottom: -40, child:
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      organizations(snapshot),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          solvedCount(snapshot),
                                          reverseRivalCount(snapshot),
                                        ],
                                      ),
                                    ],
                                  )
                                ),
                                Positioned(left: 0, top: 90, child: zandi(snapshot)),
                              ],
                            )
                          ),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          backgroundImage(snapshot),
          Positioned(left: 30, bottom: -50, child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              profileImage(snapshot),
              Positioned(left: 35, top: 60, child: tiers(snapshot)),
            ]
          ),
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

