import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/view_models/problem_detail_view_model.dart';
import 'package:my_solved/widgets/problem_widget.dart';
import 'package:html/dom.dart' as dom;

class ProblemDetailView extends StatelessWidget {
  const ProblemDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<ProblemDetailViewModel>(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${viewModel.problemId ?? 0}번'),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  FutureBuilder<dom.Document>(
                    future: viewModel.future,
                    builder: (context, snapshot) {
                      return Container(
                        padding: EdgeInsets.only(
                            top: 20, left: 20, right: 20, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            titleHeader(),
                            titleContent(snapshot, context),
                            descriptionHeader(),
                            descriptionContent(snapshot, context),
                            inputHeader(),
                            inputContent(snapshot, context),
                            outputHeader(),
                            outputContent(snapshot, context),
                            sampleInputHeader(),
                            sampleInputContent(snapshot, context),
                            sampleOutputHeader(),
                            sampleOutputContent(snapshot, context),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
