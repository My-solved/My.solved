import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/models/contest.dart';
import 'package:url_launcher/url_launcher_string.dart';

Widget contests(BuildContext context, List<Contest> contests) {
  if (contests.isEmpty) {
    return Container(
        alignment: Alignment.center,
        child: Text('대회가 없습니다.',
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
}

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
                    backgroundColor: MaterialStateProperty.all(Colors.black12),
                    foregroundColor: MaterialStateProperty.all(Colors.blue)),
                child: Text('대회 정보',
                    style: TextStyle(
                        color: hasUrl ? Colors.blue : Colors.grey,
                        fontSize: 12)),
                onPressed: () {
                  hasUrl
                      ? launchUrlString(contest.url!,
                          mode: LaunchMode.externalApplication)
                      : null;
                },
              ),
              SizedBox(width: 10),
              TextButton(
                style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(Size(0, 0)),
                    backgroundColor: MaterialStateProperty.all(
                        CupertinoTheme.of(context).main),
                    foregroundColor: MaterialStateProperty.all(Colors.white)),
                child: Text('알림 설정하기', style: TextStyle(fontSize: 12)),
                onPressed: () {},
              ),
            ],
          )
        ],
      ));
}
