import 'package:flutter/cupertino.dart';
import 'package:html/dom.dart' as dom;
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
                          children: <Widget>[
                            profileHeader(context, snapshot),
                            // organizations(context, snapshot),
                            SizedBox(height: 25),
                            Row(children: [
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4),
                              solvedCount(context, snapshot),
                              Spacer(),
                              voteCount(context, snapshot),
                              Spacer(),
                              reverseRivalCount(context, snapshot),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.1),
                            ]),
                            SizedBox(height: 25),
                            Container(
                              padding: EdgeInsets.only(
                                  left:
                                      MediaQuery.of(context).size.width * 0.05,
                                  right:
                                      MediaQuery.of(context).size.width * 0.1),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      handle(context, snapshot),
                                      Spacer(),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: bio(context, snapshot),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            Row(children: [
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.04),
                              badge(context, snapshot),
                              classes(context, snapshot),
                            ]),
                            SizedBox(height: 5),

                            zandi(context, snapshot),

                            // top100
                            FutureBuilder<dom.Document>(
                              future: viewModel.futureTop,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Container(
                                    padding: EdgeInsets.only(
                                        left:
                                            MediaQuery.of(context).size.width *
                                                0.04,
                                        top: 10,
                                        right:
                                            MediaQuery.of(context).size.width *
                                                0.04),
                                    alignment: Alignment.center,
                                    child: top100(context, snapshot),
                                  );
                                } else if (snapshot.hasError) {
                                  return Text("asdfsadfasd",
                                      style: TextStyle(
                                          color:
                                              CupertinoColors.destructiveRed));
                                }
                                return CupertinoActivityIndicator();
                              },
                            ),
                          ],
                        );
                      } else {
                        return Container(
                          padding:
                              EdgeInsets.only(top: 20, left: 20, right: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              profileHeader(context, snapshot),
                            ],
                          ),
                        );
                      }
                    }),
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
          backgroundImage(context, snapshot),
          Positioned(
            left: 25,
            bottom: -50,
            child: Stack(clipBehavior: Clip.none, children: <Widget>[
              profileImage(context, snapshot),
              Positioned(left: 38, top: 65, child: tiers(context, snapshot)),
            ]),
          ),
        ],
      ),
    );
  }
}
