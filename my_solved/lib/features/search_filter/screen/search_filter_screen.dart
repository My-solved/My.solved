import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/search_filter/bloc/search_filter_bloc.dart';

class SearchFilterScreen extends StatelessWidget {
  const SearchFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchFilterBloc(),
      child: SearchFilterView(),
    );
  }
}

class SearchFilterView extends StatefulWidget {
  const SearchFilterView({super.key});

  @override
  State<SearchFilterView> createState() => _SearchFilterViewState();
}

class _SearchFilterViewState extends State<SearchFilterView> {
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
          title: Text(
            "검색 설정",
            style: MySolvedTextStyle.title5,
          ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("정렬 기준", style: MySolvedTextStyle.body2),
                  PopupMenuButton(
                    child: Text("정렬기준"),
                    itemBuilder: (context) {
                      final sorts =
                          context.read<SearchFilterBloc>().state.sorts;
                      return List.generate(
                        sorts.length,
                        (index) => PopupMenuItem<String>(
                          value: sorts[index].value,
                          child: Text(sorts[index].displayName),
                        ),
                      );
                    },
                    onSelected: (value) {},
                  )
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("정렬 방법", style: MySolvedTextStyle.body2),
                  PopupMenuButton(
                    child: Text("정렬방법"),
                    itemBuilder: (context) {
                      final directions =
                          context.read<SearchFilterBloc>().state.directions;
                      return List.generate(
                        directions.length,
                        (index) => PopupMenuItem<String>(
                          value: directions[index].value,
                          child: Text(directions[index].displayName),
                        ),
                      );
                    },
                    onSelected: (value) {},
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("내가 푼 문제 보지 않기", style: MySolvedTextStyle.body2),
                  Switch(
                    value: true,
                    onChanged: ((value) {}),
                    activeColor: MySolvedColor.background,
                    activeTrackColor: MySolvedColor.main,
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
