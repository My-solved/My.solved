import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Problem> getProblems() async {
  final response = await http.get(Uri.parse('https://solved.ac/api/v3/problem/show?problemId=13705'));
  final statusCode = response.statusCode;

  if (statusCode == 200){
    Problem searchedProblems = Problem.fromJson(jsonDecode(response.body));
    return searchedProblems;
  } else {
    throw Exception('Failed to load');
  }
}

class Problem {
  final int problemId;
  final String titleKo;
  final bool isSolvable;
  final bool isPartial;
  final int acceptedUserCount;
  final int level;
  final int votedUserCount;
  final bool isLevelLocked;
  final num averageTries;

  const Problem({
    required this.problemId,
    required this.titleKo,
    required this.isSolvable,
    required this.isPartial,
    required this.acceptedUserCount,
    required this.level,
    required this.votedUserCount,
    required this.isLevelLocked,
    required this.averageTries,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      problemId: json['problemId'],
      titleKo: json['titleKo'],
      isSolvable: json['isSolvable'],
      isPartial: json['isPartial'],
      acceptedUserCount: json['acceptedUserCount'],
      level: json['level'],
      votedUserCount: json['votedUserCount'],
      isLevelLocked: json['isLevelLocked'],
      averageTries: json['averageTries'],
    );
  }
}

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

  late Future<Problem> futureProblem;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: 'dd');
    futureProblem = getProblems();
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
          child: FutureBuilder<Problem>(
            future: futureProblem,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data!.titleKo);
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
