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
  final Map<ContestVenue, bool> filters;

  List<String> get selectedVenues => ContestVenue.allCases
      .where((venue) => filters[venue] ?? false)
      .map((venue) => venue.value)
      .toList();
  List<Contest> get filteredEndedContests => endedContests
      .where((contest) => selectedVenues.contains(contest.venue))
      .toList();
  List<Contest> get filteredOngoingContests => ongoingContests
      .where((contest) => selectedVenues.contains(contest.venue))
      .toList();
  List<Contest> get filteredUpcomingContests => upcomingContests
      .where((contest) => selectedVenues.contains(contest.venue))
      .toList();

  const ContestState({
    this.status = ContestStatus.initial,
    this.currentIndex = 0,
    this.endedContests = const [],
    this.ongoingContests = const [],
    this.upcomingContests = const [],
    this.isOnNotificationUpcomingContests = const [],
    required this.filters,
  });

  ContestState copyWith({
    ContestStatus? status,
    int? currentIndex,
    List<Contest>? endedContests,
    List<Contest>? ongoingContests,
    List<Contest>? upcomingContests,
    List<bool>? isOnNotificationUpcomingContests,
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
        filters,
        selectedVenues,
        filteredEndedContests,
        filteredOngoingContests,
        filteredUpcomingContests,
      ];
}