import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/views/problem_view.dart';
import 'package:my_solved/view_models/problem_view_model.dart';

class ProblemPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProblemViewModel>(
      create: (_) => ProblemViewModel(),
      child: ProblemView(),
    );
  }
}
