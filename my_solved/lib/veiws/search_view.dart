import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                          padding:
                              EdgeInsets.only(top: 20, left: 20, right: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(top: 20),
                                child: Text(
                                  '문제',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xff767676)),
                                ),
                              ),
                              for (dynamic problem in snapshot.data!.problems)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xffefefef),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  margin: EdgeInsets.only(top: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        padding:
                                            EdgeInsets.only(top: 20, left: 20),
                                        child: Text(
                                            '${problem['id']}번'),
                                      ),
                                      Container(
                                        padding: EdgeInsets.only(
                                          top: 10,
                                          left: 20,
                                        ),
                                        child: Text(
                                          problem['title'].toString(),
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
                                            child: Text('맞은 사람 수 : ${problem['solved']}',
                                            style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xff767676),
                                            )),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.only(
                                              top: 4,
                                              left: 20,
                                            ),
                                            child: Text('Level : ${problem['level']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xff767676),
                                                )),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: EdgeInsets.only(top: 20),
                                child: Text(
                                  '사용자',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xff767676)),
                                ),
                              ),
                              for (dynamic user in snapshot.data!.users)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xffefefef),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
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
                                      child: Text(user['handle'].toString())),
                                ),
                              Container(
                                padding: EdgeInsets.only(top: 20),
                                child: Text(
                                  '태그',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xff767676)),
                                ),
                              ),
                              for (dynamic tag in snapshot.data!.tags)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xffefefef),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
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
                                )
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
