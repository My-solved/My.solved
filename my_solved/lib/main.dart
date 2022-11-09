import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//import 'package:my_solved/model/search/problem.dart';
import 'package:my_solved/model/search/suggestion.dart';
//import 'package:my_solved/provider/problem/show_api.dart';
//import 'package:my_solved/provider/search/problem_api.dart';
import 'package:my_solved/provider/search/suggestion_api.dart';

void main() => runApp(const SearchTextFieldApp());

class SearchTextFieldApp extends StatelessWidget {
  const SearchTextFieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: SearchTextFieldExample(),
    );
  }
}

class SearchTextFieldExample extends StatefulWidget {
  const SearchTextFieldExample({super.key});

  @override
  State<SearchTextFieldExample> createState() => _SearchTextFieldExampleState();
}

class _SearchTextFieldExampleState extends State<SearchTextFieldExample> {
  late TextEditingController textController;

  //late Future<SearchProblem> futureProblem;
  late Future<SearchSuggestion> futureProblem;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: 'dd');
    //futureProblem = searchProblem();
    futureProblem = searchSuggestion();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch Data Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fetch Data Example'),
        ),
        body: Center(
          child: FutureBuilder<SearchSuggestion>(
            future: futureProblem,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                //return Text(snapshot.data!.items.first['problemId'].toString());
                return Text(snapshot.data!.problems.first.toString());
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
