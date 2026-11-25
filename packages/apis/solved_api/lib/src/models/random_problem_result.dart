import 'problem_no_rating_warning.dart';
import 'problem_search_contest.dart';
import 'problem_search_item.dart';
import 'problem_search_tag.dart';
import 'problem_search_title.dart';
import 'problem_search_viewer_folder.dart';

/// The complete response from the official v4 random-problem endpoint.
final class RandomProblemResult {
  const RandomProblemResult({
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
    required this.viewerFolders,
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
  final List<ProblemSearchTitle> titles;
  final ProblemUserStatus? userStatus;
  final List<ProblemSearchContest> contests;
  final List<ProblemSearchTag> tags;
  final List<ProblemSearchViewerFolder> viewerFolders;
}
