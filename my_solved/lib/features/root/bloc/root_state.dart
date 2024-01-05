part of 'root_bloc.dart';

@immutable
abstract class RootState extends Equatable {
  final int tabIndex;

  const RootState({required this.tabIndex});
}

class RootInitial extends RootState {
  const RootInitial({required super.tabIndex});

  @override
  List<Object?> get props => [super.tabIndex];
}
