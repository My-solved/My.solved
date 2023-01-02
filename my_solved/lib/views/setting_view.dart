import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';

const zandiTheme = ['warm', 'cold', 'dark'];

class SettingView extends StatelessWidget {
  const SettingView({Key? key}) : super(key: key);

  Color zandiColor(int theme) {
    switch (theme) {
      case 0:
        return Color(0xFFfa8b5a);
      case 1:
        return Color(0xFF06CBE5);
      case 2:
        return Color(0xFF3f3f3f);
      default:
        return Color(0xff11ce3c);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('설정'),
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.only(top: 10, left: 20, right: 20),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 14, bottom: 14),
                    child: Text(
                      '백준 ID',
                      style: TextStyle(
                        fontSize: 16,
                        //color: CupertinoTheme.of(context).textTheme.textStyle.color,
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.only(top: 14, bottom: 14),
                    child: Text(
                      UserService().getUserName(),
                      style: TextStyle(
                        fontSize: 16,
                        //color: CupertinoTheme.of(context).textTheme.textStyle.color,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 14, bottom: 14),
                    child: Text(
                      '스트릭 테마 변경',
                      style: TextStyle(
                        fontSize: 16,
                        //color: CupertinoTheme.of(context).textTheme.textStyle.color,
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: zandiColor(UserService().getZandiTheme()),
                    ),
                    width: 100,
                    child: CupertinoButton(
                        padding: EdgeInsets.all(0),
                        child: Text(zandiTheme[UserService().getZandiTheme()],
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.white,
                            )),
                        onPressed: () async {
                          await showCupertinoModalPopup(
                            context: context,
                            builder: (context) => SizedBox(
                                height: 250.0,
                                child: CupertinoPicker(
                                  itemExtent: 30.0,
                                  scrollController: FixedExtentScrollController(
                                      initialItem:
                                          UserService().getZandiTheme()),
                                  onSelectedItemChanged: (int index) {
                                    UserService().setZandiTheme(index);
                                  },
                                  children: ['warm', 'cold', 'dark']
                                      .map((e) => Text(e))
                                      .toList(),
                                )),
                          );
                        }),
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
                    child: Text(
                      '라이센스',
                      style: TextStyle(
                        fontSize: 16,
                        //color: CupertinoTheme.of(context).textTheme.textStyle.color,
                      ),
                    ),
                  ),
                  Spacer(),
                  CupertinoButton(
                    onPressed: () {},
                    child: Icon(
                      CupertinoIcons.right_chevron,
                      //color: CupertinoTheme.of(context).textTheme.textStyle.color,
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
