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
                          Container(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.05,
                                right:
                                    MediaQuery.of(context).size.width * 0.05),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.11),
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
                                zandi(context, snapshot),
                                FutureBuilder<dom.Document>(
                                  future: viewModel.futureTop,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return top100(context, snapshot);
                                    } else if (snapshot.hasError) {
                                      return Text("asdfsadfasd",
                                          style: TextStyle(
                                              color: CupertinoColors
                                                  .destructiveRed));
                                    }
                                    return CupertinoActivityIndicator();
                                  },
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
        ],
      ),
    );
  }
}
