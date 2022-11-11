import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/problem_view_model.dart';
import 'package:html/dom.dart' as dom;


class ProblemView extends StatelessWidget {
  const ProblemView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<ProblemViewModel>(context);

    return CupertinoPageScaffold(
      child: Align(
        child: Column(
        children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 40, left: 20, right: 20),
              child: Text(
                '문제 검색',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 40, left: 16, right: 16),
              child: CupertinoSearchTextField(
                placeholder: '문제 번호, 문제 제목을 입력해주세요.',
                onChanged: (String value) {
                  viewModel.textFieldChanged(value);
                },
                onSubmitted: (String value) {
                  viewModel.textFieldChanged(value);
                  viewModel.textFieldSubmitted();
                },
              ),
            ),
            if (viewModel.isSubmitted)
              FutureBuilder<dom.Document>(
                future: viewModel.future,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                style: TextStyle(fontSize: 16), snapshot.data!.getElementById('problem_description').toString(),
                              ),
                            ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  return CircularProgressIndicator();
                },
              )
          ],
        ),
      )
    );
  }
}
