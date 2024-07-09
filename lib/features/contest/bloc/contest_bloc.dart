import 'package:boj_api/boj_api.dart';
import 'package:contest_notification_repository/contest_notification_repository.dart';
import 'package:contest_repository/contest_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_solved/features/contest_filter/bloc/contest_filter_bloc.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';

part 'contest_event.dart';
part 'contest_state.dart';

class ContestBloc extends Bloc<ContestEvent, ContestState> {
  ContestBloc({
    required ContestNotificationRepository contestNotificationRepository,
    required ContestRepository contestRepository,
    required SharedPreferencesRepository sharedPreferencesRepository,
  })  : _contestNotificationRepository = contestNotificationRepository,
        _contestRepository = contestRepository,
        _sharedPreferencesRepository = sharedPreferencesRepository,
        super(ContestState(
          filters: {
            ContestVenue.atCoder: true,
            ContestVenue.bojOpen: true,
            ContestVenue.codeForces: true,
            ContestVenue.programmers: true,
            ContestVenue.others: true,
          },
        )) {
    on<ContestInit>(_onInit);
    on<ContestSegmentedControlPressed>(_onSegmentedControlPressed);
    on<ContestNotificationButtonPressed>(_onNotificationPressed);
    on<ContestFilterTogglePressed>(_onFilterPressed);
    on<ContentPushTestButtonPressed>(_onTestPressed);
  }

  final ContestNotificationRepository _contestNotificationRepository;
  final ContestRepository _contestRepository;
  final SharedPreferencesRepository _sharedPreferencesRepository;

  Future<void> _onInit(ContestInit event, Emitter<ContestState> emit) async {
    emit(state.copyWith(status: ContestStatus.loading));

    try {
      final result = await _contestRepository.getContests();
      final endedContests = result[ContestType.ended];
      final ongoingContests = result[ContestType.ongoing];
      final upcomingContests = result[ContestType.upcoming];

      List<bool> isOnContestNotifications = [];
      for (Contest contest in upcomingContests ?? []) {
        isOnContestNotifications.add(await _sharedPreferencesRepository
            .getIsOnContestNotification(title: contest.name));
      }

      emit(state.copyWith(
        status: ContestStatus.success,
        endedContests: endedContests,
        ongoingContests: ongoingContests,
        upcomingContests: upcomingContests,
        isOnNotificationUpcomingContests: isOnContestNotifications,
      ));
    } catch (e) {
      emit(state.copyWith(status: ContestStatus.failure));
    }
  }

  Future<void> _onNotificationPressed(
    ContestNotificationButtonPressed event,
    Emitter<ContestState> emit,
  ) async {
    emit(state.copyWith(status: ContestStatus.loading));
    final contest = state.upcomingContests[event.index];
    List<bool> isOnNotifications = state.isOnNotificationUpcomingContests;
    final isOn = await _sharedPreferencesRepository.getIsOnContestNotification(
        title: contest.name);
    final minute =
        await _sharedPreferencesRepository.getContestNotificationMinute();

    print(contest);
    print(event.index);

    if (isOn) {
      await _contestNotificationRepository.cancelContestNotification(
        title: contest.name,
      );
      await _sharedPreferencesRepository.setIsOnContestNotification(
        title: contest.name,
        isOn: false,
      );
      isOnNotifications[event.index] = false;
      emit(state.copyWith(
        status: ContestStatus.success,
        isOnNotificationUpcomingContests: isOnNotifications,
      ));
    } else {
      await _contestNotificationRepository.setContestNotification(
        title: contest.name,
        startTime: contest.startTime,
        beforeMinute: minute,
      );
      await _sharedPreferencesRepository.setIsOnContestNotification(
        title: contest.name,
        isOn: true,
      );
      isOnNotifications[event.index] = true;
      emit(state.copyWith(
        status: ContestStatus.success,
        isOnNotificationUpcomingContests: isOnNotifications,
      ));
    }
  }

  void _onSegmentedControlPressed(
    ContestSegmentedControlPressed event,
    Emitter<ContestState> emit,
  ) {
    emit(state.copyWith(currentIndex: event.index));
  }

  void _onFilterPressed(
    ContestFilterTogglePressed event,
    Emitter<ContestState> emit,
  ) {
    var filters = state.filters;
    final current = filters[event.venue] ?? true;
    current ? filters[event.venue] = false : filters[event.venue] = true;
    emit(state.copyWith(status: ContestStatus.success, filters: filters));
  }

  Future<void> _onTestPressed(
    ContentPushTestButtonPressed event,
    Emitter<ContestState> emit,
  ) async {
    await _contestNotificationRepository.setTestNotification();
  }
}