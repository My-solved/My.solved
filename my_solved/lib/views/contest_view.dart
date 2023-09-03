import 'package:flutter/cupertino.dart';
import 'package:my_solved/models/contest.dart';
import 'package:my_solved/services/contest_service.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/notification_service.dart';

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

  void updateSelectedVenues() {
    _selectedVenues = contestService.showVenues;
    setState(() {
      _selectedVenues = _selectedVenues;
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
            child: contestList(),
          ),
        ));
  }
}

extension _ContestStateExtension on _ContestViewState {
  Widget contestList() {
    return FutureBuilder<List<List<Contest>>>(
      future: networkService.requestContests(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          upcomingContests = snapshot.data[0];
          ongoingContests = snapshot.data[1];
          endedContests = snapshot.data[2];

          return contests(context, endedContests);
        } else {
          return const Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }
}
