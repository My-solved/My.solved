import 'package:flutter/cupertino.dart';
import 'package:my_solved/view_models/search_view_model.dart';
import 'package:provider/provider.dart';

class SearchView extends StatelessWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<SearchViewModel>(context);

    return CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.topLeft,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!viewModel.isSubmitted)
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
              if (!viewModel.isSubmitted)
                Container(
                  padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: Text('과거 검색 내역'),
                )
              else
                Container(
                  padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          '문제',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xff767676)),
                        ),
                      ),
                      for (Problem problem in viewModel.problems)
                        Container(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(problem.titleKo),
                        ),
                      Container(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          '사용자',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xff767676)),
                        ),
                      ),
                      for (User user in viewModel.users)
                        Container(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(user.handle),
                        ),
                      Container(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(
                          '태그',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xff767676)),
                        ),
                      ),
                      for (Tag tag in viewModel.tags)
                        Container(
                          color: Color(0xffefefef),
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.only(top: 10),
                          child: Text(tag.key),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
