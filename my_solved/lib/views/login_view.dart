import 'package:flutter/cupertino.dart';
import 'package:my_solved/view_models/login_view_model.dart';
import 'package:provider/provider.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<LoginViewModel>(context);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 100, left: 20, right: 20),
                child: Text(
                  "로그인",
                  style: TextStyle(
                      color: CupertinoTheme.of(context).textTheme.textStyle.color,
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 8, left: 20, right: 20),
                child: Text(
                  "백준 닉네임을 입력해주세요",
                  style: TextStyle(fontSize: 14, color: Color(0xff767676)),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context).barBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.only(top: 60, left: 20, right: 20),
                padding:
                    EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10),
                child: CupertinoTextField.borderless(
                  placeholder: "닉네임을 입력해주세요.",
                  onChanged: (value) {
                    viewModel.textFieldChanged(value);
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                width: MediaQuery.of(context).size.width,
                child: CupertinoButton(
                  color: Color(0xff11ce3c),
                  onPressed: () {
                    viewModel.onTapLoginButton(context);
                  },
                  child: Text("로그인"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
