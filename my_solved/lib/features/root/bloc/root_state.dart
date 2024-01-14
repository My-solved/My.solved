part of 'root_bloc.dart';

class RootState extends Equatable {
  final String handle;
  final int tabIndex;

  const RootState({required this.handle, this.tabIndex = 0});

  RootState copyWith({
    String? handle,
    int? tabIndex,
  }) {
    return RootState(
      handle: handle ?? this.handle,
      tabIndex: tabIndex ?? this.tabIndex,
    );
  }

  @override
  List<Object?> get props => [handle, tabIndex];
}
