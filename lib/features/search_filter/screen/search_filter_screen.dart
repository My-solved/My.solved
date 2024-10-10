import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/search/bloc/search_bloc.dart';
import 'package:my_solved/features/search_filter/bloc/search_filter_bloc.dart';

class SearchFilterScreen extends StatelessWidget {
  final SearchBloc searchBLoc;

  const SearchFilterScreen({super.key, required this.searchBLoc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchFilterBloc(),
      child: SearchFilterView(searchBLoc: searchBLoc),
    );
  }
}

class SearchFilterView extends StatefulWidget {
  final SearchBloc searchBLoc;

  const SearchFilterView({super.key, required this.searchBLoc});

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
        backgroundColor: MySolvedColor.background,
        appBar: AppBar(
          backgroundColor: MySolvedColor.background,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            "검색 설정",
            style: MySolvedTextStyle.title5,
          ),
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
                  BlocBuilder<SearchBloc, SearchState>(
                    bloc: widget.searchBLoc,
                    builder: (context, state) {
                      return PopupMenuButton(
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: MySolvedColor.secondaryBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(state.sort.displayName,
                              style: MySolvedTextStyle.body1),
                        ),
                        itemBuilder: (context) {
                          final sorts =
                              context.read<SearchFilterBloc>().state.sorts;
                          return List.generate(
                            sorts.length,
                            (index) => PopupMenuItem<SearchSortMethod>(
                              value: sorts[index],
                              child: Text(sorts[index].displayName),
                            ),
                          );
                        },
                        onSelected: (value) => widget.searchBLoc
                            .add(SearchFilterSortMethodSelected(sort: value)),
                      );
                    },
                  )
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("정렬 방법", style: MySolvedTextStyle.body2),
                  BlocBuilder<SearchBloc, SearchState>(
                    bloc: widget.searchBLoc,
                    builder: (context, state) {
                      return PopupMenuButton(
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: MySolvedColor.secondaryBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.direction.displayName,
                            style: MySolvedTextStyle.body1,
                          ),
                        ),
                        itemBuilder: (context) {
                          final directions =
                              context.read<SearchFilterBloc>().state.directions;
                          return List.generate(
                            directions.length,
                            (index) => PopupMenuItem<SearchDirection>(
                              value: directions[index],
                              child: Text(directions[index].displayName),
                            ),
                          );
                        },
                        onSelected: (value) => widget.searchBLoc.add(
                            SearchFilterDirectionSelected(direction: value)),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("내가 푼 문제 보지 않기", style: MySolvedTextStyle.body2),
                  BlocBuilder<SearchBloc, SearchState>(
                    bloc: widget.searchBLoc,
                    builder: (context, state) {
                      return Switch(
                        value: state.showSolvedProblem,
                        onChanged: (isOn) => widget.searchBLoc.add(
                            SearchFilterShowSolvedProblemChanged(isOn: isOn)),
                        activeColor: MySolvedColor.background,
                        activeTrackColor: MySolvedColor.main,
                        inactiveThumbColor: MySolvedColor.background,
                        inactiveTrackColor:
                            MySolvedColor.disabledButtonBackground,
                        trackOutlineColor: MaterialStateProperty.resolveWith(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return null;
                            }
                            return MySolvedColor.disabledButtonBackground;
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("문제 태그 보지 않기", style: MySolvedTextStyle.body2),
                  BlocBuilder<SearchBloc, SearchState>(
                    bloc: widget.searchBLoc,
                    builder: (context, state) {
                      return Switch(
                        value: !state.showProblemTag,
                        onChanged: (isOn) => widget.searchBLoc.add(
                            SearchFilterShowProblemTagChanged(isOn: !isOn)),
                        activeColor: MySolvedColor.background,
                        activeTrackColor: MySolvedColor.main,
                        inactiveThumbColor: MySolvedColor.background,
                        inactiveTrackColor:
                            MySolvedColor.disabledButtonBackground,
                        trackOutlineColor: MaterialStateProperty.resolveWith(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return null;
                            }
                            return MySolvedColor.disabledButtonBackground;
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
