import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/dom.dart' as dom;
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/models/contest.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/notification_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContestView extends StatefulWidget {
  const ContestView({Key? key}) : super(key: key);

  @override
  State<ContestView> createState() => _ContestViewState();
}

class _ContestViewState extends State<ContestView> {
  NetworkService networkService = NetworkService();
  NotificationService notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        child: SafeArea(
          child: SingleChildScrollView(
            child: contestList(),
          ),
        ));
  }
}

extension _ContestStateExtension on _ContestViewState {
  Widget contestList() {
    return FutureBuilder<dom.Document>(
      future: networkService.requestContests(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          List<dynamic> currentContests = [];
          List<dynamic> futureContests = [];

          if (snapshot.data.body.getElementsByClassName('col-md-12').length <
              5) {
            futureContests = snapshot.data.body
                .getElementsByClassName('col-md-12')[2]
                .getElementsByTagName('tbody')
                .first
                .getElementsByTagName('tr')
                .toList()
                .map((e) {
              String venue = e.getElementsByTagName('td')[0].text;
              String name = e.getElementsByTagName('td')[1].text;
              String? url;
              if (e
                  .getElementsByTagName('td')[1]
                  .getElementsByTagName('a')
                  .isNotEmpty) {
                url = e
                    .getElementsByTagName('td')[1]
                    .getElementsByTagName('a')
                    .first
                    .attributes['href'];
              }
              List<String> startTimeList = e
                  .getElementsByTagName('td')[2]
                  .text
                  .toString()
                  .replaceAll('년', '')
                  .replaceAll('월', '')
                  .replaceAll('일', '')
                  .split(' ');
              DateTime startTime = DateTime.parse(
                      "${startTimeList[0].padLeft(4, "0")}-${startTimeList[1].padLeft(2, "0")}-${startTimeList[2].padLeft(2, "0")}T${startTimeList[3].padLeft(2, "0")}:00+09:00")
                  .toLocal();
              List<String> endTimeList = e
                  .getElementsByTagName('td')[3]
                  .text
                  .toString()
                  .replaceAll('년', '')
                  .replaceAll('월', '')
                  .replaceAll('일', '')
                  .split(' ');
              DateTime endTime = DateTime.parse(
                      "${endTimeList[0].padLeft(4, "0")}-${endTimeList[1].padLeft(2, "0")}-${endTimeList[2].padLeft(2, "0")}T${endTimeList[3].padLeft(2, "0")}:00+09:00")
                  .toLocal();
              return Contest(
                  venue: venue,
                  name: name,
                  url: url,
                  startTime: startTime,
                  endTime: endTime);
            }).toList();
          } else {
            currentContests = snapshot.data.body
                .getElementsByClassName('col-md-12')[2]
                .getElementsByTagName('tbody')
                .first
                .getElementsByTagName('tr')
                .toList()
                .map<Contest>((e) {
              String venue = e.getElementsByTagName('td')[0].text;
              String name = e.getElementsByTagName('td')[1].text;
              String? url;
              if (e
                  .getElementsByTagName('td')[1]
                  .getElementsByTagName('a')
                  .isNotEmpty) {
                url = e
                    .getElementsByTagName('td')[1]
                    .getElementsByTagName('a')
                    .first
                    .attributes['href'];
              }
              List<String> startTimeList = e
                  .getElementsByTagName('td')[2]
                  .text
                  .toString()
                  .replaceAll('년', '')
                  .replaceAll('월', '')
                  .replaceAll('일', '')
                  .split(' ');
              DateTime startTime = DateTime.parse(
                      "${startTimeList[0].padLeft(4, "0")}-${startTimeList[1].padLeft(2, "0")}-${startTimeList[2].padLeft(2, "0")}T${startTimeList[3].padLeft(2, "0")}:00+09:00")
                  .toLocal();
              List<String> endTimeList = e
                  .getElementsByTagName('td')[3]
                  .text
                  .toString()
                  .replaceAll('년', '')
                  .replaceAll('월', '')
                  .replaceAll('일', '')
                  .split(' ');
              DateTime endTime = DateTime.parse(
                      "${endTimeList[0].padLeft(4, "0")}-${endTimeList[1].padLeft(2, "0")}-${endTimeList[2].padLeft(2, "0")}T${endTimeList[3].padLeft(2, "0")}:00+09:00")
                  .toLocal();
              return Contest(
                  venue: venue,
                  name: name,
                  url: url,
                  startTime: startTime,
                  endTime: endTime);
            }).toList();

            futureContests = snapshot.data.body
                .getElementsByClassName('col-md-12')[4]
                .getElementsByTagName('tbody')
                .first
                .getElementsByTagName('tr')
                .toList()
                .map<Contest>((e) {
              String venue = e.getElementsByTagName('td')[0].text;
              String name = e.getElementsByTagName('td')[1].text;
              String? url;
              if (e
                  .getElementsByTagName('td')[1]
                  .getElementsByTagName('a')
                  .isNotEmpty) {
                url = e
                    .getElementsByTagName('td')[1]
                    .getElementsByTagName('a')
                    .first
                    .attributes['href'];
              }
              List<String> startTimeList = e
                  .getElementsByTagName('td')[2]
                  .text
                  .toString()
                  .replaceAll('년', '')
                  .replaceAll('월', '')
                  .replaceAll('일', '')
                  .split(' ');
              DateTime startTime = DateTime.parse(
                      "${startTimeList[0].padLeft(4, "0")}-${startTimeList[1].padLeft(2, "0")}-${startTimeList[2].padLeft(2, "0")}T${startTimeList[3].padLeft(2, "0")}:00+09:00")
                  .toLocal();

              List<String> endTimeList = e
                  .getElementsByTagName('td')[3]
                  .text
                  .toString()
                  .replaceAll('년', '')
                  .replaceAll('월', '')
                  .replaceAll('일', '')
                  .split(' ');
              DateTime endTime = DateTime.parse(
                      "${endTimeList[0].padLeft(4, "0")}-${endTimeList[1].padLeft(2, "0")}-${endTimeList[2].padLeft(2, "0")}T${endTimeList[3].padLeft(2, "0")}:00+09:00")
                  .toLocal();
              return Contest(
                  venue: venue,
                  name: name,
                  url: url,
                  startTime: startTime,
                  endTime: endTime);
            }).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  decoration: BoxDecoration(
                    color: Color(0xfff6f6f6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  margin:
                      EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          '진행 중${currentContests.isEmpty ? '인 대회가 없습니다.' : ''}',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (currentContests.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentContests.length,
                          itemBuilder: (BuildContext context, int index) {
                            final contest = currentContests[index];
                            Color linkColor = contest.url == null
                                ? Colors.black
                                : Colors.blue;

                            final String startYear =
                                contest.startTime.year.toString();
                            final String startMonth = contest.startTime.month
                                .toString()
                                .padLeft(2, '0');
                            final String startDay = contest.startTime.day
                                .toString()
                                .padLeft(2, '0');
                            final String startHour = contest.startTime.hour
                                .toString()
                                .padLeft(2, '0');
                            final String startMinute = contest.startTime.minute
                                .toString()
                                .padLeft(2, '0');

                            final String endYear =
                                contest.endTime.year.toString();
                            final String endMonth = contest.endTime.month
                                .toString()
                                .padLeft(2, '0');
                            final String endDay =
                                contest.endTime.day.toString().padLeft(2, '0');
                            final String endHour =
                                contest.endTime.hour.toString().padLeft(2, '0');
                            final String endMinute = contest.endTime.minute
                                .toString()
                                .padLeft(2, '0');

                            return Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  border: Border(
                                    top: BorderSide(
                                        width: 1.0, color: Colors.black26),
                                    bottom: BorderSide(
                                        width: 1.0, color: Colors.black26),
                                    left: BorderSide(
                                        width: 1.0, color: Colors.black26),
                                    right: BorderSide(
                                        width: 1.0, color: Colors.black26),
                                  ),
                                ),
                                margin:
                                    const EdgeInsets.only(top: 5, bottom: 5),
                                padding: const EdgeInsets.only(
                                    top: 10, bottom: 10, left: 20),
                                child: CupertinoButton(
                                    alignment: Alignment.centerLeft,
                                    minSize: 0,
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      if (contest.url != null) {
                                        await launchUrlString(contest.url!,
                                            mode:
                                                LaunchMode.externalApplication);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: RichText(
                                              textAlign: TextAlign.left,
                                              text: TextSpan(
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: contest.venue,
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: '\n',
                                                  ),
                                                  TextSpan(
                                                    text: contest.name,
                                                    style: TextStyle(
                                                      color: linkColor,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: '\n',
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '$startYear-$startMonth-$startDay $startHour:$startMinute ~ $endYear-$endMonth-$endDay $endHour:$endMinute',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 15,
                                            color: Colors.blue,
                                          ),
                                        )
                                      ],
                                    )));
                          },
                        ),
                    ],
                  )),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '예정',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (futureContests.isEmpty)
                        const Text(
                          '예정된 대회가 없습니다.',
                          style: TextStyle(fontSize: 15),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: futureContests.length,
                          itemBuilder: (BuildContext context, int index) {
                            final contest = futureContests[index];
                            Color linkColor = contest.url == null
                                ? Colors.black
                                : Colors.blue;
                            final startYear = contest.startTime.year.toString();
                            final startMonth = contest.startTime.month
                                .toString()
                                .padLeft(2, '0');
                            final startDay = contest.startTime.day
                                .toString()
                                .padLeft(2, '0');
                            final startHour = contest.startTime.hour
                                .toString()
                                .padLeft(2, '0');
                            final startMinute = contest.startTime.minute
                                .toString()
                                .padLeft(2, '0');

                            final endYear = contest.endTime.year.toString();
                            final endMonth = contest.endTime.month
                                .toString()
                                .padLeft(2, '0');
                            final endDay =
                                contest.endTime.day.toString().padLeft(2, '0');
                            final endHour =
                                contest.endTime.hour.toString().padLeft(2, '0');
                            final endMinute = contest.endTime.minute
                                .toString()
                                .padLeft(2, '0');

                            return Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        width: 1.0, color: Colors.black26),
                                    bottom: BorderSide(
                                        width: 1.0, color: Colors.black26),
                                    left: BorderSide(
                                        width: 1.0, color: Colors.black26),
                                    right: BorderSide(
                                        width: 1.0, color: Colors.black26),
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                margin:
                                    const EdgeInsets.only(top: 5, bottom: 5),
                                padding: const EdgeInsets.only(
                                    top: 10, bottom: 10, left: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: CupertinoButton(
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.zero,
                                        minSize: 0,
                                        onPressed: () {
                                          if (contest.url != null) {
                                            launchUrlString(contest.url!,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          }
                                        },
                                        child: RichText(
                                            textAlign: TextAlign.left,
                                            text: TextSpan(
                                              style: const TextStyle(
                                                color: Colors.black87,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: contest.venue,
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const TextSpan(
                                                  text: '\n',
                                                ),
                                                TextSpan(
                                                  text: contest.name,
                                                  style: TextStyle(
                                                    color: linkColor,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const TextSpan(
                                                  text: '\n',
                                                ),
                                                TextSpan(
                                                  text:
                                                      '$startYear-$startMonth-$startDay $startHour:$startMinute ~ $endYear-$endMonth-$endDay $endHour:$endMinute',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            )),
                                      ),
                                    ),
                                    Expanded(
                                        flex: 1,
                                        child: FutureBuilder(
                                          future: notificationService
                                              .getContestPush(contest.name),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<bool> snapshot) {
                                            if (snapshot.hasData) {
                                              bool isOn = snapshot.data!;
                                              return CupertinoButton(
                                                onPressed: () async {
                                                  notificationService
                                                      .toggleContestPush(
                                                          contest);
                                                  Fluttertoast.showToast(
                                                      msg: isOn
                                                          ? '알림이 해제되었습니다.'
                                                          : '알림이 설정되었습니다.');
                                                  // ignore: invalid_use_of_protected_member
                                                  setState(() {
                                                    notificationService
                                                        .setContestPush(
                                                            contest.name,
                                                            !isOn);
                                                  });
                                                },
                                                padding: EdgeInsets.zero,
                                                minSize: 0,
                                                child: Icon(
                                                  CupertinoIcons.alarm,
                                                  color: snapshot.data!
                                                      ? CupertinoTheme.of(
                                                              context)
                                                          .main
                                                      : Colors.black26,
                                                ),
                                              );
                                            } else {
                                              return const SizedBox();
                                            }
                                          },
                                        ))
                                  ],
                                ));
                          },
                        )
                    ],
                  ))
            ],
          );
        } else {
          return const Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }
}
