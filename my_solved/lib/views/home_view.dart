import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html/dom.dart' as dom;
import 'package:my_solved/pages/setting_page.dart';
import 'package:my_solved/services/user_service.dart';
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
    String userName = UserService().fetchUserName();
    print(userName);
    viewModel.onInit(userName);

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
                                  left:
                                      MediaQuery.of(context).size.width * 0.05,
                                  right:
                                      MediaQuery.of(context).size.width * 0.1),
                              child: Column(
                                children: [
                                  handle(context, snapshot),
                                  organizations(context, snapshot),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      solvedCount(context, snapshot),
                                      SizedBox(width: 10),
                                      reverseRivalCount(context, snapshot),
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
                FutureBuilder<dom.Document>(
                  future: viewModel.futureTop,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Container(
                            color: CupertinoColors.white,
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.05,
                                right: MediaQuery.of(context).size.width * 0.1),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Html(
                                  data: snapshot.data!.body!
                                      .getElementsByClassName('css-5vptc8')[0]
                                      .innerHtml,
                                ),
                                SizedBox(height: 10),
                                for (var i = 0; i < 10; i++)
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        for (var j = 1; j <= 10; j++)
                                          Container(
                                            margin: EdgeInsets.only(
                                              right: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.03,
                                              top: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.03,
                                            ),
                                            child: SvgPicture.asset(
                                                snapshot.data!.body!
                                                    .getElementsByClassName(
                                                        'css-1wnvjz2')[10 *
                                                            i +
                                                        j]
                                                    .getElementsByTagName('img')
                                                    .first
                                                    .attributes['src']
                                                    .toString()
                                                    .replaceAll(
                                                        'https://static.solved.ac/tier_small/',
                                                        'lib/assets/tiers/'),
                                                width: 20,
                                                height: 20),
                                          )
                                      ]),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Text("asdfsadfasd",
                          style:
                              TextStyle(color: CupertinoColors.destructiveRed));
                    }
                    return CupertinoActivityIndicator();
                  },
                ),

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
