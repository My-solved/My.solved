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
                placeholder: '문제 번호를 입력해주세요.',
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
                          Align(alignment: Alignment.center,child: Container(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(snapshot.data!.getElementById('problem_title')!.text),
                          ),),
                          Container(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              '문제',
                              style:
                                  TextStyle(fontSize: 16, color: Color(0xff767676)),
                            ),
                          ),
                          Container(
                            child: Text(snapshot.data!.getElementById('problem_description')!.text,
                              style: TextStyle(fontSize: 14, color: Color(0xff767676)),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              '입력',
                              style:
                                  TextStyle(fontSize: 16, color: Color(0xff767676)),
                            ),
                          ),
                          Container(
                            child: Text(snapshot.data!.getElementById('problem_input')!.text,
                              style: TextStyle(fontSize: 14, color: Color(0xff767676)),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              '출력',
                              style:
                                  TextStyle(fontSize: 16, color: Color(0xff767676)),
                            ),
                          ),
                          Container(
                            child: Text(snapshot.data!.getElementById('problem_output')!.text,
                              style: TextStyle(fontSize: 14, color: Color(0xff767676)),
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
