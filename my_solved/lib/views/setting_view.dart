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
          padding: EdgeInsets.only(top: 10, right: 20, left: 20),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Text('백준 ID'),
                ],
              ),
              Row(
                children: [
                  Text('백준 ID'),
                ],
              ),
              Row(
                children: [
                  Text('백준 ID'),
                ],
              ),
              Divider(),
              Row(
                children: [
                  Text('백준 ID'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
