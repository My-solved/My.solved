part of 'contest_bloc.dart';

@immutable
abstract class ContestState extends Equatable {
  final int current;

  const ContestState({required this.current});
}

class ContestInitial extends ContestState {
  const ContestInitial({super.current = 0});

  @override
  List<Object?> get props => [super.current];
}

class ContestSuccess extends ContestState {
  final List<String> processingContest;
  final List<String> expiredContest;

  const ContestSuccess({
    super.current = 0,
    required this.processingContest,
    required this.expiredContest,
  });

  @override
  List<Object?> get props => [
        super.current,
        processingContest,
        expiredContest,
      ];
}

class ContestFailure extends ContestState {
  final String errorMessage;

  const ContestFailure({super.current = 0, required this.errorMessage});

  @override
  List<Object?> get props => [super.current, errorMessage];
}
