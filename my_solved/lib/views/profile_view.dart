import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_solved/models/User.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/view_models/profile_view_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<ProfileViewModel>(context);

    return CupertinoPageScaffold(
        child: Align(
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(top: 40, left: 20, right: 20),
            child: Text(
              '프로필',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 40, left: 16, right: 16),
            child: CupertinoSearchTextField(
              placeholder: '프로필을 검색할 유저의 아이디를 입력하세요.',
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
            FutureBuilder<User>(
              future: viewModel.future,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Image.network(snapshot.data!.background['backgroundImageUrl']),
                        Container(
                          padding: EdgeInsets.only(top: 20),
                          child: Text(
                            '문제',
                            style: TextStyle(
                                fontSize: 16, color: Color(0xff767676)),
                          ),
                        ),
                        Container(
                          child: Text('푼 문제: ${snapshot.data!.solvedCount}',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xff767676)),
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
    ));
  }
}
