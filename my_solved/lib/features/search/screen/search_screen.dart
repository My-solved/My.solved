import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/atoms/text_field/text_field.dart';
import 'package:my_solved/components/molecules/segmented_control/segmented_control.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/features/search/bloc/search_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              MySolvedSearchField(
                hintText: "문제, 사용자, 태그를 입력해주세요",
                onChange: (text) => context
                    .read<SearchBloc>()
                    .add(SearchTextFieldOnChanged(text: text)),
                onSubmitted: (text) => context
                    .read<SearchBloc>()
                    .add(SearchTextFieldOnSummited(text: text)),
              ),
              if (state.status.isSuccess)
                Column(
                  children: [
                    SizedBox(height: 32),
                    MySolvedSegmentedControl(
                      screenTitles: ["문제", "사용자", "태그"],
                      defaultIndex: state.currentIndex,
                      onSelected: (index) => context
                          .read<SearchBloc>()
                          .add(SearchSegmentedControlTapped(index: index)),
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
