import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/atoms/button/button.dart';
import 'package:my_solved/components/atoms/text_field/text_field.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/login/login_bloc.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          padding:
              const EdgeInsets.only(top: 100, right: 20, left: 20, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "계정 연결하기",
                    style: MySolvedTextStyle.title1,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "백준 아이디를 입력해주세요!",
                    style: MySolvedTextStyle.body2.copyWith(
                      color: MySolvedColor.secondaryFont,
                    ),
                  ),
                  SizedBox(height: 42),
                  BlocBuilder(
                    bloc: BlocProvider.of<LoginBloc>(context),
                    builder: (context, state) {
                      return MySolvedTextField(
                        hintText: "아이디를 입력해주세요",
                        onChange: (text) {},
                        onSubmitted: (text) {},
                      );
                    },
                  ),
                ],
              ),
              MySolvedFillButton(
                onPressed: () {},
                text: "로그인",
              )
            ],
          ),
        ),
      ),
    );
  }
}
