import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/models/contest.dart';
import 'package:my_solved/services/contest_service.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/notification_service.dart';
import 'package:my_solved/views/search_view.dart';

import '../widgets/contest_widget.dart';

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
                      children: {
                        0: '진행',
                        1: '예정',
                        2: '종료',
                      },
                      onValueChanged: (value) {
                        _updateSelectedSegment(value);
                      }),
                  contestList(_selectedSegment),
                ],
              ),
            )));
  }
}

extension _ContestStateExtension on _ContestViewState {
  Widget venueFilter(BuildContext context) {
    return FutureBuilder(builder: (context, snapshot) {
      return Container(
        margin: EdgeInsets.only(left: 10, right: 10, top: 20),
        height: 40,
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
                    color: isSelected
                        ? Colors.grey[400]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      isOthers
                          ? Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: isSelected
                            ? Colors.grey[200]
                            : Colors.grey[400],
                      )
                          : ExtendedImage.asset(
                        'lib/assets/venues/${venue.toLowerCase()}.png',
                        fit: BoxFit.fill,
                        width: 20,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        venue,
                        style: TextStyle(
                            fontSize: 16,
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

  Widget contestList(int index) {
    return FutureBuilder<List<List<Contest>>>(
      future: networkService.requestContests(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          List<Contest> contestData = snapshot.data![index].where((contest) {
            return _selectedVenues[contest.venue] == true;
          }).toList();

          return contests(context, contestData);
        } else {
          return const Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }
}
