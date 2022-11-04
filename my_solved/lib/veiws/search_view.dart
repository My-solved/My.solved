import 'package:flutter/material.dart';

class SearchView extends StatelessWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            child: Text(
              "문제 검색",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            padding: EdgeInsets.only(left: 20, top: 40, bottom: 40, right: 20),
          ),
          Container(
            child: TextField(
              decoration: InputDecoration(
                hintText: "문제 번호, 문제 제목을 입력해주세요.",
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
            ),
            margin: EdgeInsets.only(left: 16, right: 16),
          ),
        ],
      ),
    );
  }
}
