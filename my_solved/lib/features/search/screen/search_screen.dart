import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/atoms/text_field/text_field.dart';
import 'package:my_solved/features/search/bloc/search_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(),
      child: SearchScreen(),
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              MySolvedSearchField(
                hintText: "문제, 사용자, 태그를 입력해주세요",
                onChange: (text) {},
                onSubmitted: (text) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
