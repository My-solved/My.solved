part of 'root_bloc.dart';

class RootState extends Equatable {
  final String handle;
  final int tabIndex;
  final String version;

  const RootState({
    required this.handle,
    this.tabIndex = 0,
    this.version = "",
  });

  RootState copyWith({
    String? handle,
    int? tabIndex,
    String? version,
  }) {
    return RootState(
      handle: handle ?? this.handle,
      tabIndex: tabIndex ?? this.tabIndex,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [handle, tabIndex, version];
}
