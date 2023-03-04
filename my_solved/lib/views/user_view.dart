import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/widgets/user_widget.dart';

import 'home_view.dart';

class UserView extends StatefulWidget {
  const UserView({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  _UserViewState createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final NetworkService networkService = NetworkService();
  int _selectedSegment = 0;

  void _updateSelectedSegment(int value) {
    setState(() {
      _selectedSegment = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    String username = widget.username;
    var navigationBar = CupertinoNavigationBar(
      leading: CupertinoNavigationBarBackButton(
        color: CupertinoColors.label,
        onPressed: () => Navigator.of(context).pop(),
      ),
      middle: Text(widget.username),
    );

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      navigationBar: navigationBar,
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: FutureBuilder(
            future: networkService.requestUser(username),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final Widget _zandi = zandi(context, snapshot);
                final Widget _top100 = top100(
                    context, snapshot, networkService.requestTop100(username));
                final Widget _tagChart = tagChart(context, snapshot);
                final Widget _badges =
                    badges(context, networkService.requestBadges(username));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    profileHeader(context, snapshot),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    Divider(
                      height: 0,
                      thickness: 1,
                    ),
                    Container(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.05),
                        child: Column(
                          children: [
                            UnderlineSegmentControl(
                                children: {0: '프로필', 1: '태그', 2: '뱃지'},
                                onValueChanged: (value) {
                                  _updateSelectedSegment(value);
                                }),
                            Builder(builder: (context) {
                              if (_selectedSegment == 0) {
                                return Column(
                                  children: [
                                    profileDetail(context, snapshot),
                                    _zandi,
                                    _top100
                                  ],
                                );
                              } else if (_selectedSegment == 1) {
                                return _tagChart;
                              } else if (_selectedSegment == 2) {
                                return _badges;
                              } else {
                                return Text('Error');
                              }
                            })
                          ],
                        ))
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              return Center(
                child: CupertinoActivityIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }
}
