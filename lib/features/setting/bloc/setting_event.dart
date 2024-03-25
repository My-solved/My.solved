part of 'setting_bloc.dart';

abstract class SettingEvent {}

class SettingInit extends SettingEvent {}

class SettingIsOnIllustBackgroundChanged extends SettingEvent {
  final bool isOn;

  SettingIsOnIllustBackgroundChanged({required this.isOn});
}

class SettingStreakNotificationSwitchChanged extends SettingEvent {
  final bool isOn;

  SettingStreakNotificationSwitchChanged({required this.isOn});
}

class SettingStreakNotificationTimeChanged extends SettingEvent {
  final TimeOfDay timeOfDay;

  SettingStreakNotificationTimeChanged({required this.timeOfDay});
}

class SettingContestNotificationMinuteChanged extends SettingEvent {
  final int minute;

  SettingContestNotificationMinuteChanged({required this.minute});
}