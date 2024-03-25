import 'package:boj_api/boj_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/atoms/button/button.dart';
import 'package:my_solved/components/molecules/segmented_control/segmented_control.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/contest/bloc/contest_bloc.dart';
import 'package:my_solved/features/contest_filter/screen/contest_filter_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContestScreen extends StatelessWidget {
  const ContestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<ContestBloc>(context);
    return BlocBuilder<ContestBloc, ContestState>(
      bloc: bloc,
      builder: (context, state) => Scaffold(
        backgroundColor: MySolvedColor.secondaryBackground,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: MySolvedColor.secondaryBackground,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: MySolvedSegmentedControl(
              defaultIndex: state.currentIndex,
              screenTitles: ["진행중인 대회", "예정된 대회", "종료된 대회"],
              onSelected: (index) {
                context
                    .read<ContestBloc>()
                    .add(SegmentedControlTapped(index: index));
              },
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => ContestFilterScreen(
                    contestBloc: bloc,
                  ),
                );
              },
              icon: Icon(Icons.filter_list),
            ),
          ],
          leadingWidth: 320,
        ),
        body: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ContestView(),
            ),
          ],
        ),
      ),
    );
  }
}

class ContestView extends StatefulWidget {
  const ContestView({super.key});

  @override
  State<ContestView> createState() => _ContestViewState();
}

class _ContestViewState extends State<ContestView> {
  @override
  void initState() {
    super.initState();
    context.read<ContestBloc>().add(InitContest());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContestBloc, ContestState>(
      bloc: BlocProvider.of<ContestBloc>(context),
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
        if (state.status.isSuccess) {
          final contests = _fetchContests(state);
          if (contests.isEmpty) {
            return Center(
              child: Text(
                "현재 대회가 없어요",
                style: MySolvedTextStyle.body1.copyWith(
                  color: MySolvedColor.secondaryFont,
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  contests.length,
                  (index) => Column(
                    children: [
                      ElevatedButton(
                        onPressed: state.currentIndex == 2
                            ? null
                            : () async {
                                final urlString = contests[index].url;
                                if (urlString != null) {
                                  launchUrlString(urlString);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.fromHeight(128),
                          padding: EdgeInsets.all(16),
                          backgroundColor: MySolvedColor.background,
                          disabledBackgroundColor: MySolvedColor.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contests[index].name,
                              style: MySolvedTextStyle.title5.copyWith(
                                color: MySolvedColor.font,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "주최: ${contests[index].venue ?? ""}",
                              style: MySolvedTextStyle.body2.copyWith(
                                color: MySolvedColor.secondaryFont,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '일정: ${contests[index].startTime.month}월 ${contests[index].startTime.day}일 ${contests[index].startTime.hour}:${contests[index].startTime.minute.toString().padLeft(2, '0')} ~ ${contests[index].endTime.month}월 ${contests[index].endTime.day}일 ${contests[index].endTime.hour}:${contests[index].endTime.minute.toString().padLeft(2, '0')}',
                              style: MySolvedTextStyle.body2.copyWith(
                                color: MySolvedColor.secondaryFont,
                              ),
                            ),
                            if (state.currentIndex == 1)
                              Column(
                                children: [
                                  SizedBox(height: 8),
                                  MySolvedFitButton(
                                    onPressed: () {},
                                    text: "알림 설정하기",
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          }
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

  List<Contest> _fetchContests(ContestState state) {
    switch (state.currentIndex) {
      case 0:
        return state.filteredOngoingContests;
      case 1:
        return state.filteredUpcomingContests;
      default:
        return state.filteredEndedContests;
    }
  }
}