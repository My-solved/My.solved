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
  final User? user;

  const HomeState({
    this.status = HomeStatus.initial,
    required this.handle,
    required this.isShowIllustBackground,
    this.user,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? handle,
    bool? isShowIllustBackground,
    User? user,
  }) {
    return HomeState(
      status: status ?? this.status,
      handle: handle ?? this.handle,
      isShowIllustBackground:
          isShowIllustBackground ?? this.isShowIllustBackground,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
        status,
        handle,
        isShowIllustBackground,
        user,
      ];
}
