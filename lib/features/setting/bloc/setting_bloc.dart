import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:streak_notification_repository/streak_notification_repository.dart';

part 'setting_event.dart';
part 'setting_state.dart';

class SettingBloc extends Bloc<SettingEvent, SettingState> {
  SettingBloc({
    required SharedPreferencesRepository sharedPreferencesRepository,
    required StreakNotificationRepository streakNotificationRepository,
  })  : _sharedPreferencesRepository = sharedPreferencesRepository,
        _streakNotificationRepository = streakNotificationRepository,
        super(SettingState(
          isOnStreakNotification: true,
          streakTime: TimeOfDay.now(),
          contestTime: TimeOfDay.now(),
        )) {
    on<SettingInit>(_onInit);
    on<SettingStreakNotificationTimeChanged>(_onChangeStreakTime);
    on<SettingStreakNotificationSwitchChanged>(_onChangeIsOnStreakNotification);
  }

  final SharedPreferencesRepository _sharedPreferencesRepository;
  final StreakNotificationRepository _streakNotificationRepository;

  Future<void> _onInit(
    SettingInit event,
    Emitter<SettingState> emit,
  ) async {
    final isOnStreakNotification =
        await _sharedPreferencesRepository.getIsOnStreakNotification();
    final streakNotificationHour =
        await _sharedPreferencesRepository.getStreakNotificationHour();
    final streakNotificationMinute =
        await _sharedPreferencesRepository.getStreakNotificationMinute();
    final now = TimeOfDay.now();
    final streakTime =
        (streakNotificationHour != null) && (streakNotificationMinute != null)
            ? TimeOfDay(
                hour: streakNotificationHour, minute: streakNotificationMinute)
            : now;

    emit(state.copyWith(
      isOnStreakNotification: isOnStreakNotification,
      streakTime: streakTime,
    ));
  }

  Future<void> _onChangeStreakTime(
    SettingStreakNotificationTimeChanged event,
    Emitter<SettingState> emit,
  ) async {
    await _sharedPreferencesRepository.setStreakNotificationHour(
      hour: event.timeOfDay.hour,
    );
    await _sharedPreferencesRepository.setStreakNotificationMinute(
      minute: event.timeOfDay.minute,
    );
    await _streakNotificationRepository.setStreakNotification(
      hour: event.timeOfDay.hour,
      minute: event.timeOfDay.minute,
    );
    emit(state.copyWith(streakTime: event.timeOfDay));
  }

  Future<void> _onChangeIsOnStreakNotification(
    SettingStreakNotificationSwitchChanged event,
    Emitter<SettingState> emit,
  ) async {
    if (event.isOn) {
      await _streakNotificationRepository.setStreakNotification(
        hour: state.streakTime.hour,
        minute: state.streakTime.minute,
      );
      await _sharedPreferencesRepository.setIsOnStreakNotification(
        isOn: event.isOn,
      );
      emit(state.copyWith(isOnStreakNotification: event.isOn));
    } else {
      _streakNotificationRepository.cancelStreakNotification();
      await _sharedPreferencesRepository.setIsOnStreakNotification(
        isOn: event.isOn,
      );
      emit(state.copyWith(isOnStreakNotification: event.isOn));
    }
  }
}
