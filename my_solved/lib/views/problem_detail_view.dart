import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/view_models/problem_detail_view_model.dart';
import 'package:html/dom.dart' as dom;

class ProblemDetailView extends StatelessWidget {
  const ProblemDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<ProblemDetailViewModel>(context);

    return CupertinoPageScaffold(
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
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            titleHeader(),
                            titleContent(snapshot),
                            descriptionHeader(),
                            descriptionContent(snapshot),
                            inputContent(snapshot),
                            outputContent(snapshot),
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

extension ProblemDetailViewExtension on ProblemDetailView {
  Widget titleHeader() {
    return CupertinoPageScaffold(
      child: Text(
        '문제',
        style: TextStyle(fontSize: 12, color: Color(0xff767676)),
      ),
    );
  }

  Widget titleContent(AsyncSnapshot<dom.Document> snapshot) {
    return CupertinoPageScaffold(
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          snapshot.data?.getElementById('problem_title')?.text ?? '',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget descriptionHeader() {
    return CupertinoPageScaffold(
      child: Text(
        '설명',
        style: TextStyle(fontSize: 12, color: Color(0xff767676)),
      ),
    );
  }

  Widget descriptionContent(AsyncSnapshot<dom.Document> snapshot) {
    return CupertinoPageScaffold(
      child: Container(
        child: Text(
          snapshot.data?.getElementById('problem_description')?.text ?? '',
          style: TextStyle(fontSize: 17),
        ),
      ),
    );
  }

  Widget inputContent(AsyncSnapshot<dom.Document> snapshot) {
    return CupertinoPageScaffold(
      child: Container(
        child: Text(
          snapshot.data?.getElementById('problem_input')?.text ?? '',
          style: TextStyle(fontSize: 17),
        ),
      ),
    );
  }

  Widget outputContent(AsyncSnapshot<dom.Document> snapshot) {
    return CupertinoPageScaffold(
      child: Container(
        child: Text(
          snapshot.data?.getElementById('problem_output')?.text ?? '',
          style: TextStyle(fontSize: 17),
        ),
      ),
    );
  }
}
