import 'problem_no_rating_warning.dart';
import 'problem_search_item.dart';

/// The complete response from the official v4 problem-detail endpoint.
final class ProblemDetailResult {
  const ProblemDetailResult({
    required this.id,
    required this.problemId,
    required this.subId,
    required this.level,
    required this.levelAverage,
    required this.levelStdev,
    required this.isStandard,
    required this.votedUserCount,
    required this.effectiveVoteCount,
    required this.solvedUserCount,
    required this.givesNoRating,
    required this.noRatingReasons,
    required this.noRatingWarnings,
    required this.titles,
    required this.userStatus,
    required this.contests,
    required this.tags,
    required this.ojLinks,
  });

  final num id;
  final num problemId;
  final String subId;
  final num level;
  final num levelAverage;
  final num levelStdev;
  final bool isStandard;
  final num votedUserCount;
  final num effectiveVoteCount;
  final num solvedUserCount;
  final bool givesNoRating;
  final List<ProblemNoRatingReason> noRatingReasons;
  final List<ProblemNoRatingWarning> noRatingWarnings;
  final List<ProblemDetailTitle> titles;
  final ProblemUserStatus? userStatus;
  final List<ProblemDetailContest> contests;
  final List<ProblemDetailTag> tags;
  final List<ProblemDetailOjLink> ojLinks;
}

/// One localized title from an official v4 problem-detail response.
final class ProblemDetailTitle {
  const ProblemDetailTitle({
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

/// One contest association from an official v4 problem-detail response.
final class ProblemDetailContest {
  const ProblemDetailContest({
    required this.id,
    required this.displayId,
    required this.name,
    required this.abbreviation,
  });

  final num id;
  final String displayId;
  final String name;
  final String? abbreviation;
}

/// One tag from an official v4 problem-detail response.
final class ProblemDetailTag {
  const ProblemDetailTag({
    required this.id,
    required this.key,
    required this.isMeta,
  });

  final num id;
  final String key;
  final bool isMeta;
}

/// One external judge link from an official v4 problem-detail response.
final class ProblemDetailOjLink {
  const ProblemDetailOjLink({
    required this.ojId,
    required this.ojName,
    required this.nativeProblemId,
    required this.url,
    required this.logoUrl,
  });

  final String ojId;
  final String ojName;
  final String nativeProblemId;
  final String url;
  final String? logoUrl;
}
