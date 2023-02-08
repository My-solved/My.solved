import 'package:flutter/cupertino.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/models/search/suggestion.dart';
import 'package:my_solved/services/network_service.dart';

class SearchView extends StatefulWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  NetworkService networkService = NetworkService();
  String input = '';
  bool isSubmitted = false;
  Future<SearchSuggestion>? future;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!isSubmitted)
                  header(),
                searchBar(),
                if (isSubmitted)
                  FutureBuilder(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (snapshot.data!.problems.length > 0)
                              problemHeader(context),
                            for (dynamic problem in snapshot.data!.problems)
                              Container(
                                decoration: BoxDecoration(
                                    color: CupertinoTheme.of(context)
                                        .backgroundGray,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10))),
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(20),
                                width: MediaQuery.of(context).size.width,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${problem['id']}번',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      '${problem['title']}',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      '맞은 사람 수: ${problem['solved']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                        CupertinoTheme.of(context).fontGray,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      'Level: ${problem['level']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                        CupertinoTheme.of(context).fontGray,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      '평균 시도 횟수:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                        CupertinoTheme.of(context).fontGray,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      '태그:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                        CupertinoTheme.of(context).fontGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (snapshot.data!.users.length > 0)
                              userHeader(context),
                            for (dynamic user in snapshot.data?.users ?? [])
                              Container(
                                decoration: BoxDecoration(
                                    color: CupertinoTheme.of(context)
                                        .backgroundGray,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10))),
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.only(
                                    top: 12, right: 20, bottom: 12, left: 20),
                                width: MediaQuery.of(context).size.width,
                                child: Text(
                                  '${user['handle']}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            if (snapshot.data!.tags.length > 0)
                              tagHeader(context),
                            for (dynamic tag in snapshot.data?.tags ?? [])
                              Container(
                                decoration: BoxDecoration(
                                    color: CupertinoTheme.of(context)
                                        .backgroundGray,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10))),
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.only(
                                    top: 12, right: 20, bottom: 12, left: 20),
                                width: MediaQuery.of(context).size.width,
                                child: Text(
                                  '${tag['key']}:${tag['description']}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error'),);
                      } else {
                        return Center(child: CupertinoActivityIndicator());
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _SearchStateExtension on _SearchViewState {
  Widget header() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      child: const Text(
        '문제 검색',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget searchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: CupertinoSearchTextField(
        placeholder: '문제 번호, 문제 제목을 입력해주세요.',
        onChanged: (text) {
          setState(() {
            input = text;
          });
        },
        onSubmitted: (text) {
          setState(() {
            future = networkService.requestSearch(input);
            isSubmitted = true;
          });
        },
      ),
    );
  }

  Widget problemHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Text(
        '문제',
        style:
        TextStyle(fontSize: 12, color: CupertinoTheme.of(context).fontGray),
      ),
    );
  }

  Widget userHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Text(
        '사용자',
        style: TextStyle(fontSize: 12, color: CupertinoTheme.of(context).fontGray),
      ),
    );
  }

  Widget tagHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Text(
        '태그',
        style: TextStyle(fontSize: 12, color: CupertinoTheme.of(context).fontGray),
      ),
    );
  }
}
