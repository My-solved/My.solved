class SearchSuggestion {
  final List<dynamic> autocomplete;
  final List<ProblemSuggestion> problems;
  final int problemCount;
  final List<TagSuggestion> tags;
  final int tagCount;
  final List<UserSuggestion> users;
  final int userCount;

  const SearchSuggestion({
    required this.autocomplete,
    required this.problems,
    required this.problemCount,
    required this.users,
    required this.userCount,
    required this.tags,
    required this.tagCount,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      autocomplete: json['autocomplete'],
      problems: json['problems']
          .map((problem) => ProblemSuggestion.fromJson(problem))
          .toList()
          .cast<ProblemSuggestion>(),
      problemCount: json['problemCount'],
      tags: json['tags']
          .map((tag) => TagSuggestion.fromJson(tag))
          .toList()
          .cast<TagSuggestion>(),
      tagCount: json['tagCount'],
      users: json['users']
          .map((user) => UserSuggestion.fromJson(user))
          .toList()
          .cast<UserSuggestion>(),
      userCount: json['userCount'],
    );
  }
}

class ProblemSuggestion {
  final int id;
  final String title;
  final int level;
  final int solved;
  final String caption;
  final String description;
  final String href;

  const ProblemSuggestion({
    required this.id,
    required this.title,
    required this.level,
    required this.solved,
    required this.caption,
    required this.description,
    required this.href,
  });

  factory ProblemSuggestion.fromJson(Map<String, dynamic> json) {
    return ProblemSuggestion(
      id: json['id'],
      title: json['title'],
      level: json['level'],
      solved: json['solved'],
      caption: json['caption'],
      description: json['description'],
      href: json['href'],
    );
  }
}

class TagSuggestion {
  final String key;
  final String name;
  final int problemCount;
  final String caption;
  final String description;
  final String href;

  const TagSuggestion({
    required this.key,
    required this.name,
    required this.problemCount,
    required this.caption,
    required this.description,
    required this.href,
  });

  factory TagSuggestion.fromJson(Map<String, dynamic> json) {
    return TagSuggestion(
      key: json['key'],
      name: json['name'],
      problemCount: json['problemCount'],
      caption: json['caption'],
      description: json['description'],
      href: json['href'],
    );
  }
}

class UserSuggestion {
  final String handle;
  final String bio;
  final String? badgeId;
  final String backgroundId;
  final String? profileImageUrl;
  final int solvedCount;
  final int voteCount;
  final int userClass;
  final String classDecoration;
  final int rivalCount;
  final int reverseRivalCount;
  final int tier;
  final int rating;
  final int ratingByProblemsSum;
  final int ratingByClass;
  final int ratingBySolvedCount;
  final int ratingByVoteCount;
  final int arenaTier;
  final int arenaRating;
  final int arenaMaxTier;
  final int arenaMaxRating;
  final int arenaCompetedRoundCount;
  final int maxStreak;
  final int coins;
  final int stardusts;
  final DateTime joinedAt;
  final DateTime bannedUntil;
  final DateTime proUntil;

  const UserSuggestion({
    required this.handle,
    required this.bio,
    required this.badgeId,
    required this.backgroundId,
    required this.profileImageUrl,
    required this.solvedCount,
    required this.voteCount,
    required this.userClass,
    required this.classDecoration,
    required this.rivalCount,
    required this.reverseRivalCount,
    required this.tier,
    required this.rating,
    required this.ratingByProblemsSum,
    required this.ratingByClass,
    required this.ratingBySolvedCount,
    required this.ratingByVoteCount,
    required this.arenaTier,
    required this.arenaRating,
    required this.arenaMaxTier,
    required this.arenaMaxRating,
    required this.arenaCompetedRoundCount,
    required this.maxStreak,
    required this.coins,
    required this.stardusts,
    required this.joinedAt,
    required this.bannedUntil,
    required this.proUntil,
  });

  factory UserSuggestion.fromJson(Map<String, dynamic> json) {
    return UserSuggestion(
      handle: json['handle'],
      bio: json['bio'],
      badgeId: json['badgeId'],
      backgroundId: json['backgroundId'],
      profileImageUrl: json['profileImageUrl'],
      solvedCount: json['solvedCount'],
      voteCount: json['voteCount'],
      userClass: json['class'],
      classDecoration: json['classDecoration'],
      rivalCount: json['rivalCount'],
      reverseRivalCount: json['reverseRivalCount'],
      tier: json['tier'],
      rating: json['rating'],
      ratingByProblemsSum: json['ratingByProblemsSum'],
      ratingByClass: json['ratingByClass'],
      ratingBySolvedCount: json['ratingBySolvedCount'],
      ratingByVoteCount: json['ratingByVoteCount'],
      arenaTier: json['arenaTier'],
      arenaRating: json['arenaRating'],
      arenaMaxTier: json['arenaMaxTier'],
      arenaMaxRating: json['arenaMaxRating'],
      arenaCompetedRoundCount: json['arenaCompetedRoundCount'],
      maxStreak: json['maxStreak'],
      coins: json['coins'],
      stardusts: json['stardusts'],
      joinedAt: DateTime.parse(json['joinedAt']),
      bannedUntil: DateTime.parse(json['bannedUntil']),
      proUntil: DateTime.parse(json['proUntil']),
    );
  }
}
