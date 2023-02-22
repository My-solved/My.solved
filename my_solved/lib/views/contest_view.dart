import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:my_solved/services/network_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContestView extends StatefulWidget {
  const ContestView({Key? key}) : super(key: key);

  @override
  _ContestViewState createState() => _ContestViewState();
}

class _ContestViewState extends State<ContestView> {
  NetworkService networkService = NetworkService();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  header(),
                  contestList(),
                ],
              ),
            ),
          ),
        ));
  }
}

extension _ContestStateExtension on _ContestViewState {
  Widget header() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      child: const Text(
        '대회 일정',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget contestList() {
    return FutureBuilder<dom.Document>(
      future: networkService.requestContests(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          List<dom.Element> currentContests = snapshot.data.body
              .getElementsByClassName('col-md-12')[2]
              .getElementsByTagName('tbody')
              .first
              .getElementsByTagName('tr')
              .toList();
          List<dom.Element> futureContests = snapshot.data.body
              .getElementsByClassName('col-md-12')[4]
              .getElementsByTagName('tbody')
              .first
              .getElementsByTagName('tr')
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '진행 중',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(
                height: 10,
                thickness: 1,
              ),
              currentContests.isEmpty
                  ? const Text(
                      '진행 중인 대회가 없습니다.',
                      style: TextStyle(fontSize: 15),
                    )
                  : Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 20),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(width: 1.0, color: Colors.black),
                          bottom: BorderSide(width: 1.0, color: Colors.black),
                          left: BorderSide(width: 1.0, color: Colors.black),
                          right: BorderSide(width: 1.0, color: Colors.black),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentContests.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                              margin: const EdgeInsets.only(
                                  top: 5, bottom: 5, left: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      currentContests[index]
                                          .getElementsByTagName('td')[0]
                                          .text,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        currentContests[index]
                                                .getElementsByTagName('td')[1]
                                                .getElementsByTagName('a')
                                                .isEmpty
                                            ? Text(
                                                currentContests[index]
                                                    .getElementsByTagName(
                                                        'td')[1]
                                                    .text,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : CupertinoButton(
                                                minSize: 0,
                                                padding: EdgeInsets.zero,
                                                child: Text(
                                                  currentContests[index]
                                                      .getElementsByTagName(
                                                          'td')[1]
                                                      .getElementsByTagName('a')
                                                      .first
                                                      .text,
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  await launchUrlString(
                                                      currentContests[index]
                                                          .getElementsByTagName(
                                                              'td')[1]
                                                          .getElementsByTagName(
                                                              'a')
                                                          .first
                                                          .attributes['href']!,
                                                      mode: LaunchMode
                                                          .externalApplication);
                                                },
                                              ),
                                        Text(
                                          '${currentContests[index].getElementsByTagName('td')[2].text} ~ ${currentContests[index].getElementsByTagName('td')[3].text}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ));
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return const Divider(
                            color: Colors.black,
                            thickness: 1,
                            indent: 0,
                            endIndent: 0,
                          );
                        },
                      ),
                    ),
              const Text(
                '예정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(
                height: 10,
                thickness: 1,
              ),
              futureContests.isEmpty
                  ? const Text(
                      '예정된 대회가 없습니다.',
                      style: TextStyle(fontSize: 15),
                    )
                  : Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(width: 1.0, color: Colors.black),
                          bottom: BorderSide(width: 1.0, color: Colors.black),
                          left: BorderSide(width: 1.0, color: Colors.black),
                          right: BorderSide(width: 1.0, color: Colors.black),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: futureContests.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                              margin: const EdgeInsets.only(
                                  top: 5, bottom: 5, left: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      futureContests[index]
                                          .getElementsByTagName('td')[0]
                                          .text,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        futureContests[index]
                                                .getElementsByTagName('td')[1]
                                                .getElementsByTagName('a')
                                                .isEmpty
                                            ? Text(
                                                futureContests[index]
                                                    .getElementsByTagName(
                                                        'td')[1]
                                                    .text,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                minSize: 0,
                                                child: Text(
                                                  futureContests[index]
                                                      .getElementsByTagName(
                                                          'td')[1]
                                                      .getElementsByTagName('a')
                                                      .first
                                                      .text,
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  launchUrlString(
                                                      futureContests[index]
                                                          .getElementsByTagName(
                                                              'td')[1]
                                                          .getElementsByTagName(
                                                              'a')
                                                          .first
                                                          .attributes['href']!,
                                                      mode: LaunchMode
                                                          .externalApplication);
                                                },
                                              ),
                                        Text(
                                          '${futureContests[index].getElementsByTagName('td')[2].text} ~ ${futureContests[index].getElementsByTagName('td')[3].text}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ));
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return const Divider(
                            color: Colors.black,
                            thickness: 1,
                            indent: 0,
                            endIndent: 0,
                          );
                        },
                      ),
                    )
            ],
          );
        } else {
          return const Center(child: CupertinoActivityIndicator());
        }
      },
    );
  }
}
