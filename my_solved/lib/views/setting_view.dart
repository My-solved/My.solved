import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/services/user_service.dart';

const _themeList = ['warm', 'cold', 'dark'];

class SettingView extends StatefulWidget {
  const SettingView({Key? key}) : super(key: key);

  @override
  _SettingViewState createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  UserService userService = UserService();
  int _selectedIndex = UserService().streakTheme;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: GestureDetector(
          child: Icon(
            CupertinoIcons.back,
            color: CupertinoColors.label,
          ),
          onTap: () => Navigator.of(context).pop(),
        ),
        middle: Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              id(userService.name),
              themeOfStrick(context),
              Divider(
                thickness: 1,
                height: 1,
                color: CupertinoTheme.of(context).dividerGray,
              ),
              logoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  void _showDialog(Widget child, BuildContext context) {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(top: false, child: child),
        ));
  }

  String getCurrent(int index) {
    return _themeList[index];
  }
}

extension _SettingStateExtension on _SettingViewState {
  Widget id(String name) {
    return Container(
      margin: EdgeInsets.only(top: 24, bottom: 14),
      child: Row(
        children: [
          Text('백준 ID'),
          Spacer(),
          Text(name),
        ],
      ),
    );
  }

  Widget themeOfStrick(BuildContext context) {
    var _selectedTheme = _themeList[_selectedIndex];
    return Container(
      margin: EdgeInsets.only(top: 14, bottom: 14),
      child: Row(
        children: <Widget>[
          Text('스트릭 테마'),
          Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Text(_selectedTheme),
            onPressed: () => _showDialog(
                CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: UserService().streakTheme,
                  ),
                  onSelectedItemChanged: (int selected) {
                    setState(() {
                      _selectedIndex = selected;
                      UserService().setStreakTheme(selected);
                    });
                  },
                  children: List<Widget>.generate(_themeList.length, (index) {
                    return Center(
                      child: Text(
                        _themeList[index],
                      ),
                    );
                  }),
                ),
                context),
          ),
        ],
      ),
    );
  }

  Widget logoutButton() {
    return Container(
      margin: EdgeInsets.only(top: 24, bottom: 14),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Text(
          '로그아웃',
          style: TextStyle(color: CupertinoColors.systemRed),
        ),
        onPressed: () {
          userService.logout();
        },
      ),
    );
  }
}