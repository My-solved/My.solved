import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/pages/problem_detail_page.dart';
import 'package:my_solved/pages/profile_detail_page.dart';
import 'package:provider/provider.dart';
import '../view_models/tag_detail_view_model.dart';

class TagDetailView extends StatelessWidget {
  const TagDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<TagDetailViewModel>(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${viewModel.tagName ?? 0}'),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FutureBuilder(
                  future: viewModel.future,
                  builder: ((context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        padding: EdgeInsets.only(
                          top: 20,
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            problemHeader(),
                            for (dynamic problem in snapshot.data!.items)
                              problemCell(problem, context),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    }
                    return const CircularProgressIndicator();
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension TagDetailViewExtension on TagDetailView {
  Widget problemHeader() {
    return CupertinoPageScaffold(
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          '문제',
          style: TextStyle(fontSize: 12, color: Color(0xff767676)),
        ),
      ),
    );
  }

  Widget problemCell(dynamic problem, BuildContext context) {
    return CupertinoPageScaffold(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ProblemDetailPage(problem['problemId']),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xffefefef),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 20, left: 20),
                child: Text('${problem['problemId']}번'),
              ),
              Container(
                padding: EdgeInsets.only(
                  top: 10,
                  left: 20,
                ),
                child: Text(
                  '${problem['titleKo']}',
                  style: TextStyle(fontSize: 22),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      top: 12,
                      left: 20,
                    ),
                    child: Text(
                      '평균 시도 : ${problem['averageTries']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xff767676),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      top: 4,
                      left: 20,
                      bottom: 20,
                    ),
                    child: Text(
                      'Level : ${problem['level']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xff767676),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget userHeader() {
    return CupertinoPageScaffold(
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          '사용자',
          style: TextStyle(fontSize: 12, color: Color(0xff767676)),
        ),
      ),
    );
  }

  Widget userCell(dynamic user, BuildContext context) {
    return CupertinoPageScaffold(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ProfileDetailPage(user['handle']),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xffefefef),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.only(top: 10),
          child: Container(
              padding: EdgeInsets.only(
                top: 12,
                bottom: 12,
                left: 20,
                right: 20,
              ),
              child: Text('${user['handle']}')),
        ),
      ),
    );
  }

  Widget tagHeader() {
    return CupertinoPageScaffold(
      child: Container(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          '태그',
          style: TextStyle(fontSize: 12, color: Color(0xff767676)),
        ),
      ),
    );
  }

  Widget tagCell(dynamic tag, BuildContext context) {
    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xffefefef),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(top: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: 12,
            bottom: 12,
            left: 20,
            right: 20,
          ),
          child: Text('${tag['key']} : ${tag['description']}'),
        ),
      ),
    );
  }
}
