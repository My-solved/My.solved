import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'setting_event.dart';
part 'setting_state.dart';

class SettingBloc extends Bloc<SettingEvent, SettingState> {
  SettingBloc()
      : super(SettingState(
          streakTime: TimeOfDay.now(),
          contestTime: TimeOfDay.now(),
        )) {
    on<StreakTimeOfDayChanged>(
      (event, emit) => state.copyWith(streakTime: event.timeOfDay),
    );
  }
}
