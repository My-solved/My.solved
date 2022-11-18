import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingView extends StatelessWidget {
  const SettingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('설정'),
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.only(top: 10, left: 20),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 14, bottom: 14),
                    child: Text('백준 ID'),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 14, bottom: 14),
                    child: Text('스트릭 테마'),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.only(right: 20),
                child: Divider(),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 14, bottom: 14),
                    child: Text('라이센스'),
                  ),
                  Spacer(),
                  CupertinoButton(
                    onPressed: () {},
                    child: Icon(
                      CupertinoIcons.right_chevron,
                      color: CupertinoColors.black,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
