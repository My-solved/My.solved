import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/services/notification_service.dart';
import 'package:my_solved/services/user_service.dart';

const _sortList = ['ID', '레벨', '제목', '푼 사람 수', '평균 시도'];

class SettingView extends StatefulWidget {
  const SettingView({Key? key}) : super(key: key);

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  NotificationService notificationService = NotificationService();
  UserService userService = UserService();

  bool _isIllustration = UserService().isIllustration;
  bool _showTier = UserService().showTier;
  bool _showTags = UserService().showTags;

  int _searchDefaultOpt = UserService().searchDefaultOpt;
  bool _searchDefaultSort = UserService().searchDefaultSort;

  bool _isOnStreakAlarm = UserService().isOnStreakAlarm;
  int _streakAlarmHour = UserService().streakAlarmHour;
  int _streakAlarmMinute = UserService().streakAlarmMinute;

  bool _isOnContestAlarm = UserService().isOnContestAlarm;
  int _contestAlarmHour = UserService().contestAlarmHour;
  int _contestAlarmMinute = UserService().contestAlarmMinute;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
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
              searchDefaultOpt(context),
              illustration(context),
              tierIcon(context),
              tags(context),
              Divider(
                thickness: 1,
                height: 20,
                color: CupertinoTheme.of(context).dividerGray,
              ),
              Container(
                  // padding: EdgeInsets.only(top: 20),
                  alignment: Alignment.center,
                  child: Text('구현 예정 기능')),
              streakAlarm(context),
              contestAlarm(context),
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
          CupertinoSwitch(
            value: _isIllustration,
            activeColor: CupertinoTheme.of(context).main,
            onChanged: (bool value) {
              // ignore: invalid_use_of_protected_member
              setState(() {
                _isIllustration = value;
                UserService().setIllustration(value);
              });
            },
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
                '문제 검색시 난이도를 표시합니다.',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Spacer(),
          CupertinoSwitch(
            value: _showTier,
            activeColor: CupertinoTheme.of(context).main,
            onChanged: (bool value) {
              // ignore: invalid_use_of_protected_member
              setState(() {
                _showTier = value;
                UserService().setTier(value);
              });
            },
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
          CupertinoSwitch(
            value: _showTags,
            activeColor: CupertinoTheme.of(context).main,
            onChanged: (bool value) {
              // ignore: invalid_use_of_protected_member
              setState(() {
                _showTags = value;
                UserService().setTags(value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget searchDefaultOpt(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(top: 5, bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('문제 정렬 기본 옵션'),
                Text(
                  '검색한 문제들의 정렬 기본 옵션입니다.',
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
              minSize: 0,
              child: Text(
                _sortList[UserService().searchDefaultOpt],
                textAlign: TextAlign.right,
              ),
              onPressed: () => _showDialog(
                  CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: _searchDefaultOpt,
                    ),
                    onSelectedItemChanged: (int selected) {
                      // ignore: invalid_use_of_protected_member
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
              minSize: 0,
              child: Text(_searchDefaultSort ? '오름차순' : '내림차순'),
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
                      // ignore: invalid_use_of_protected_member
                      setState(() {
                        _searchDefaultSort = selected == 0 ? true : false;
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

  Widget streakAlarm(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('스트릭 알림'),
              Text(
                '스트릭 알림 시간을 설정합니다.',
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
            child: Text(
              '매일 $_streakAlarmHour시 ${_streakAlarmMinute.toString().padLeft(2, '0')}분',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
              ),
            ),
            onPressed: () => _showDialog(
                CupertinoDatePicker(
                  use24hFormat: true,
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime:
                      DateTime(0, 0, 0, _streakAlarmHour, _streakAlarmMinute),
                  minuteInterval: 10,
                  onDateTimeChanged: (DateTime newDateTime) {
                    // ignore: invalid_use_of_protected_member
                    setState(() {
                      _streakAlarmHour = newDateTime.hour;
                      _streakAlarmMinute = newDateTime.minute;
                      userService.setStreakAlarmTime(
                          newDateTime.hour, newDateTime.minute);
                    });
                  },
                ),
                context),
          ),
          CupertinoSwitch(
            value: _isOnStreakAlarm,
            activeColor: CupertinoTheme.of(context).main,
            onChanged: (bool value) {
              // ignore: invalid_use_of_protected_member
              setState(() {
                _isOnStreakAlarm = value;
              });
              userService.setStreakAlarm(value);

              if(value) {
                notificationService.setStreakPush(_streakAlarmHour, _streakAlarmMinute);
              }
              else {
                notificationService.cancelStreakPush();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget contestAlarm(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('대회 시작 알림'),
              Text(
                '대회 시작 미리 알림 시간을 설정합니다.',
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
            child: Text(
              '$_contestAlarmHour시간 ${_contestAlarmMinute.toString().padLeft(2, '0')}분 전',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
              ),
            ),
            onPressed: () => _showDialog(
                CupertinoDatePicker(
                  use24hFormat: true,
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime:
                      DateTime(0, 0, 0, _contestAlarmHour, _contestAlarmMinute),
                  minuteInterval: 10,
                  onDateTimeChanged: (DateTime newDateTime) {
                    // ignore: invalid_use_of_protected_member
                    setState(() {
                      _contestAlarmHour = newDateTime.hour;
                      _contestAlarmMinute = newDateTime.minute;
                      UserService().setContestAlarmTime(
                          newDateTime.hour, newDateTime.minute);
                    });
                  },
                ),
                context),
          ),
          CupertinoSwitch(
            value: _isOnContestAlarm,
            activeColor: CupertinoTheme.of(context).main,
            onChanged: (bool value) {
              // ignore: invalid_use_of_protected_member
              setState(() {
                _isOnContestAlarm = value;
                UserService().setContestAlarm(value);
              });
            },
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
