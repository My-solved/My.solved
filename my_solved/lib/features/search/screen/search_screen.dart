import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/components/atoms/text_field/text_field.dart';
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
                                  child: SearchFilterScreen(),
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
              if (state.status.isLoading) {
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
                                      Text(
                                        state.problems!.items[index].titleKo,
                                        style: MySolvedTextStyle.title5,
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
                            state.users!.length,
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
                                        "assets/images/tiers/${state.users![index].tier}.svg",
                                        width: 24,
                                        height: 24,
                                      ),
                                      SizedBox(width: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: ExtendedImage.network(
                                          state.users![index].profileImageUrl ??
                                              "https://static.solved.ac/misc/360x360/default_profile.png",
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        state.users![index].handle,
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
