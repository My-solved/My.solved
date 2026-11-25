import 'problem_no_rating_warning.dart';
import 'profile_background_asset.dart';

/// Achievement-item kinds exposed by the official v4 API.
enum OfficialAchievementItemKind {
  badge('badge'),
  background('background');

  const OfficialAchievementItemKind(this.value);

  final String value;
}

/// One credited author in an official standalone achievement background.
final class OfficialAchievementItemBackgroundAuthor {
  const OfficialAchievementItemBackgroundAuthor({
    required this.key,
    required this.displayName,
    required this.role,
    required this.authorUrl,
    required this.handle,
    required this.twitter,
    required this.instagram,
  });

  final String key;
  final String? displayName;
  final String role;
  final String? authorUrl;
  final String? handle;
  final String? twitter;
  final String? instagram;
}

/// A background nested in an official standalone achievement item.
final class OfficialAchievementItemBackground extends ProfileBackgroundAsset {
  const OfficialAchievementItemBackground({
    required String key,
    required super.imageUrl,
    required super.fallbackImageUrl,
    required this.backgroundVideoUrl,
    required this.thumbnailPlaceholder,
    required this.isIllust,
    required this.displayName,
    required this.authors,
  }) : super(key: key);

  @override
  String get key => super.key!;

  final String? backgroundVideoUrl;
  final String? thumbnailPlaceholder;
  final bool isIllust;
  final String? displayName;

  /// Authors in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<OfficialAchievementItemBackgroundAuthor> authors;
}

/// One credit attached to an official standalone achievement item.
final class OfficialAchievementItemCredit {
  const OfficialAchievementItemCredit({
    required this.key,
    required this.displayName,
    required this.role,
    required this.authorUrl,
    required this.handle,
    required this.twitter,
    required this.instagram,
  });

  final String key;
  final String? displayName;
  final String role;
  final String? authorUrl;
  final String? handle;
  final String? twitter;
  final String? instagram;
}

/// One localized problem title nested in an achievement item.
final class OfficialAchievementItemProblemTitle {
  const OfficialAchievementItemProblemTitle({
    required this.language,
    required this.title,
    required this.isOriginal,
    required this.latex,
    required this.html,
  });

  final String language;
  final String title;
  final bool isOriginal;
  final bool latex;
  final bool html;
}

/// One problem associated with an official standalone achievement.
final class OfficialAchievementItemProblem {
  const OfficialAchievementItemProblem({
    required this.problemId,
    required this.level,
    required this.effectiveVoteCount,
    required this.givesNoRating,
    required this.isStandard,
    required this.titles,
    required this.userStatus,
  });

  /// Raw finite response number. The schema declares no integer or bounds.
  final num problemId;

  /// Raw finite response number. The schema declares no integer or bounds.
  final num level;

  /// Raw finite response number. The schema declares no integer or bounds.
  final num effectiveVoteCount;

  final bool givesNoRating;
  final bool isStandard;

  /// Titles in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<OfficialAchievementItemProblemTitle> titles;

  /// Required nullable user status from the official response.
  final ProblemUserStatus? userStatus;
}

/// One achievement nested in an official standalone item.
final class OfficialAchievementItemAchievement {
  const OfficialAchievementItemAchievement({
    required this.key,
    required this.name,
    required this.condition,
    required this.historic,
    required this.hidden,
    required this.holderCount,
    required this.earnedAt,
    required this.problems,
  });

  final String key;
  final String name;
  final String? condition;
  final bool historic;
  final bool hidden;
  final int holderCount;

  /// Raw required nullable response value. Calendar validity is not implied.
  final String? earnedAt;

  /// Problems in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<OfficialAchievementItemProblem> problems;
}

/// The complete official v4 standalone achievement item.
final class OfficialAchievementItem {
  const OfficialAchievementItem({
    required this.kind,
    required this.id,
    required this.key,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.addedAt,
    required this.unlockedByDefault,
    required this.owned,
    required this.equipped,
    required this.background,
    required this.credits,
    required this.userCount,
    required this.achievements,
  });

  final OfficialAchievementItemKind kind;
  final int id;
  final String key;
  final String name;
  final String imageUrl;
  final String category;

  /// Raw response value. The schema declares no date format or pattern.
  final String addedAt;

  final bool unlockedByDefault;
  final bool? owned;
  final bool? equipped;
  final OfficialAchievementItemBackground? background;

  /// Credits in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<OfficialAchievementItemCredit> credits;

  final int userCount;

  /// Achievements in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<OfficialAchievementItemAchievement> achievements;
}
