import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/molecules/segmented_control/segmented_control.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/contest/bloc/contest_bloc.dart';

class ContestScreen extends StatelessWidget {
  const ContestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: BlocBuilder<ContestBloc, ContestState>(
            builder: (context, state) {
              return MySolvedSegmentedControl(
                defaultIndex: 0,
                screenTitles: ["진행중인 대회", "예정된 대회"],
                onSelected: (index) {
                  context
                      .read<ContestBloc>()
                      .add(SegmentedControlTapped(index: index));
                },
              );
            },
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Center(
                  child: Text("Contest Filter View"),
                ),
              );
            },
            icon: Icon(Icons.filter_list),
          ),
        ],
        leadingWidth: 240,
      ),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ContestView(),
          )
        ],
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
      listener: (context, state) {
        if (state is ContestFailure) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("네트워크 오류가 발생했어요"),
                content: Text("잠시 후 다시 시도해주세요\n${state.errorMessage}"),
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
      bloc: BlocProvider.of<ContestBloc>(context),
      builder: (context, state) {
        if (state is ContestSuccess) {
          final contests = state.current == 0
              ? state.processingContest
              : state.expiredContest;
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
            return Column(
              children: List.generate(
                contests.length,
                (index) => Text(contests[index]),
              ),
            );
          }
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
