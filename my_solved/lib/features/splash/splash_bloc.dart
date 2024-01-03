import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_solved/components/utils/routes.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    on<SplashInit>(_onSplashInit);
  }

  Future<void> _onSplashInit(
    SplashInit event,
    Emitter<SplashState> emit,
  ) async {
    Future.delayed(Duration(seconds: 1));

    // TODO: 로그인 상태에 따라 분기
    event.context.pushNamed(Routes.login.name);
  }
}
