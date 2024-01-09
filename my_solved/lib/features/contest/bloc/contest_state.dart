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
