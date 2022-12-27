import 'package:flutter/cupertino.dart';
import 'package:html/dom.dart' as dom;
import 'package:my_solved/pages/setting_page.dart';
import 'package:my_solved/view_models/home_view_model.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';
import '../providers/user/user_name.dart';
import '../widgets/user_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<HomeViewModel>(context);
    String userName = Provider.of<UserName>(context).name;
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
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Spacer(),
                              solvedCount(context, snapshot),
                              SizedBox(width: 20),
                              voteCount(context, snapshot),
                              SizedBox(width: 20),
                              reverseRivalCount(context, snapshot),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.1),
                            ],
                          ),
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.05,
                                right: MediaQuery.of(context).size.width * 0.1),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    handle(context, snapshot),
                                    badge(context, snapshot),
                                    classes(context, snapshot),
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
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Spacer(),
                              zandi(context, snapshot),
                              Spacer(),
                            ],
                          ),
                          // top100
                          FutureBuilder<dom.Document>(
                            future: viewModel.futureTop,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Container(
                                  padding: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.width *
                                          0.04,
                                      top: 10,
                                      right: MediaQuery.of(context).size.width *
                                          0.04),
                                  alignment: Alignment.center,
                                  child: top100(context, snapshot),
                                );
                              } else if (snapshot.hasError) {
                                return Text("asdfsadfasd",
                                    style: TextStyle(
                                        color: CupertinoColors.destructiveRed));
                              }
                              return CupertinoActivityIndicator();
                            },
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
                  }),

              // FutureBuilder<List<ProblemStats>>(
              //   future: viewModel.futurePS,
              //   builder: (context, snapshot) {
              //       return genQR(snapshot);
              //   }
              // ),
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
            left: 15,
            bottom: -50,
            child: Stack(clipBehavior: Clip.none, children: <Widget>[
              profileImage(context, snapshot),
              Positioned(left: 38, top: 65, child: tiers(context, snapshot)),
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
