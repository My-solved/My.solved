import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:boj_api/boj_api.dart';
import 'package:contest_notification_repository/contest_notification_repository.dart';
import 'package:contest_repository/contest_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_solved/features/contest_filter/bloc/contest_filter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';

import '../../../components/styles/color.dart';

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
    on<ContestCalendarButtonPressed>(_onCalendarPressed);
    on<ContestFilterTogglePressed>(_onFilterPressed);
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
      List<bool> isOnContestCalendars = [];
      for (Contest contest in upcomingContests ?? []) {
        isOnContestNotifications.add(await _sharedPreferencesRepository
            .getIsOnContestNotification(title: contest.name));
        isOnContestCalendars.add(await _sharedPreferencesRepository
            .getIsOnContestCalendar(title: contest.name));
      }

      emit(state.copyWith(
        status: ContestStatus.success,
        endedContests: endedContests,
        ongoingContests: ongoingContests,
        upcomingContests: upcomingContests,
        isOnNotificationUpcomingContests: isOnContestNotifications,
        isOnCalendarUpcomingContests: isOnContestCalendars,
      ));
    } catch (e) {
      emit(state.copyWith(status: ContestStatus.failure));
    }
  }

  Future<void> _onNotificationPressed(
    ContestNotificationButtonPressed event,
    Emitter<ContestState> emit,
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

    emit(state.copyWith(status: ContestStatus.loading));

    final contest = state.filteredUpcomingContests[event.index];
    List<bool> isOnNotifications = state.isOnNotificationUpcomingContests;
    final isOn = await _sharedPreferencesRepository.getIsOnContestNotification(
      title: contest.name,
    );
    final minute =
        await _sharedPreferencesRepository.getContestNotificationMinute();

    Fluttertoast.showToast(
        msg: isOn ? "알람이 취소되었습니다." : "알람이 설정되었습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: MySolvedColor.main.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0);

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

  void _onCalendarPressed(
    ContestCalendarButtonPressed event,
    Emitter<ContestState> emit,
  ) async {
    emit(state.copyWith(status: ContestStatus.loading));
    final contest = state.filteredUpcomingContests[event.index];
    List<bool> isOnCalendar = state.isOnCalendarUpcomingContests;
    final isOn = await _sharedPreferencesRepository.getIsOnContestCalendar(
      title: contest.name,
    );

    if (isOn) {
      await _sharedPreferencesRepository.setIsOnContestCalendar(
        title: contest.name,
        isOn: false,
      );
      isOnCalendar[event.index] = false;
      emit(state.copyWith(
        status: ContestStatus.success,
        isOnCalendarUpcomingContests: isOnCalendar,
      ));
    } else {
      Fluttertoast.showToast(
          msg: "일정을 등록합니다.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: MySolvedColor.main.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0);

      final Event calendarEvent = Event(
        title: contest.name,
        description: contest.url,
        startDate: contest.startTime,
        endDate: contest.endTime,
        iosParams: IOSParams(
          url: contest.url,
        ),
      );
      Add2Calendar.addEvent2Cal(calendarEvent);

      await _sharedPreferencesRepository.setIsOnContestCalendar(
        title: contest.name,
        isOn: true,
      );
      isOnCalendar[event.index] = true;
      emit(state.copyWith(
        status: ContestStatus.success,
        isOnCalendarUpcomingContests: isOnCalendar,
      ));
    }

    emit(state.copyWith(status: ContestStatus.success));
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
  ) async {
    emit(state.copyWith(status: ContestStatus.loading));

    var filters = state.filters;
    final current = filters[event.venue] ?? true;
    current ? filters[event.venue] = false : filters[event.venue] = true;
    emit(state.copyWith(status: ContestStatus.success, filters: filters));
  }
}
