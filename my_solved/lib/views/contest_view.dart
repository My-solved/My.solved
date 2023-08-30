import 'package:flutter/cupertino.dart';
import 'package:html/dom.dart' as dom;
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

  List<Contest> currentContests = [];
  List<Contest> futureContests = [];

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
  List<Contest> upcomingContests(dom.Element element) {
    if (element.getElementsByClassName('col-md-12').length < 5) {
      return element
          .getElementsByClassName('col-md-12')[2]
          .getElementsByTagName('tbody')
          .first
          .getElementsByTagName('tr')
          .toList()
          .map((e) {
        return Contest.fromElement(e);
      }).toList();
    } else {
      return element
          .getElementsByClassName('col-md-12')[4]
          .getElementsByTagName('tbody')
          .first
          .getElementsByTagName('tr')
          .toList()
          .map<Contest>((e) {
        return Contest.fromElement(e);
      }).toList();
    }
  }

  List<Contest> ongoingContests(dom.Element element) {
    if (element.getElementsByClassName('col-md-12').length < 5) {
      return element
          .getElementsByClassName('col-md-12')[2]
          .getElementsByTagName('tbody')
          .first
          .getElementsByTagName('tr')
          .toList()
          .map((e) {
        return Contest.fromElement(e);
      }).toList();
    } else {
      return [];
    }
  }

  Widget contestList() {
    return FutureBuilder<dom.Document>(
      future: networkService.requestContests(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          futureContests = upcomingContests(snapshot.data.body);
          currentContests = ongoingContests(snapshot.data.body);

          return contests(context, futureContests);
        } else {
          return const Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }
}
