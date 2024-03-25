part of 'setting_bloc.dart';

class SettingState extends Equatable {
  final bool isOnStreakNotification;
  final TimeOfDay streakTime;
  final TimeOfDay contestTime;

  const SettingState({
    required this.isOnStreakNotification,
    required this.streakTime,
    required this.contestTime,
  });

  SettingState copyWith({
    bool? isOnStreakNotification,
    TimeOfDay? streakTime,
    TimeOfDay? contestTime,
  }) {
    return SettingState(
      isOnStreakNotification:
          isOnStreakNotification ?? this.isOnStreakNotification,
      streakTime: streakTime ?? this.streakTime,
      contestTime: contestTime ?? this.contestTime,
    );
  }

  @override
  List<Object?> get props => [
        isOnStreakNotification,
        streakTime,
        contestTime,
      ];
}
