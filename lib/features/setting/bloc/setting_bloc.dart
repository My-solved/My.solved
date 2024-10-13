import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:streak_notification_repository/streak_notification_repository.dart';

import '../../../components/styles/color.dart';

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

    final now = TimeOfDay.now();
    var streakNotificationHour =
        await _sharedPreferencesRepository.getStreakNotificationHour();
    if (streakNotificationHour == null) {
      await _sharedPreferencesRepository.setStreakNotificationHour(
          hour: now.hour);
      streakNotificationHour = now.hour;
    }
    var streakNotificationMinute =
        await _sharedPreferencesRepository.getStreakNotificationMinute();
    if (streakNotificationMinute == null) {
      await _sharedPreferencesRepository.setStreakNotificationMinute(
          minute: now.minute);
      streakNotificationMinute = now.minute;
    }

    final contestNotificationMinute =
        await _sharedPreferencesRepository.getContestNotificationMinute();

    final streakNotificationTime = TimeOfDay(
        hour: streakNotificationHour, minute: streakNotificationMinute);

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
    var status = await Permission.notification.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(
          msg: "알림 권한을 허용해주세요.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: MySolvedColor.main.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0);
      await Future.delayed(const Duration(seconds: 1));
      await openAppSettings();
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
