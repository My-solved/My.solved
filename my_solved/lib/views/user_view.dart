import 'package:flutter/cupertino.dart';
import 'package:my_solved/models/User.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/views/home_view.dart';
import 'package:my_solved/widgets/user_widget.dart';

class UserView extends StatefulWidget {
  const UserView({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  _UserViewState createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final NetworkService _networkService = NetworkService();

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
            future: _networkService.requestUser(username),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _profileHeader(context, snapshot),
                    _profileDetail(context, snapshot),
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

extension _UserStateExtension on _UserViewState {
  Widget _profileHeader(BuildContext context, AsyncSnapshot<User> snapshot) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        backgroundImage(context, snapshot),
        Positioned(
          bottom: -50,
          left: 20,
          child: profileImage(context, snapshot),
        ),
      ],
    );
  }

  Widget _profileDetail(BuildContext context, AsyncSnapshot<User> snapshot) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              solvedCount(context, snapshot),
              voteCount(context, snapshot),
              reverseRivalCount(context, snapshot)
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.start,
            children: [
              handle(context, snapshot),
              badge(context, snapshot),
              classes(context, snapshot),
            ],
          ),
          bio(context, snapshot),
        ],
      ),
    );
  }
}