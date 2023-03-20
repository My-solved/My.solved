import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/models/search/object.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/notification_service.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:my_solved/views/user_view.dart';
import 'package:my_solved/widgets/user_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SearchView extends StatefulWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  NetworkService networkService = NetworkService();
  NotificationService notificationService = NotificationService();
  String input = '';
  bool isSubmitted = false;
  Future<SearchObject>? futureProblem;
  Future<SearchObject>? futureUser;
  Future<SearchObject>? futureTag;
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
                CupertinoButton(child: Text("Test"), onPressed: () {
                  notificationService.testPush();
                }),
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
                            // print('Selected segment: $value');
                            _updateSelectedSegment(value);
                          }),
                      Builder(
                        builder: (context) {
                          if (_selectedSegment == 0) {
                            return FutureBuilder(
                                future: futureProblem,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Column(
                                      children: <Widget>[
                                        for (dynamic problem
                                            in snapshot.data!.items)
                                          CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            minSize: 0,
                                            onPressed: () async {
                                              String url =
                                                  'https://acmicpc.net/problem/${problem['problemId']}';
                                              launchUrlString(url,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    CupertinoTheme.of(context)
                                                        .backgroundGray,
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(10),
                                                ),
                                              ),
                                              margin: const EdgeInsets.only(
                                                  top: 10),
                                              padding: const EdgeInsets.all(20),
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Consumer<UserService>(
                                                          builder: (context,
                                                              userService,
                                                              child) {
                                                        return userService
                                                                .showTier
                                                            ? Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            5),
                                                                child:
                                                                    SvgPicture
                                                                        .asset(
                                                                  'lib/assets/tiers/${problem['level']}.svg',
                                                                  height: 18,
                                                                ))
                                                            : Container();
                                                      }),
                                                      Consumer<UserService>(
                                                          builder: (context,
                                                              userService,
                                                              child) {
                                                        return Text(
                                                          '${problem['problemId']}번',
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              color: userService
                                                                      .showTier
                                                                  ? levelColor(
                                                                      problem['level'] ??
                                                                          0)
                                                                  : Colors
                                                                      .black),
                                                        );
                                                      }),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    '${problem['titleKo']}',
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.black),
                                                  ),
                                                  Consumer<UserService>(builder:
                                                      (context, userService,
                                                          child) {
                                                    return userService.showTags
                                                        ? problem['tags']
                                                                .isNotEmpty
                                                            ? Wrap(
                                                                children: [
                                                                  for (dynamic tag
                                                                      in problem[
                                                                          'tags'])
                                                                    Text(
                                                                      '#${tag['displayNames'][0]['name']} ',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.5),
                                                                      ),
                                                                    ),
                                                                ],
                                                              )
                                                            : SizedBox.shrink()
                                                        : SizedBox.shrink();
                                                  }),
                                                ],
                                              ),
                                            ),
                                          )
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
                              future: futureUser,
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
                                            child: Row(
                                              children: [
                                                SvgPicture.asset(
                                                  'lib/assets/tiers/${user['tier'] ?? 0}.svg',
                                                  height: 20,
                                                ),
                                                const SizedBox(width: 5),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: ExtendedImage.network(
                                                    user['profileImageUrl'] ??
                                                        'https://static.solved.ac/misc/360x360/default_profile.png',
                                                    width: 20,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${user['handle']}',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: ratingColor(
                                                          user['rating'] ?? 0)),
                                                ),
                                              ],
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
                              future: futureTag,
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
                                              launchUrlString(url,
                                                  mode: LaunchMode
                                                      .externalApplication);
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
                      )
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
          // ignore: invalid_use_of_protected_member
          setState(() {
            input = text;
          });
        },
        onSubmitted: (text) {
          // ignore: invalid_use_of_protected_member
          setState(() {
            const optList = ['id', 'level', 'title', 'solved', 'average_try'];
            int opt = UserService().searchDefaultOpt;
            bool asc = UserService().searchDefaultSort;
            futureProblem = networkService.requestSearchProblem(
                input, null, optList[opt], asc ? 'asc' : 'desc');
            futureUser = NetworkService().requestSearchUser(input, null);
            futureTag = NetworkService().requestSearchTag(input, null);
            isSubmitted = true;
          });
        },
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
    super.key,
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
  State<UnderlineSegmentControl> createState() =>
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
