import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/user_service.dart';
import 'package:my_solved/widgets/user_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  UserService userService = UserService();
  NetworkService networkService = NetworkService();
  int _selectedSegment = 0;

  void _updateSelectedSegment(int value) {
    setState(() {
      _selectedSegment = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    String handle = userService.name;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: FutureBuilder(
              future: networkService.requestUser(handle),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final Widget _zandi = zandi(context, snapshot);
                  final Widget _top100 = top100(
                      context, snapshot, networkService.requestTop100(handle));
                  final Widget _tagChart = tagChart(context, snapshot);
                  final Widget _badges =
                      badges(context, networkService.requestBadges(handle));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      profileHeader(context, snapshot),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1),
                      Divider(
                        height: 0,
                        thickness: 1,
                      ),
                      Container(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.05),
                          child: Column(
                            children: [
                              UnderlineSegmentControl(
                                  children: {
                                    0: '프로필',
                                    1: '레이팅',
                                    2: '태그',
                                    3: '뱃지'
                                  },
                                  onValueChanged: (value) {
                                    _updateSelectedSegment(value);
                                  }),
                              Builder(builder: (context) {
                                if (_selectedSegment == 0) {
                                  return Column(
                                    children: [
                                      profileDetail(context, snapshot),
                                      _zandi
                                    ],
                                  );
                                } else if (_selectedSegment == 1) {
                                  return _top100;
                                } else if (_selectedSegment == 2) {
                                  return _tagChart;
                                } else if (_selectedSegment == 3) {
                                  return _badges;
                                } else {
                                  return Text('Error');
                                }
                              })
                            ],
                          ))
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return Center(child: CupertinoActivityIndicator());
              },
            )),
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
