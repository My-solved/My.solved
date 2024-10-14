part of 'root_bloc.dart';

abstract class RootState extends Equatable {
  final int tabIndex;

  const RootState({required this.tabIndex});

  RootState copyWith({int? tabIndex});

  @override
  List<Object?> get props => [tabIndex];
}

class RootInitial extends RootState {
  const RootInitial({super.tabIndex = 0});

  @override
  RootInitial copyWith({int? tabIndex}) {
    return RootInitial(
      tabIndex: tabIndex ?? this.tabIndex,
    );
  }
}

class RootSuccess extends RootState {
  const RootSuccess({
    required super.tabIndex,
    required this.version,
  });

  final String version;

  @override
  RootSuccess copyWith({int? tabIndex, String? version}) {
    return RootSuccess(
      tabIndex: tabIndex ?? this.tabIndex,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [...super.props, version];
}
