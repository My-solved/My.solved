import 'profile_background_asset.dart';
import 'profile_badge_asset.dart';
import 'user_profile.dart';

/// One credited author in an official v4 profile background.
final class OfficialUserProfileBackgroundAuthor {
  const OfficialUserProfileBackgroundAuthor({
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

/// The full background embedded in an official v4 public profile.
final class OfficialUserProfileBackground extends ProfileBackgroundAsset {
  const OfficialUserProfileBackground({
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
  final List<OfficialUserProfileBackgroundAuthor> authors;
}

/// The badge embedded in an official v4 public profile.
final class OfficialUserProfileBadge extends ProfileBadgeAsset {
  const OfficialUserProfileBadge({
    required String key,
    required String name,
    required super.imageUrl,
  }) : super(key: key, name: name);

  @override
  String get key => super.key!;

  @override
  String get name => super.name!;
}

/// Sources exposed by the official v4 public-profile streak vacation field.
enum OfficialUserProfileStreakVacationSource {
  item('item'),
  launch('launch');

  const OfficialUserProfileStreakVacationSource(this.value);

  final String value;
}

/// The nullable current streak vacation in an official v4 public profile.
final class OfficialUserProfileStreakVacation {
  const OfficialUserProfileStreakVacation({
    required this.fromDay,
    required this.source,
  });

  /// Raw response value. The schema does not declare a date format.
  final String fromDay;
  final OfficialUserProfileStreakVacationSource source;
}

/// One external online-judge account embedded in an official v4 profile.
final class OfficialUserProfileOjAccount {
  const OfficialUserProfileOjAccount({
    required this.ojId,
    required this.ojName,
    required this.handle,
    required this.profileUrl,
    required this.logoUrl,
    required this.verified,
  });

  final String ojId;
  final String ojName;
  final String handle;
  final String? profileUrl;
  final String? logoUrl;
  final bool verified;
}

/// Providers exposed by official v4 linked profile accounts.
enum OfficialUserProfileLinkedAccountProvider {
  discord('discord'),
  icpc('icpc');

  const OfficialUserProfileLinkedAccountProvider(this.value);

  final String value;
}

/// One linked service account embedded in an official v4 profile.
final class OfficialUserProfileLinkedAccount {
  const OfficialUserProfileLinkedAccount({
    required this.provider,
    required this.name,
    required this.url,
  });

  final OfficialUserProfileLinkedAccountProvider provider;
  final String name;
  final String url;
}

/// Affiliation types exposed by official v4 public profiles.
enum OfficialUserProfileAffiliationType {
  undefined('undefined'),
  university('university'),
  highSchool('high_school'),
  middleSchool('middle_school'),
  elementarySchool('elementary_school'),
  company('company'),
  community('community');

  const OfficialUserProfileAffiliationType(this.value);

  final String value;
}

/// One affiliation embedded in an official v4 public profile.
final class OfficialUserProfileAffiliation {
  const OfficialUserProfileAffiliation({
    required this.id,
    required this.affiliationId,
    required this.name,
    required this.type,
    required this.logoThumbnailUrl,
    required this.color,
  });

  /// Raw finite response number. The schema declares no integer or bounds.
  final num id;

  /// Raw finite response number, independent from [id].
  final num affiliationId;

  final String name;
  final OfficialUserProfileAffiliationType type;
  final String? logoThumbnailUrl;
  final String? color;
}

/// The official v4 public profile with its wire metadata preserved.
final class OfficialUserProfile extends UserProfile {
  const OfficialUserProfile({
    required this.id,
    required this.voteCount,
    required this.streakVacation,
    required this.streakCountedToday,
    required this.streakFrozenYesterday,
    required this.streakTheme,
    required this.isRival,
    required this.isReverseRival,
    required this.ojAccounts,
    required this.linkedAccounts,
    required this.affiliations,
    required super.handle,
    required super.profileImageUrl,
    super.bio,
    required super.solvedCount,
    required super.userClass,
    required super.tier,
    required super.rating,
    super.classPlus,
    super.currentStreak,
    super.maxStreak,
    super.reputation,
    super.ratingBreakdown,
    required OfficialUserProfileBackground? background,
    required OfficialUserProfileBadge? badge,
    super.tagRatings,
  }) : super(
          badgeId: null,
          backgroundId: null,
          legacyContributionCount: null,
          reverseRivalCount: null,
          background: background,
          badge: badge,
        );

  /// Raw finite response number. The public-profile schema declares no bounds
  /// or stability relationship with other identity endpoints.
  final num id;

  /// Official v4 vote count, distinct from Reputation and the v3 legacy field.
  final int voteCount;

  /// Required nullable current streak vacation from the profile response.
  final OfficialUserProfileStreakVacation? streakVacation;

  final bool streakCountedToday;
  final bool streakFrozenYesterday;

  /// Raw required nullable theme value from the profile response.
  final String? streakTheme;

  /// Raw official v4 rivalry flags.
  ///
  /// Neither flag implies the other, nor a v3 reverse-rival count.
  final bool isRival;
  final bool isReverseRival;

  /// External online-judge accounts in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<OfficialUserProfileOjAccount> ojAccounts;

  /// Linked service accounts in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<OfficialUserProfileLinkedAccount> linkedAccounts;

  /// Affiliations in wire order, including duplicates.
  ///
  /// Decoder-produced lists are unmodifiable. An empty list is authoritative.
  final List<OfficialUserProfileAffiliation> affiliations;

  @override
  OfficialUserProfileBackground? get background =>
      super.background as OfficialUserProfileBackground?;

  @override
  OfficialUserProfileBadge? get badge =>
      super.badge as OfficialUserProfileBadge?;

  @override
  String? get backgroundId => background?.key;

  @override
  String? get badgeId => badge?.key;
}
