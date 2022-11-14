import 'package:flutter/cupertino.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                profileHeader(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension HomeViewExtension on HomeView {
  Widget profileHeader(BuildContext context) {
    return CupertinoPageScaffold(
      child: Container(
        margin: EdgeInsets.only(bottom: 50),
        child: Stack(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: 150,
              color: CupertinoColors.systemGrey,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeGreen,
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.only(top: 100, left: 20),
                ),
                Spacer(),
                CupertinoButton(
                  onPressed: () {},
                  child: Icon(
                    CupertinoIcons.gear_alt_fill,
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
