import 'problem_search_tag.dart';

/// Sort orders of the official v4 problem vote listing.
enum ProblemVoteSort {
  recent('recent'),
  level('level'),
  weight('weight');

  const ProblemVoteSort(this.value);

  final String value;
}

/// Why the viewer may not mark votes, from the official v4 vote listing.
enum ProblemVoteMarkRefusal {
  unauthenticated('UNAUTHENTICATED'),
  reputationTooLow('REPUTATION_TOO_LOW'),
  tierTooLow('TIER_TOO_LOW'),
  accountTooNew('ACCOUNT_TOO_NEW'),
  notSolved('NOT_SOLVED'),
  banned('BANNED');

  const ProblemVoteMarkRefusal(this.value);

  final String value;
}

/// A helpful or unhelpful mark on an official v4 problem vote.
enum ProblemVoteMark {
  helpful('helpful'),
  unhelpful('unhelpful');

  const ProblemVoteMark(this.value);

  final String value;
}

/// One page of an official v4 problem's votes.
final class ProblemVotesResult {
  const ProblemVotesResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.sort,
    required this.markRefusal,
    required this.unhelpfulLocked,
  });

  /// Votes in wire order, including duplicates. No ordering is enforced.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<ProblemVote> items;

  /// Raw finite numbers. No bounds or relation to [items] are implied, and
  /// the response page need not equal the requested page.
  final num total;
  final num page;
  final num pageSize;

  /// Response sort. It need not equal the requested sort.
  final ProblemVoteSort sort;

  /// Required nullable refusal reason.
  final ProblemVoteMarkRefusal? markRefusal;

  final bool unhelpfulLocked;
}

/// One official v4 problem vote.
final class ProblemVote {
  const ProblemVote({
    required this.id,
    required this.user,
    required this.votedAt,
    required this.level,
    required this.weight,
    required this.invalidated,
    required this.notInCalculation,
    required this.banned,
    required this.superseded,
    required this.cutoff,
    required this.comment,
    required this.commentLanguage,
    required this.emoticonId,
    required this.emoticon,
    required this.source,
    required this.tags,
    required this.isStandard,
    required this.marks,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  /// Required nullable voter.
  final ProblemVoteUser? user;

  /// Raw string. It is not parsed or ordered.
  final String votedAt;

  /// Raw required nullable finite number. No bounds are implied.
  final num? level;

  /// Raw finite number. No bounds are implied.
  final num weight;

  /// Raw flags. No relationship between them is implied.
  final bool invalidated;
  final bool notInCalculation;
  final bool banned;
  final bool superseded;
  final bool cutoff;

  /// Raw required nullable strings.
  final String? comment;
  final String? commentLanguage;
  final String? emoticonId;

  /// Required nullable emoticon. No relation to [emoticonId] is implied.
  final ProblemVoteEmoticon? emoticon;

  final String source;

  /// Tags in wire order, including duplicates.
  ///
  /// Decoder-produced lists are eagerly validated, source-isolated, and
  /// unmodifiable.
  final List<ProblemVoteTag> tags;

  final bool isStandard;

  /// Required nullable mark state.
  final ProblemVoteMarks? marks;
}

/// The voter of an official v4 problem vote.
final class ProblemVoteUser {
  const ProblemVoteUser({
    required this.id,
    required this.handle,
    required this.tier,
    required this.profileImageUrl,
  });

  /// Raw finite response number. Integer semantics and bounds are not implied.
  final num id;

  final String handle;

  /// Required nullable official tier. Non-null values are in the range 0..31.
  final int? tier;

  /// Raw required nullable response value. URI validity is not implied.
  final String? profileImageUrl;
}

/// The emoticon attached to an official v4 problem vote.
final class ProblemVoteEmoticon {
  const ProblemVoteEmoticon({required this.key, required this.url});

  final String key;

  /// Raw response value. URI validity is not implied.
  final String url;
}

/// One tag entry of an official v4 problem vote.
final class ProblemVoteTag {
  const ProblemVoteTag({required this.tag, required this.legacyKey});

  /// Required nullable tag in the exact problem-search tag shape.
  final ProblemSearchTag? tag;

  /// Raw required nullable legacy key. No relation to [tag] is implied.
  final String? legacyKey;
}

/// Mark state of an official v4 problem vote.
final class ProblemVoteMarks {
  const ProblemVoteMarks({
    required this.score,
    required this.counts,
    required this.mine,
    required this.own,
  });

  /// Raw integer. No relation to [counts] is implied.
  final int score;

  /// Required nullable counts.
  final ProblemVoteMarkCounts? counts;

  /// Required nullable viewer mark.
  final ProblemVoteMark? mine;

  final bool own;
}

/// Helpful and unhelpful mark counts of an official v4 problem vote.
final class ProblemVoteMarkCounts {
  const ProblemVoteMarkCounts({required this.helpful, required this.unhelpful});

  /// Raw integers. The schema declares no bounds.
  final int helpful;
  final int unhelpful;
}

/// The viewer's own official v4 vote on one problem.
final class ProblemVoteMineResult {
  const ProblemVoteMineResult({required this.vote});

  /// Required nullable vote in the exact vote-listing item shape. Null means
  /// the viewer has not voted.
  final ProblemVote? vote;
}
