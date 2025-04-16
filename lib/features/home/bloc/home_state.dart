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
  final String? profileImageUrl;
  final Background? background;
  final Badge? badge;
  final List<Badge> badges;
  final List<Organization> organizations;
  final Streak? streak;
  final bool? solvedToday;
  final List<TagRating>? tagRatings;
  final List<ProblemStat>? problemStats;

  const HomeState({
    this.status = HomeStatus.initial,
    required this.handle,
    required this.isOnIllustBackground,
    this.user,
    this.profileImageUrl,
    this.background,
    this.badge,
    required this.badges,
    required this.organizations,
    this.streak,
    this.solvedToday,
    this.tagRatings,
    this.problemStats,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? handle,
    bool? isOnIllustBackground,
    User? user,
    String? profileImageUrl,
    Background? background,
    Badge? badge,
    List<Badge>? badges,
    List<Organization>? organizations,
    Streak? streak,
    bool? solvedToday,
    List<TagRating>? tagRatings,
    List<ProblemStat>? problemStats,
  }) {
    return HomeState(
      status: status ?? this.status,
      handle: handle ?? this.handle,
      isOnIllustBackground: isOnIllustBackground ?? this.isOnIllustBackground,
      user: user ?? this.user,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      background: background ?? this.background,
      badge: badge ?? this.badge,
      badges: badges ?? this.badges,
      organizations: organizations ?? this.organizations,
      streak: streak ?? this.streak,
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
        profileImageUrl,
        background,
        badge,
        badges,
        organizations,
        streak,
        solvedToday,
        tagRatings,
        problemStats,
      ];
}
