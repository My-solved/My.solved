part of 'setting_bloc.dart';

class SettingState extends Equatable {
  final TimeOfDay streakTime;
  final TimeOfDay contestTime;

  const SettingState({
    required this.streakTime,
    required this.contestTime,
  });

  SettingState copyWith({
    TimeOfDay? streakTime,
    TimeOfDay? contestTime,
  }) {
    return SettingState(
      streakTime: streakTime ?? this.streakTime,
      contestTime: contestTime ?? this.contestTime,
    );
  }

  @override
  List<Object?> get props => [streakTime, contestTime];
}
