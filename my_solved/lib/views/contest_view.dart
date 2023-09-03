import 'package:flutter/cupertino.dart';
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

  List<Contest> ongoingContests = [];
  List<Contest> upcomingContests = [];
  List<Contest> endedContests = [];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        child: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
  Widget contestList(int index) {
    return FutureBuilder<List<List<Contest>>>(
      future: networkService.requestContests(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          List<Contest> contestData = snapshot.data![index];

          return contests(context, contestData);
        } else {
          return const Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }
}
