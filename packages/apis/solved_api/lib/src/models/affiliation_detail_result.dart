import 'official_user_profile.dart';

/// The complete official v4 public detail for one affiliation.
final class AffiliationDetailResult {
  const AffiliationDetailResult({
    required this.id,
    required this.affiliationId,
    required this.name,
    required this.type,
    required this.countryCode,
    required this.logoImageUrl,
    required this.logoThumbnailUrl,
    required this.color,
    required this.website,
    required this.rating,
    required this.userCount,
    required this.solvedCount,
    required this.voteCount,
    required this.displayName,
    required this.rank,
    required this.rankedOf,
    required this.typeRank,
    required this.typeRankedOf,
    required this.tierCounts,
    required this.ratingByProblemsSum,
    required this.ratingByClass,
    required this.ratingBySolvedCount,
    required this.ratingProblemsHistogram,
    required this.ratingClass,
    required this.ratingClassPlus,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  /// Raw integer affiliation identifier, independent from [id].
  final int affiliationId;

  final String name;

  /// The exact shared official affiliation type vocabulary.
  final OfficialUserProfileAffiliationType type;

  /// Raw required nullable response value. Format is not implied.
  final String? countryCode;

  /// Raw required nullable response value. URI validity is not implied.
  final String? logoImageUrl;

  /// Raw required nullable response value. URI validity is not implied.
  final String? logoThumbnailUrl;

  /// Raw required nullable response value. Color syntax is not implied.
  final String? color;

  /// Raw required nullable response value. URI validity is not implied.
  final String? website;

  /// Raw integer values. The schema declares no bounds or relationships.
  final int rating;
  final int userCount;
  final int solvedCount;
  final int voteCount;

  final String displayName;

  /// Raw integer rank values. The schema declares no bounds or relationships.
  final int rank;
  final int rankedOf;
  final int typeRank;
  final int typeRankedOf;

  /// Raw tier counts in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<int> tierCounts;

  /// Raw integer rating components. No arithmetic relationship is implied.
  final int ratingByProblemsSum;
  final int ratingByClass;
  final int ratingBySolvedCount;

  /// Raw problem-rating histogram in wire order, including duplicates.
  ///
  /// Decoder-produced lists are source-isolated and unmodifiable.
  final List<int> ratingProblemsHistogram;

  /// Raw integer rating class. The schema declares no bounds.
  final int ratingClass;

  final bool ratingClassPlus;
}
