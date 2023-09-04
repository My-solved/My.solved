import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/models/contest.dart';
import 'package:my_solved/services/contest_service.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/notification_service.dart';
import 'package:my_solved/views/search_view.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContestView extends StatefulWidget {
  const ContestView({Key? key}) : super(key: key);

  @override
  State<ContestView> createState() => _ContestViewState();
}

class _ContestViewState extends State<ContestView> {
  ContestService contestService = ContestService();
  NetworkService networkService = NetworkService();
  NotificationService notificationService = NotificationService();

  Map _selectedVenues = ContestService().showVenues;
  int _selectedSegment = 0;
  Map<int, String> contestStatus = {
    0: '진행중인 대회',
    1: '예정된 대회',
    2: '종료된 대회',
  };

  void updateSelectedVenues() {
    _selectedVenues = contestService.showVenues;
    setState(() {
      _selectedVenues = _selectedVenues;
    });
  }

  void _updateSelectedSegment(int value) {
    setState(() {
      _selectedSegment = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        child: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              venueFilter(context),
              UnderlineSegmentControl(
                  children: contestStatus,
                  fontSize: 14,
                  onValueChanged: (value) {
                    _updateSelectedSegment(value);
                  }),
              contestBody(_selectedSegment),
            ],
          ),
        )));
  }
}

extension _ContestStateExtension on _ContestViewState {
  /// 대회 필터링 위젯
  Widget venueFilter(BuildContext context) {
    return FutureBuilder(builder: (context, snapshot) {
      return Container(
        margin: EdgeInsets.only(left: 10, right: 10, top: 20),
        height: 30,
        child: ListView.builder(
          itemCount: _selectedVenues.length,
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            String venue = _selectedVenues.keys.elementAt(index);
            bool isSelected = _selectedVenues[venue]!;
            bool isOthers = venue == 'Others';

            return CupertinoButton(
              minSize: 0,
              padding: EdgeInsets.zero,
              child: Container(
                  margin: EdgeInsets.only(right: 10),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.grey[400] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      isOthers
                          ? Icon(
                              Icons.more_horiz,
                              size: 14,
                              color: isSelected
                                  ? Colors.grey[200]
                                  : Colors.grey[400],
                            )
                          : ExtendedImage.asset(
                              'lib/assets/venues/${venue.toLowerCase()}.png',
                              fit: BoxFit.fill,
                              width: 14,
                            ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        venue,
                        style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? Colors.grey[200]
                                : Colors.grey[400]),
                      )
                    ],
                  )),
              onPressed: () {
                ContestService().toggleContestShow(venue);
                updateSelectedVenues();
              },
            );
          },
        ),
      );
    });
  }

  /// 대회 탭
  /// index: 0 - 진행, 1 - 예정, 2 - 종료
  Widget contestBody(int index) {
    return FutureBuilder<List<List<Contest>>>(
      future: networkService.requestContests(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          List<Contest> contests = snapshot.data![index].where((contest) {
            return _selectedVenues[contest.venue] == true;
          }).toList();

          if (contests.isEmpty) {
            return Container(
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Text('현재 ${contestStatus[index]}가 없습니다.',
                    style: TextStyle(fontSize: 14, color: Colors.grey)));
          }

          return Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var c in contests) contest(context, c),
                ],
              ));
        } else {
          return const Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }

  /// 대회 위젯
  /// contest: 대회 정보
  /// return: 대회 위젯
  Widget contest(BuildContext context, Contest contest) {
    bool hasUrl = contest.url != null;
    return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contest.name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('주최: ${contest.venue}',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              '일정: ${contest.startTime.month}월 ${contest.startTime.day}일 ${contest.startTime.hour}:${contest.startTime.minute.toString().padLeft(2, '0')} ~ ${contest.endTime.month}월 ${contest.endTime.day}일 ${contest.endTime.hour}:${contest.endTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 5),
            Row(
              children: [
                TextButton(
                  style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(Size(0, 0)),
                      backgroundColor: MaterialStateProperty.all(
                        hasUrl
                            ? CupertinoTheme.of(context).main
                            : Colors.black12,
                      ),
                      foregroundColor: MaterialStateProperty.all(Colors.blue)),
                  child: Text('대회 정보',
                      style: TextStyle(
                          color: hasUrl ? Colors.white : Colors.grey,
                          fontSize: 12)),
                  onPressed: () {
                    hasUrl
                        ? launchUrlString(contest.url!,
                            mode: LaunchMode.externalApplication)
                        : null;
                  },
                ),
                SizedBox(width: 10),
                FutureBuilder(
                  future: notificationService.getContestPush(contest.name),
                  builder: (context, snapshot) {
                    bool isPush = snapshot.data ?? false;
                    return TextButton(
                      style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all(Size(0, 0)),
                          backgroundColor: MaterialStateProperty.all(isPush
                              ? CupertinoTheme.of(context).main
                              : Colors.black12)),
                      child: Text(isPush ? '알림 해제' : '알림 켜기',
                          style: TextStyle(
                            color: isPush ? Colors.white : Colors.grey,
                            fontSize: 12,
                          )),
                      onPressed: () {
                        setState(() {
                          notificationService.toggleContestPush(contest);
                        });
                        Fluttertoast.showToast(
                          msg: isPush ? '알림이 해제되었습니다.' : '알림이 설정되었습니다.',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.grey[700],
                          textColor: Colors.white,
                          fontSize: 14.0,
                        );
                      },
                    );
                  },
                )
              ],
            )
          ],
        ));
  }
}
