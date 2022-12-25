import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_solved/pages/problem_detail_page.dart';
import 'package:my_solved/pages/profile_detail_page.dart';
import 'package:my_solved/view_models/search_view_model.dart';
import 'package:provider/provider.dart';

import '../pages/tag_detail_page.dart';

class SearchView extends StatelessWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<SearchViewModel>(context);

    return CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.topLeft,
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!viewModel.isSubmitted)
                  Container(
                    padding: EdgeInsets.only(top: 40, left: 20, right: 20),
                    child: Text(
                      '문제 검색',
                      style: TextStyle(
                          color: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .color,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
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
                if (!viewModel.isSubmitted)
                  Container(
                    padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                    child: Text('과거 검색 내역'),
                  )
                else
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
                              problemHeader(context),
                              for (dynamic problem in snapshot.data!.problems)
                                problemCell(problem, context),
                              userHeader(),
                              for (dynamic user in snapshot.data!.users)
                                userCell(user, context),
                              tagHeader(),
                              for (dynamic tag in snapshot.data!.tags)
                                tagCell(tag, context)
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

extension SearchViewExtension on SearchView {
  Widget problemHeader(BuildContext context) {
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
          builder: (context) => ProblemDetailPage(problem['id']),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 20, left: 20),
              child: Text(
                '${problem['id']}번',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoTheme.of(context).textTheme.textStyle.color,
                ),
              ),
            ),
            Container(
                padding: EdgeInsets.only(
                  top: 10,
                  left: 20,
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'lib/assets/tiers/${problem['level']}.svg',
                      width: 20,
                      height: 20,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      '${problem['title']}',
                      style: TextStyle(
                          fontSize: 20,
                          color: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .color),
                    ),
                  ],
                )),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.only(
                    top: 12,
                    left: 20,
                  ),
                  child: Text(
                    '맞은 사람 수 : ${problem['solved']}',
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
                ),
              ],
            ),
          ],
        ),
      ),
    ));
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
            color: CupertinoTheme.of(context).barBackgroundColor,
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
              child: Row(
                children: [
                  SvgPicture.asset(
                    'lib/assets/tiers/${user['tier']}.svg',
                    width: 20,
                    height: 20,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text('${user['handle']}',
                      style: TextStyle(
                          color: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .color)),
                ],
              )),
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
        child: GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => TagDetailPage(tag['key']),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
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
          child: Text('${tag['key']} : ${tag['description']}',
              style: TextStyle(
                  color: CupertinoTheme.of(context).textTheme.textStyle.color)),
        ),
      ),
    ));
  }
}
