import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/services/user_service.dart';

const _themeList = ['warm', 'cold', 'dark'];
const _sortList = ['ID', '레벨', '제목', '푼 사람 수', '평균 시도'];

class SettingView extends StatefulWidget {
  const SettingView({Key? key}) : super(key: key);

  @override
  _SettingViewState createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  UserService userService = UserService();
  int _selectedIndex = UserService().streakTheme;
  bool _isIllustration = UserService().isIllustration;
  bool _showTierIcon = UserService().showTierIcon;
  bool _showTags = UserService().showTags;
  int _searchDefaultOpt = UserService().searchDefaultOpt;
  bool _searchDefaltSort = UserService().searchDefaultSort;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.label,
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Text('설정'),
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              id(userService.name),
              Divider(
                thickness: 1,
                height: 1,
                color: CupertinoTheme.of(context).dividerGray,
              ),
              illustration(context),
              themeOfStrick(context),
              Divider(
                thickness: 1,
                height: 1,
                color: CupertinoTheme.of(context).dividerGray,
              ),
              tags(context),
              tierIcon(context),
              searchDefaultOpt(context),
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
          Text('백준 핸들'),
          Spacer(),
          Text(name),
        ],
      ),
    );
  }

  Widget illustration(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('일러스트 배경'),
              Text(
                '일러스트 배경을 사용합니다.',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Text(UserService().isIllustration ? '켜기' : '끄기'),
            onPressed: () => _showDialog(
                CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: UserService().isIllustration ? 0 : 1,
                  ),
                  onSelectedItemChanged: (int selected) {
                    setState(() {
                      _isIllustration = selected == 0 ? true : false;
                      UserService()
                          .setIllustration(selected == 0 ? true : false);
                    });
                  },
                  children: List<Widget>.generate(2, (index) {
                    return Center(
                      child: Text(
                        index == 0 ? '켜기' : '끄기',
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

  Widget themeOfStrick(BuildContext context) {
    var _selectedTheme = _themeList[_selectedIndex];
    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('스트릭 테마'),
              Text('스트릭 색상을 변경합니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  )),
            ],
          ),
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

  Widget tierIcon(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('난이도 표시'),
              Text(
                '문제 검색시 난이도 아이콘을 표시합니다.',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Text(UserService().showTierIcon ? '켜기' : '끄기'),
            onPressed: () => _showDialog(
                CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: UserService().showTierIcon ? 0 : 1,
                  ),
                  onSelectedItemChanged: (int selected) {
                    setState(() {
                      _showTierIcon = selected == 0 ? true : false;
                      UserService().setTierIcon(selected == 0 ? true : false);
                    });
                  },
                  children: List<Widget>.generate(2, (index) {
                    return Center(
                      child: Text(
                        index == 0 ? '켜기' : '끄기',
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

  Widget tags(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('태그 표시'),
              Text(
                '문제 검색시 태그를 표시합니다.',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Text(UserService().showTags ? '켜기' : '끄기'),
            onPressed: () => _showDialog(
                CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: UserService().showTags ? 0 : 1,
                  ),
                  onSelectedItemChanged: (int selected) {
                    setState(() {
                      _showTags = selected == 0 ? true : false;
                      UserService().setTags(selected == 0 ? true : false);
                    });
                  },
                  children: List<Widget>.generate(2, (index) {
                    return Center(
                      child: Text(
                        index == 0 ? '켜기' : '끄기',
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

  Widget searchDefaultOpt(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(top: 5, bottom: 5),
        child: Row(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('검색 기본 옵션'),
                Text(
                  '검색 결과를 정렬하는 기준입니다.',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Spacer(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 100,
                child: Text(
                  _sortList[UserService().searchDefaultOpt],
                  textAlign: TextAlign.right,
                ),
              ),
              onPressed: () => _showDialog(
                  CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: UserService().searchDefaultOpt,
                    ),
                    onSelectedItemChanged: (int selected) {
                      setState(() {
                        _searchDefaultOpt = selected;
                        UserService().setSearchDefaultOpt(selected);
                      });
                    },
                    children: List<Widget>.generate(5, (index) {
                      return Center(
                        child: Text(
                          _sortList[index],
                        ),
                      );
                    }),
                  ),
                  context),
            ),
            SizedBox(width: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Text(_searchDefaltSort ? '오름차순' : '내림차순'),
              onPressed: () => _showDialog(
                  CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: UserService().searchDefaultSort ? 0 : 1,
                    ),
                    onSelectedItemChanged: (int selected) {
                      setState(() {
                        _searchDefaltSort = selected == 0 ? true : false;
                        UserService()
                            .setSearchDefaultSort(selected == 0 ? true : false);
                      });
                    },
                    children: List<Widget>.generate(2, (index) {
                      return Center(
                        child: Text(
                          index == 0 ? '오름차순' : '내림차순',
                        ),
                      );
                    }),
                  ),
                  context),
            )
          ],
        ));
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
