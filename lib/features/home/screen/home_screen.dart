import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/home/bloc/home_bloc.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:solved_api/solved_api.dart' as solved_api;
import 'package:solved_api/solved_api.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MySolvedColor.secondaryBackground,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: MySolvedColor.secondaryBackground,
        actions: [
          SizedBox(width: 16),
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
                backgroundColor: MySolvedColor.background,
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () async {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ClipOval(
                    child: ExtendedImage.network(
                      context.read<HomeBloc>().state.user?.profileImageUrl ??
                          "https://static.solved.ac/misc/360x360/default_profile.png",
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.read<HomeBloc>().state.handle,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      fontFamily: MySolvedFont.pretendard,
                      color: MySolvedColor.font,
                    ),
                  ),
                ],
              )),
          Spacer(),
          ExtendedImage.asset(
            "assets/images/venues/solved ac.png",
            height: 40,
          ),
          IconButton(
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
            icon: Icon(Icons.menu),
          ),
        ],
      ),
      body: HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeInit());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      bloc: BlocProvider.of<HomeBloc>(context),
      listener: (context, state) {
        if (state.status.isFailure) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("네트워크 오류가 발생했어요"),
                content: Text("잠시 후 다시 시도해주세요"),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("확인"),
                  ),
                ],
              );
            },
          );
        }
      },
      builder: (context, state) {
        if (state.status.isSuccess && state.user != null) {
          final slideItem = [
            [
              "문제 해결",
              state.user!.solvedCount.toString(),
              "https://solved.ac/profile/${state.handle}/solved"
            ],
            [
              "기여",
              state.user!.voteCount.toString(),
              "https://solved.ac/profile/${state.handle}/votes"
            ],
            [
              "라이벌",
              state.user!.reverseRivalCount.toString(),
              "https://solved.ac/ranking/reverse_rival"
            ],
          ];

          final solvedToday = state.solvedToday ?? false;
          final tags = state.tagRatings ?? [];
          final stats = state.problemStats ?? [];
          final gridItem = [
            GridItem(
              title: "레이팅",
              value: "${_tierText(state.user!.tier)} ${state.user!.rating}",
              onPressed: () {},
              backgroundColor: _ratingColor(state.user!.rating),
              foregroundColor: MySolvedColor.background,
            ),
            GridItem(
              title: "스트릭",
              value: state.user!.maxStreak.toString(),
              unit: "일",
              onPressed: () async {
                Fluttertoast.showToast(
                    msg: solvedToday ? "오늘은 이미 문제를 풀었어요" : "오늘은 아직 문제를 풀지 않았어요",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: MySolvedColor.main.withOpacity(0.8),
                    textColor: Colors.white,
                    fontSize: 16.0);
              },
              foregroundColor: MySolvedColor.background,
              backgroundColor: MySolvedColor.main,
              widget: SvgPicture.asset(
                  width: 60,
                  height: 60,
                  "assets/images/icons/streak.svg",
                  color: solvedToday ? Colors.green : MySolvedColor.main),
            ),
            GridItem(
              title: "클래스",
              onPressed: () {},
              foregroundColor: MySolvedColor.background,
              backgroundColor: _classColor(state.user!.userClass),
              widget: SvgPicture.asset(
                width: 60,
                height: 60,
                "assets/images/classes/c${state.user!.userClass}.svg",
              ),
            ),
            GridItem(
              title: "뱃지",
              onPressed: () {},
              widget: ExtendedImage.network(
                state.badge!.badgeImageUrl,
                width: 60,
                height: 60,
              ),
            ),
            GridItem(
              onPressed: () {},
              title: "배경",
              backgroundImageUrl: state.background?.backgroundImageUrl,
            ),
            GridItem(
              onPressed: () {},
              title: "난이도 분포",
              widget: _pieChart(stats: stats),
            ),
            GridItem(
              onPressed: () {},
              title: "태그 분포",
              widget: _tagChart(tags: tags, rating: state.user!.rating),
            ),
            GridItem(
              onPressed: () {},
              title: "난이도 분포",
              widget: _pieChart(stats: stats),
            ),
          ];
          return CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _backgroundImage(
                          isShowIllustBackground: state.isOnIllustBackground,
                          background: state.background,
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          height: 8,
                          color: Colors.grey,
                        ),
                        _solvedVotesRivals(slideItem: slideItem),
                        Divider(
                          height: 8,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _gridItem(item: gridItem[index]);
                    },
                    childCount: gridItem.length,
                  ),
                  gridDelegate: SliverQuiltedGridDelegate(
                    crossAxisCount: 6,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    pattern: [
                      QuiltedGridTile(2, 4),
                      QuiltedGridTile(2, 2),
                      QuiltedGridTile(2, 2),
                      QuiltedGridTile(2, 2),
                      QuiltedGridTile(2, 2),
                      QuiltedGridTile(3, 3),
                      QuiltedGridTile(3, 3),
                      QuiltedGridTile(6, 6),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: MySolvedColor.main,
            ),
          );
        }
      },
    );
  }

  Widget _backgroundImage({
    required bool isShowIllustBackground,
    required solved_api.Background? background,
  }) {
    final backgroundImageUrl = background?.backgroundImageUrl ??
        "https://static.solved.ac/profile_bg/abstract_001/abstract_001_light.png";
    final illustBackgroundImageUrl = background?.fallbackBackgroundImageUrl;
    final url = isShowIllustBackground && illustBackgroundImageUrl != null
        ? illustBackgroundImageUrl
        : backgroundImageUrl;
    return IconButton(
      onPressed: () {},
      padding: EdgeInsets.zero,
      icon: Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExtendedImage.network(url)),
    );
  }

  Widget _solvedVotesRivals({required List<List<String>> slideItem}) {
    return SizedBox(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 1; i < 2 * slideItem.length; i++)
            i.isOdd
                ? Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          launchUrlString(slideItem[(i / 2).floor()][2]);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(
                            color: Colors.transparent,
                            width: 0,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        child: Container(
                          width: 100,
                          clipBehavior: Clip.none,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slideItem[(i / 2).floor()][0],
                                style: MySolvedTextStyle.body2,
                              ),
                              Text(
                                slideItem[(i / 2).floor()][1],
                                style: MySolvedTextStyle.title1,
                              ),
                            ],
                          ),
                        )))
                : VerticalDivider(
                    color: Colors.grey,
                    indent: 20,
                    endIndent: 20,
                  ),
        ],
      ),
    );
  }

  Widget _pieChart({required List<ProblemStat> stats}) {
    Map<String, double> dataMap = {};
    for (var stat in stats) {
      dataMap[stat.level.toString()] = stat.solved.toDouble();
    }

    stats.fold(0, (sum, stat) => sum + stat.solved);
    List<Color> colorList = [];
    for (var i = 0; i <= 30; i++) {
      colorList.add(MySolvedColor.tier[i]!);
    }

    return Padding(
        padding: EdgeInsets.all(24),
        child: PieChart(
          dataMap: dataMap,
          animationDuration: Duration(milliseconds: 800),
          chartLegendSpacing: 32,
          colorList: colorList,
          initialAngleInDegree: 270,
          chartType: ChartType.ring,
          ringStrokeWidth: 40,
          legendOptions: LegendOptions(
            showLegendsInRow: false,
            showLegends: false,
          ),
          chartValuesOptions: ChartValuesOptions(
            showChartValueBackground: true,
            showChartValues: false,
            showChartValuesInPercentage: false,
            showChartValuesOutside: false,
          ),
        ));
  }

  Widget _tagChart({required List<TagRating> tags, required int rating}) {
    tags.sort((a, b) => b.rating.compareTo(a.rating));

    List<int> ticks = [];
    List<String> features = [];
    List<List<num>> data = [[]];

    int? length = min(8, tags.length);
    int maxTick = 0;
    for (var i = 0; i < length; i++) {
      // features.add(tags[i].tag.key);
      features.add("");
      data[0].add(tags[i].rating);
      maxTick = max(maxTick, data[0][i].toInt());
    }
    maxTick = (maxTick + 500) ~/ 500 * 500;
    while (maxTick > 0) {
      ticks.add(maxTick);
      maxTick -= 500;
    }

    return RadarChart(
      ticks: ticks.reversed.toList(),
      features: features,
      data: data,
      outlineColor: Color(0xff8a8f95),
      graphColors: [_ratingColor(rating)],
    );
  }

  Color _ratingColor(int rating) {
    if (rating < 30) return Color(0xFF2D2D2D);
    if (rating < 200) return Color(0xffad5600);
    if (rating < 800) return Color(0xFF425E79);
    if (rating < 1600) return Color(0xffec9a00);
    if (rating < 2200) return Color(0xff00c78b);
    if (rating < 2700) return Color(0xff00b4fc);
    if (rating < 3000) return Color(0xffff0062);
    return Color(0xffb300e0);
  }

  Color _classColor(int userClass) {
    if (userClass == 1) return Color.fromARGB(255, 36, 156, 229);
    if (userClass == 2) return Color.fromARGB(255, 32, 197, 233);
    if (userClass == 3) return Color.fromARGB(255, 27, 223, 139);
    if (userClass == 4) return Color.fromARGB(255, 43, 213, 33);
    if (userClass == 5) return Color.fromARGB(255, 176, 219, 21);
    if (userClass == 6) return Color.fromARGB(255, 235, 202, 15);
    if (userClass == 7) return Color.fromARGB(255, 243, 180, 18);
    if (userClass == 8) return Color.fromARGB(255, 255, 125, 0);
    if (userClass == 9) return Color.fromARGB(255, 243, 27, 116);
    if (userClass == 10) return Color.fromARGB(255, 167, 32, 232);
    return Color.fromARGB(255, 79, 82, 87);
  }

  String _tierText(int tier) {
    if (tier == 1) return 'Bronze V';
    if (tier == 2) return 'Bronze IV';
    if (tier == 3) return 'Bronze III';
    if (tier == 4) return 'Bronze II';
    if (tier == 5) return 'Bronze I';
    if (tier == 6) return 'Silver V';
    if (tier == 7) return 'Silver IV';
    if (tier == 8) return 'Silver III';
    if (tier == 9) return 'Silver II';
    if (tier == 10) return 'Silver I';
    if (tier == 11) return 'Gold V';
    if (tier == 12) return 'Gold IV';
    if (tier == 13) return 'Gold III';
    if (tier == 14) return 'Gold II';
    if (tier == 15) return 'Gold I';
    if (tier == 16) return 'Platinum V';
    if (tier == 17) return 'Platinum IV';
    if (tier == 18) return 'Platinum III';
    if (tier == 19) return 'Platinum II';
    if (tier == 20) return 'Platinum I';
    if (tier == 21) return 'Diamond V';
    if (tier == 22) return 'Diamond IV';
    if (tier == 23) return 'Diamond III';
    if (tier == 24) return 'Diamond II';
    if (tier == 25) return 'Diamond I';
    if (tier == 26) return 'Ruby V';
    if (tier == 27) return 'Ruby IV';
    if (tier == 28) return 'Ruby III';
    if (tier == 29) return 'Ruby II';
    if (tier == 30) return 'Ruby I';
    if (tier == 31) return 'Master';
    return 'Unrated';
  }
}

class GridItem {
  String title;
  String value;
  String unit;
  bool isPrefixUnit;
  Color foregroundColor;
  Color backgroundColor;
  VoidCallback? onPressed;
  String? backgroundImageUrl;
  Widget? widget;

  GridItem({
    required this.title,
    this.value = "",
    this.unit = "",
    this.isPrefixUnit = false,
    this.foregroundColor = MySolvedColor.font,
    this.backgroundColor = MySolvedColor.background,
    this.onPressed,
    this.backgroundImageUrl,
    this.widget,
  });
}

Widget _gridItem({required GridItem item}) {
  if (item.backgroundImageUrl != null) {
    return IconButton(
        onPressed: item.onPressed,
        padding: EdgeInsets.zero,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.grey,
          side: BorderSide(
            color: MySolvedColor.background,
            width: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Stack(clipBehavior: Clip.none, children: [
          Container(
              height: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExtendedImage.network(
                item.backgroundImageUrl!,
                fit: BoxFit.fitHeight,
                opacity: AlwaysStoppedAnimation(0.6),
              )),
          Positioned(
            top: 20,
            left: 16,
            child: Text(
              item.title,
              style:
                  MySolvedTextStyle.body1.copyWith(color: item.backgroundColor),
            ),
          ),
        ]));
  }
  return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: item.backgroundColor,
        padding: EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 20),
        side: BorderSide(
          color: MySolvedColor.background,
          width: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: item.onPressed,
      child: Stack(clipBehavior: Clip.none, children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: item.widget ?? Container(),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: MySolvedTextStyle.body1.copyWith(
                color: item.foregroundColor,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.isPrefixUnit)
                  Column(
                    children: [
                      Text(
                        item.unit,
                        style: MySolvedTextStyle.body1.copyWith(
                          color: item.foregroundColor,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                if (item.isPrefixUnit) SizedBox(width: 2),
                Text(
                  item.value,
                  style: MySolvedTextStyle.title1.copyWith(
                    fontSize: 24,
                    color: item.foregroundColor,
                  ),
                ),
                if (!item.isPrefixUnit) SizedBox(width: 2),
                if (!item.isPrefixUnit)
                  Column(
                    children: [
                      Text(
                        item.unit,
                        style: MySolvedTextStyle.body1.copyWith(
                          color: item.foregroundColor,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ]));
}
