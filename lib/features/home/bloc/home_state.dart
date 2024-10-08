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
  final bool isOnIllustBackground;
  final User? user;
  final Background? background;
  final List<Organization> organizations;
  final Badge? badge;
  final List<Badge> badges;
  final bool? solvedToday;
  final List<TagRating>? tagRatings;
  final List<ProblemStat>? problemStats;

  const HomeState({
    this.status = HomeStatus.initial,
    required this.handle,
    required this.isOnIllustBackground,
    this.user,
    this.background,
    required this.organizations,
    this.badge,
    required this.badges,
    this.solvedToday,
    this.tagRatings,
    this.problemStats,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? handle,
    bool? isOnIllustBackground,
    User? user,
    Background? background,
    List<Organization>? organizations,
    Badge? badge,
    List<Badge>? badges,
    bool? solvedToday,
    List<TagRating>? tagRatings,
    List<ProblemStat>? problemStats,
  }) {
    return HomeState(
      status: status ?? this.status,
      handle: handle ?? this.handle,
      isOnIllustBackground: isOnIllustBackground ?? this.isOnIllustBackground,
      user: user ?? this.user,
      background: background ?? this.background,
      organizations: organizations ?? this.organizations,
      badge: badge ?? this.badge,
      badges: badges ?? this.badges,
      solvedToday: solvedToday ?? this.solvedToday,
      tagRatings: tagRatings ?? this.tagRatings,
      problemStats: problemStats ?? this.problemStats,
    );
  }

  @override
  List<Object?> get props => [
        status,
        handle,
        isOnIllustBackground,
        user,
        background,
        organizations,
        badge,
        badges,
        solvedToday,
        tagRatings,
        problemStats,
      ];
}
