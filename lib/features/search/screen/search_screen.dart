import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:my_solved/components/atoms/text_field/my_solved_search_field.dart';
import 'package:my_solved/components/molecules/segmented_control/segmented_control.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/search/bloc/search_bloc.dart';
import 'package:my_solved/features/search_filter/screen/search_filter_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MySolvedColor.secondaryBackground,
      body: SafeArea(
        child: SearchView(),
      ),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: SearchHeaderDelegate(
            body: BlocBuilder<SearchBloc, SearchState>(
              bloc: BlocProvider.of<SearchBloc>(context),
              builder: (context, state) {
                return Container(
                  padding: EdgeInsets.only(top: 16, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: MySolvedColor.secondaryBackground,
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: MySolvedColor.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: MySolvedSearchField(
                          hintText: "문제, 사용자, 태그를 입력해주세요",
                          onChange: (text) => context
                              .read<SearchBloc>()
                              .add(SearchTextFieldOnChanged(text: text)),
                          onSubmitted: (text) => context
                              .read<SearchBloc>()
                              .add(SearchTextFieldOnSummited(text: text)),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MySolvedSegmentedControl(
                            screenTitles: ["문제", "사용자", "태그"],
                            defaultIndex: state.currentIndex,
                            onSelected: (index) => context
                                .read<SearchBloc>()
                                .add(
                                    SearchSegmentedControlTapped(index: index)),
                          ),
                          IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isDismissible: true,
                                isScrollControlled: true,
                                builder: (contest) => SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.9,
                                  child: SearchFilterScreen(
                                    searchBLoc: context.read<SearchBloc>(),
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.filter_list),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: BlocConsumer<SearchBloc, SearchState>(
            bloc: BlocProvider.of<SearchBloc>(context),
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
              if (state.status.isInitial) {
                return Column(
                  children: [
                    SizedBox(height: 16),
                    Text('문제 고급 검색', style: MySolvedTextStyle.title5),
                    Text('이 기능은 문제 검색에만 적용됩니다.',
                        style: MySolvedTextStyle.caption1),
                    SizedBox(height: 16),
                    DataTable(
                        horizontalMargin: 16,
                        columnSpacing: 16,
                        headingTextStyle: TextStyle(
                          color: MySolvedColor.font,
                          fontFamily: MySolvedFont.pretendard,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        dataTextStyle: TextStyle(
                          color: MySolvedColor.font,
                          fontFamily: MySolvedFont.pretendard,
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                        ),
                        headingRowHeight: 32,
                        columns: [
                          DataColumn(label: Text("연산자")),
                          DataColumn(label: Text("예시")),
                        ],
                        rows: [
                          _dataRow(
                            operator: '""',
                            function: "정확히 일치",
                            example: '"A+B - 2"',
                            description: '문제 이름에 "A+B - 2"가 포함되는 문제들',
                          ),
                          _dataRow(
                            operator: '()',
                            function: "우선순위 지정자",
                            example: 'A+B (2 | 3)',
                            description:
                                '문제 이름에 "A+B"가 포함되고 "2" 또는 "3"이 포함되는 문제들',
                          ),
                          _dataRow(
                            operator: '-, !, ~',
                            function: "포함하지 않음\n('not' 연산)",
                            example: '*s..g -@\$me',
                            description:
                                'Silver 이상 Gold 이하인 문제들 중 내가 풀지 않은 문제들',
                          ),
                          _dataRow(
                            operator: "&",
                            function: "모두 포함\n('and' 연산)",
                            example: '#dp #math',
                            description: "다이나믹 프로그래밍과 수학 두 태그 모두를 갖는 문제들",
                          ),
                          _dataRow(
                            operator: "|",
                            function: "하나 이상 포함\n('or' 연산)",
                            example: '#greedy | #ad_hoc',
                            description: "그리디 알고리즘 또는 애드 혹 태그를 갖는 문제들",
                          ),
                          _dataRow(
                            operator: "*, tier:",
                            function: "난이도",
                            example: '*g4..g1',
                            description: "난이도가 Gold IV 이상 Gold I 이하인 문제들",
                          ),
                          _dataRow(
                            operator: "id:",
                            function: "문제 번호",
                            example: '*id:1000..2000',
                            description: "문제 번호가 1000 이상 2000 이하인 문제들",
                          ),
                          _dataRow(
                              operator: "s#, solved:",
                              function: "푼 사람 수",
                              example: 's#1000..',
                              description: "1,000명 이상이 푼 문제들"),
                          _dataRow(
                            operator: "#, tag:",
                            function: "태그",
                            example: '#dp',
                            description: "다이나믹 프로그래밍 태그를 갖는 문제들",
                          ),
                          _dataRow(
                            operator: "/, from:",
                            function: "문제 출처",
                            example: '/ucpc2022',
                            description: "UCPC 2022 본선 문제들",
                          ),
                          _dataRow(
                            operator: "t#, average_try:, µ#",
                            function: "평균 시도 횟수",
                            example: 't#1..2',
                            description: "평균 시도 횟수가 1회 이상 2회 이하인 문제들",
                          ),
                          _dataRow(
                            operator: "%, lang:",
                            function: "언어",
                            example: '%ko',
                            description: "한국어로 작성된 문제들",
                          ),
                          _dataRow(
                            operator: "@, solved_by:, s@",
                            function: "유저가 푼 문제",
                            example: '@shiftpsh',
                            description: "shiftpsh가 푼 문제들",
                          ),
                          _dataRow(
                            operator: "t@, tried_by:",
                            function: "유저가 시도한 문제",
                            example: 't@shiftpsh',
                            description: "shiftpsh가 시도한 문제들",
                          ),
                          _dataRow(
                            operator: "v@, voted_by:, c@, contributed_by:",
                            function: "유저가 기여한 문제",
                            example: 'v@shiftpsh',
                            description: "shiftpsh가 기여한 문제들",
                          ),
                          _dataRow(
                            operator: "c/, in_class:",
                            function: "CLASS 단계 안의 문제",
                            example: 'c/1',
                            description: "CLASS 1 단계의 문제들",
                          ),
                          _dataRow(
                            operator: "e/, in_class_essentials:",
                            function: "CLASS 단계 안의 에센셜 문제",
                            example: 'e/1',
                            description: "CLASS 1 에센셜 문제들",
                          ),
                          _dataRow(
                            operator: "s?, standard:",
                            function: "난이도 표준 문제",
                            example: 's?true',
                            description: "난이도 표준 문제들",
                          ),
                          _dataRow(
                            operator: "p?, sprout: sp?",
                            function: "새싹 난이도 문제",
                            example: 'p?true',
                            description: "새싹 난이도 문제들",
                          ),
                          _dataRow(
                              operator: "o?, solvable",
                              function: "풀 수 있는 문제",
                              example: "o?true",
                              description: "풀 수 있는 문제들"),
                          _dataRow(
                              operator: "v?, votable:, c?, contributable:",
                              function: "기여할 수 있는 문제",
                              example: "v?true",
                              description: "기여할 수 있는 문제들"),
                          _dataRow(
                            operator: "w?, warning:",
                            function: "문제해결 경고",
                            example: "w?true",
                            description: "문제해결 경고가 있는 문제들",
                          ),
                          _dataRow(
                            operator: "v#, voted:, c#, contributed:",
                            function: "기여한 사람 수",
                            example: "v#100..",
                            description: "100명 이상이 기여한 문제들",
                          ),
                        ]),
                  ],
                );
              } else if (state.status.isLoading) {
                return Center(
                  child: CircularProgressIndicator(color: MySolvedColor.main),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      if (state.currentIndex == 0 && state.problems != null)
                        Column(
                          children: List.generate(
                            state.problems!.items.length,
                            (index) => Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    String urlString =
                                        "https://acmicpc.net/problem/${state.problems!.items[index].problemId}";
                                    launchUrlString(urlString);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.all(16),
                                    backgroundColor: MySolvedColor.background,
                                    foregroundColor: MySolvedColor.font,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    minimumSize: Size.fromHeight(52),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/images/tiers/${state.problems!.items[index].level}.svg',
                                            width: 18,
                                            height: 18,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "${state.problems!.items[index].problemId}번",
                                            style: MySolvedTextStyle.body2,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      // 문제 제목에 HTML 태그가 포함되어 있을 경우
                                      state.problems!.items[index].titleKo
                                              .contains("</")
                                          ? HtmlWidget(
                                              state.problems!.items[index]
                                                  .titleKo,
                                              textStyle:
                                                  MySolvedTextStyle.body1,
                                            )
                                          : Text(
                                              state.problems!.items[index]
                                                  .titleKo,
                                              style: MySolvedTextStyle.body1,
                                            ),
                                      SizedBox(height: 8),
                                      Wrap(
                                        children: List.generate(
                                          state.problems!.items[index].tags
                                              .length,
                                          (subIndex) => Text(
                                            "#${state.problems!.items[index].tags[subIndex].displayNames[0]["name"]} ",
                                            style: MySolvedTextStyle.caption1
                                                .copyWith(
                                              color:
                                                  MySolvedColor.secondaryFont,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      if (state.currentIndex == 1 && state.users != null)
                        Column(
                          children: List.generate(
                            state.users!.items.length,
                            (index) => Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.all(16),
                                    backgroundColor: MySolvedColor.background,
                                    foregroundColor: MySolvedColor.font,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    minimumSize: Size.fromHeight(52),
                                  ),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/images/tiers/${state.users!.items[index].tier}.svg",
                                        width: 24,
                                        height: 24,
                                      ),
                                      SizedBox(width: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: ExtendedImage.network(
                                          state.users!.items[index]
                                                  .profileImageUrl ??
                                              "https://static.solved.ac/misc/360x360/default_profile.png",
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        state.users!.items[index].handle,
                                        style: MySolvedTextStyle.body1,
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      if (state.currentIndex == 2 && state.tags != null)
                        Column(
                          children: List.generate(
                            state.tags!.items.length,
                            (index) => Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    String urlString =
                                        "https://solved.ac/search?query=%23${state.tags!.items[index].key}";
                                    launchUrlString(urlString);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.all(16),
                                    backgroundColor: MySolvedColor.background,
                                    foregroundColor: MySolvedColor.font,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    minimumSize: Size.fromHeight(52),
                                  ),
                                  child: Text(
                                    "${state.tags!.items[index].key}:${state.tags!.items[index].problemCount}",
                                    style: MySolvedTextStyle.body1,
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
    // return
  }
}

class SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  Widget body;

  SearchHeaderDelegate({required this.body});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return body;
  }

  @override
  double get maxExtent => 144 - 16;

  @override
  double get minExtent => 144 - 16;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

DataRow _dataRow({
  required String operator,
  required String function,
  required String example,
  required String description,
}) {
  return DataRow(
    cells: [
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(operator),
          Text(function, style: MySolvedTextStyle.caption2),
        ],
      )),
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(example),
          Text(description, style: MySolvedTextStyle.caption2),
        ],
      )),
    ],
  );
}
