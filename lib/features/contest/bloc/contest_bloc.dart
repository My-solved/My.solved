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
            ContestVenue.bojOpen: false,
            ContestVenue.atCoder: false,
            ContestVenue.codeForces: false,
            ContestVenue.olympiad: false,
            ContestVenue.google: false,
            ContestVenue.facebook: false,
            ContestVenue.icpc: false,
            ContestVenue.scpc: false,
            ContestVenue.codeChef: false,
            ContestVenue.topCoder: false,
            ContestVenue.programmers: false,
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
      final filters = state.filters;
      for (ContestVenue venue in ContestVenue.allCases) {
        filters[venue] =
            await _sharedPreferencesRepository.getIsOnContestFilter(
          venue: venue.value,
        );
      }

      final result = await _contestRepository.getContests();
      final endedContests = result[ContestType.ended];
      final ongoingContests = result[ContestType.ongoing];
      final upcomingContests = result[ContestType.upcoming];

      List<Contest> filteredEndedContests = [];
      List<Contest> filteredOngoingContests = [];
      List<Contest> filteredUpcomingContests = [];
      List<bool> isOnContestNotifications = [];
      List<bool> isOnContestCalendars = [];
      for (Contest contest in endedContests ?? []) {
        if (await _sharedPreferencesRepository.getIsOnContestFilter(
          venue: contest.venue,
        )) {
          continue;
        }
        filteredEndedContests.add(contest);
      }
      for (Contest contest in ongoingContests ?? []) {
        if (await _sharedPreferencesRepository.getIsOnContestFilter(
          venue: contest.venue,
        )) {
          continue;
        }
        filteredOngoingContests.add(contest);
      }
      for (Contest contest in upcomingContests ?? []) {
        if (await _sharedPreferencesRepository.getIsOnContestFilter(
          venue: contest.venue,
        )) {
          continue;
        }
        filteredUpcomingContests.add(contest);
        isOnContestNotifications.add(
            await _sharedPreferencesRepository.getIsOnContestNotification(
                title: contest.name, startTime: contest.startTime.hashCode));
        isOnContestCalendars.add(
            await _sharedPreferencesRepository.getIsOnContestCalendar(
                title: contest.name, startTime: contest.startTime.hashCode));
      }

      emit(state.copyWith(
        status: ContestStatus.success,
        filters: filters,
        endedContests: endedContests,
        ongoingContests: ongoingContests,
        upcomingContests: upcomingContests,
        isOnNotificationUpcomingContests: isOnContestNotifications,
        isOnCalendarUpcomingContests: isOnContestCalendars,
        filteredEndedContests: filteredEndedContests,
        filteredOngoingContests: filteredOngoingContests,
        filteredUpcomingContests: filteredUpcomingContests,
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
      startTime: contest.startTime.hashCode,
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
        startTime: contest.startTime.hashCode,
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
        startTime: contest.startTime.hashCode,
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
      startTime: contest.startTime.hashCode,
    );

    if (isOn) {
      await _sharedPreferencesRepository.setIsOnContestCalendar(
        title: contest.name,
        startTime: contest.startTime.hashCode,
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
        startTime: contest.startTime.hashCode,
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
    filters[event.venue] = !current;

    await _sharedPreferencesRepository.setIsOnContestFilter(
      venue: event.venue.value,
      isOn: !current,
    );

    List<Contest> filteredEndedContests = [];
    List<Contest> filteredOngoingContests = [];
    List<Contest> filteredUpcomingContests = [];
    List<bool> isOnContestNotifications = [];
    List<bool> isOnContestCalendars = [];
    for (Contest contest in state.endedContests) {
      if (await _sharedPreferencesRepository.getIsOnContestFilter(
        venue: contest.venue,
      )) {
        continue;
      }
      filteredEndedContests.add(contest);
    }
    for (Contest contest in state.ongoingContests) {
      if (await _sharedPreferencesRepository.getIsOnContestFilter(
        venue: contest.venue,
      )) {
        continue;
      }
      filteredOngoingContests.add(contest);
    }
    for (Contest contest in state.upcomingContests) {
      if (await _sharedPreferencesRepository.getIsOnContestFilter(
        venue: contest.venue,
      )) {
        continue;
      }
      filteredUpcomingContests.add(contest);
      isOnContestNotifications.add(
          await _sharedPreferencesRepository.getIsOnContestNotification(
              title: contest.name, startTime: contest.startTime.hashCode));
      isOnContestCalendars.add(
          await _sharedPreferencesRepository.getIsOnContestCalendar(
              title: contest.name, startTime: contest.startTime.hashCode));
    }

    emit(state.copyWith(
        status: ContestStatus.success,
        filters: filters,
        isOnNotificationUpcomingContests: isOnContestNotifications,
        isOnCalendarUpcomingContests: isOnContestCalendars,
        filteredEndedContests: filteredEndedContests,
        filteredOngoingContests: filteredOngoingContests,
        filteredUpcomingContests: filteredUpcomingContests));
  }
}
