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
  final List<String> processingContests;
  final List<String> expiredContests;

  const ContestState({
    this.status = ContestStatus.initial,
    this.currentIndex = 0,
    this.processingContests = const [],
    this.expiredContests = const [],
  });

  ContestState copyWith({
    ContestStatus? status,
    int? currentIndex,
    List<String>? processingContests,
    List<String>? expiredContests,
  }) {
    return ContestState(
      status: status ?? this.status,
      currentIndex: currentIndex ?? this.currentIndex,
      processingContests: processingContests ?? this.processingContests,
      expiredContests: expiredContests ?? this.expiredContests,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentIndex,
        processingContests,
        expiredContests,
      ];
}
