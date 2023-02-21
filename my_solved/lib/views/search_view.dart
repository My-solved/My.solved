import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/models/search/object.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:my_solved/views/user_view.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SearchView extends StatefulWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  NetworkService networkService = NetworkService();
  String input = '';
  bool isSubmitted = false;
  Future<SearchObject>? future;
  int _selectedSegment = 0;

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
          scrollDirection: Axis.vertical,
          child: Container(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!isSubmitted) header(),
                searchBar(),
                if (isSubmitted)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      UnderlineSegmentControl(
                          children: {
                            0: '문제',
                            1: '사용자',
                            2: '태그',
                          },
                          onValueChanged: (value) {
                            print('Selected segment: $value');
                            _updateSelectedSegment(value);
                          }),
                      Builder(
                        builder: (context) {
                          if (_selectedSegment == 0) {
                            return FutureBuilder(
                                future: NetworkService().requestSearchProblem(
                                    input, null, null, null),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Column(
                                      children: <Widget>[
                                        for (dynamic problem
                                            in snapshot.data!.items)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: CupertinoTheme.of(context)
                                                  .backgroundGray,
                                              borderRadius:
                                                  const BorderRadius.all(
                                                Radius.circular(10),
                                              ),
                                            ),
                                            margin:
                                                const EdgeInsets.only(top: 10),
                                            padding: const EdgeInsets.all(20),
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                String url =
                                                    'https://acmicpc.net/problem/${problem['problemId']}';
                                                launchUrlString(url);
                                              },
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      SvgPicture.asset(
                                                        'lib/assets/tiers/${problem['level'].toString()}.svg',
                                                        height: 18,
                                                      ),
                                                      const SizedBox(
                                                        width: 5,
                                                      ),
                                                      Text(
                                                        '${problem['problemId']}번',
                                                        style: TextStyle(
                                                            fontSize: 16),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                    '${problem['titleKo']}',
                                                    style:
                                                        TextStyle(fontSize: 20),
                                                  ),
                                                  // SizedBox(
                                                  //   height: 12,
                                                  // ),
                                                  // Text(
                                                  //   '맞은 사람 수: ${problem['solved']}',
                                                  //   style: TextStyle(
                                                  //     fontSize: 14,
                                                  //     color: CupertinoTheme.of(context)
                                                  //         .fontGray,
                                                  //   ),
                                                  // ),
                                                  // SizedBox(
                                                  //   height: 4,
                                                  // ),
                                                  // Text(
                                                  //   'Level: ${problem['level']}',
                                                  //   style: TextStyle(
                                                  //     fontSize: 14,
                                                  //     color: CupertinoTheme.of(context)
                                                  //         .fontGray,
                                                  //   ),
                                                  // ),
                                                  // SizedBox(
                                                  //   height: 4,
                                                  // ),
                                                  // Text(
                                                  //   '평균 시도 횟수:',
                                                  //   style: TextStyle(
                                                  //     fontSize: 14,
                                                  //     color: CupertinoTheme.of(context)
                                                  //         .fontGray,
                                                  //   ),
                                                  // ),
                                                  // SizedBox(
                                                  //   height: 4,
                                                  // ),
                                                  // Text(
                                                  //   '태그:',
                                                  //   style: TextStyle(
                                                  //     fontSize: 14,
                                                  //     color: CupertinoTheme.of(context)
                                                  //         .fontGray,
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text('${snapshot.error}');
                                  } else {
                                    return CupertinoActivityIndicator();
                                  }
                                });
                          } else if (_selectedSegment == 1) {
                            return FutureBuilder(
                              future: NetworkService()
                                  .requestSearchUser(input, null),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Column(
                                    children: [
                                      for (dynamic user in snapshot.data!.items)
                                        Container(
                                          decoration: BoxDecoration(
                                              color: CupertinoTheme.of(context)
                                                  .backgroundGray,
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(10))),
                                          margin:
                                              const EdgeInsets.only(top: 10),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: CupertinoButton(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.only(left: 20),
                                            child: Text(
                                              '${user['handle']}',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                              CupertinoPageRoute(
                                                builder:
                                                    (BuildContext context) {
                                                  return UserView(
                                                      username: user['handle']);
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                } else if (snapshot.hasError) {
                                  return Text('${snapshot.error}');
                                } else {
                                  return CupertinoActivityIndicator();
                                }
                              },
                            );
                          } else {
                            return FutureBuilder(
                              future: NetworkService()
                                  .requestSearchTag(input, null),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Column(
                                    children: [
                                      for (dynamic tag in snapshot.data!.items)
                                        Container(
                                          decoration: BoxDecoration(
                                              color: CupertinoTheme.of(context)
                                                  .backgroundGray,
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(10))),
                                          margin:
                                              const EdgeInsets.only(top: 10),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: CupertinoButton(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.only(left: 20),
                                            child: Text(
                                              '${tag['key']}:${tag['problemCount']}',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            onPressed: () async {
                                              String url =
                                                  'https://solved.ac/search?query=%23${tag['key']}';
                                              launchUrlString(url);
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                } else if (snapshot.hasError) {
                                  return Text('${snapshot.error}');
                                } else {
                                  return CupertinoActivityIndicator();
                                }
                              },
                            );
                          }
                        },
                      ),
                    ],
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _SearchStateExtension on _SearchViewState {
  Widget header() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      child: const Text(
        '문제 검색',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget searchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: CupertinoSearchTextField(
        placeholder: '문제 번호, 문제 제목을 입력해주세요.',
        onChanged: (text) {
          setState(() {
            input = text;
          });
        },
        onSubmitted: (text) {
          setState(() {
            if (_selectedSegment == 0) {
              const optList = ['id', 'level', 'title', 'solved', 'average_try'];
              int opt = UserService().searchDefaultOpt;
              bool asc = UserService().searchDefaultSort;

              future = networkService.requestSearchProblem(
                  input, null, optList[opt], asc ? 'asc' : 'desc');
            } else if (_selectedSegment == 1) {
              future = networkService.requestSearchUser(input, null);
            } else {
              future = networkService.requestSearchTag(input, null);
            }
            isSubmitted = true;
          });
        },
      ),
    );
  }

  Widget problemHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Text(
        '문제',
        style:
            TextStyle(fontSize: 12, color: CupertinoTheme.of(context).fontGray),
      ),
    );
  }

  Widget userHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Text(
        '사용자',
        style:
            TextStyle(fontSize: 12, color: CupertinoTheme.of(context).fontGray),
      ),
    );
  }

  Widget tagHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Text(
        '태그',
        style:
            TextStyle(fontSize: 12, color: CupertinoTheme.of(context).fontGray),
      ),
    );
  }
}

class UnderlineSegmentControl extends StatefulWidget {
  final Map<int, String> children;
  final ValueChanged<int> onValueChanged;
  final Color color;
  final double fontSize;
  final FontWeight selectionFontWeight;
  final FontWeight unselectionFontWeight;
  final double indicatorHeight;
  final double indicatorWidth;

  const UnderlineSegmentControl({
    required this.children,
    required this.onValueChanged,
    this.color = CupertinoColors.label,
    this.fontSize = 16.0,
    this.selectionFontWeight = FontWeight.bold,
    this.unselectionFontWeight = FontWeight.normal,
    this.indicatorHeight = 2.0,
    this.indicatorWidth = 50.0,
  });

  @override
  _UnderlineSegmentedControlState createState() =>
      _UnderlineSegmentedControlState();
}

class _UnderlineSegmentedControlState extends State<UnderlineSegmentControl> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: widget.children.entries
          .map(
            (entry) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = entry.key;
                  widget.onValueChanged(_selectedIndex);
                });
              },
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.only(
                      left: 10,
                      top: 10,
                      right: 10,
                      bottom: 10,
                    ),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: _selectedIndex == entry.key
                            ? widget.selectionFontWeight
                            : widget.unselectionFontWeight,
                        color: widget.color,
                      ),
                    ),
                  ),
                  if (_selectedIndex == entry.key)
                    Container(
                      width: widget.indicatorWidth,
                      height: widget.indicatorHeight,
                      decoration: BoxDecoration(
                        color: widget.color,
                      ),
                    )
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
