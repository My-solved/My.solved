import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/contest_filter/bloc/contest_filter_bloc.dart';

class ContestFilterScreen extends StatelessWidget {
  const ContestFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ContestFilterBloc>(
      create: (context) => ContestFilterBloc(),
      child: ContestFilterView(),
    );
  }
}

class ContestFilterView extends StatefulWidget {
  const ContestFilterView({super.key});

  @override
  State<ContestFilterView> createState() => _ContestFilterViewState();
}

class _ContestFilterViewState extends State<ContestFilterView> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text("대회 필터 설정", style: MySolvedTextStyle.title5),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "저장",
                style: MySolvedTextStyle.body1.copyWith(
                  color: MySolvedColor.main,
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text("주최", style: MySolvedTextStyle.body2),
            ],
          ),
        ),
      ),
    );
  }
}
