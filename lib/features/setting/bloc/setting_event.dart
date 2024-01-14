part of 'setting_bloc.dart';

@immutable
abstract class SettingEvent extends Equatable {}

class StreakTimeOfDayChanged extends SettingEvent {
  final TimeOfDay timeOfDay;

  StreakTimeOfDayChanged({required this.timeOfDay});

  @override
  List<Object?> get props => [timeOfDay];
}
