part of 'root_bloc.dart';

@immutable
abstract class RootState extends Equatable {
  final String handle;
  final int tabIndex;

  const RootState({required this.handle, required this.tabIndex});
}

class RootInitial extends RootState {
  const RootInitial({required super.handle, required super.tabIndex});

  @override
  List<Object?> get props => [super.tabIndex];
}
