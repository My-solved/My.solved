class User {
  final String? handle;
  final String? bio;
  final String? badgeId;
  final String? backgroundId;
  final String? profileImageUrl;
  final int solvedCount;
  final int voteCount;
  final int userClass;
  final String? classDecoration;
  final int rivalCount;
  final int reverseRivalCount;
  final int tier;
  final int rating;
  final int ratingByProblemsSum;
  final int ratingByClass;
  final int ratingBySolvedCount;
  final int ratingByVoteCount;
  final int maxStreak;
  final int coins;
  final int stardusts;
  final String? joinedAt;
  final String? bannedUntil;
  final String? proUntil;
  final int rank;

  const User({
    required this.handle,
    required this.bio,
    required this.badgeId,
    required this.backgroundId,
    required this.profileImageUrl,
    required this.solvedCount,
    required this.voteCount,
    required this.userClass,
    required this.classDecoration,
    required this.tier,
    required this.rating,
    required this.ratingByProblemsSum,
    required this.ratingByClass,
    required this.ratingBySolvedCount,
    required this.ratingByVoteCount,
    required this.rivalCount,
    required this.reverseRivalCount,
    required this.maxStreak,
    required this.coins,
    required this.stardusts,
    required this.joinedAt,
    required this.bannedUntil,
    required this.proUntil,
    required this.rank,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      handle: json['handle'],
      bio: json['bio'],
      badgeId: json['badgeId'],
      backgroundId: json['backgroundId'],
      profileImageUrl: json['profileImageUrl'],
      solvedCount: json['solvedCount'],
      voteCount: json['voteCount'],
      userClass: json['class'],
      classDecoration: json['classDecoration'],
      tier: json['tier'],
      rating: json['rating'],
      ratingByProblemsSum: json['ratingByProblemsSum'],
      ratingByClass: json['ratingByClass'],
      ratingBySolvedCount: json['ratingBySolvedCount'],
      ratingByVoteCount: json['ratingByVoteCount'],
      rivalCount: json['rivalCount'],
      reverseRivalCount: json['reverseRivalCount'],
      maxStreak: json['maxStreak'],
      coins: json['coins'],
      stardusts: json['stardusts'],
      joinedAt: json['joinedAt'],
      bannedUntil: json['bannedUntil'],
      proUntil: json['proUntil'],
      rank: json['rank'],
    );
  }
}
