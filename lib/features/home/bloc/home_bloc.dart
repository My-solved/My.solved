import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part "home_event.dart";
part "home_state.dart";

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeState()) {
    on<InitHome>((event, emit) {
      print("Init Home");
    });
  }
}
