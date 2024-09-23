import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
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
          streakNotificationTime: TimeOfDay.now(),
          contestNotificationMinute: 60,
        )) {
    on<SettingInit>(_onInit);
    on<SettingIsOnIllustBackgroundChanged>(_onIsOnIllustBackgroundChanged);
    on<SettingStreakNotificationTimeChanged>(_onChangeStreakTime);
    on<SettingStreakNotificationSwitchChanged>(_onChangeIsOnStreakNotification);
    on<SettingContestNotificationMinuteChanged>(
        _onChangeContestNotificationMinute);
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
    final contestNotificationMinute =
        await _sharedPreferencesRepository.getContestNotificationMinute();
    final streakNotificationTime =
        (streakNotificationHour != null) && (streakNotificationMinute != null)
            ? TimeOfDay(
                hour: streakNotificationHour, minute: streakNotificationMinute)
            : now;

    emit(state.copyWith(
      isOnStreakNotification: isOnStreakNotification,
      streakNotificationTime: streakNotificationTime,
      contestNotificationMinute: contestNotificationMinute,
    ));
  }

  Future<void> _onIsOnIllustBackgroundChanged(
    SettingIsOnIllustBackgroundChanged event,
    Emitter<SettingState> emit,
  ) async {
    await _sharedPreferencesRepository.setIsOnIllustBackground(
      isShow: event.isOn,
    );
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
    emit(state.copyWith(streakNotificationTime: event.timeOfDay));
  }

  Future<void> _onChangeIsOnStreakNotification(
    SettingStreakNotificationSwitchChanged event,
    Emitter<SettingState> emit,
  ) async {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      status = await Permission.notification.request();
      emit(state.copyWith(isOnStreakNotification: status.isGranted));
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      emit(state.copyWith(isOnStreakNotification: status.isGranted));
    }
    if (!status.isGranted) {
      return;
    }

    if (event.isOn) {
      await _streakNotificationRepository.setStreakNotification(
        hour: state.streakNotificationTime.hour,
        minute: state.streakNotificationTime.minute,
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

  Future<void> _onChangeContestNotificationMinute(
    SettingContestNotificationMinuteChanged event,
    Emitter<SettingState> emit,
  ) async {
    await _sharedPreferencesRepository.setContestNotificationMinute(
      minute: event.minute,
    );
    emit(state.copyWith(contestNotificationMinute: event.minute));
  }
}
