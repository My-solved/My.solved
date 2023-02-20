import 'package:flutter/cupertino.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/widgets/user_widget.dart';

class UserView extends StatefulWidget {
  const UserView({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  _UserViewState createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final NetworkService networkService = NetworkService();

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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    profileHeader(context, snapshot),
                    profileDetail(context, snapshot),
                    zandi(context, snapshot),
                    top100(context, snapshot,
                        networkService.requestTop100(username)),
                    badges(context, networkService.requestBadges(username)),
                    tagChart(context, snapshot),
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
