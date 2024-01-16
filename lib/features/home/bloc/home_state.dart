part of "home_bloc.dart";

enum HomeStatus { initial, loading, success, failure }

extension HomeStatusX on HomeStatus {
  bool get isInitial => this == HomeStatus.initial;
  bool get isLoading => this == HomeStatus.loading;
  bool get isSuccess => this == HomeStatus.success;
  bool get isFailure => this == HomeStatus.failure;
}

class HomeState extends Equatable {
  final HomeStatus status;
  final String handle;

  const HomeState({
    this.status = HomeStatus.initial,
    required this.handle,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? handle,
  }) {
    return HomeState(
      status: status ?? this.status,
      handle: handle ?? this.handle,
    );
  }

  @override
  List<Object?> get props => [status, handle];
}
