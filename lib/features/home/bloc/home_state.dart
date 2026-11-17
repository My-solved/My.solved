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
  final UserProfile? user;
  final String? profileImageUrl;
  final ProfileBackgroundAsset? background;
  final ProfileBadgeAsset? badge;
  final ProfileStreak? streak;
  final bool? solvedToday;
  final List<ProfileTagRating>? tagRatings;
  final List<ProfileTierStat>? problemStats;

  const HomeState({
    this.status = HomeStatus.initial,
    required this.handle,
    required this.isOnIllustBackground,
    this.user,
    this.profileImageUrl,
    this.background,
    this.badge,
    this.streak,
    this.solvedToday,
    this.tagRatings,
    this.problemStats,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? handle,
    bool? isOnIllustBackground,
    UserProfile? user,
    String? profileImageUrl,
    ProfileBackgroundAsset? background,
    ProfileBadgeAsset? badge,
    ProfileStreak? streak,
    bool? solvedToday,
    List<ProfileTagRating>? tagRatings,
    List<ProfileTierStat>? problemStats,
  }) {
    return HomeState(
      status: status ?? this.status,
      handle: handle ?? this.handle,
      isOnIllustBackground: isOnIllustBackground ?? this.isOnIllustBackground,
      user: user ?? this.user,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      background: background ?? this.background,
      badge: badge ?? this.badge,
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
        streak,
        solvedToday,
        tagRatings,
        problemStats,
      ];
}
