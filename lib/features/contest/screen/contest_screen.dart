import 'package:boj_api/boj_api.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
                    .add(ContestSegmentedControlPressed(index: index));
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
    context.read<ContestBloc>().add(ContestInit());
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
                        onPressed: () {},
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
                            SizedBox(height: 8),
                            Text(
                              '일정: ${contests[index].startTime.toLocal().month}월 ${contests[index].startTime.toLocal().day}일 ${contests[index].startTime.toLocal().hour}:${contests[index].startTime.toLocal().minute.toString().padLeft(2, '0')} ~ ${contests[index].endTime.toLocal().month}월 ${contests[index].endTime.toLocal().day}일 ${contests[index].endTime.toLocal().hour}:${contests[index].endTime.toLocal().minute.toString().padLeft(2, '0')}',
                              style: MySolvedTextStyle.body2.copyWith(
                                color: MySolvedColor.secondaryFont,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              height: 50,
                              child: Row(
                                children: [
                                  if (state.currentIndex == 1)
                                    IconButton(
                                        onPressed: () => context
                                            .read<ContestBloc>()
                                            .add(
                                                ContestNotificationButtonPressed(
                                              index: index,
                                            )),
                                        style: ButtonStyle(
                                          backgroundColor: state
                                                      .isOnNotificationUpcomingContests[
                                                  index]
                                              ? MaterialStateProperty.all(
                                                  MySolvedColor
                                                      .secondaryButtonBackground)
                                              : MaterialStateProperty.all(
                                                  MySolvedColor.main),
                                        ),
                                        icon: Icon(
                                          state.isOnNotificationUpcomingContests[
                                                  index]
                                              ? Icons.alarm_off
                                              : Icons.alarm,
                                          color:
                                              state.isOnNotificationUpcomingContests[
                                                      index]
                                                  ? MySolvedColor.secondaryFont
                                                  : MySolvedColor.background,
                                        )),
                                  if (state.currentIndex == 1)
                                    IconButton(
                                        onPressed: () {
                                          context.read<ContestBloc>().add(
                                              ContestCalendarButtonPressed(
                                                  index: index));
                                        },
                                        style: ButtonStyle(
                                          backgroundColor: state
                                                      .isOnCalendarUpcomingContests[
                                                  index]
                                              ? MaterialStateProperty.all(
                                                  MySolvedColor
                                                      .secondaryButtonBackground)
                                              : MaterialStateProperty.all(
                                                  MySolvedColor.main),
                                        ),
                                        icon: Icon(
                                          Icons.calendar_month,
                                          color:
                                              state.isOnCalendarUpcomingContests[
                                                      index]
                                                  ? MySolvedColor.secondaryFont
                                                  : MySolvedColor.background,
                                          size: 20,
                                        )),
                                  Spacer(),
                                  if (contests[index].badge != null)
                                    IconButton(
                                      onPressed: () => Fluttertoast.showToast(
                                          msg:
                                              "${contests[index].badge!}시 뱃지 획득",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: MySolvedColor.main
                                              .withOpacity(0.8),
                                          textColor: Colors.white,
                                          fontSize: 16.0),
                                      style: IconButton.styleFrom(
                                          foregroundColor: Color(0xFFfab005),
                                          backgroundColor: MySolvedColor
                                              .secondaryBackground),
                                      icon: Icon(Icons.badge),
                                    ),
                                  if (contests[index].background != null)
                                    IconButton(
                                      onPressed: () => Fluttertoast.showToast(
                                          msg:
                                              "${contests[index].background!}시 배경 획득",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: MySolvedColor.main
                                              .withOpacity(0.8),
                                          textColor: Colors.white,
                                          fontSize: 16.0),
                                      style: IconButton.styleFrom(
                                        foregroundColor: Color(0xFFb197fc),
                                        backgroundColor:
                                            MySolvedColor.secondaryBackground,
                                      ),
                                      icon: Icon(Icons.image),
                                    ),
                                  IconButton(
                                    onPressed: () async {
                                      final urlString = contests[index].url;
                                      if (urlString != null) {
                                        launchUrlString(urlString);
                                      }
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          MySolvedColor.secondaryBackground,
                                    ),
                                    icon: ExtendedImage.asset(
                                      "assets/images/venues/${contests[index].venue.toLowerCase()}.png",
                                      width: 24,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            if (state.currentIndex == 0)
                              Container(
                                  margin: EdgeInsets.only(top: 8),
                                  child: ProgressIndicator(
                                      contests[index].startTime.toLocal(),
                                      contests[index].endTime.toLocal())),
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

class ProgressIndicator extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;

  const ProgressIndicator(this.startTime, this.endTime, {super.key});

  @override
  State<ProgressIndicator> createState() => _ProgressIndicatorState();
}

class _ProgressIndicatorState extends State<ProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController controller;

  DateTime get startTime => widget.startTime;

  DateTime get endTime => widget.endTime;

  @override
  void initState() {
    controller = AnimationController(
        vsync: this,
        duration: endTime.difference(startTime),
        value: DateTime.now().difference(startTime).inSeconds /
            endTime.difference(startTime).inSeconds)
      ..addListener(() {
        setState(() {});
      });
    controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: controller.value,
      valueColor: AlwaysStoppedAnimation(MySolvedColor.main),
    );
  }
}
