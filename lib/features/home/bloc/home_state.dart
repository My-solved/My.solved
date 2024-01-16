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
  final bool isShowIllustBackground;

  const HomeState({
    this.status = HomeStatus.initial,
    required this.handle,
    required this.isShowIllustBackground,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? handle,
    bool? isShowIllustBackground,
  }) {
    return HomeState(
      status: status ?? this.status,
      handle: handle ?? this.handle,
      isShowIllustBackground:
          isShowIllustBackground ?? this.isShowIllustBackground,
    );
  }

  @override
  List<Object?> get props => [
        status,
        handle,
        isShowIllustBackground,
      ];
}
