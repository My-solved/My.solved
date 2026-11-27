import 'official_user_profile.dart';

/// Official v4 affiliations that have a rankable population.
final class RankingAffiliationsResult {
  const RankingAffiliationsResult({required this.affiliations});

  /// Affiliations in the wire order supplied by solved.ac.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<RankingAffiliationItem> affiliations;
}

/// One affiliation in the official public ranking catalog.
final class RankingAffiliationItem {
  const RankingAffiliationItem({
    required this.id,
    required this.affiliationId,
    required this.name,
    required this.type,
    required this.userCount,
    required this.logoThumbnailUrl,
    required this.color,
  });

  /// Raw integer identifier. The schema declares no bounds.
  final int id;

  /// Raw integer affiliation identifier, independent from [id].
  final int affiliationId;

  final String name;

  /// The exact shared official affiliation type vocabulary.
  final OfficialUserProfileAffiliationType type;

  /// Raw user count. The schema declares no lower or upper bound.
  final int userCount;

  /// Raw required nullable response value. URI validity is not implied.
  final String? logoThumbnailUrl;

  /// Raw required nullable response value. Color syntax is not implied.
  final String? color;
}
