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

  const ContestState({
    this.status = ContestStatus.initial,
    this.currentIndex = 1,
    this.endedContests = const [],
    this.ongoingContests = const [],
    this.upcomingContests = const [],
  });

  ContestState copyWith({
    ContestStatus? status,
    int? currentIndex,
    List<Contest>? endedContests,
    List<Contest>? ongoingContests,
    List<Contest>? upcomingContests,
  }) {
    return ContestState(
      status: status ?? this.status,
      currentIndex: currentIndex ?? this.currentIndex,
      endedContests: endedContests ?? this.endedContests,
      ongoingContests: ongoingContests ?? this.ongoingContests,
      upcomingContests: upcomingContests ?? this.upcomingContests,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentIndex,
        endedContests,
        ongoingContests,
        upcomingContests,
      ];
}
