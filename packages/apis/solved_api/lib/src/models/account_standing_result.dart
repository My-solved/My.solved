import 'account_bans_result.dart';
import 'official_user_profile.dart';
import 'problem_reports_result.dart';

/// The viewer's standing warnings and bans, from the official v4 API.
final class AccountStandingResult {
  const AccountStandingResult({
    required this.strikes,
    required this.bans,
    required this.priorStrikeBans,
    required this.nextBanDays,
  });

  /// Strikes in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable, as is [bans].
  final List<AccountStrike> strikes;

  /// Bans in the exact public-profile ban shape.
  final List<OfficialUserProfileBan> bans;

  /// Raw integers. No bounds or relation to the lists are implied.
  final int priorStrikeBans;
  final int nextBanDays;
}

/// Why a strike was issued.
enum AccountStrikeCategory {
  hate('hate'),
  disparagement('disparagement'),
  profanity('profanity'),
  spam('spam'),
  personalInfo('personal-info'),
  offTopic('off-topic'),
  trollLevel('troll-level'),
  irrelevantTags('irrelevant-tags');

  const AccountStrikeCategory(this.value);

  final String value;
}

/// What happened to the content behind a strike.
enum AccountStrikeAction {
  hidden('hidden'),
  removed('removed');

  const AccountStrikeAction(this.value);

  final String value;
}

/// One strike against the viewer.
final class AccountStrike {
  const AccountStrike({
    required this.id,
    required this.problem,
    required this.category,
    required this.text,
    required this.action,
    required this.createdAt,
    required this.seen,
    required this.restored,
    required this.appeal,
    required this.appealable,
    required this.strikeCleared,
    required this.strikeExpiresAt,
  });

  /// Raw integer. The schema declares no bounds.
  final int id;

  /// Required nullable problem.
  final AccountStrikeProblem? problem;

  final AccountStrikeCategory category;
  final String text;
  final AccountStrikeAction action;

  /// Raw string. It is not parsed.
  final String createdAt;

  /// Raw flags. No relationship between them is implied.
  final bool seen;
  final bool restored;

  /// Required nullable appeal in the exact ban-appeal shape.
  final BanAppeal? appeal;

  final bool appealable;
  final bool strikeCleared;

  /// Raw required nullable string. It is not parsed.
  final String? strikeExpiresAt;
}

/// The problem behind a strike.
final class AccountStrikeProblem {
  const AccountStrikeProblem({required this.problem, required this.title});

  /// The seven fields shared exactly with a report's same-problem entry.
  final ProblemReportSameProblem problem;

  /// Raw required nullable title.
  final String? title;
}
