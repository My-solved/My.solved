import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_solved/components/atoms/button/button.dart';
import 'package:my_solved/components/atoms/text_field/text_field.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/login/bloc/login_bloc.dart';

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
              BlocBuilder<LoginBloc, LoginState>(
                bloc: BlocProvider.of<LoginBloc>(context),
                builder: (context, state) {
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MySolvedTextField(
                            hintText: "아이디를 입력해주세요",
                            onChange: (text) => context
                                .read<LoginBloc>()
                                .add(HandleTextFieldOnChanged(handle: text)),
                            onSubmitted: (text) {
                              context
                                  .read<LoginBloc>()
                                  .add(HandleTextFieldOnSummited(handle: text));
                            }),
                        MySolvedFillButton(
                          onPressed: state.handle.isEmpty
                              ? () {
                                  Fluttertoast.showToast(
                                      msg: "존재하지 않는 아이디입니다.",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor:
                                          MySolvedColor.main.withOpacity(0.8),
                                      textColor: Colors.white,
                                      fontSize: 16.0);
                                }
                              : () => context
                                  .read<LoginBloc>()
                                  .add(LoginButtonTapped(
                                    context: context,
                                    handle: state.handle,
                                  )),
                          text: "로그인",
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
