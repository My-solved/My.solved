import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/views/problem_detail_view.dart';
import 'package:my_solved/view_models/problem_detail_view_model.dart';

class ProblemDetailPage extends StatelessWidget {
  late int problemId;

  ProblemDetailPage(this.problemId);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProblemDetailViewModel>(
      create: (_) => ProblemDetailViewModel(problemId),
      child: ProblemDetailView(),
    );
  }
}
