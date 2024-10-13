part of 'contest_bloc.dart';

enum ContestStatus { initial, loading, success, failure }

extension ContestStatusX on ContestStatus {
  bool get isInitial => this == ContestStatus.initial;

  bool get isLoading => this == ContestStatus.loading;

  bool get isSuccess => this == ContestStatus.success;

  bool get isFailure => this == ContestStatus.failure;
}

class ContestState extends Equatable {
  final ContestStatus status;
  final int currentIndex;
  final List<Contest> endedContests;
  final List<Contest> ongoingContests;
  final List<Contest> upcomingContests;
  final List<bool> isOnNotificationUpcomingContests;
  final List<bool> isOnCalendarUpcomingContests;
  final Map<ContestVenue, bool> filters;
  final List<Contest> filteredEndedContests;
  final List<Contest> filteredOngoingContests;
  final List<Contest> filteredUpcomingContests;

  List<String> get selectedVenues => ContestVenue.allCases
      .where((venue) => filters[venue] ?? false)
      .map((venue) => venue.value)
      .toList();

  const ContestState({
    this.status = ContestStatus.initial,
    this.currentIndex = 0,
    this.endedContests = const [],
    this.ongoingContests = const [],
    this.upcomingContests = const [],
    this.isOnNotificationUpcomingContests = const [],
    this.isOnCalendarUpcomingContests = const [],
    this.filteredUpcomingContests = const [],
    this.filteredOngoingContests = const [],
    this.filteredEndedContests = const [],
    required this.filters,
  });

  ContestState copyWith({
    ContestStatus? status,
    int? currentIndex,
    List<Contest>? endedContests,
    List<Contest>? ongoingContests,
    List<Contest>? upcomingContests,
    List<bool>? isOnNotificationUpcomingContests,
    List<bool>? isOnCalendarUpcomingContests,
    List<Contest>? filteredEndedContests,
    List<Contest>? filteredOngoingContests,
    List<Contest>? filteredUpcomingContests,
    Map<ContestVenue, bool>? filters,
  }) {
    return ContestState(
      status: status ?? this.status,
      currentIndex: currentIndex ?? this.currentIndex,
      endedContests: endedContests ?? this.endedContests,
      ongoingContests: ongoingContests ?? this.ongoingContests,
      upcomingContests: upcomingContests ?? this.upcomingContests,
      isOnNotificationUpcomingContests: isOnNotificationUpcomingContests ??
          this.isOnNotificationUpcomingContests,
      isOnCalendarUpcomingContests:
          isOnCalendarUpcomingContests ?? this.isOnCalendarUpcomingContests,
      filteredEndedContests:
          filteredEndedContests ?? this.filteredEndedContests,
      filteredOngoingContests:
          filteredOngoingContests ?? this.filteredOngoingContests,
      filteredUpcomingContests:
          filteredUpcomingContests ?? this.filteredUpcomingContests,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentIndex,
        endedContests,
        ongoingContests,
        upcomingContests,
        isOnNotificationUpcomingContests,
        isOnCalendarUpcomingContests,
        filters,
        selectedVenues,
        filteredEndedContests,
        filteredOngoingContests,
        filteredUpcomingContests,
      ];
}
