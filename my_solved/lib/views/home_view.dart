import 'package:flutter/cupertino.dart';
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          profileHeader(context, snapshot),
                          SizedBox(height: 70),
                          Container(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.05,
                              right: MediaQuery.of(context).size.width * 0.1
                            ),
                            child: Column(
                              children: [
                                handle(snapshot),
                                organizations(snapshot),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    solvedCount(snapshot),
                                    reverseRivalCount(snapshot),
                                    Spacer(),
                                  ],
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Spacer(),
                              zandi(context, snapshot),
                              Spacer(),
                            ],
                          )
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
                ),
                // FutureBuilder<ProblemStats>(
                //   future: viewModel.futurePS,
                //   builder: (context, snapshot) {
                //       return genQR(snapshot);
                //   }
                // ),
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
          Positioned(left: 15, bottom: -50, child:
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                profileImage(snapshot),
                Positioned(left: 38, top: 65, child: tiers(snapshot)),
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

