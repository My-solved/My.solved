import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:my_solved/services/network_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContestView extends StatefulWidget {
  const ContestView({Key? key}) : super(key: key);

  @override
  State<ContestView> createState() => _ContestViewState();
}

class _ContestViewState extends State<ContestView> {
  NetworkService networkService = NetworkService();

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
          List<dom.Element> currentContests = [];
          List<dom.Element> futureContests = [];

          if (snapshot.data.body.getElementsByClassName('col-md-12').length <
              5) {
            futureContests = snapshot.data.body
                .getElementsByClassName('col-md-12')[2]
                .getElementsByTagName('tbody')
                .first
                .getElementsByTagName('tr')
                .toList();
          } else {
            currentContests = snapshot.data.body
                .getElementsByClassName('col-md-12')[2]
                .getElementsByTagName('tbody')
                .first
                .getElementsByTagName('tr')
                .toList();
            futureContests = snapshot.data.body
                .getElementsByClassName('col-md-12')[4]
                .getElementsByTagName('tbody')
                .first
                .getElementsByTagName('tr')
                .toList();
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
                      const Text(
                        '진행 중',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      currentContests.isEmpty
                          ? Text(
                              '진행 중인 대회가 없습니다.',
                              style: TextStyle(fontSize: 15),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentContests.length,
                              itemBuilder: (BuildContext context, int index) {
                                Color linkColor = currentContests[index]
                                            .getElementsByTagName('td')[1]
                                            .getElementsByTagName('a')
                                            .first
                                            .attributes['href'] ==
                                        null
                                    ? Colors.black
                                    : Colors.blue;
                                late String contestUrl = '';
                                if (currentContests[index]
                                    .getElementsByTagName('td')[1]
                                    .getElementsByTagName('a')
                                    .isNotEmpty) {
                                  contestUrl = currentContests[index]
                                      .getElementsByTagName('td')[1]
                                      .getElementsByTagName('a')
                                      .first
                                      .attributes['href']!;
                                }
                                final String contestVenue =
                                    currentContests[index]
                                        .getElementsByTagName('td')[0]
                                        .text;
                                final String contestName =
                                    currentContests[index]
                                        .getElementsByTagName('td')[1]
                                        .text;
                                final String contestStart =
                                    currentContests[index]
                                        .getElementsByTagName('td')[2]
                                        .text;
                                final String contestEnd = currentContests[index]
                                    .getElementsByTagName('td')[3]
                                    .text;
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
                                    margin: const EdgeInsets.only(
                                        top: 5, bottom: 5),
                                    child: CupertinoButton(
                                        minSize: 0,
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {
                                          if (contestUrl.isNotEmpty) {
                                            await launchUrlString(contestUrl,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          }
                                        },
                                        child: Container(
                                            margin: const EdgeInsets.only(
                                                top: 10, bottom: 10, left: 10),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    contestVenue,
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: RichText(
                                                      text: TextSpan(
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: contestName,
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
                                                            '$contestStart ~ $contestEnd',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  )),
                                                ),
                                              ],
                                            ))));
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
                      futureContests.isEmpty
                          ? const Text(
                              '예정된 대회가 없습니다.',
                              style: TextStyle(fontSize: 15),
                            )
                          : Container(
                              margin: const EdgeInsets.only(top: 10),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: futureContests.length,
                                itemBuilder: (BuildContext context, int index) {
                                  Color linkColor = futureContests[index]
                                          .getElementsByTagName('td')[1]
                                          .getElementsByTagName('a')
                                          .isEmpty
                                      ? Colors.black
                                      : Colors.blue;
                                  late String contestUrl = '';
                                  if (futureContests[index]
                                      .getElementsByTagName('td')[1]
                                      .getElementsByTagName('a')
                                      .isNotEmpty) {
                                    contestUrl = futureContests[index]
                                        .getElementsByTagName('td')[1]
                                        .getElementsByTagName('a')
                                        .first
                                        .attributes['href']!;
                                  }
                                  final String contestVenue =
                                      futureContests[index]
                                          .getElementsByTagName('td')[0]
                                          .text;
                                  final String contestName =
                                      futureContests[index]
                                          .getElementsByTagName('td')[1]
                                          .text;
                                  final String contestStart =
                                      futureContests[index]
                                          .getElementsByTagName('td')[2]
                                          .text;
                                  final String contestEnd =
                                      futureContests[index]
                                          .getElementsByTagName('td')[3]
                                          .text;
                                  return Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                              width: 1.0,
                                              color: Colors.black26),
                                          bottom: BorderSide(
                                              width: 1.0,
                                              color: Colors.black26),
                                          left: BorderSide(
                                              width: 1.0,
                                              color: Colors.black26),
                                          right: BorderSide(
                                              width: 1.0,
                                              color: Colors.black26),
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      margin: const EdgeInsets.only(
                                          top: 5, bottom: 5),
                                      padding: const EdgeInsets.all(10),
                                      child: CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          minSize: 0,
                                          onPressed: () {
                                            if (contestUrl.isNotEmpty) {
                                              launchUrlString(contestUrl,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  contestVenue,
                                                  style: TextStyle(
                                                    color: linkColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: RichText(
                                                    text: TextSpan(
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: contestName,
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
                                                          '$contestStart ~ $contestEnd',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                )),
                                              ),
                                            ],
                                          )));
                                },
                              ),
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
