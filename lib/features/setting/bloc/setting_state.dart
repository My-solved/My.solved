part of 'setting_bloc.dart';

class SettingState extends Equatable {
  final bool isOnStreakNotification;
  final TimeOfDay streakNotificationTime;
  final int contestNotificationMinute;

  const SettingState({
    required this.isOnStreakNotification,
    required this.streakNotificationTime,
    required this.contestNotificationMinute,
  });

  SettingState copyWith({
    bool? isOnStreakNotification,
    TimeOfDay? streakNotificationTime,
    int? contestNotificationMinute,
  }) {
    return SettingState(
      isOnStreakNotification:
          isOnStreakNotification ?? this.isOnStreakNotification,
      streakNotificationTime:
          streakNotificationTime ?? this.streakNotificationTime,
      contestNotificationMinute:
          contestNotificationMinute ?? this.contestNotificationMinute,
    );
  }

  @override
  List<Object?> get props => [
        isOnStreakNotification,
        streakNotificationTime,
        contestNotificationMinute,
      ];
}
