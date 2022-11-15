import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

extension ProfileDetailViewExtension on ProfileDetailView {
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
        ],
      ),
    );
  }
}
