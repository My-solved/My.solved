import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/atoms/text_field/text_field.dart';
import 'package:my_solved/components/molecules/segmented_control/segmented_control.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/search/bloc/search_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MySolvedColor.secondaryBackground,
      body: SafeArea(
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: SearchView(),
            )
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BlocConsumer<SearchBloc, SearchState>(
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
        bloc: BlocProvider.of<SearchBloc>(context),
        builder: (context, state) {
          return Column(
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
                        .add(SearchSegmentedControlTapped(index: index)),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.filter_list),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (state.status.isSuccess)
                Column(
                  children: [
                    if (state.currentIndex == 0 && state.problems != null)
                      Column(
                        children: List.generate(
                          state.problems!.items.length,
                          (index) => Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: MySolvedColor.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${state.problems!.items[index]["problemId"]}번",
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      state.problems!.items[index]["titleKo"],
                                      style: MySolvedTextStyle.title5,
                                    ),
                                    SizedBox(height: 4),
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
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: MySolvedColor.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      state.users![index].handle,
                                      style: MySolvedTextStyle.body1,
                                    ),
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
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: MySolvedColor.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  "${state.tags!.items[index]["key"]}:${state.tags!.items[index]["problemCount"]}",
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
              if (state.status.isLoading)
                Center(
                  child: CircularProgressIndicator(color: MySolvedColor.main),
                ),
            ],
          );
        },
      ),
    );
  }
}
