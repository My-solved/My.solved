import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/view_models/problem_detail_view_model.dart';

class ProblemDetailView extends StatelessWidget {
  const ProblemDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<ProblemDetailViewModel>(context);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Text("Problem Detail"),
      ),
    );
  }
}
