import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../views/search_view.dart';
import '../view_models/search_view_model.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchViewModel>(
      create: (_) => SearchViewModel(),
      child: SearchView(),
    );
  }
}
