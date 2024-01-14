import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/app/bloc/app_bloc.dart';

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
    await Future.delayed(Duration(seconds: 1));
    if (!event.context.mounted) return;
    event.context.read<AppBloc>().add(AppInit());
  }
}
