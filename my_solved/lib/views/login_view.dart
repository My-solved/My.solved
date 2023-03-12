import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_solved/extensions/color_extension.dart';
import 'package:my_solved/main.dart';
import 'package:my_solved/services/network_service.dart';
import 'package:my_solved/services/user_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  UserService userService = UserService();
  NetworkService networkService = NetworkService();
  String input = '';

  @override
  Widget build(BuildContext context) {
    PageRouterState? parent =
        context.findAncestorStateOfType<PageRouterState>();

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      child: SafeArea(
        child: Container(
          padding:
              const EdgeInsets.only(top: 100, right: 20, left: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              header(),
              userNameTextField(),
              loginButton(parent),
            ],
          ),
        ),
      ),
    );
  }
}

extension _LoginStateExtension on _LoginViewState {
  Widget header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '로그인',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(
            '백준 아이디로 로그인해주세요.',
            style: TextStyle(
                fontSize: 14, color: CupertinoTheme.of(context).fontGray),
          ),
        ),
      ],
    );
  }

  Widget userNameTextField() {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).backgroundGray,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: CupertinoTextField.borderless(
        padding: const EdgeInsets.all(20),
        placeholder: '아이디를 입력해주세요.',
        onChanged: (text) {
          input = text;
        },
      ),
    );
  }

  Widget loginButton(PageRouterState? parent) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      width: MediaQuery.of(context).size.width,
      child: CupertinoButton(
        padding: const EdgeInsets.all(20),
        color: CupertinoTheme.of(context).main,
        onPressed: () {
          networkService
              .requestUser(input)
              .then((value) => parent?.setState(() {
                    userService.setUserName(input);
                    userService.state = UserState.loggedIn;
                    Fluttertoast.showToast(msg: '로그인 성공!');
                  }))
              .onError((error, stackTrace) =>
                  Fluttertoast.showToast(msg: '아이디를 확인해주세요.'));
        },
        child: const Text('로그인'),
      ),
    );
  }
}
