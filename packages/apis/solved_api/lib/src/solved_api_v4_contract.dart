import 'models/models.dart';
import 'solved_api_contract.dart';

/// Date ranges supported by the public v4 reputation summary.
enum SolvedApiV4ReputationRange {
  days90('90d'),
  year('1y'),
  all('all');

  const SolvedApiV4ReputationRange(this.value);

  final String value;
}

/// Date ranges supported by the public v4 rating history.
enum SolvedApiV4RatingHistoryRange {
  days90('90d'),
  year('1y'),
  all('all');

  const SolvedApiV4RatingHistoryRange(this.value);

  final String value;
}

/// Sort orders supported by the official v4 problem search.
///
/// In particular, the v3-only `title` sort is intentionally not representable.
enum SolvedApiV4ProblemSort {
  id('id'),
  level('level'),
  solved('solved'),
  averageTry('average_try'),
  random('random');

  const SolvedApiV4ProblemSort(this.value);

  final String value;
}

enum SolvedApiV4SearchDirection {
  asc('asc'),
  desc('desc');

  const SolvedApiV4SearchDirection(this.value);

  final String value;
}

enum SolvedApiV4UserSort {
  rating('rating'),
  solved('solved'),
  contribution('contribution');

  const SolvedApiV4UserSort(this.value);

  final String value;
}

/// Sort orders supported by the official v4 public bookmark listing.
enum SolvedApiV4BookmarkSort {
  updated('updated'),
  problems('problems');

  const SolvedApiV4BookmarkSort(this.value);

  final String value;
}

/// Problem sort orders supported by an official v4 bookmark folder.
enum SolvedApiV4BookmarkProblemSort {
  order('order'),
  level('level'),
  solved('solved'),
  averageTry('average_try'),
  id('id');

  const SolvedApiV4BookmarkProblemSort(this.value);

  final String value;
}

/// Sort orders supported by the official v4 user collection.
enum SolvedApiV4CollectionSort {
  recent('recent'),
  rarity('rarity'),
  name('name');

  const SolvedApiV4CollectionSort(this.value);

  final String value;
}

/// Sort orders supported by the official v4 achievement-holder listing.
enum SolvedApiV4AchievementHolderSort {
  recent('recent'),
  first('first');

  const SolvedApiV4AchievementHolderSort(this.value);

  final String value;
}

/// Official v4 endpoints and response normalization.
///
/// Every ordinary v4 request needs an application secret. This contract keeps
/// the direct target as protocol metadata, but Flutter callers must select the
/// supplied proxy target so that the secret remains on the backend.
final class SolvedApiV4Contract {
  SolvedApiV4Contract({required Uri proxyBaseUri})
      : _proxyBaseUri = proxyBaseUri;

  static final Uri _directBaseUri = Uri.https('solved.ac', '/api/v4/');

  final Uri _proxyBaseUri;

  bool get requiresProxy => true;

  /// Page size used when adapting the unpaged v4 tag catalog for the UI.
  static const int tagSearchPageSize = 50;

  /// Resolves the stable identity spoken for by a user access token.
  ///
  /// Transport for this endpoint must attach a profile-scoped Bearer token.
  SolvedApiEndpoint<SolvedUserIdentity> currentUser() => _endpoint(
        path: 'me',
        decode: _decodeV4UserIdentity,
      );

  SolvedApiEndpoint<OfficialUserProfile> userProfile(String handle) =>
      _endpoint(
        path: 'users/${_pathSegment(handle, 'handle')}',
        queryParameters: const {'lang': 'ko'},
        decode: _decodeV4UserProfile,
      );

  SolvedApiEndpoint<ProfileActivityResult> userActivity(
    String handle, {
    required DateTime from,
    required DateTime to,
  }) {
    final fromDay = _activityQueryDay(from, 'from');
    final toDay = _activityQueryDay(to, 'to');
    if (fromDay.isAfter(toDay)) {
      throw ArgumentError.value(from, 'from', 'Must not be after to');
    }
    return _endpoint(
      path: 'users/${_pathSegment(handle, 'handle')}/activity/days',
      queryParameters: {
        'from': _formatDay(fromDay),
        'to': _formatDay(toDay),
      },
      decode: _decodeV4ProfileActivity,
    );
  }

  SolvedApiEndpoint<ProfileActivityFeedResult> userActivityFeed(
    String handle, {
    String? before,
    String? from,
    String? to,
    int? limit,
  }) {
    if (from != null) _activityFeedQueryDay(from, 'from');
    if (to != null) _activityFeedQueryDay(to, 'to');
    if (limit != null && (limit < 1 || limit > 500)) {
      throw ArgumentError.value(limit, 'limit', 'Must be from 1 through 500');
    }
    return _endpoint(
      path: 'users/${_pathSegment(handle, 'handle')}/activity/feed',
      queryParameters: {
        if (before != null) 'before': before,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (limit != null) 'limit': limit.toString(),
      },
      decode: _decodeV4ProfileActivityFeed,
    );
  }

  SolvedApiEndpoint<ProfileReputationResult> userReputation(
    String handle, {
    SolvedApiV4ReputationRange? range,
  }) =>
      _endpoint(
        path: 'users/${_pathSegment(handle, 'handle')}/reputation',
        queryParameters: {
          if (range != null) 'range': range.value,
        },
        decode: _decodeV4ProfileReputation,
      );

  SolvedApiEndpoint<ProfileReputationLogResult> userReputationLog(
    String handle, {
    String? month,
  }) {
    final segment = _pathSegment(handle, 'handle');
    if (month != null && !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month)) {
      throw ArgumentError.value(month, 'month', 'Must match YYYY-MM');
    }
    return _endpoint(
      path: 'users/$segment/reputation/log',
      queryParameters: {
        if (month != null) 'month': month,
      },
      decode: _decodeV4ProfileReputationLog,
    );
  }

  SolvedApiEndpoint<ProfileRatingHistoryResult> userRatingHistory(
    String handle, {
    SolvedApiV4RatingHistoryRange? range,
  }) =>
      _endpoint(
        path: 'users/${_pathSegment(handle, 'handle')}/rating/history',
        queryParameters: {
          if (range != null) 'range': range.value,
        },
        decode: _decodeV4ProfileRatingHistory,
      );

  SolvedApiEndpoint<ProfileTagLevelHistogramResult> userTagLevelHistogram(
    String handle,
    String key,
  ) =>
      _endpoint(
        path: 'users/${_pathSegment(handle, 'handle')}/tags/'
            '${_pathSegment(key, 'key')}/histogram',
        decode: _decodeV4ProfileTagLevelHistogram,
      );

  SolvedApiEndpoint<ProfileAchievementsResult> userAchievements(
    String handle, {
    String? language,
    String? versusHandle,
  }) {
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    if (versusHandle != null &&
        (versusHandle.isEmpty || versusHandle.runes.length > 64)) {
      throw ArgumentError.value(
        versusHandle,
        'versusHandle',
        'Must contain 1 to 64 characters',
      );
    }
    return _endpoint(
      path: 'users/${_pathSegment(handle, 'handle')}/achievements',
      queryParameters: {
        if (language != null) 'lang': language,
        if (versusHandle != null) 'vs': versusHandle,
      },
      decode: _decodeV4ProfileAchievements,
    );
  }

  SolvedApiEndpoint<ProfileAchievementSummaryResult> userAchievementSummary(
    String handle,
  ) =>
      _endpoint(
        path: 'users/${_pathSegment(handle, 'handle')}/achievements/summary',
        queryParameters: const {'lang': 'ko'},
        decode: _decodeV4ProfileAchievementSummary,
      );

  SolvedApiEndpoint<ProfileBadgeStandResult> userBadgeStand(String handle) =>
      _endpoint(
        path: 'users/${_pathSegment(handle, 'handle')}/badge-stand',
        queryParameters: const {'lang': 'ko'},
        decode: _decodeV4ProfileBadgeStand,
      );

  SolvedApiEndpoint<AchievementCatalogResult> achievementCatalog({
    String? language,
  }) {
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    return _endpoint(
      path: 'achievements',
      queryParameters: {
        if (language != null) 'lang': language,
      },
      decode: _decodeV4AchievementCatalog,
    );
  }

  SolvedApiEndpoint<ProblemAchievementsResult> achievementsForProblem(
    int problemId, {
    String? language,
  }) {
    if (problemId < 1) {
      throw ArgumentError.value(problemId, 'problemId', 'Must be at least 1');
    }
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    return _endpoint(
      path: 'achievements/for-problem/$problemId',
      queryParameters: {
        if (language != null) 'lang': language,
      },
      decode: _decodeV4ProblemAchievements,
    );
  }

  SolvedApiEndpoint<OfficialAchievementItem> achievementItem(
    OfficialAchievementItemKind kind,
    String key,
  ) =>
      _endpoint(
        path: 'achievements/items/${kind.value}/${_pathSegment(key, 'key')}',
        queryParameters: const {'lang': 'ko'},
        decode: (json) => _decodeV4AchievementItem(json, kind),
      );

  SolvedApiEndpoint<AchievementHoldersResult> achievementHolders(
    OfficialAchievementItemKind kind,
    String key, {
    SolvedApiV4AchievementHolderSort? sort,
    int? page,
  }) {
    if (page != null && (page < 1 || page > 200)) {
      throw ArgumentError.value(page, 'page', 'Must be from 1 through 200');
    }
    return _endpoint(
      path: 'achievements/items/${kind.value}/'
          '${_pathSegment(key, 'key')}/holders',
      queryParameters: {
        if (sort != null) 'sort': sort.value,
        if (page != null) 'page': '$page',
      },
      decode: _decodeV4AchievementHolders,
    );
  }

  SolvedApiEndpoint<ProfileBackgroundAsset?> backgroundShow(String key) =>
      _endpoint(
        path: 'achievements/items/background/${_pathSegment(key, 'key')}',
        queryParameters: const {'lang': 'ko'},
        decode: _decodeV4BackgroundAsset,
      );

  SolvedApiEndpoint<ProfileBadgeAsset> badgeShow(String key) => _endpoint(
        path: 'achievements/items/badge/${_pathSegment(key, 'key')}',
        queryParameters: const {'lang': 'ko'},
        decode: _decodeV4BadgeAsset,
      );

  SolvedApiEndpoint<ProblemDetailResult> problemDetail(
    int problemId, {
    String? sub,
  }) {
    if (problemId < 1) {
      throw ArgumentError.value(problemId, 'problemId', 'Must be at least 1');
    }
    return _endpoint(
      path: 'problems/$problemId',
      queryParameters: {if (sub != null) 'sub': sub},
      decode: _decodeV4ProblemDetail,
    );
  }

  SolvedApiEndpoint<ProblemReportsResult> problemReports(
    int problemId, {
    String? sub,
    int? page,
  }) {
    if (problemId < 1) {
      throw ArgumentError.value(problemId, 'problemId', 'Must be at least 1');
    }
    if (page != null) {
      _positivePage(page);
    }
    return _endpoint(
      path: 'problems/$problemId/reports',
      queryParameters: {
        if (sub != null) 'sub': sub,
        if (page != null) 'page': page.toString(),
      },
      decode: _decodeV4ProblemReports,
    );
  }

  SolvedApiEndpoint<ProblemVotesResult> problemVotes(
    int problemId, {
    String? sub,
    int? page,
    ProblemVoteSort? sort,
  }) {
    if (problemId < 1) {
      throw ArgumentError.value(problemId, 'problemId', 'Must be at least 1');
    }
    if (page != null) {
      _positivePage(page);
    }
    return _endpoint(
      path: 'problems/$problemId/votes',
      queryParameters: {
        if (sub != null) 'sub': sub,
        if (page != null) 'page': page.toString(),
        if (sort != null) 'sort': sort.value,
      },
      decode: _decodeV4ProblemVotes,
    );
  }

  SolvedApiEndpoint<ProblemVoteSummaryResult> problemVoteSummary(
    int problemId, {
    String? sub,
  }) {
    if (problemId < 1) {
      throw ArgumentError.value(problemId, 'problemId', 'Must be at least 1');
    }
    return _endpoint(
      path: 'problems/$problemId/votes/summary',
      queryParameters: {if (sub != null) 'sub': sub},
      decode: _decodeV4ProblemVoteSummary,
    );
  }

  SolvedApiEndpoint<ProblemSearchResult> searchProblems(
    String query, {
    int page = 1,
    SolvedApiV4ProblemSort sort = SolvedApiV4ProblemSort.id,
    SolvedApiV4SearchDirection direction = SolvedApiV4SearchDirection.asc,
    String? seed,
  }) {
    _positivePage(page);
    if (seed != null && (seed.isEmpty || seed.runes.length > 64)) {
      throw ArgumentError.value(seed, 'seed', 'Must contain 1 to 64 characters');
    }
    return _endpoint(
      path: 'problems',
      queryParameters: {
        'q': query,
        'page': page.toString(),
        'sort': sort.value,
        'direction': direction.value,
        if (seed != null) 'seed': seed,
      },
      decode: _decodeV4ProblemSearch,
    );
  }

  SolvedApiEndpoint<UserSearchResult> searchUsers(
    String query, {
    SolvedApiV4UserSort sort = SolvedApiV4UserSort.rating,
  }) {
    if (query.runes.length > 64) {
      throw ArgumentError.value(query, 'query', 'Must not exceed 64 characters');
    }
    return _endpoint(
      path: 'rankings/users/search',
      queryParameters: {'q': query, 'sort': sort.value},
      decode: _decodeV4UserSearch,
    );
  }

  SolvedApiEndpoint<RankingLeaderboardResult> rankingUsers({
    int? page,
    SolvedApiV4UserSort? sort,
  }) {
    if (page != null) {
      _positivePage(page);
    }
    return _endpoint(
      path: 'rankings/users',
      queryParameters: {
        if (page != null) 'page': page.toString(),
        if (sort != null) 'sort': sort.value,
      },
      decode: _decodeV4RankingLeaderboard,
    );
  }

  SolvedApiEndpoint<RankingLeaderboardResult> rankingRegionUsers(
    String countryCode, {
    int? page,
  }) {
    if (countryCode.runes.length != 2) {
      throw ArgumentError.value(
        countryCode,
        'countryCode',
        'Must be exactly 2 characters',
      );
    }
    final segment = _pathSegment(
      countryCode,
      'countryCode',
      maximumLength: 2,
    );
    if (page != null) {
      _positivePage(page);
    }
    return _endpoint(
      path: 'rankings/regions/$segment',
      queryParameters: {
        if (page != null) 'page': page.toString(),
      },
      decode: _decodeV4RankingLeaderboard,
    );
  }

  SolvedApiEndpoint<RankingLeaderboardResult> rankingTagUsers(
    String key, {
    int? page,
  }) {
    final segment = _pathSegment(key, 'key');
    if (page != null) {
      _positivePage(page);
    }
    return _endpoint(
      path: 'rankings/tags/$segment',
      queryParameters: {
        if (page != null) 'page': page.toString(),
      },
      decode: _decodeV4RankingLeaderboard,
    );
  }

  /// The raw official document marks [affiliationId] optional and nullable,
  /// but a path segment cannot be absent or null. This follows the reviewed
  /// proxy overlay, which requires a non-null integer without bounds.
  SolvedApiEndpoint<RankingLeaderboardResult> rankingAffiliationUsers(
    int affiliationId, {
    int? page,
  }) {
    if (page != null) {
      _positivePage(page);
    }
    return _endpoint(
      path: 'rankings/affiliations/$affiliationId',
      queryParameters: {
        if (page != null) 'page': page.toString(),
      },
      decode: _decodeV4RankingLeaderboard,
    );
  }

  SolvedApiEndpoint<AffiliationDetailResult> affiliationDetail(
    int id, {
    String? language,
  }) {
    if (id < 1) {
      throw ArgumentError.value(id, 'id', 'Must be at least 1');
    }
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    return _endpoint(
      path: 'affiliations/$id',
      queryParameters: {
        if (language != null) 'lang': language,
      },
      decode: _decodeV4AffiliationDetail,
    );
  }

  SolvedApiEndpoint<BookmarkFoldersResult> publicBookmarks({
    int? page,
    SolvedApiV4BookmarkSort? sort,
    String? query,
  }) {
    if (page != null && (page < 1 || page > 10000)) {
      throw ArgumentError.value(page, 'page', 'Must be from 1 through 10000');
    }
    if (query != null && query.runes.length > 100) {
      throw ArgumentError.value(
        query,
        'query',
        'Must not exceed 100 characters',
      );
    }
    return _endpoint(
      path: 'bookmarks',
      queryParameters: {
        if (page != null) 'page': page.toString(),
        if (sort != null) 'sort': sort.value,
        if (query != null) 'q': query,
      },
      decode: _decodeV4BookmarkFolders,
    );
  }

  SolvedApiEndpoint<BookmarkFoldersResult> userBookmarks(
    String handle, {
    int? page,
  }) {
    final segment = _pathSegment(handle, 'handle');
    if (page != null && (page < 1 || page > 10000)) {
      throw ArgumentError.value(page, 'page', 'Must be from 1 through 10000');
    }
    return _endpoint(
      path: 'users/$segment/bookmarks',
      queryParameters: {
        if (page != null) 'page': page.toString(),
      },
      decode: _decodeV4BookmarkFolders,
    );
  }

  SolvedApiEndpoint<BookmarkFolderDetailResult> bookmarkFolderDetail(
    String handle,
    String slug, {
    int? page,
    SolvedApiV4BookmarkProblemSort? sort,
    SolvedApiV4SearchDirection? direction,
    String? query,
  }) {
    final handleSegment = _pathSegment(handle, 'handle');
    if (!RegExp(r'^[0-9a-z_]{1,32}$').hasMatch(slug)) {
      throw ArgumentError.value(slug, 'slug', 'Must match [0-9a-z_]{1,32}');
    }
    if (page != null && (page < 1 || page > 10000)) {
      throw ArgumentError.value(page, 'page', 'Must be from 1 through 10000');
    }
    if (query != null && query.runes.length > 512) {
      throw ArgumentError.value(
        query,
        'query',
        'Must not exceed 512 characters',
      );
    }
    return _endpoint(
      path: 'users/$handleSegment/bookmarks/$slug',
      queryParameters: {
        if (page != null) 'page': page.toString(),
        if (sort != null) 'sort': sort.value,
        if (direction != null) 'direction': direction.value,
        if (query != null) 'q': query,
      },
      decode: _decodeV4BookmarkFolderDetail,
    );
  }

  SolvedApiEndpoint<UserCollectionResult> userCollection(
    String handle, {
    String? language,
    OfficialAchievementItemKind? kind,
    SolvedApiV4CollectionSort? sort,
    String? category,
    String? query,
    int? offset,
  }) {
    final segment = _pathSegment(handle, 'handle');
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    if (category != null && category.runes.length > 64) {
      throw ArgumentError.value(
        category,
        'category',
        'Must not exceed 64 characters',
      );
    }
    if (query != null && query.runes.length > 64) {
      throw ArgumentError.value(
        query,
        'query',
        'Must not exceed 64 characters',
      );
    }
    if (offset != null && offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Must not be negative');
    }
    return _endpoint(
      path: 'users/$segment/collection',
      queryParameters: {
        if (language != null) 'lang': language,
        if (kind != null) 'kind': kind.value,
        if (sort != null) 'sort': sort.value,
        if (category != null) 'category': category,
        if (query != null) 'q': query,
        if (offset != null) 'offset': offset.toString(),
      },
      decode: _decodeV4UserCollection,
    );
  }

  SolvedApiEndpoint<RankingRegionsResult> rankingRegions() => _endpoint(
        path: 'rankings/regions',
        decode: _decodeV4RankingRegions,
      );

  SolvedApiEndpoint<RankingAffiliationsResult> rankingAffiliations({
    String? query,
    String? language,
  }) {
    if (query != null && query.runes.length > 64) {
      throw ArgumentError.value(
        query,
        'query',
        'Must not exceed 64 characters',
      );
    }
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    return _endpoint(
      path: 'rankings/affiliations',
      queryParameters: {
        if (query != null) 'q': query,
        if (language != null) 'lang': language,
      },
      decode: _decodeV4RankingAffiliations,
    );
  }

  SolvedApiEndpoint<RankingAffiliationBoardResult> rankingAffiliationBoard({
    int? page,
    OfficialUserProfileAffiliationType? affiliationType,
    String? language,
  }) {
    if (page != null) {
      _positivePage(page);
    }
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    return _endpoint(
      path: 'rankings/affiliation-board',
      queryParameters: {
        if (page != null) 'page': page.toString(),
        if (affiliationType != null) 'type': affiliationType.value,
        if (language != null) 'lang': language,
      },
      decode: _decodeV4RankingAffiliationBoard,
    );
  }

  SolvedApiEndpoint<RankingTagsResult> rankingTags({String? language}) =>
      _endpoint(
        path: 'rankings/tags',
        queryParameters: {
          if (language != null) 'lang': language,
        },
        decode: _decodeV4RankingTags,
      );

  SolvedApiEndpoint<SearchSuggestionResult> searchSuggestions(
    String topic, {
    String? value,
  }) {
    if (topic.runes.length > 64) {
      throw ArgumentError.value(
        topic,
        'topic',
        'Must not exceed 64 characters',
      );
    }
    if (value != null && value.runes.length > 100) {
      throw ArgumentError.value(
        value,
        'value',
        'Must not exceed 100 characters',
      );
    }
    return _endpoint(
      path: 'search/suggest',
      queryParameters: {
        'topic': topic,
        if (value != null) 'value': value,
      },
      decode: _decodeV4SearchSuggestions,
    );
  }

  SolvedApiEndpoint<ProblemSearchAnalysisResult> analyzeProblemSearch({
    String? query,
  }) {
    if (query != null && query.runes.length > 1000) {
      throw ArgumentError.value(
        query,
        'query',
        'Must not exceed 1000 characters',
      );
    }
    return _endpoint(
      path: 'search/analyze',
      queryParameters: {if (query != null) 'q': query},
      decode: _decodeV4ProblemSearchAnalysis,
    );
  }

  SolvedApiEndpoint<RandomProblemResult> randomProblem({String? query}) {
    if (query != null && query.runes.length > 1000) {
      throw ArgumentError.value(
        query,
        'query',
        'Must not exceed 1000 characters',
      );
    }
    return _endpoint(
      path: 'search/random-problem',
      queryParameters: {if (query != null) 'q': query},
      decode: _decodeV4RandomProblem,
    );
  }

  SolvedApiEndpoint<NoticeListResult> notices({
    String? language,
    int? page,
    String? query,
  }) {
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    if (page != null && (page < 1 || page > 10000)) {
      throw ArgumentError.value(page, 'page', 'Must be from 1 through 10000');
    }
    if (query != null && query.runes.length > 64) {
      throw ArgumentError.value(
        query,
        'query',
        'Must not exceed 64 characters',
      );
    }
    return _endpoint(
      path: 'posts/notice',
      queryParameters: {
        if (language != null) 'lang': language,
        if (page != null) 'page': page.toString(),
        if (query != null) 'q': query,
      },
      decode: _decodeV4NoticeList,
    );
  }

  SolvedApiEndpoint<PostDetailResult> helpPage(
    String path, {
    String? language,
  }) {
    if (path.length > 255 ||
        !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*(?:\/[a-z0-9]+(?:-[a-z0-9]+)*)*$')
            .hasMatch(path)) {
      throw ArgumentError.value(
        path,
        'path',
        'Must be 1 through 255 characters of slug segments separated by /',
      );
    }
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    return _endpoint(
      path: 'posts/help/page',
      queryParameters: {
        if (language != null) 'lang': language,
        'path': path,
      },
      decode: _decodeV4PostDetail,
    );
  }

  SolvedApiEndpoint<PostDetailResult> notice(
    String slug, {
    String? language,
  }) {
    if (slug.length > 64 ||
        !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug)) {
      throw ArgumentError.value(
        slug,
        'slug',
        'Must be 1 through 64 lowercase letters, digits, and single hyphens',
      );
    }
    if (language != null && language.runes.length > 16) {
      throw ArgumentError.value(
        language,
        'language',
        'Must not exceed 16 characters',
      );
    }
    return _endpoint(
      path: 'posts/notice/$slug',
      queryParameters: {if (language != null) 'lang': language},
      decode: _decodeV4PostDetail,
    );
  }

  SolvedApiEndpoint<SiteStatsResult> siteStats() => _endpoint(
        path: 'site/stats',
        decode: _decodeV4SiteStats,
      );

  SolvedApiEndpoint<SourceLookupResult> sourceContest(
    String ojId,
    String nativeId,
  ) =>
      _endpoint(
        path: 'sources/oj/'
            '${_pathSegment(ojId, 'ojId', maximumLength: 32)}/contests/'
            '${_pathSegment(nativeId, 'nativeId')}',
        decode: _decodeV4SourceLookup,
      );

  SolvedApiEndpoint<SourceLookupResult> sourceGroup(
    String ojId,
    String nativeId,
  ) =>
      _endpoint(
        path: 'sources/oj/'
            '${_pathSegment(ojId, 'ojId', maximumLength: 32)}/groups/'
            '${_pathSegment(nativeId, 'nativeId')}',
        decode: _decodeV4SourceLookup,
      );

  SolvedApiEndpoint<SourceGroupsResult> sourceGroups() => _endpoint(
        path: 'sources',
        decode: _decodeV4SourceGroups,
      );

  SolvedApiEndpoint<SourceContestDetailResult> sourceContestDetail(int id) {
    if (id < 1) {
      throw ArgumentError.value(id, 'id', 'Must be at least 1');
    }
    return _endpoint(
      path: 'sources/contests/$id',
      decode: _decodeV4SourceContestDetail,
    );
  }

  SolvedApiEndpoint<SourceGroupDetailResult> sourceGroupDetail(int id) {
    if (id < 1) {
      throw ArgumentError.value(id, 'id', 'Must be at least 1');
    }
    return _endpoint(
      path: 'sources/groups/$id',
      decode: _decodeV4SourceGroupDetail,
    );
  }

  /// Fetches the complete official tag catalog and filters it locally.
  ///
  /// The v4 `/tags` endpoint accepts no query or page parameters. Matching is
  /// case-insensitive across the tag key, every localized name, and aliases.
  SolvedApiEndpoint<SearchObject<TagSearchItem>> searchTags(
    String query, {
    int page = 1,
  }) {
    _positivePage(page);
    return _endpoint(
      path: 'tags',
      decode: (json) => _decodeV4TagSearch(json, query: query, page: page),
    );
  }

  SolvedApiEndpoint<TagDetailResult> tagDetail(String key) => _endpoint(
        path: 'tags/${_pathSegment(key, 'key')}',
        decode: _decodeV4TagDetail,
      );

  SolvedApiEndpoint<T> _endpoint<T>({
    required String path,
    Map<String, String> queryParameters = const {},
    required SolvedApiDecoder<T> decode,
  }) =>
      SolvedApiEndpoint(
        direct: SolvedApiTarget(
          baseUri: _directBaseUri,
          path: path,
          queryParameters: queryParameters,
        ),
        proxy: SolvedApiTarget(
          baseUri: _proxyBaseUri,
          path: path,
          queryParameters: queryParameters,
        ),
        decode: decode,
      );
}

SolvedUserIdentity _decodeV4UserIdentity(dynamic json) {
  final body = _object(json, 'current user');
  return SolvedUserIdentity(
    id: _number(body['id'], 'id'),
    handle: _string(body['handle'], 'handle'),
  );
}

SearchSuggestionResult _decodeV4SearchSuggestions(dynamic json) {
  final body = _object(json, 'search suggestions');
  final suggestions = List<SearchSuggestionItem>.unmodifiable(
    _list(body['suggestions'], 'suggestions').map(
      (value) => _decodeV4SearchSuggestionItem(
        _object(value, 'suggestions[]'),
      ),
    ),
  );
  return SearchSuggestionResult(suggestions: suggestions);
}

SearchSuggestionItem _decodeV4SearchSuggestionItem(
  Map<String, dynamic> body,
) =>
    SearchSuggestionItem(
      value: _string(body['value'], 'suggestions[].value'),
      detail: _requiredNullableString(
        body,
        'detail',
        'suggestions[].detail',
      ),
      tier: _requiredNullableInteger(
        body,
        'tier',
        'suggestions[].tier',
      ),
    );

ProblemSearchAnalysisResult _decodeV4ProblemSearchAnalysis(dynamic json) {
  final body = _object(json, 'problem search analysis');
  final diagnostics = List<ProblemSearchDiagnostic>.unmodifiable(
    _list(body['diagnostics'], 'diagnostics').map(
      (value) =>
          _decodeV4ProblemSearchDiagnostic(_object(value, 'diagnostics[]')),
    ),
  );
  return ProblemSearchAnalysisResult(diagnostics: diagnostics);
}

ProblemDetailResult _decodeV4ProblemDetail(dynamic json) {
  const field = 'problem detail';
  final body = _object(json, field);
  final noRatingReasons = List<ProblemNoRatingReason>.unmodifiable(
    _list(body['noRatingReasons'], '$field.noRatingReasons').map(
      (value) => _decodeV4ProblemNoRatingReason(
        value,
        '$field.noRatingReasons[]',
      ),
    ),
  );
  final noRatingWarnings = List<ProblemNoRatingWarning>.unmodifiable(
    _list(body['noRatingWarnings'], '$field.noRatingWarnings').map(
      (value) => _decodeV4ProblemNoRatingWarning(
        _object(value, '$field.noRatingWarnings[]'),
        '$field.noRatingWarnings[]',
      ),
    ),
  );
  final titles = List<ProblemDetailTitle>.unmodifiable(
    _list(body['titles'], '$field.titles').map(
      (value) => _decodeV4ProblemDetailTitle(
        _object(value, '$field.titles[]'),
        '$field.titles[]',
      ),
    ),
  );
  final contests = List<ProblemDetailContest>.unmodifiable(
    _list(body['contests'], '$field.contests').map(
      (value) => _decodeV4ProblemDetailContest(
        _object(value, '$field.contests[]'),
        '$field.contests[]',
      ),
    ),
  );
  final tags = List<ProblemDetailTag>.unmodifiable(
    _list(body['tags'], '$field.tags').map(
      (value) => _decodeV4ProblemDetailTag(
        _object(value, '$field.tags[]'),
        '$field.tags[]',
      ),
    ),
  );
  final ojLinks = List<ProblemDetailOjLink>.unmodifiable(
    _list(body['ojLinks'], '$field.ojLinks').map(
      (value) => _decodeV4ProblemDetailOjLink(
        _object(value, '$field.ojLinks[]'),
        '$field.ojLinks[]',
      ),
    ),
  );
  if (!body.containsKey('userStatus')) {
    throw const FormatException(
      'Missing required field problem detail.userStatus',
    );
  }
  final userStatusValue = body['userStatus'];
  return ProblemDetailResult(
    id: _number(body['id'], '$field.id'),
    problemId: _number(body['problemId'], '$field.problemId'),
    subId: _string(body['subId'], '$field.subId'),
    level: _number(body['level'], '$field.level'),
    levelAverage: _number(body['levelAverage'], '$field.levelAverage'),
    levelStdev: _number(body['levelStdev'], '$field.levelStdev'),
    isStandard: _boolean(body['isStandard'], '$field.isStandard'),
    votedUserCount: _number(body['votedUserCount'], '$field.votedUserCount'),
    effectiveVoteCount: _number(
      body['effectiveVoteCount'],
      '$field.effectiveVoteCount',
    ),
    solvedUserCount: _number(
      body['solvedUserCount'],
      '$field.solvedUserCount',
    ),
    givesNoRating: _boolean(
      body['givesNoRating'],
      '$field.givesNoRating',
    ),
    noRatingReasons: noRatingReasons,
    noRatingWarnings: noRatingWarnings,
    titles: titles,
    userStatus: userStatusValue == null
        ? null
        : _decodeV4ProblemUserStatus(
            userStatusValue,
            '$field.userStatus',
          ),
    contests: contests,
    tags: tags,
    ojLinks: ojLinks,
  );
}

ProblemDetailTitle _decodeV4ProblemDetailTitle(
  Map<String, dynamic> body,
  String field,
) =>
    ProblemDetailTitle(
      language: _string(body['language'], '$field.language'),
      title: _string(body['title'], '$field.title'),
      isOriginal: _boolean(body['isOriginal'], '$field.isOriginal'),
      latex: _boolean(body['latex'], '$field.latex'),
      html: _boolean(body['html'], '$field.html'),
    );

ProblemDetailContest _decodeV4ProblemDetailContest(
  Map<String, dynamic> body,
  String field,
) {
  if (!body.containsKey('abbreviation')) {
    throw FormatException('Missing required field $field.abbreviation');
  }
  return ProblemDetailContest(
    id: _number(body['id'], '$field.id'),
    displayId: _string(body['displayId'], '$field.displayId'),
    name: _string(body['name'], '$field.name'),
    abbreviation: _nullableString(
      body['abbreviation'],
      '$field.abbreviation',
    ),
  );
}

ProblemDetailTag _decodeV4ProblemDetailTag(
  Map<String, dynamic> body,
  String field,
) =>
    ProblemDetailTag(
      id: _number(body['id'], '$field.id'),
      key: _string(body['key'], '$field.key'),
      isMeta: _boolean(body['isMeta'], '$field.isMeta'),
    );

ProblemDetailOjLink _decodeV4ProblemDetailOjLink(
  Map<String, dynamic> body,
  String field,
) {
  if (!body.containsKey('logoUrl')) {
    throw FormatException('Missing required field $field.logoUrl');
  }
  return ProblemDetailOjLink(
    ojId: _string(body['ojId'], '$field.ojId'),
    ojName: _string(body['ojName'], '$field.ojName'),
    nativeProblemId: _string(
      body['nativeProblemId'],
      '$field.nativeProblemId',
    ),
    url: _string(body['url'], '$field.url'),
    logoUrl: _nullableString(body['logoUrl'], '$field.logoUrl'),
  );
}

ProblemSearchResult _decodeV4ProblemSearch(dynamic json) {
  final body = _object(json, 'problem search');
  final problems = _list(body['problems'], 'problems')
      .map((item) => _decodeV4ProblemSearchItem(_object(item, 'problems[]')))
      .toList(growable: false);
  List<ProblemSearchDiagnostic>? diagnostics;
  if (body.containsKey('diagnostics')) {
    diagnostics = List<ProblemSearchDiagnostic>.unmodifiable(
      _list(body['diagnostics'], 'diagnostics').map(
        (value) =>
            _decodeV4ProblemSearchDiagnostic(_object(value, 'diagnostics[]')),
      ),
    );
  }
  return ProblemSearchResult(
    count: _number(body['total'], 'total'),
    items: problems,
    page: _number(body['page'], 'page'),
    pageSize: _number(body['pageSize'], 'pageSize'),
    diagnostics: diagnostics,
    seed: body.containsKey('seed') ? _string(body['seed'], 'seed') : null,
  );
}

ProblemSearchDiagnostic _decodeV4ProblemSearchDiagnostic(
  Map<String, dynamic> body,
) {
  Map<String, String>? data;
  if (body.containsKey('data')) {
    final decodedData = <String, String>{};
    for (final entry in _object(body['data'], 'diagnostics[].data').entries) {
      decodedData[entry.key] = _string(entry.value, 'diagnostics[].data[]');
    }
    data = Map<String, String>.unmodifiable(decodedData);
  }
  return ProblemSearchDiagnostic(
    start: _number(body['start'], 'diagnostics[].start'),
    end: _number(body['end'], 'diagnostics[].end'),
    severity: _decodeV4ProblemSearchDiagnosticSeverity(body['severity']),
    code: _decodeV4ProblemSearchDiagnosticCode(body['code']),
    messageKey: _string(body['messageKey'], 'diagnostics[].messageKey'),
    message: _string(body['message'], 'diagnostics[].message'),
    data: data,
  );
}

ProblemSearchDiagnosticSeverity _decodeV4ProblemSearchDiagnosticSeverity(
  Object? value,
) {
  switch (_string(value, 'diagnostics[].severity')) {
    case 'error':
      return ProblemSearchDiagnosticSeverity.error;
    case 'warning':
      return ProblemSearchDiagnosticSeverity.warning;
    default:
      throw const FormatException('Unsupported diagnostics[].severity');
  }
}

ProblemSearchDiagnosticCode _decodeV4ProblemSearchDiagnosticCode(
  Object? value,
) {
  switch (_string(value, 'diagnostics[].code')) {
    case 'unknown-filter':
      return ProblemSearchDiagnosticCode.unknownFilter;
    case 'unimplemented-filter':
      return ProblemSearchDiagnosticCode.unimplementedFilter;
    case 'empty-value':
      return ProblemSearchDiagnosticCode.emptyValue;
    case 'invalid-value':
      return ProblemSearchDiagnosticCode.invalidValue;
    case 'unknown-lang':
      return ProblemSearchDiagnosticCode.unknownLang;
    case 'invalid-boolean':
      return ProblemSearchDiagnosticCode.invalidBoolean;
    case 'unclosed-quote':
      return ProblemSearchDiagnosticCode.unclosedQuote;
    case 'unmatched-paren':
      return ProblemSearchDiagnosticCode.unmatchedParen;
    case 'dangling-operator':
      return ProblemSearchDiagnosticCode.danglingOperator;
    case 'ignored-input':
      return ProblemSearchDiagnosticCode.ignoredInput;
    case 'unknown-handle':
      return ProblemSearchDiagnosticCode.unknownHandle;
    case 'unknown-tag':
      return ProblemSearchDiagnosticCode.unknownTag;
    case 'me-without-viewer':
      return ProblemSearchDiagnosticCode.meWithoutViewer;
    default:
      throw const FormatException('Unsupported diagnostics[].code');
  }
}

ProblemSearchItem _decodeV4ProblemSearchItem(Map<String, dynamic> body) {
  final titles = List<ProblemSearchTitle>.unmodifiable(
    _list(body['titles'], 'problems[].titles').map(
      (value) => _decodeV4ProblemSearchTitle(
        _object(value, 'problems[].titles[]'),
        'problems[].titles[]',
      ),
    ),
  );
  final contests = List<ProblemSearchContest>.unmodifiable(
    _list(body['contests'], 'problems[].contests').map(
      (value) => _decodeV4ProblemSearchContest(
        _object(value, 'problems[].contests[]'),
        'problems[].contests[]',
      ),
    ),
  );
  final tags = List<ProblemSearchTag>.unmodifiable(
    _list(body['tags'], 'problems[].tags').map(
      (value) => _decodeV4ProblemSearchTag(
        _object(value, 'problems[].tags[]'),
        'problems[].tags[]',
      ),
    ),
  );
  final viewerFolders = List<ProblemSearchViewerFolder>.unmodifiable(
    _list(body['viewerFolders'], 'problems[].viewerFolders').map(
      (value) => _decodeV4ProblemSearchViewerFolder(
        _object(value, 'problems[].viewerFolders[]'),
        'problems[].viewerFolders[]',
      ),
    ),
  );
  final noRatingReasons = List<ProblemNoRatingReason>.unmodifiable(
    _list(
      body['noRatingReasons'],
      'problems[].noRatingReasons',
    ).map(
      (value) => _decodeV4ProblemNoRatingReason(
        value,
        'problems[].noRatingReasons[]',
      ),
    ),
  );
  final noRatingWarnings = List<ProblemNoRatingWarning>.unmodifiable(
    _list(body['noRatingWarnings'], 'problems[].noRatingWarnings').map(
      (value) => _decodeV4ProblemNoRatingWarning(
        _object(value, 'problems[].noRatingWarnings[]'),
        'problems[].noRatingWarnings[]',
      ),
    ),
  );
  if (!body.containsKey('userStatus')) {
    throw const FormatException('Missing required field problems[].userStatus');
  }
  final userStatusValue = body['userStatus'];
  ProblemUserStatus? userStatus;
  if (userStatusValue != null) {
    userStatus = _decodeV4ProblemUserStatus(
      userStatusValue,
      'problems[].userStatus',
    );
  }
  return ProblemSearchItem(
    problemId: _wholeNumber(body['problemId'], 'problems[].problemId'),
    id: _number(body['id'], 'problems[].id'),
    subId: _string(body['subId'], 'problems[].subId'),
    title: _selectV4ProblemTitle(titles),
    titles: titles,
    contests: contests,
    tags: tags,
    viewerFolders: viewerFolders,
    level: _wholeNumber(body['level'], 'problems[].level'),
    levelAverage: _number(body['levelAverage'], 'problems[].levelAverage'),
    levelStdev: _number(body['levelStdev'], 'problems[].levelStdev'),
    isStandard: _boolean(body['isStandard'], 'problems[].isStandard'),
    userStatus: userStatus,
    votedUserCount: _number(
      body['votedUserCount'],
      'problems[].votedUserCount',
    ),
    effectiveVoteCount: _number(
      body['effectiveVoteCount'],
      'problems[].effectiveVoteCount',
    ),
    solvedUserCount: _number(
      body['solvedUserCount'],
      'problems[].solvedUserCount',
    ),
    givesNoRating: _boolean(body['givesNoRating'], 'problems[].givesNoRating'),
    noRatingReasons: noRatingReasons,
    noRatingWarnings: noRatingWarnings,
    // The official v4 problem shape has tag keys but no localized names.
    tagNames: tags.map((tag) => tag.key).toList(growable: false),
  );
}

RandomProblemResult _decodeV4RandomProblem(dynamic json) {
  const field = 'random problem';
  final body = _object(json, field);
  final titles = List<ProblemSearchTitle>.unmodifiable(
    _list(body['titles'], '$field.titles').map(
      (value) => _decodeV4ProblemSearchTitle(
        _object(value, '$field.titles[]'),
        '$field.titles[]',
      ),
    ),
  );
  final contests = List<ProblemSearchContest>.unmodifiable(
    _list(body['contests'], '$field.contests').map(
      (value) => _decodeV4ProblemSearchContest(
        _object(value, '$field.contests[]'),
        '$field.contests[]',
      ),
    ),
  );
  final tags = List<ProblemSearchTag>.unmodifiable(
    _list(body['tags'], '$field.tags').map(
      (value) => _decodeV4ProblemSearchTag(
        _object(value, '$field.tags[]'),
        '$field.tags[]',
      ),
    ),
  );
  final viewerFolders = List<ProblemSearchViewerFolder>.unmodifiable(
    _list(body['viewerFolders'], '$field.viewerFolders').map(
      (value) => _decodeV4ProblemSearchViewerFolder(
        _object(value, '$field.viewerFolders[]'),
        '$field.viewerFolders[]',
      ),
    ),
  );
  final noRatingReasons = List<ProblemNoRatingReason>.unmodifiable(
    _list(body['noRatingReasons'], '$field.noRatingReasons').map(
      (value) => _decodeV4ProblemNoRatingReason(
        value,
        '$field.noRatingReasons[]',
      ),
    ),
  );
  final noRatingWarnings = List<ProblemNoRatingWarning>.unmodifiable(
    _list(body['noRatingWarnings'], '$field.noRatingWarnings').map(
      (value) => _decodeV4ProblemNoRatingWarning(
        _object(value, '$field.noRatingWarnings[]'),
        '$field.noRatingWarnings[]',
      ),
    ),
  );
  if (!body.containsKey('userStatus')) {
    throw const FormatException(
      'Missing required field random problem.userStatus',
    );
  }
  final userStatusValue = body['userStatus'];
  return RandomProblemResult(
    id: _number(body['id'], '$field.id'),
    problemId: _number(body['problemId'], '$field.problemId'),
    subId: _string(body['subId'], '$field.subId'),
    level: _number(body['level'], '$field.level'),
    levelAverage: _number(body['levelAverage'], '$field.levelAverage'),
    levelStdev: _number(body['levelStdev'], '$field.levelStdev'),
    isStandard: _boolean(body['isStandard'], '$field.isStandard'),
    votedUserCount: _number(body['votedUserCount'], '$field.votedUserCount'),
    effectiveVoteCount: _number(
      body['effectiveVoteCount'],
      '$field.effectiveVoteCount',
    ),
    solvedUserCount: _number(
      body['solvedUserCount'],
      '$field.solvedUserCount',
    ),
    givesNoRating: _boolean(
      body['givesNoRating'],
      '$field.givesNoRating',
    ),
    noRatingReasons: noRatingReasons,
    noRatingWarnings: noRatingWarnings,
    titles: titles,
    userStatus: userStatusValue == null
        ? null
        : _decodeV4ProblemUserStatus(
            userStatusValue,
            '$field.userStatus',
          ),
    contests: contests,
    tags: tags,
    viewerFolders: viewerFolders,
  );
}

SiteStatsResult _decodeV4SiteStats(dynamic json) {
  const field = 'site stats';
  final body = _object(json, field);
  return SiteStatsResult(
    problemsWithLevel: _integer(
      body['problemsWithLevel'],
      '$field.problemsWithLevel',
    ),
    users: _integer(body['users'], '$field.users'),
    contributors: _integer(body['contributors'], '$field.contributors'),
    contributions: _integer(body['contributions'], '$field.contributions'),
    usersByTier: List<int>.unmodifiable(
      _list(body['usersByTier'], '$field.usersByTier').map(
        (value) => _integer(value, '$field.usersByTier[]'),
      ),
    ),
  );
}

SourceGroupsResult _decodeV4SourceGroups(dynamic json) {
  final body = _object(json, 'source groups');
  return SourceGroupsResult(
    groups: List<SourceGroupSummary>.unmodifiable(
      _list(body['groups'], 'groups').map(
        (value) => _decodeV4SourceGroupSummary(
          _object(value, 'groups[]'),
          'groups[]',
        ),
      ),
    ),
  );
}

SourceGroupDetailResult _decodeV4SourceGroupDetail(dynamic json) {
  final body = _object(json, 'source group');
  return SourceGroupDetailResult(
    group:
        _decodeV4SourceGroupSummary(_object(body['group'], 'group'), 'group'),
    path: _decodeV4SourcePath(body),
    links: _decodeV4SourceLinks(body),
    query: _requiredNullableString(body, 'query'),
    groups: List<SourceGroupSummary>.unmodifiable(
      _list(body['groups'], 'groups').map(
        (value) => _decodeV4SourceGroupSummary(
          _object(value, 'groups[]'),
          'groups[]',
        ),
      ),
    ),
    contests: List<SourceContestSummary>.unmodifiable(
      _list(body['contests'], 'contests').map(
        (value) => _decodeV4SourceContestSummary(
          _object(value, 'contests[]'),
          'contests[]',
        ),
      ),
    ),
  );
}

SourceContestDetailResult _decodeV4SourceContestDetail(dynamic json) {
  final body = _object(json, 'source contest');
  final contestBody = _object(body['contest'], 'contest');
  final contest = _decodeV4SourceContestSummary(contestBody, 'contest');
  return SourceContestDetailResult(
    contest: SourceContestDetail(
      id: contest.id,
      name: contest.name,
      abbreviation: contest.abbreviation,
      startsAt: contest.startsAt,
      problemCount: contest.problemCount,
      solvedCount: contest.solvedCount,
      level: contest.level,
      url: _requiredNullableString(contestBody, 'url', 'contest.url'),
      venue: _requiredNullableString(contestBody, 'venue', 'contest.venue'),
    ),
    path: _decodeV4SourcePath(body),
    links: _decodeV4SourceLinks(body),
    query: _requiredNullableString(body, 'query'),
    problems: List<SourceContestProblem>.unmodifiable(
      _list(body['problems'], 'problems').map((value) {
        final item = _object(value, 'problems[]');
        return SourceContestProblem(
          numberInContest: _string(
            item['numberInContest'],
            'problems[].numberInContest',
          ),
          problem: _decodeV4ProblemSearchItem(
            _object(item['problem'], 'problems[].problem'),
          ),
        );
      }),
    ),
  );
}

List<SourcePathEntry> _decodeV4SourcePath(Map<String, dynamic> body) =>
    List<SourcePathEntry>.unmodifiable(
      _list(body['path'], 'path').map((value) {
        final entry = _object(value, 'path[]');
        return SourcePathEntry(
          id: _number(entry['id'], 'path[].id'),
          name: _string(entry['name'], 'path[].name'),
        );
      }),
    );

List<SourceLink> _decodeV4SourceLinks(Map<String, dynamic> body) =>
    List<SourceLink>.unmodifiable(
      _list(body['links'], 'links').map((value) {
        final link = _object(value, 'links[]');
        return SourceLink(
          ojId: _string(link['ojId'], 'links[].ojId'),
          ojName: _string(link['ojName'], 'links[].ojName'),
          url: _string(link['url'], 'links[].url'),
        );
      }),
    );

SourceContestSummary _decodeV4SourceContestSummary(
  Map<String, dynamic> body,
  String field,
) {
  final levelValue = _requiredValue(body, 'level', '$field.level');
  return SourceContestSummary(
    id: _number(body['id'], '$field.id'),
    name: _string(body['name'], '$field.name'),
    abbreviation: _requiredNullableString(
      body,
      'abbreviation',
      '$field.abbreviation',
    ),
    startsAt: _requiredNullableString(body, 'startsAt', '$field.startsAt'),
    problemCount: _number(body['problemCount'], '$field.problemCount'),
    solvedCount: _requiredNullableNumber(
      body,
      'solvedCount',
      '$field.solvedCount',
    ),
    level: levelValue == null
        ? null
        : _decodeV4SourceLevel(
            _object(levelValue, '$field.level'),
            '$field.level',
          ),
  );
}

SourceGroupSummary _decodeV4SourceGroupSummary(
  Map<String, dynamic> body,
  String field,
) {
  final levelValue = _requiredValue(body, 'level', '$field.level');
  return SourceGroupSummary(
    id: _number(body['id'], '$field.id'),
    name: _string(body['name'], '$field.name'),
    abbreviation: _requiredNullableString(
      body,
      'abbreviation',
      '$field.abbreviation',
    ),
    groupCount: _number(body['groupCount'], '$field.groupCount'),
    contestCount: _number(body['contestCount'], '$field.contestCount'),
    problemCount: _requiredNullableNumber(
      body,
      'problemCount',
      '$field.problemCount',
    ),
    solvedCount: _requiredNullableNumber(
      body,
      'solvedCount',
      '$field.solvedCount',
    ),
    level: levelValue == null
        ? null
        : _decodeV4SourceLevel(
            _object(levelValue, '$field.level'),
            '$field.level',
          ),
    order: _requiredNullableSourceOrder(body, '$field.order'),
  );
}

SourceLevelSummary _decodeV4SourceLevel(
  Map<String, dynamic> body,
  String field,
) {
  final progressValue = _requiredValue(body, 'progress', '$field.progress');
  return SourceLevelSummary(
    q25: _integer(body['q25'], '$field.q25'),
    q50: _integer(body['q50'], '$field.q50'),
    q75: _integer(body['q75'], '$field.q75'),
    tierCounts: List<int>.unmodifiable(
      _list(body['tierCounts'], '$field.tierCounts').map(
        (value) => _integer(value, '$field.tierCounts[]'),
      ),
    ),
    ratedCount: _integer(body['ratedCount'], '$field.ratedCount'),
    order: _requiredNullableSourceOrder(body, '$field.order'),
    progress: progressValue == null
        ? null
        : _decodeV4SourceLevelProgress(
            _object(progressValue, '$field.progress'),
            '$field.progress',
          ),
  );
}

SourceLevelProgress _decodeV4SourceLevelProgress(
  Map<String, dynamic> body,
  String field,
) {
  final through = _object(body['through'], '$field.through');
  return SourceLevelProgress(
    solved: _integer(body['solved'], '$field.solved'),
    through: SourceLevelProgressThrough(
      q25: _boolean(through['q25'], '$field.through.q25'),
      q50: _boolean(through['q50'], '$field.through.q50'),
      q75: _boolean(through['q75'], '$field.through.q75'),
    ),
  );
}

SourceProblemOrder? _requiredNullableSourceOrder(
  Map<String, dynamic> body,
  String field,
) {
  final value = _requiredValue(body, 'order', field);
  if (value == null) return null;
  switch (_string(value, field)) {
    case 'ascending':
      return SourceProblemOrder.ascending;
    case 'random':
      return SourceProblemOrder.random;
    case 'mixed':
      return SourceProblemOrder.mixed;
    default:
      throw FormatException('Unknown $field');
  }
}

Object? _requiredValue(
  Map<String, dynamic> body,
  String wireKey,
  String field,
) {
  if (!body.containsKey(wireKey)) {
    throw FormatException('Missing required field $field');
  }
  return body[wireKey];
}

num? _requiredNullableNumber(
  Map<String, dynamic> body,
  String wireKey,
  String field,
) {
  final value = _requiredValue(body, wireKey, field);
  return value == null ? null : _number(value, field);
}

PostDetailResult _decodeV4PostDetail(dynamic json) {
  final body = _object(json, 'post');
  final contentValue = _object(body['content'], 'content');
  if (_string(contentValue['type'], 'content.type') != 'doc') {
    throw const FormatException('Unsupported content.type');
  }
  if (contentValue.containsKey('content') && contentValue['content'] is! List) {
    throw const FormatException('Expected list for content.content');
  }
  final previousValue = _requiredValue(body, 'previous', 'previous');
  final nextValue = _requiredValue(body, 'next', 'next');
  return PostDetailResult(
    board: switch (_string(body['board'], 'board')) {
      'notice' => PostBoard.notice,
      'help' => PostBoard.help,
      _ => throw const FormatException('Unsupported board'),
    },
    path: _string(body['path'], 'path'),
    language: _string(body['language'], 'language'),
    languages: List<String>.unmodifiable(
      _list(body['languages'], 'languages').map(
        (value) => _string(value, 'languages[]'),
      ),
    ),
    title: _string(body['title'], 'title'),
    summary: _requiredNullableString(body, 'summary'),
    content:
        _immutableJsonValue(contentValue, 'content')! as Map<String, Object?>,
    publishedAt: _string(body['publishedAt'], 'publishedAt'),
    updatedAt: _string(body['updatedAt'], 'updatedAt'),
    pinned: _boolean(body['pinned'], 'pinned'),
    coverImageUrl: _requiredNullableString(body, 'coverImageUrl'),
    basisDate: _requiredNullableString(body, 'basisDate'),
    breadcrumbs: List<PostLink>.unmodifiable(
      _list(body['breadcrumbs'], 'breadcrumbs').map(
        (value) => _decodeV4PostLink(value, 'breadcrumbs[]'),
      ),
    ),
    previous: previousValue == null
        ? null
        : _decodeV4PostLink(previousValue, 'previous'),
    next: nextValue == null ? null : _decodeV4PostLink(nextValue, 'next'),
  );
}

PostLink _decodeV4PostLink(Object? value, String field) {
  final body = _object(value, field);
  return PostLink(
    path: _string(body['path'], '$field.path'),
    title: _string(body['title'], '$field.title'),
  );
}

NoticeListResult _decodeV4NoticeList(dynamic json) {
  final body = _object(json, 'notice list');
  return NoticeListResult(
    items: List<NoticeListItem>.unmodifiable(
      _list(body['items'], 'items').map((value) {
        final item = _object(value, 'items[]');
        return NoticeListItem(
          path: _string(item['path'], 'items[].path'),
          language: _string(item['language'], 'items[].language'),
          title: _string(item['title'], 'items[].title'),
          summary: _requiredNullableString(item, 'summary', 'items[].summary'),
          publishedAt: _string(item['publishedAt'], 'items[].publishedAt'),
          pinned: _boolean(item['pinned'], 'items[].pinned'),
          isNew: _boolean(item['isNew'], 'items[].isNew'),
          coverImageUrl: _requiredNullableString(
            item,
            'coverImageUrl',
            'items[].coverImageUrl',
          ),
        );
      }),
    ),
    total: _integer(body['total'], 'total'),
    page: _integer(body['page'], 'page'),
    perPage: _integer(body['perPage'], 'perPage'),
  );
}

SourceLookupResult _decodeV4SourceLookup(dynamic json) {
  final body = _object(json, 'source lookup');
  return SourceLookupResult(
    id: _number(body['id'], 'source lookup.id'),
  );
}

ProblemNoRatingWarning _decodeV4ProblemNoRatingWarning(
  Map<String, dynamic> body,
  String field,
) {
  if (!body.containsKey('problem')) {
    throw FormatException('Missing required field $field.problem');
  }
  final problemValue = body['problem'];
  ProblemNoRatingWarningProblem? problem;
  if (problemValue != null) {
    problem = _decodeV4ProblemNoRatingWarningProblem(
      _object(problemValue, '$field.problem'),
      '$field.problem',
    );
  }
  return ProblemNoRatingWarning(
    type: _decodeV4ProblemNoRatingWarningType(body['type'], '$field.type'),
    problem: problem,
  );
}

ProblemNoRatingWarningType _decodeV4ProblemNoRatingWarningType(
  Object? value,
  String field,
) {
  final code = _string(value, field);
  return switch (code) {
    'same' => ProblemNoRatingWarningType.same,
    'searchable' => ProblemNoRatingWarningType.searchable,
    'wrong-inputs' => ProblemNoRatingWarningType.wrongInputs,
    'insufficient-conditions' =>
      ProblemNoRatingWarningType.insufficientConditions,
    'no-special-judge' => ProblemNoRatingWarningType.noSpecialJudge,
    'wrong-conditions' => ProblemNoRatingWarningType.wrongConditions,
    'wrong-statement' => ProblemNoRatingWarningType.wrongStatement,
    _ => throw FormatException('Unknown problem no-rating warning: $code'),
  };
}

ProblemNoRatingWarningProblem _decodeV4ProblemNoRatingWarningProblem(
  Map<String, dynamic> body,
  String field,
) {
  if (!body.containsKey('userStatus')) {
    throw FormatException('Missing required field $field.userStatus');
  }
  final userStatusValue = body['userStatus'];
  ProblemUserStatus? userStatus;
  if (userStatusValue != null) {
    userStatus = _decodeV4ProblemUserStatus(
      userStatusValue,
      '$field.userStatus',
    );
  }
  return ProblemNoRatingWarningProblem(
    problemId: _number(
      body['problemId'],
      '$field.problemId',
    ),
    subId: _string(body['subId'], '$field.subId'),
    level: _number(body['level'], '$field.level'),
    effectiveVoteCount: _number(
      body['effectiveVoteCount'],
      '$field.effectiveVoteCount',
    ),
    givesNoRating: _boolean(
      body['givesNoRating'],
      '$field.givesNoRating',
    ),
    isStandard: _boolean(
      body['isStandard'],
      '$field.isStandard',
    ),
    userStatus: userStatus,
  );
}

ProblemVoteSummaryResult _decodeV4ProblemVoteSummary(dynamic json) {
  final body = _object(json, 'problem vote summary');
  return ProblemVoteSummaryResult(
    items: List<ProblemVoteSummaryPoint>.unmodifiable(
      _list(body['items'], 'items').map((value) {
        final point = _object(value, 'items[]');
        return ProblemVoteSummaryPoint(
          votedAt: _string(point['votedAt'], 'items[].votedAt'),
          level: _requiredNullableNumber(point, 'level', 'items[].level'),
          weight: _number(point['weight'], 'items[].weight'),
          invalidated: _boolean(point['invalidated'], 'items[].invalidated'),
          notInCalculation: _boolean(
            point['notInCalculation'],
            'items[].notInCalculation',
          ),
          banned: _boolean(point['banned'], 'items[].banned'),
          cutoff: _boolean(point['cutoff'], 'items[].cutoff'),
        );
      }),
    ),
    tagDistribution: List<ProblemVoteTagShare>.unmodifiable(
      _list(body['tagDistribution'], 'tagDistribution').map((value) {
        final share = _object(value, 'tagDistribution[]');
        return ProblemVoteTagShare(
          tag: _decodeV4ProblemSearchTag(
            _object(share['tag'], 'tagDistribution[].tag'),
            'tagDistribution[].tag',
          ),
          count: _number(share['count'], 'tagDistribution[].count'),
          denominator: _number(
            share['denominator'],
            'tagDistribution[].denominator',
          ),
        );
      }),
    ),
  );
}

ProblemVotesResult _decodeV4ProblemVotes(dynamic json) {
  final body = _object(json, 'problem votes');
  final markRefusalValue = _requiredValue(body, 'markRefusal', 'markRefusal');
  return ProblemVotesResult(
    items: List<ProblemVote>.unmodifiable(
      _list(body['items'], 'items').map(
        (value) => _decodeV4ProblemVote(_object(value, 'items[]'), 'items[]'),
      ),
    ),
    total: _number(body['total'], 'total'),
    page: _number(body['page'], 'page'),
    pageSize: _number(body['pageSize'], 'pageSize'),
    sort: switch (_string(body['sort'], 'sort')) {
      'recent' => ProblemVoteSort.recent,
      'level' => ProblemVoteSort.level,
      'weight' => ProblemVoteSort.weight,
      _ => throw const FormatException('Unsupported sort'),
    },
    markRefusal: markRefusalValue == null
        ? null
        : switch (_string(markRefusalValue, 'markRefusal')) {
            'UNAUTHENTICATED' => ProblemVoteMarkRefusal.unauthenticated,
            'REPUTATION_TOO_LOW' => ProblemVoteMarkRefusal.reputationTooLow,
            'TIER_TOO_LOW' => ProblemVoteMarkRefusal.tierTooLow,
            'ACCOUNT_TOO_NEW' => ProblemVoteMarkRefusal.accountTooNew,
            'NOT_SOLVED' => ProblemVoteMarkRefusal.notSolved,
            'BANNED' => ProblemVoteMarkRefusal.banned,
            _ => throw const FormatException('Unsupported markRefusal'),
          },
    unhelpfulLocked: _boolean(body['unhelpfulLocked'], 'unhelpfulLocked'),
  );
}

ProblemVote _decodeV4ProblemVote(Map<String, dynamic> body, String field) {
  final userValue = _requiredValue(body, 'user', '$field.user');
  final user = userValue == null ? null : _object(userValue, '$field.user');
  final emoticonValue = _requiredValue(body, 'emoticon', '$field.emoticon');
  final emoticon =
      emoticonValue == null ? null : _object(emoticonValue, '$field.emoticon');
  final marksValue = _requiredValue(body, 'marks', '$field.marks');
  return ProblemVote(
    id: _number(body['id'], '$field.id'),
    user: user == null
        ? null
        : ProblemVoteUser(
            id: _number(user['id'], '$field.user.id'),
            handle: _string(user['handle'], '$field.user.handle'),
            tier: _requiredNullableTier(user, '$field.user.tier'),
            profileImageUrl: _requiredNullableString(
              user,
              'profileImageUrl',
              '$field.user.profileImageUrl',
            ),
          ),
    votedAt: _string(body['votedAt'], '$field.votedAt'),
    level: _requiredNullableNumber(body, 'level', '$field.level'),
    weight: _number(body['weight'], '$field.weight'),
    invalidated: _boolean(body['invalidated'], '$field.invalidated'),
    notInCalculation: _boolean(
      body['notInCalculation'],
      '$field.notInCalculation',
    ),
    banned: _boolean(body['banned'], '$field.banned'),
    superseded: _boolean(body['superseded'], '$field.superseded'),
    cutoff: _boolean(body['cutoff'], '$field.cutoff'),
    comment: _requiredNullableString(body, 'comment', '$field.comment'),
    commentLanguage: _requiredNullableString(
      body,
      'commentLanguage',
      '$field.commentLanguage',
    ),
    emoticonId: _requiredNullableString(
      body,
      'emoticonId',
      '$field.emoticonId',
    ),
    emoticon: emoticon == null
        ? null
        : ProblemVoteEmoticon(
            key: _string(emoticon['key'], '$field.emoticon.key'),
            url: _string(emoticon['url'], '$field.emoticon.url'),
          ),
    source: _string(body['source'], '$field.source'),
    tags: List<ProblemVoteTag>.unmodifiable(
      _list(body['tags'], '$field.tags').map((value) {
        final entry = _object(value, '$field.tags[]');
        final tagValue = _requiredValue(entry, 'tag', '$field.tags[].tag');
        return ProblemVoteTag(
          tag: tagValue == null
              ? null
              : _decodeV4ProblemSearchTag(
                  _object(tagValue, '$field.tags[].tag'),
                  '$field.tags[].tag',
                ),
          legacyKey: _requiredNullableString(
            entry,
            'legacyKey',
            '$field.tags[].legacyKey',
          ),
        );
      }),
    ),
    isStandard: _boolean(body['isStandard'], '$field.isStandard'),
    marks: marksValue == null
        ? null
        : _decodeV4ProblemVoteMarks(
            _object(marksValue, '$field.marks'),
            '$field.marks',
          ),
  );
}

ProblemVoteMarks _decodeV4ProblemVoteMarks(
  Map<String, dynamic> body,
  String field,
) {
  final countsValue = _requiredValue(body, 'counts', '$field.counts');
  final counts =
      countsValue == null ? null : _object(countsValue, '$field.counts');
  final mineValue = _requiredValue(body, 'mine', '$field.mine');
  return ProblemVoteMarks(
    score: _integer(body['score'], '$field.score'),
    counts: counts == null
        ? null
        : ProblemVoteMarkCounts(
            helpful: _integer(counts['helpful'], '$field.counts.helpful'),
            unhelpful: _integer(counts['unhelpful'], '$field.counts.unhelpful'),
          ),
    mine: mineValue == null
        ? null
        : switch (_string(mineValue, '$field.mine')) {
            'helpful' => ProblemVoteMark.helpful,
            'unhelpful' => ProblemVoteMark.unhelpful,
            _ => throw FormatException('Unsupported $field.mine'),
          },
    own: _boolean(body['own'], '$field.own'),
  );
}

ProblemReportsResult _decodeV4ProblemReports(dynamic json) {
  final body = _object(json, 'problem reports');
  return ProblemReportsResult(
    items: List<ProblemReport>.unmodifiable(
      _list(body['items'], 'items').map(
        (value) => _decodeV4ProblemReport(_object(value, 'items[]')),
      ),
    ),
    total: _number(body['total'], 'total'),
    page: _number(body['page'], 'page'),
    pageSize: _number(body['pageSize'], 'pageSize'),
  );
}

ProblemReport _decodeV4ProblemReport(Map<String, dynamic> body) {
  const field = 'items[]';
  final statusChangeValue =
      _requiredValue(body, 'statusChange', '$field.statusChange');
  final statusChange = statusChangeValue == null
      ? null
      : _object(statusChangeValue, '$field.statusChange');
  return ProblemReport(
    id: _number(body['id'], '$field.id'),
    user: _requiredNullableProblemReportUser(body, 'user', '$field.user'),
    reason: _decodeV4ProblemReportReason(
      _object(body['reason'], '$field.reason'),
    ),
    sameProblems: List<ProblemReportSameProblem>.unmodifiable(
      _list(body['sameProblems'], '$field.sameProblems').map(
        (value) => _decodeV4ProblemReportSameProblem(
          _object(value, '$field.sameProblems[]'),
        ),
      ),
    ),
    comment: _string(body['comment'], '$field.comment'),
    status: switch (_string(body['status'], '$field.status')) {
      'pending' => ProblemReportStatus.pending,
      'accepted' => ProblemReportStatus.accepted,
      'rejected' => ProblemReportStatus.rejected,
      'resolved' => ProblemReportStatus.resolved,
      _ => throw const FormatException('Unsupported items[].status'),
    },
    statusChange: statusChange == null
        ? null
        : ProblemReportStatusChange(
            by: _requiredNullableProblemReportUser(
              statusChange,
              'by',
              '$field.statusChange.by',
            ),
            at: _string(statusChange['at'], '$field.statusChange.at'),
            comment: _requiredNullableString(
              statusChange,
              'comment',
              '$field.statusChange.comment',
            ),
          ),
    createdAt: _string(body['createdAt'], '$field.createdAt'),
  );
}

ProblemReportReason _decodeV4ProblemReportReason(Map<String, dynamic> body) {
  const field = 'items[].reason';
  switch (_string(body['type'], '$field.type')) {
    case 'same-problem':
      final problemIds = List<int>.unmodifiable(
        _list(body['problemIds'], '$field.problemIds').map((value) {
          final id = _integer(value, '$field.problemIds[]');
          if (id < 1) {
            throw const FormatException(
              'Expected positive integer for items[].reason.problemIds[]',
            );
          }
          return id;
        }),
      );
      if (problemIds.isEmpty || problemIds.length > 20) {
        throw const FormatException(
          'Expected 1 through 20 items[].reason.problemIds',
        );
      }
      return ProblemReportSameProblemReason(problemIds: problemIds);
    case 'issue':
      final url = _string(body['url'], '$field.url');
      if (url.runes.length > 512) {
        throw const FormatException(
          'Expected at most 512 characters for items[].reason.url',
        );
      }
      return ProblemReportIssueReason(url: url);
    case 'issue-resolved':
      final id = _integer(body['problemReportId'], '$field.problemReportId');
      if (id < 1) {
        throw const FormatException(
          'Expected positive integer for items[].reason.problemReportId',
        );
      }
      return ProblemReportIssueResolvedReason(problemReportId: id);
    default:
      throw const FormatException('Unsupported items[].reason.type');
  }
}

ProblemReportSameProblem _decodeV4ProblemReportSameProblem(
  Map<String, dynamic> body,
) {
  const field = 'items[].sameProblems[]';
  final userStatusValue =
      _requiredValue(body, 'userStatus', '$field.userStatus');
  return ProblemReportSameProblem(
    problemId: _number(body['problemId'], '$field.problemId'),
    subId: _string(body['subId'], '$field.subId'),
    level: _number(body['level'], '$field.level'),
    effectiveVoteCount: _number(
      body['effectiveVoteCount'],
      '$field.effectiveVoteCount',
    ),
    givesNoRating: _boolean(body['givesNoRating'], '$field.givesNoRating'),
    isStandard: _boolean(body['isStandard'], '$field.isStandard'),
    userStatus: userStatusValue == null
        ? null
        : _decodeV4ProblemUserStatus(userStatusValue, '$field.userStatus'),
  );
}

ProblemReportUser? _requiredNullableProblemReportUser(
  Map<String, dynamic> body,
  String wireKey,
  String field,
) {
  final value = _requiredValue(body, wireKey, field);
  if (value == null) return null;
  final user = _object(value, field);
  return ProblemReportUser(
    id: _number(user['id'], '$field.id'),
    handle: _string(user['handle'], '$field.handle'),
    tier: _requiredNullableTier(user, '$field.tier'),
    profileImageUrl: _requiredNullableString(
      user,
      'profileImageUrl',
      '$field.profileImageUrl',
    ),
  );
}

ProblemUserStatus _decodeV4ProblemUserStatus(Object? value, String field) {
  final code = _string(value, field);
  return switch (code) {
    'solved' => ProblemUserStatus.solved,
    'partial' => ProblemUserStatus.partial,
    'tried' => ProblemUserStatus.tried,
    _ => throw FormatException('Unknown problem user status: $code'),
  };
}

ProblemNoRatingReason _decodeV4ProblemNoRatingReason(
  Object? value,
  String field,
) {
  final code = _string(value, field);
  return switch (code) {
    'unofficial' => ProblemNoRatingReason.unofficial,
    'legacy' => ProblemNoRatingReason.legacy,
    'staff' => ProblemNoRatingReason.staff,
    'unsettled' => ProblemNoRatingReason.unsettled,
    _ => throw FormatException('Unknown problem no-rating reason: $code'),
  };
}

ProblemSearchTitle _decodeV4ProblemSearchTitle(
  Map<String, dynamic> body,
  String field,
) =>
    ProblemSearchTitle(
      language: _string(body['language'], '$field.language'),
      title: _string(body['title'], '$field.title'),
      isOriginal: _boolean(body['isOriginal'], '$field.isOriginal'),
      latex: _boolean(body['latex'], '$field.latex'),
      html: _boolean(body['html'], '$field.html'),
    );

ProblemSearchTag _decodeV4ProblemSearchTag(
  Map<String, dynamic> body,
  String field,
) =>
    ProblemSearchTag(
      id: _number(body['id'], '$field.id'),
      key: _string(body['key'], '$field.key'),
      isMeta: _boolean(body['isMeta'], '$field.isMeta'),
    );

ProblemSearchContest _decodeV4ProblemSearchContest(
  Map<String, dynamic> body,
  String field,
) {
  if (!body.containsKey('abbreviation')) {
    throw FormatException('Missing required field $field.abbreviation');
  }
  return ProblemSearchContest(
    id: _number(body['id'], '$field.id'),
    displayId: _string(body['displayId'], '$field.displayId'),
    name: _string(body['name'], '$field.name'),
    abbreviation: _nullableString(body['abbreviation'], '$field.abbreviation'),
  );
}

ProblemSearchViewerFolder _decodeV4ProblemSearchViewerFolder(
  Map<String, dynamic> body,
  String field,
) {
  if (!body.containsKey('color')) {
    throw FormatException('Missing required field $field.color');
  }
  final colorValue = body['color'];
  return ProblemSearchViewerFolder(
    slug: _string(body['slug'], '$field.slug'),
    name: _string(body['name'], '$field.name'),
    color: colorValue == null
        ? null
        : _decodeV4ProblemSearchViewerFolderColor(
            colorValue,
            '$field.color',
          ),
  );
}

BookmarkFoldersResult _decodeV4BookmarkFolders(dynamic json) {
  final body = _object(json, 'bookmark folders');
  return BookmarkFoldersResult(
    folders: List<BookmarkFolder>.unmodifiable(
      _list(body['folders'], 'folders').map(
        (value) => _decodeV4BookmarkFolder(
          _object(value, 'folders[]'),
          'folders[]',
        ),
      ),
    ),
    total: _number(body['total'], 'total'),
    page: _number(body['page'], 'page'),
    pageSize: _number(body['pageSize'], 'pageSize'),
  );
}

UserCollectionResult _decodeV4UserCollection(dynamic json) {
  final body = _object(json, 'user collection');
  final counts = _object(body['counts'], 'counts');
  final equippedByKind = _object(body['equippedByKind'], 'equippedByKind');
  return UserCollectionResult(
    items: List<UserCollectionItem>.unmodifiable(
      _list(body['items'], 'items').map(
        (value) => _decodeV4UserCollectionItem(
          _object(value, 'items[]'),
          'items[]',
        ),
      ),
    ),
    total: _integer(body['total'], 'total'),
    nextOffset: _requiredNullableInteger(body, 'nextOffset', 'nextOffset'),
    counts: UserCollectionCounts(
      badge: _integer(counts['badge'], 'counts.badge'),
      background: _integer(counts['background'], 'counts.background'),
    ),
    categories: List<String>.unmodifiable(
      _list(body['categories'], 'categories').map(
        (value) => _string(value, 'categories[]'),
      ),
    ),
    equipped: _requiredNullableUserCollectionItem(body, 'equipped', 'equipped'),
    equippedBadge: _requiredNullableUserCollectionItem(
      equippedByKind,
      'badge',
      'equippedByKind.badge',
    ),
    equippedBackground: _requiredNullableUserCollectionItem(
      equippedByKind,
      'background',
      'equippedByKind.background',
    ),
  );
}

UserCollectionItem? _requiredNullableUserCollectionItem(
  Map<String, dynamic> body,
  String wireKey,
  String field,
) {
  final value = _requiredValue(body, wireKey, field);
  return value == null
      ? null
      : _decodeV4UserCollectionItem(_object(value, field), field);
}

UserCollectionItem _decodeV4UserCollectionItem(
  Map<String, dynamic> body,
  String field,
) =>
    UserCollectionItem(
      kind: switch (_string(body['kind'], '$field.kind')) {
        'badge' => OfficialAchievementItemKind.badge,
        'background' => OfficialAchievementItemKind.background,
        _ => throw FormatException('Unsupported $field.kind'),
      },
      id: _integer(body['id'], '$field.id'),
      key: _string(body['key'], '$field.key'),
      name: _string(body['name'], '$field.name'),
      imageUrl: _string(body['imageUrl'], '$field.imageUrl'),
      category: _string(body['category'], '$field.category'),
      addedAt: _string(body['addedAt'], '$field.addedAt'),
      equipped: _boolean(body['equipped'], '$field.equipped'),
      acquiredAt: _requiredNullableString(
        body,
        'acquiredAt',
        '$field.acquiredAt',
      ),
      holderCount: _requiredNullableInteger(
        body,
        'holderCount',
        '$field.holderCount',
      ),
    );

BookmarkFolderDetailResult _decodeV4BookmarkFolderDetail(dynamic json) {
  final body = _object(json, 'bookmark folder');
  final isFavoriteValue = _requiredValue(body, 'isFavorite', 'isFavorite');
  return BookmarkFolderDetailResult(
    folder:
        _decodeV4BookmarkFolder(_object(body['folder'], 'folder'), 'folder'),
    isOwner: _boolean(body['isOwner'], 'isOwner'),
    isFavorite: isFavoriteValue == null
        ? null
        : _boolean(isFavoriteValue, 'isFavorite'),
    levels: List<BookmarkFolderLevel>.unmodifiable(
      _list(body['levels'], 'levels').map((value) {
        final level = _object(value, 'levels[]');
        return BookmarkFolderLevel(
          level: _number(level['level'], 'levels[].level'),
          count: _number(level['count'], 'levels[].count'),
          solved: _requiredNullableNumber(level, 'solved', 'levels[].solved'),
        );
      }),
    ),
    problems: List<BookmarkFolderProblem>.unmodifiable(
      _list(body['problems'], 'problems').map((value) {
        final item = _object(value, 'problems[]');
        return BookmarkFolderProblem(
          problem: _decodeV4ProblemSearchItem(
            _object(item['problem'], 'problems[].problem'),
          ),
          note: _requiredNullableString(item, 'note', 'problems[].note'),
          addedAt: _string(item['addedAt'], 'problems[].addedAt'),
        );
      }),
    ),
    total: _number(body['total'], 'total'),
    page: _number(body['page'], 'page'),
    pageSize: _number(body['pageSize'], 'pageSize'),
  );
}

BookmarkFolder _decodeV4BookmarkFolder(
  Map<String, dynamic> body,
  String field,
) {
  final colorValue = _requiredValue(body, 'color', '$field.color');
  final owner = _object(body['owner'], '$field.owner');
  return BookmarkFolder(
    slug: _string(body['slug'], '$field.slug'),
    name: _string(body['name'], '$field.name'),
    description: _string(body['description'], '$field.description'),
    color: colorValue == null
        ? null
        : _decodeV4ProblemSearchViewerFolderColor(colorValue, '$field.color'),
    visibility: switch (_string(body['visibility'], '$field.visibility')) {
      'private' => BookmarkFolderVisibility.private,
      'unlisted' => BookmarkFolderVisibility.unlisted,
      'public' => BookmarkFolderVisibility.public,
      _ => throw FormatException('Unsupported $field.visibility'),
    },
    problemCount: _number(body['problemCount'], '$field.problemCount'),
    favoriteCount: _number(body['favoriteCount'], '$field.favoriteCount'),
    solvedCount: _requiredNullableNumber(
      body,
      'solvedCount',
      '$field.solvedCount',
    ),
    owner: BookmarkFolderOwner(
      id: _number(owner['id'], '$field.owner.id'),
      handle: _string(owner['handle'], '$field.owner.handle'),
      tier: _requiredNullableTier(owner, '$field.owner.tier'),
      profileImageUrl: _requiredNullableString(
        owner,
        'profileImageUrl',
        '$field.owner.profileImageUrl',
      ),
    ),
    createdAt: _string(body['createdAt'], '$field.createdAt'),
    updatedAt: _string(body['updatedAt'], '$field.updatedAt'),
  );
}

ProblemSearchViewerFolderColor _decodeV4ProblemSearchViewerFolderColor(
  Object? value,
  String field,
) {
  final color = _string(value, field);
  return switch (color) {
    'red' => ProblemSearchViewerFolderColor.red,
    'violet' => ProblemSearchViewerFolderColor.violet,
    'blue' => ProblemSearchViewerFolderColor.blue,
    'teal' => ProblemSearchViewerFolderColor.teal,
    'lime' => ProblemSearchViewerFolderColor.lime,
    'yellow' => ProblemSearchViewerFolderColor.yellow,
    'orange' => ProblemSearchViewerFolderColor.orange,
    _ => throw FormatException('Unsupported $field'),
  };
}

String? _selectV4ProblemTitle(List<ProblemSearchTitle> titles) {
  String? first;
  String? original;
  for (final title in titles) {
    first ??= title.title;
    if (title.language == 'ko') return title.title;
    if (title.isOriginal) original ??= title.title;
  }
  return original ?? first;
}

AffiliationDetailResult _decodeV4AffiliationDetail(dynamic json) {
  final body = _object(json, 'affiliation detail');
  return AffiliationDetailResult(
    id: _number(body['id'], 'id'),
    affiliationId: _integer(body['affiliationId'], 'affiliationId'),
    name: _string(body['name'], 'name'),
    type: _decodeV4AffiliationType(body['type'], 'type'),
    countryCode: _requiredNullableString(body, 'countryCode', 'countryCode'),
    logoImageUrl: _requiredNullableString(
      body,
      'logoImageUrl',
      'logoImageUrl',
    ),
    logoThumbnailUrl: _requiredNullableString(
      body,
      'logoThumbnailUrl',
      'logoThumbnailUrl',
    ),
    color: _requiredNullableString(body, 'color', 'color'),
    website: _requiredNullableString(body, 'website', 'website'),
    rating: _integer(body['rating'], 'rating'),
    userCount: _integer(body['userCount'], 'userCount'),
    solvedCount: _integer(body['solvedCount'], 'solvedCount'),
    voteCount: _integer(body['voteCount'], 'voteCount'),
    displayName: _string(body['displayName'], 'displayName'),
    rank: _integer(body['rank'], 'rank'),
    rankedOf: _integer(body['rankedOf'], 'rankedOf'),
    typeRank: _integer(body['typeRank'], 'typeRank'),
    typeRankedOf: _integer(body['typeRankedOf'], 'typeRankedOf'),
    tierCounts: List<int>.unmodifiable(
      _list(body['tierCounts'], 'tierCounts').map(
        (value) => _integer(value, 'tierCounts[]'),
      ),
    ),
    ratingByProblemsSum: _integer(
      body['ratingByProblemsSum'],
      'ratingByProblemsSum',
    ),
    ratingByClass: _integer(body['ratingByClass'], 'ratingByClass'),
    ratingBySolvedCount: _integer(
      body['ratingBySolvedCount'],
      'ratingBySolvedCount',
    ),
    ratingProblemsHistogram: List<int>.unmodifiable(
      _list(body['ratingProblemsHistogram'], 'ratingProblemsHistogram').map(
        (value) => _integer(value, 'ratingProblemsHistogram[]'),
      ),
    ),
    ratingClass: _integer(body['ratingClass'], 'ratingClass'),
    ratingClassPlus: _boolean(body['ratingClassPlus'], 'ratingClassPlus'),
  );
}

RankingRegionsResult _decodeV4RankingRegions(dynamic json) {
  final body = _object(json, 'ranking regions');
  return RankingRegionsResult(
    regions: List<RankingRegion>.unmodifiable(
      _list(body['regions'], 'regions').map(
        (value) {
          final region = _object(value, 'regions[]');
          return RankingRegion(
            countryCode: _string(
              region['countryCode'],
              'regions[].countryCode',
            ),
            userCount: _integer(region['userCount'], 'regions[].userCount'),
          );
        },
      ),
    ),
  );
}

RankingAffiliationsResult _decodeV4RankingAffiliations(dynamic json) {
  final body = _object(json, 'ranking affiliations');
  return RankingAffiliationsResult(
    affiliations: List<RankingAffiliationItem>.unmodifiable(
      _list(body['affiliations'], 'affiliations').map(
        (value) {
          final affiliation = _object(value, 'affiliations[]');
          final fields = _decodeV4RankingAffiliationFields(
            affiliation,
            'affiliations[]',
          );
          return RankingAffiliationItem(
            id: fields.id,
            affiliationId: fields.affiliationId,
            name: fields.name,
            type: fields.type,
            userCount: fields.userCount,
            logoThumbnailUrl: fields.logoThumbnailUrl,
            color: fields.color,
          );
        },
      ),
    ),
  );
}

typedef _RankingAffiliationFields = ({
  int id,
  int affiliationId,
  String name,
  OfficialUserProfileAffiliationType type,
  int userCount,
  String? logoThumbnailUrl,
  String? color,
});

_RankingAffiliationFields _decodeV4RankingAffiliationFields(
  Map<String, dynamic> body,
  String field,
) =>
    (
      id: _integer(body['id'], '$field.id'),
      affiliationId: _integer(
        body['affiliationId'],
        '$field.affiliationId',
      ),
      name: _string(body['name'], '$field.name'),
      type: _decodeV4AffiliationType(body['type'], '$field.type'),
      userCount: _integer(body['userCount'], '$field.userCount'),
      logoThumbnailUrl: _requiredNullableString(
        body,
        'logoThumbnailUrl',
        '$field.logoThumbnailUrl',
      ),
      color: _requiredNullableString(body, 'color', '$field.color'),
    );

typedef _RankingAffiliationBoardFields = ({
  _RankingAffiliationFields affiliation,
  int rank,
  int? globalRank,
  int rating,
  int solvedCount,
});

_RankingAffiliationBoardFields _decodeV4RankingAffiliationBoardFields(
  Map<String, dynamic> body,
  String field,
) =>
    (
      affiliation: _decodeV4RankingAffiliationFields(body, field),
      rank: _integer(body['rank'], '$field.rank'),
      globalRank: _requiredNullableInteger(
        body,
        'globalRank',
        '$field.globalRank',
      ),
      rating: _integer(body['rating'], '$field.rating'),
      solvedCount: _integer(body['solvedCount'], '$field.solvedCount'),
    );

RankingAffiliationBoardResult _decodeV4RankingAffiliationBoard(dynamic json) {
  final body = _object(json, 'ranking affiliation board');
  return RankingAffiliationBoardResult(
    mine: List<RankingAffiliationBoardMineItem>.unmodifiable(
      _list(body['mine'], 'mine').map(
        (value) => _decodeV4RankingAffiliationBoardMineItem(
          _object(value, 'mine[]'),
        ),
      ),
    ),
    total: _integer(body['total'], 'total'),
    page: _integer(body['page'], 'page'),
    pageSize: _integer(body['pageSize'], 'pageSize'),
    items: List<RankingAffiliationBoardItem>.unmodifiable(
      _list(body['items'], 'items').map(
        (value) => _decodeV4RankingAffiliationBoardItem(
          _object(value, 'items[]'),
        ),
      ),
    ),
  );
}

RankingAffiliationBoardItem _decodeV4RankingAffiliationBoardItem(
  Map<String, dynamic> body,
) {
  final fields = _decodeV4RankingAffiliationBoardFields(body, 'items[]');
  final affiliation = fields.affiliation;
  return RankingAffiliationBoardItem(
    id: affiliation.id,
    affiliationId: affiliation.affiliationId,
    name: affiliation.name,
    type: affiliation.type,
    logoThumbnailUrl: affiliation.logoThumbnailUrl,
    color: affiliation.color,
    rank: fields.rank,
    globalRank: fields.globalRank,
    rating: fields.rating,
    userCount: affiliation.userCount,
    solvedCount: fields.solvedCount,
  );
}

RankingAffiliationBoardMineItem _decodeV4RankingAffiliationBoardMineItem(
  Map<String, dynamic> body,
) {
  final fields = _decodeV4RankingAffiliationBoardFields(body, 'mine[]');
  final affiliation = fields.affiliation;
  return RankingAffiliationBoardMineItem(
    id: affiliation.id,
    affiliationId: affiliation.affiliationId,
    name: affiliation.name,
    type: affiliation.type,
    logoThumbnailUrl: affiliation.logoThumbnailUrl,
    color: affiliation.color,
    rank: fields.rank,
    globalRank: fields.globalRank,
    rating: fields.rating,
    userCount: affiliation.userCount,
    solvedCount: fields.solvedCount,
    page: _integer(body['page'], 'mine[].page'),
  );
}

RankingTagsResult _decodeV4RankingTags(dynamic json) {
  final body = _object(json, 'ranking tags');
  return RankingTagsResult(
    tags: List<RankingTag>.unmodifiable(
      _list(body['tags'], 'tags').map(
        (value) {
          final tag = _object(value, 'tags[]');
          return RankingTag(
            key: _string(tag['key'], 'tags[].key'),
            ratingTagIndex: _integer(
              tag['ratingTagIndex'],
              'tags[].ratingTagIndex',
            ),
            displayName: _string(
              tag['displayName'],
              'tags[].displayName',
            ),
          );
        },
      ),
    ),
  );
}

RankingLeaderboardResult _decodeV4RankingLeaderboard(dynamic json) {
  final body = _object(json, 'ranking leaderboard');
  if (!body.containsKey('me')) {
    throw const FormatException('Missing required field me');
  }
  final meValue = body['me'];
  return RankingLeaderboardResult(
    me: meValue == null
        ? null
        : _decodeV4RankingLeaderboardUser(
            _object(meValue, 'me'),
            'me',
          ),
    mePage: _requiredNullableInteger(body, 'mePage', 'mePage'),
    total: _integer(body['total'], 'total'),
    page: _integer(body['page'], 'page'),
    pageSize: _integer(body['pageSize'], 'pageSize'),
    items: List<RankingLeaderboardUser>.unmodifiable(
      _list(body['items'], 'items').map(
        (value) => _decodeV4RankingLeaderboardUser(
          _object(value, 'items[]'),
          'items[]',
        ),
      ),
    ),
  );
}

RankingLeaderboardUser _decodeV4RankingLeaderboardUser(
  Map<String, dynamic> body,
  String field,
) =>
    RankingLeaderboardUser(
      id: _number(body['id'], '$field.id'),
      handle: _string(body['handle'], '$field.handle'),
      tier: _requiredNullableTier(body, '$field.tier'),
      profileImageUrl: _requiredNullableString(
        body,
        'profileImageUrl',
        '$field.profileImageUrl',
      ),
      rank: _integer(body['rank'], '$field.rank'),
      rating: _integer(body['rating'], '$field.rating'),
      solvedCount: _integer(body['solvedCount'], '$field.solvedCount'),
      voteCount: _integer(body['voteCount'], '$field.voteCount'),
      reputation: _integer(body['reputation'], '$field.reputation'),
      userClass: _integer(body['class'], '$field.class'),
      classPlus: _boolean(body['classPlus'], '$field.classPlus'),
      tagRating: _requiredNullableInteger(
        body,
        'tagRating',
        '$field.tagRating',
      ),
      globalRank: _requiredNullableInteger(
        body,
        'globalRank',
        '$field.globalRank',
      ),
    );

UserSearchResult _decodeV4UserSearch(dynamic json) {
  final body = _object(json, 'user search');
  if (!body.containsKey('exact')) {
    throw const FormatException('Missing required field exact');
  }
  final exactValue = body['exact'];
  return UserSearchResult(
    exact: exactValue == null
        ? null
        : _decodeV4UserSearchItem(_object(exactValue, 'exact')),
    items: _list(body['items'], 'items')
        .map((item) => _decodeV4UserSearchItem(_object(item, 'items[]')))
        .toList(growable: false),
  );
}

UserSearchItem _decodeV4UserSearchItem(Map<String, dynamic> body) =>
    UserSearchItem(
      id: _number(body['id'], 'user.id'),
      handle: _string(body['handle'], 'user.handle'),
      profileImageUrl: _requiredNullableString(
        body,
        'profileImageUrl',
        'user.profileImageUrl',
      ),
      tier: _requiredNullableTier(body, 'user.tier'),
      rank: _integer(body['rank'], 'user.rank'),
      userClass: _integer(body['class'], 'user.class'),
      classPlus: _boolean(body['classPlus'], 'user.classPlus'),
      rating: _integer(body['rating'], 'user.rating'),
      solvedCount: _integer(body['solvedCount'], 'user.solvedCount'),
      voteCount: _integer(body['voteCount'], 'user.voteCount'),
      reputation: _integer(body['reputation'], 'user.reputation'),
      tagRating: _requiredNullableInteger(body, 'tagRating', 'user.tagRating'),
      globalRank: _requiredNullableInteger(
        body,
        'globalRank',
        'user.globalRank',
      ),
      page: _integer(body['page'], 'user.page'),
    );

SearchObject<TagSearchItem> _decodeV4TagSearch(
  dynamic json, {
  required String query,
  required int page,
}) {
  final body = _object(json, 'tag catalog');
  final normalizedQuery = query.toLowerCase();
  final matches = _list(body['tags'], 'tags')
      .map((item) => _decodeV4CatalogTag(_object(item, 'tags[]')))
      .where((tag) => tag.matches(normalizedQuery))
      .toList(growable: false);
  final start = (page - 1) * SolvedApiV4Contract.tagSearchPageSize;
  final pageItems =
      start >= matches.length
          ? const <TagSearchItem>[]
          : matches
              .skip(start)
              .take(SolvedApiV4Contract.tagSearchPageSize)
              .map(
                (tag) => TagSearchItem(
                  key: tag.key,
                  problemCount: null,
                  displayName: tag.displayName,
                  id: tag.id,
                  isMeta: tag.isMeta,
                  parents: tag.parents,
                  names: tag.names,
                  aliases: tag.aliases,
                  rated: tag.rated,
                ),
              )
              .toList(growable: false);
  return SearchObject(count: matches.length, items: pageItems);
}

_V4CatalogTag _decodeV4CatalogTag(Map<String, dynamic> body) {
  final names = <String, String>{};
  for (final entry in _object(body['names'], 'tags[].names').entries) {
    names[entry.key] = _string(entry.value, 'tags[].names[]');
  }
  final immutableNames = Map<String, String>.unmodifiable(names);
  final parents = List<String>.unmodifiable(
    _list(
      body['parents'],
      'tags[].parents',
    ).map((value) => _string(value, 'tags[].parents[]')),
  );
  final aliases = List<String>.unmodifiable(
    _list(
      body['aliases'],
      'tags[].aliases',
    ).map((value) => _string(value, 'tags[].aliases[]')),
  );
  return _V4CatalogTag(
    id: _number(body['id'], 'tags[].id'),
    key: _string(body['key'], 'tags[].key'),
    isMeta: _boolean(body['isMeta'], 'tags[].isMeta'),
    parents: parents,
    names: immutableNames,
    displayName: _preferredLocalizedName(immutableNames),
    aliases: aliases,
    rated: _boolean(body['rated'], 'tags[].rated'),
  );
}

TagDetailResult _decodeV4TagDetail(dynamic json) {
  final body = _object(json, 'tag detail');
  return TagDetailResult(
    id: _number(body['id'], 'id'),
    key: _string(body['key'], 'key'),
    names: _stringMap(body['names'], 'names'),
    aliases: List<String>.unmodifiable(
      _list(
        body['aliases'],
        'aliases',
      ).map((value) => _string(value, 'aliases[]')),
    ),
    parents: List<TagDetailRelatedTag>.unmodifiable(
      _list(body['parents'], 'parents').map(
        (value) =>
            _decodeV4RelatedTag(_object(value, 'parents[]'), 'parents[]'),
      ),
    ),
    children: List<TagDetailRelatedTag>.unmodifiable(
      _list(body['children'], 'children').map(
        (value) =>
            _decodeV4RelatedTag(_object(value, 'children[]'), 'children[]'),
      ),
    ),
    rated: _boolean(body['rated'], 'rated'),
    problemCount: _integer(body['problemCount'], 'problemCount'),
    solvedCount: _requiredNullableInteger(body, 'solvedCount', 'solvedCount'),
    levels: List<TagDetailLevel>.unmodifiable(
      _list(
        body['levels'],
        'levels',
      ).map((value) => _decodeV4TagLevel(_object(value, 'levels[]'))),
    ),
  );
}

TagDetailRelatedTag _decodeV4RelatedTag(
  Map<String, dynamic> body,
  String field,
) =>
    TagDetailRelatedTag(
      key: _string(body['key'], '$field.key'),
      names: _stringMap(body['names'], '$field.names'),
    );

TagDetailLevel _decodeV4TagLevel(Map<String, dynamic> body) => TagDetailLevel(
      level: _integer(body['level'], 'levels[].level'),
      count: _integer(body['count'], 'levels[].count'),
      solved: _requiredNullableInteger(body, 'solved', 'levels[].solved'),
    );

String? _preferredLocalizedName(Map<String, String> names) {
  for (final language in const ['ko', 'en']) {
    final name = names[language]?.trim();
    if (name != null && name.isNotEmpty) return name;
  }
  final fallbackLanguages = names.keys.toList(growable: false)..sort();
  for (final language in fallbackLanguages) {
    final name = names[language]!.trim();
    if (name.isNotEmpty) return name;
  }
  return null;
}

final class _V4CatalogTag {
  const _V4CatalogTag({
    required this.id,
    required this.key,
    required this.isMeta,
    required this.parents,
    required this.names,
    required this.displayName,
    required this.aliases,
    required this.rated,
  });

  final num id;
  final String key;
  final bool isMeta;
  final List<String> parents;
  final Map<String, String> names;
  final String? displayName;
  final List<String> aliases;
  final bool rated;

  bool matches(String normalizedQuery) => <String>[
    key,
    ...names.values,
    ...aliases,
  ].any((candidate) => candidate.toLowerCase().contains(normalizedQuery));
}

OfficialUserProfile _decodeV4UserProfile(dynamic json) {
  final body = _object(json, 'profile');
  if (!body.containsKey('background')) {
    throw const FormatException('Missing required field background');
  }
  if (!body.containsKey('badge')) {
    throw const FormatException('Missing required field badge');
  }
  final backgroundValue = body['background'];
  final badgeValue = body['badge'];
  final background = backgroundValue == null
      ? null
      : _decodeOfficialUserProfileBackground(
          _object(backgroundValue, 'background'),
        );
  final badge = badgeValue == null
      ? null
      : _decodeOfficialUserProfileBadge(_object(badgeValue, 'badge'));
  final rating = _integer(body['rating'], 'rating');
  final tagRatings = List<ProfileTagRating>.unmodifiable(
    _list(body['tagRatings'], 'tagRatings').map(
      (item) => _decodeV4TagRating(_object(item, 'tagRatings[]')),
    ),
  );
  final ojAccounts = List<OfficialUserProfileOjAccount>.unmodifiable(
    _list(body['ojAccounts'], 'ojAccounts').map(
      (item) => _decodeV4OfficialUserProfileOjAccount(
        _object(item, 'ojAccounts[]'),
      ),
    ),
  );
  final linkedAccounts = List<OfficialUserProfileLinkedAccount>.unmodifiable(
    _list(body['linkedAccounts'], 'linkedAccounts').map(
      (item) => _decodeV4OfficialUserProfileLinkedAccount(
        _object(item, 'linkedAccounts[]'),
      ),
    ),
  );
  final affiliations = List<OfficialUserProfileAffiliation>.unmodifiable(
    _list(body['affiliations'], 'affiliations').map(
      (item) => _decodeV4OfficialUserProfileAffiliation(
        _object(item, 'affiliations[]'),
      ),
    ),
  );
  final bans = List<OfficialUserProfileBan>.unmodifiable(
    _list(body['bans'], 'bans').map(
      (item) => _decodeV4OfficialUserProfileBan(
        _object(item, 'bans[]'),
      ),
    ),
  );
  final metadata = _decodeV4OfficialUserProfileMetadata(
    _object(body['metadata'], 'metadata'),
  );
  if (!body.containsKey('streakVacation')) {
    throw const FormatException('Missing required field streakVacation');
  }
  final streakVacationValue = body['streakVacation'];

  return OfficialUserProfile(
    id: _number(body['id'], 'id'),
    voteCount: _integer(body['voteCount'], 'voteCount'),
    streakVacation: streakVacationValue == null
        ? null
        : _decodeV4OfficialUserProfileStreakVacation(
            _object(streakVacationValue, 'streakVacation'),
          ),
    streakCountedToday:
        _boolean(body['streakCountedToday'], 'streakCountedToday'),
    streakFrozenYesterday:
        _boolean(body['streakFrozenYesterday'], 'streakFrozenYesterday'),
    streakTheme: _requiredNullableString(body, 'streakTheme'),
    isRival: _boolean(body['isRival'], 'isRival'),
    isReverseRival: _boolean(body['isReverseRival'], 'isReverseRival'),
    ojAccounts: ojAccounts,
    linkedAccounts: linkedAccounts,
    affiliations: affiliations,
    bans: bans,
    metadata: metadata,
    handle: _string(body['handle'], 'handle'),
    profileImageUrl: _requiredNullableString(body, 'profileImageUrl'),
    bio: _requiredNullableString(body, 'bio'),
    solvedCount: _integer(body['solvedCount'], 'solvedCount'),
    userClass: _officialUserProfileClass(body['class'], 'class'),
    classPlus: _boolean(body['classPlus'], 'classPlus'),
    tier: _requiredNullableTier(body, 'tier'),
    rating: rating,
    currentStreak: _integer(body['currentStreak'], 'currentStreak'),
    maxStreak: _integer(body['maxStreak'], 'maxStreak'),
    reputation: _integer(body['reputation'], 'reputation'),
    ratingBreakdown: ProfileRatingBreakdown(
      rating: rating,
      ratingByProblemsSum:
          _integer(body['ratingByProblemsSum'], 'ratingByProblemsSum'),
      ratingByClass: _integer(body['ratingByClass'], 'ratingByClass'),
      ratingBySolvedCount:
          _integer(body['ratingBySolvedCount'], 'ratingBySolvedCount'),
      ratingProblemsCutoff:
          _integer(body['ratingProblemsCutoff'], 'ratingProblemsCutoff'),
      ratingProblemsHistogram: List<int>.unmodifiable(
        _list(body['ratingProblemsHistogram'], 'ratingProblemsHistogram').map(
          (value) => _integer(value, 'ratingProblemsHistogram[]'),
        ),
      ),
      noRatingSolvedCount:
          _integer(body['noRatingSolvedCount'], 'noRatingSolvedCount'),
    ),
    background: background,
    badge: badge,
    tagRatings: tagRatings,
  );
}

OfficialUserProfileOjAccount _decodeV4OfficialUserProfileOjAccount(
  Map<String, dynamic> body,
) {
  return OfficialUserProfileOjAccount(
    ojId: _string(body['ojId'], 'ojAccounts[].ojId'),
    ojName: _string(body['ojName'], 'ojAccounts[].ojName'),
    handle: _string(body['handle'], 'ojAccounts[].handle'),
    profileUrl: _requiredNullableString(
      body,
      'profileUrl',
      'ojAccounts[].profileUrl',
    ),
    logoUrl: _requiredNullableString(
      body,
      'logoUrl',
      'ojAccounts[].logoUrl',
    ),
    verified: _boolean(body['verified'], 'ojAccounts[].verified'),
  );
}

OfficialUserProfileLinkedAccount _decodeV4OfficialUserProfileLinkedAccount(
  Map<String, dynamic> body,
) {
  return OfficialUserProfileLinkedAccount(
    provider: _decodeV4OfficialUserProfileLinkedAccountProvider(
      body['provider'],
    ),
    name: _string(body['name'], 'linkedAccounts[].name'),
    url: _string(body['url'], 'linkedAccounts[].url'),
  );
}

OfficialUserProfileLinkedAccountProvider
    _decodeV4OfficialUserProfileLinkedAccountProvider(Object? value) {
  switch (_string(value, 'linkedAccounts[].provider')) {
    case 'discord':
      return OfficialUserProfileLinkedAccountProvider.discord;
    case 'icpc':
      return OfficialUserProfileLinkedAccountProvider.icpc;
    default:
      throw const FormatException('Unknown linkedAccounts[].provider');
  }
}

OfficialUserProfileAffiliation _decodeV4OfficialUserProfileAffiliation(
  Map<String, dynamic> body,
) {
  return OfficialUserProfileAffiliation(
    id: _number(body['id'], 'affiliations[].id'),
    affiliationId: _number(
      body['affiliationId'],
      'affiliations[].affiliationId',
    ),
    name: _string(body['name'], 'affiliations[].name'),
    type: _decodeV4AffiliationType(body['type'], 'affiliations[].type'),
    logoThumbnailUrl: _requiredNullableString(
      body,
      'logoThumbnailUrl',
      'affiliations[].logoThumbnailUrl',
    ),
    color: _requiredNullableString(
      body,
      'color',
      'affiliations[].color',
    ),
  );
}

OfficialUserProfileAffiliationType _decodeV4AffiliationType(
  Object? value,
  String field,
) {
  switch (_string(value, field)) {
    case 'undefined':
      return OfficialUserProfileAffiliationType.undefined;
    case 'university':
      return OfficialUserProfileAffiliationType.university;
    case 'high_school':
      return OfficialUserProfileAffiliationType.highSchool;
    case 'middle_school':
      return OfficialUserProfileAffiliationType.middleSchool;
    case 'elementary_school':
      return OfficialUserProfileAffiliationType.elementarySchool;
    case 'company':
      return OfficialUserProfileAffiliationType.company;
    case 'community':
      return OfficialUserProfileAffiliationType.community;
    default:
      throw FormatException('Unknown $field');
  }
}

OfficialUserProfileBan _decodeV4OfficialUserProfileBan(
  Map<String, dynamic> body,
) {
  return OfficialUserProfileBan(
    banType: _decodeV4OfficialUserProfileBanType(body['banType']),
    banReason: _decodeV4OfficialUserProfileBanReason(body),
    reason: _string(body['reason'], 'bans[].reason'),
    until: _string(body['until'], 'bans[].until'),
  );
}

OfficialUserProfileBanType _decodeV4OfficialUserProfileBanType(Object? value) {
  switch (_string(value, 'bans[].banType')) {
    case 'rating':
      return OfficialUserProfileBanType.rating;
    case 'vote':
      return OfficialUserProfileBanType.vote;
    default:
      throw const FormatException('Unknown bans[].banType');
  }
}

OfficialUserProfileBanReason? _decodeV4OfficialUserProfileBanReason(
  Map<String, dynamic> body,
) {
  if (!body.containsKey('banReason')) {
    throw const FormatException('Missing required field bans[].banReason');
  }
  final value = body['banReason'];
  if (value == null) return null;

  switch (_string(value, 'bans[].banReason')) {
    case 'vote_troll_level':
      return OfficialUserProfileBanReason.voteTrollLevel;
    case 'vote_hate_speech':
      return OfficialUserProfileBanReason.voteHateSpeech;
    case 'vote_disparagement':
      return OfficialUserProfileBanReason.voteDisparagement;
    case 'vote_profanity':
      return OfficialUserProfileBanReason.voteProfanity;
    case 'vote_multi_account':
      return OfficialUserProfileBanReason.voteMultiAccount;
    case 'vote_repeat_offence':
      return OfficialUserProfileBanReason.voteRepeatOffence;
    case 'rating_copied_code':
      return OfficialUserProfileBanReason.ratingCopiedCode;
    case 'other':
      return OfficialUserProfileBanReason.other;
    case 'rating_auto_pace':
      return OfficialUserProfileBanReason.ratingAutoPace;
    case 'vote_automated':
      return OfficialUserProfileBanReason.voteAutomated;
    case 'vote_comment_strikes':
      return OfficialUserProfileBanReason.voteCommentStrikes;
    case 'vote_mark_abuse':
      return OfficialUserProfileBanReason.voteMarkAbuse;
    default:
      throw const FormatException('Unknown bans[].banReason');
  }
}

OfficialUserProfileMetadata _decodeV4OfficialUserProfileMetadata(
  Map<String, dynamic> body,
) {
  if (!body.containsKey('birthday')) {
    throw const FormatException('Missing required field metadata.birthday');
  }
  final birthdayValue = body['birthday'];

  return OfficialUserProfileMetadata(
    countryCode: _requiredNullableString(
      body,
      'countryCode',
      'metadata.countryCode',
    ),
    pronouns: _requiredNullableString(
      body,
      'pronouns',
      'metadata.pronouns',
    ),
    name: _requiredNullableString(body, 'name', 'metadata.name'),
    nameNative: _requiredNullableString(
      body,
      'nameNative',
      'metadata.nameNative',
    ),
    birthday: birthdayValue == null
        ? null
        : _decodeV4OfficialUserProfileBirthday(
            _object(birthdayValue, 'metadata.birthday'),
          ),
  );
}

OfficialUserProfileBirthday _decodeV4OfficialUserProfileBirthday(
  Map<String, dynamic> body,
) {
  return OfficialUserProfileBirthday(
    year: _requiredNullableInteger(
      body,
      'year',
      'metadata.birthday.year',
    ),
    month: _requiredNullableInteger(
      body,
      'month',
      'metadata.birthday.month',
    ),
    day: _requiredNullableInteger(
      body,
      'day',
      'metadata.birthday.day',
    ),
  );
}

OfficialUserProfileStreakVacation _decodeV4OfficialUserProfileStreakVacation(
  Map<String, dynamic> body,
) {
  return OfficialUserProfileStreakVacation(
    fromDay: _string(body['fromDay'], 'streakVacation.fromDay'),
    source: _decodeV4OfficialUserProfileStreakVacationSource(body['source']),
  );
}

OfficialUserProfileStreakVacationSource
    _decodeV4OfficialUserProfileStreakVacationSource(Object? value) {
  switch (_string(value, 'streakVacation.source')) {
    case 'item':
      return OfficialUserProfileStreakVacationSource.item;
    case 'launch':
      return OfficialUserProfileStreakVacationSource.launch;
    default:
      throw const FormatException('Unsupported streakVacation.source');
  }
}

ProfileActivityResult _decodeV4ProfileActivity(dynamic json) {
  final body = _object(json, 'activity');
  final days = List<ProfileSolvedDay>.unmodifiable(
    _list(body['days'], 'days').map((item) {
      final day = _object(item, 'days[]');
      final date = _profileActivityDay(
        _string(day['day'], 'days[].day'),
        'days[].day',
      );
      return ProfileSolvedDay(
        year: date.year,
        month: date.month,
        day: date.day,
        solvedCount: _nonNegativeInteger(
          day['solvedCount'],
          'days[].solvedCount',
        ),
        maxSolvedLevel: _profileActivityMaxSolvedLevel(
          day['maxSolvedLevel'],
          'days[].maxSolvedLevel',
        ),
        ratingDelta: _integer(day['ratingDelta'], 'days[].ratingDelta'),
        freezeUsed: _boolean(day['freezeUsed'], 'days[].freezeUsed'),
        streakRepaired: _boolean(
          day['streakRepaired'],
          'days[].streakRepaired',
        ),
      );
    }),
  );
  if (!body.containsKey('vacation')) {
    throw const FormatException('Missing required field vacation');
  }
  final vacationValue = body['vacation'];
  final vacations = List<ProfileActivityVacation>.unmodifiable(
    _list(body['vacations'], 'vacations').map(
      (value) => _decodeV4ProfileActivityVacation(
        _object(value, 'vacations[]'),
      ),
    ),
  );
  return ProfileActivityResult(
    from: _string(body['from'], 'from'),
    to: _string(body['to'], 'to'),
    days: days,
    maxSolvedCount: _nonNegativeInteger(
      body['maxSolvedCount'],
      'maxSolvedCount',
    ),
    currentStreak: _nonNegativeInteger(
      body['currentStreak'],
      'currentStreak',
    ),
    maxStreak: _nonNegativeInteger(body['maxStreak'], 'maxStreak'),
    theme: _requiredNullableString(body, 'theme'),
    firstActiveDay: _requiredNullableString(body, 'firstActiveDay'),
    vacation: vacationValue == null
        ? null
        : _decodeV4ProfileActivityCurrentVacation(
            _object(vacationValue, 'vacation'),
          ),
    vacations: vacations,
    countedToday: _boolean(body['countedToday'], 'countedToday'),
    frozenYesterday: _boolean(body['frozenYesterday'], 'frozenYesterday'),
  );
}

ProfileActivityFeedResult _decodeV4ProfileActivityFeed(dynamic json) {
  final body = _object(json, 'activity feed');
  final events = List<ProfileActivityFeedEvent>.unmodifiable(
    _list(body['events'], 'events').map(
      (value) => _decodeV4ProfileActivityFeedEvent(
        _object(value, 'events[]'),
      ),
    ),
  );
  return ProfileActivityFeedResult(
    events: events,
    nextCursor: _requiredNullableString(body, 'nextCursor'),
  );
}

ProfileActivityFeedEvent _decodeV4ProfileActivityFeedEvent(
  Map<String, dynamic> body,
) {
  if (!body.containsKey('problem')) {
    throw const FormatException('Missing required field events[].problem');
  }
  final problemValue = body['problem'];
  final hasPayload = body.containsKey('payload');
  return ProfileActivityFeedEvent(
    id: _integer(body['id'], 'events[].id'),
    type: _decodeV4ProfileActivityFeedEventType(body['type']),
    occurredAt: _string(body['occurredAt'], 'events[].occurredAt'),
    problem: problemValue == null
        ? null
        : _decodeV4ProfileActivityFeedProblem(
            _object(problemValue, 'events[].problem'),
          ),
    reason: _requiredNullableString(body, 'reason', 'events[].reason'),
    milestone: _requiredNullableInteger(
      body,
      'milestone',
      'events[].milestone',
    ),
    hasPayload: hasPayload,
    payload: hasPayload
        ? _immutableJsonValue(body['payload'], 'events[].payload')
        : null,
  );
}

ProfileActivityFeedEventType _decodeV4ProfileActivityFeedEventType(
  Object? value,
) {
  final code = _string(value, 'events[].type');
  return switch (code) {
    'solved' => ProfileActivityFeedEventType.solved,
    'unsolved' => ProfileActivityFeedEventType.unsolved,
    'vote' => ProfileActivityFeedEventType.vote,
    'rating' => ProfileActivityFeedEventType.rating,
    'tier' => ProfileActivityFeedEventType.tier,
    'solvedMilestone' => ProfileActivityFeedEventType.solvedMilestone,
    'voteMilestone' => ProfileActivityFeedEventType.voteMilestone,
    _ => throw const FormatException('Unsupported events[].type'),
  };
}

ProfileReputationLogResult _decodeV4ProfileReputationLog(dynamic json) {
  final body = _object(json, 'reputation log');
  final firstDayValue = _requiredValue(body, 'firstDay', 'firstDay');
  return ProfileReputationLogResult(
    days: List<ProfileReputationLogDay>.unmodifiable(
      _list(body['days'], 'days').map(
        (value) => _decodeV4ProfileReputationLogDay(_object(value, 'days[]')),
      ),
    ),
    firstDay: firstDayValue == null
        ? null
        : _profileHistoryDay(firstDayValue, 'firstDay'),
  );
}

ProfileReputationLogDay _decodeV4ProfileReputationLogDay(
  Map<String, dynamic> body,
) {
  final othersValue = _requiredValue(body, 'others', 'days[].others');
  final others =
      othersValue == null ? null : _object(othersValue, 'days[].others');
  return ProfileReputationLogDay(
    day: _profileHistoryDay(body['day'], 'days[].day'),
    change: _integer(body['change'], 'days[].change'),
    after: _integer(body['after'], 'days[].after'),
    capped: _integer(body['capped'], 'days[].capped'),
    items: List<ProfileReputationLogItem>.unmodifiable(
      _list(body['items'], 'days[].items').map(
        (value) => _decodeV4ProfileReputationLogItem(
          _object(value, 'days[].items[]'),
        ),
      ),
    ),
    others: others == null
        ? null
        : ProfileReputationLogOthers(
            count: _integer(others['count'], 'days[].others.count'),
            points: _integer(others['points'], 'days[].others.points'),
          ),
  );
}

ProfileReputationLogItem _decodeV4ProfileReputationLogItem(
  Map<String, dynamic> body,
) {
  final problemValue =
      _requiredValue(body, 'problem', 'days[].items[].problem');
  return ProfileReputationLogItem(
    kind: switch (_string(body['kind'], 'days[].items[].kind')) {
      'contribution' => ProfileReputationLogKind.contribution,
      'helpful' => ProfileReputationLogKind.helpful,
      'unhelpful' => ProfileReputationLogKind.unhelpful,
      'markedUnhelpful' => ProfileReputationLogKind.markedUnhelpful,
      'takedown' => ProfileReputationLogKind.takedown,
      _ => throw const FormatException('Unsupported days[].items[].kind'),
    },
    problem: problemValue == null
        ? null
        : _decodeV4ProfileActivityFeedProblem(
            _object(problemValue, 'days[].items[].problem'),
          ),
    count: _integer(body['count'], 'days[].items[].count'),
    points: _integer(body['points'], 'days[].items[].points'),
  );
}

ProfileActivityFeedProblem _decodeV4ProfileActivityFeedProblem(
  Map<String, dynamic> body,
) {
  if (!body.containsKey('userStatus')) {
    throw const FormatException(
      'Missing required field events[].problem.userStatus',
    );
  }
  final userStatusValue = body['userStatus'];
  return ProfileActivityFeedProblem(
    problemId: _integer(body['problemId'], 'events[].problem.problemId'),
    subId: _string(body['subId'], 'events[].problem.subId'),
    level: _activityFeedProblemLevel(
      body['level'],
      'events[].problem.level',
    ),
    effectiveVoteCount: _nonNegativeInteger(
      body['effectiveVoteCount'],
      'events[].problem.effectiveVoteCount',
    ),
    givesNoRating: _boolean(
      body['givesNoRating'],
      'events[].problem.givesNoRating',
    ),
    isStandard: _boolean(
      body['isStandard'],
      'events[].problem.isStandard',
    ),
    titles: List<ProblemSearchTitle>.unmodifiable(
      _list(body['titles'], 'events[].problem.titles').map(
        (value) => _decodeV4ProblemSearchTitle(
          _object(value, 'events[].problem.titles[]'),
          'events[].problem.titles[]',
        ),
      ),
    ),
    userStatus: userStatusValue == null
        ? null
        : _decodeV4ProblemUserStatus(
            userStatusValue,
            'events[].problem.userStatus',
          ),
  );
}

ProfileActivityCurrentVacation _decodeV4ProfileActivityCurrentVacation(
  Map<String, dynamic> body,
) =>
    ProfileActivityCurrentVacation(
      fromDay: _string(body['fromDay'], 'vacation.fromDay'),
      source: _decodeV4ProfileActivityVacationSource(body['source']),
    );

ProfileActivityVacation _decodeV4ProfileActivityVacation(
  Map<String, dynamic> body,
) =>
    ProfileActivityVacation(
      fromDay: _string(body['fromDay'], 'vacations[].fromDay'),
      untilDay: _requiredNullableString(
        body,
        'untilDay',
        'vacations[].untilDay',
      ),
    );

ProfileActivityVacationSource _decodeV4ProfileActivityVacationSource(
  Object? value,
) {
  switch (_string(value, 'vacation.source')) {
    case 'item':
      return ProfileActivityVacationSource.item;
    case 'launch':
      return ProfileActivityVacationSource.launch;
    default:
      throw const FormatException('Unsupported vacation.source');
  }
}

ProfileReputationResult _decodeV4ProfileReputation(dynamic json) {
  final body = _object(json, 'reputation');
  final history = List<ProfileReputationHistoryEntry>.unmodifiable(
    _list(body['history'], 'history').map(
      (item) => _decodeV4ProfileReputationHistoryEntry(
        _object(item, 'history[]'),
      ),
    ),
  );
  return ProfileReputationResult(
    reputation: _integer(body['reputation'], 'reputation'),
    scoringCount: _integer(body['scoringCount'], 'scoringCount'),
    helpfulCount: _integer(body['helpfulCount'], 'helpfulCount'),
    vouchedCount: _integer(body['vouchedCount'], 'vouchedCount'),
    history: history,
    today: _decodeV4ProfileReputationToday(_object(body['today'], 'today')),
  );
}

ProfileReputationHistoryEntry _decodeV4ProfileReputationHistoryEntry(
  Map<String, dynamic> body,
) =>
    ProfileReputationHistoryEntry(
      day: _profileHistoryDay(body['day'], 'history[].day'),
      value: _integer(body['value'], 'history[].value'),
    );

ProfileReputationToday _decodeV4ProfileReputationToday(
  Map<String, dynamic> body,
) =>
    ProfileReputationToday(
      contributions: _decodeV4ProfileReputationTodayContributions(
        _object(body['contributions'], 'today.contributions'),
      ),
      helpful: _decodeV4ProfileReputationTodayHelpful(
        _object(body['helpful'], 'today.helpful'),
      ),
    );

ProfileReputationTodayContributions
    _decodeV4ProfileReputationTodayContributions(
  Map<String, dynamic> body,
) =>
        ProfileReputationTodayContributions(
          count: _integer(body['count'], 'today.contributions.count'),
          max: _integer(body['max'], 'today.contributions.max'),
        );

ProfileReputationTodayHelpful _decodeV4ProfileReputationTodayHelpful(
  Map<String, dynamic> body,
) =>
    ProfileReputationTodayHelpful(
      earned: _integer(body['earned'], 'today.helpful.earned'),
      cap: _integer(body['cap'], 'today.helpful.cap'),
    );

ProfileRatingHistoryResult _decodeV4ProfileRatingHistory(dynamic json) {
  final body = _object(json, 'rating history');
  final history = List<ProfileRatingHistoryEntry>.unmodifiable(
    _list(body['history'], 'history').map(
      (item) => _decodeV4ProfileRatingHistoryEntry(
        _object(item, 'history[]'),
      ),
    ),
  );
  return ProfileRatingHistoryResult(history: history);
}

ProfileRatingHistoryEntry _decodeV4ProfileRatingHistoryEntry(
  Map<String, dynamic> body,
) =>
    ProfileRatingHistoryEntry(
      day: _profileHistoryDay(body['day'], 'history[].day'),
      value: _integer(body['value'], 'history[].value'),
    );

ProfileTagLevelHistogramResult _decodeV4ProfileTagLevelHistogram(dynamic json) {
  final body = _object(json, 'tag level histogram');
  final histogram = List<int>.unmodifiable(
    _list(body['histogram'], 'histogram').map(
      (value) => _integer(value, 'histogram[]'),
    ),
  );
  return ProfileTagLevelHistogramResult(
    key: _string(body['key'], 'key'),
    histogram: histogram,
  );
}

AchievementCatalogResult _decodeV4AchievementCatalog(dynamic json) {
  final body = _object(json, 'achievement catalog');
  return AchievementCatalogResult(
    items: List<AchievementCatalogItem>.unmodifiable(
      _list(body['items'], 'items').map(
        (value) => _decodeV4AchievementCatalogItem(
          _object(value, 'items[]'),
        ),
      ),
    ),
    userCount: _nonNegativeInteger(body['userCount'], 'userCount'),
  );
}

AchievementCatalogItem _decodeV4AchievementCatalogItem(
  Map<String, dynamic> body,
) {
  final fields = _decodeV4AchievementItemFields(body);
  return AchievementCatalogItem(
    id: fields.id,
    key: fields.key,
    series: fields.series,
    seriesOrder: fields.seriesOrder,
    historic: fields.historic,
    hidden: fields.hidden,
    name: fields.name,
    condition: fields.condition,
    searchQuery: fields.searchQuery,
    shopKey: fields.shopKey,
    rewards: fields.rewards,
    holderCount: fields.holderCount,
    earnedAt: fields.earnedAt,
    progress: fields.progress,
  );
}

typedef _AchievementItemFields = ({
  int id,
  String key,
  String series,
  int seriesOrder,
  bool historic,
  bool hidden,
  String name,
  String? condition,
  String? searchQuery,
  String? shopKey,
  List<AchievementReward> rewards,
  int holderCount,
  String? earnedAt,
  AchievementProgress? progress,
});

_AchievementItemFields _decodeV4AchievementItemFields(
  Map<String, dynamic> body,
) {
  if (!body.containsKey('progress')) {
    throw const FormatException('Missing required field items[].progress');
  }
  final progressValue = body['progress'];
  final rewards = List<AchievementReward>.unmodifiable(
    _list(body['rewards'], 'items[].rewards').map(
      (value) => _decodeV4AchievementReward(
        _object(value, 'items[].rewards[]'),
        'items[].rewards[]',
      ),
    ),
  );
  return (
    id: _integer(body['id'], 'items[].id'),
    key: _string(body['key'], 'items[].key'),
    series: _string(body['series'], 'items[].series'),
    seriesOrder: _integer(body['seriesOrder'], 'items[].seriesOrder'),
    historic: _boolean(body['historic'], 'items[].historic'),
    hidden: _boolean(body['hidden'], 'items[].hidden'),
    name: _string(body['name'], 'items[].name'),
    condition: _requiredNullableString(
      body,
      'condition',
      'items[].condition',
    ),
    searchQuery: _requiredNullableString(
      body,
      'searchQuery',
      'items[].searchQuery',
    ),
    shopKey: _requiredNullableString(
      body,
      'shopKey',
      'items[].shopKey',
    ),
    rewards: rewards,
    holderCount: _integer(body['holderCount'], 'items[].holderCount'),
    earnedAt: _requiredNullableString(
      body,
      'earnedAt',
      'items[].earnedAt',
    ),
    progress: progressValue == null
        ? null
        : _decodeV4AchievementProgress(
            _object(progressValue, 'items[].progress'),
          ),
  );
}

AchievementProgress _decodeV4AchievementProgress(
  Map<String, dynamic> body,
) =>
    AchievementProgress(
      current: _integer(body['current'], 'items[].progress.current'),
      target: _integer(body['target'], 'items[].progress.target'),
    );

AchievementReward _decodeV4AchievementReward(
  Map<String, dynamic> body,
  String field,
) =>
    AchievementReward(
      kind: _decodeV4AchievementItemKind(body['kind'], '$field.kind'),
      id: _integer(body['id'], '$field.id'),
      key: _string(body['key'], '$field.key'),
      name: _string(body['name'], '$field.name'),
      imageUrl: _string(body['imageUrl'], '$field.imageUrl'),
      category: _string(body['category'], '$field.category'),
      addedAt: _string(body['addedAt'], '$field.addedAt'),
    );

ProfileAchievementsResult _decodeV4ProfileAchievements(dynamic json) {
  final body = _object(json, 'profile achievements');
  return ProfileAchievementsResult(
    handle: _string(body['handle'], 'handle'),
    vsHandle: _requiredNullableString(body, 'vsHandle', 'vsHandle'),
    items: List<ProfileAchievementItem>.unmodifiable(
      _list(body['items'], 'items').map(
        (value) => _decodeV4ProfileAchievementItem(
          _object(value, 'items[]'),
        ),
      ),
    ),
    userCount: _nonNegativeInteger(body['userCount'], 'userCount'),
  );
}

ProfileAchievementItem _decodeV4ProfileAchievementItem(
  Map<String, dynamic> body,
) {
  if (!body.containsKey('vs')) {
    throw const FormatException('Missing required field items[].vs');
  }
  final vsValue = body['vs'];
  final fields = _decodeV4AchievementItemFields(body);
  return ProfileAchievementItem(
    id: fields.id,
    key: fields.key,
    series: fields.series,
    seriesOrder: fields.seriesOrder,
    historic: fields.historic,
    hidden: fields.hidden,
    name: fields.name,
    condition: fields.condition,
    searchQuery: fields.searchQuery,
    shopKey: fields.shopKey,
    rewards: fields.rewards,
    holderCount: fields.holderCount,
    earnedAt: fields.earnedAt,
    progress: fields.progress,
    vs: vsValue == null
        ? null
        : _decodeV4ProfileAchievementVs(
            _object(vsValue, 'items[].vs'),
          ),
  );
}

ProfileAchievementVs _decodeV4ProfileAchievementVs(
  Map<String, dynamic> body,
) =>
    ProfileAchievementVs(
      earnedAt: _requiredNullableString(
        body,
        'earnedAt',
        'items[].vs.earnedAt',
      ),
    );

ProblemAchievementsResult _decodeV4ProblemAchievements(dynamic json) {
  final body = _object(json, 'problem achievements');
  return ProblemAchievementsResult(
    items: List<ProblemAchievementItem>.unmodifiable(
      _list(body['items'], 'items').map(
        (value) => _decodeV4ProblemAchievementItem(
          _object(value, 'items[]'),
        ),
      ),
    ),
  );
}

ProblemAchievementItem _decodeV4ProblemAchievementItem(
  Map<String, dynamic> body,
) {
  final rewards = List<AchievementReward>.unmodifiable(
    _list(body['rewards'], 'items[].rewards').map(
      (value) => _decodeV4AchievementReward(
        _object(value, 'items[].rewards[]'),
        'items[].rewards[]',
      ),
    ),
  );
  return ProblemAchievementItem(
    key: _string(body['key'], 'items[].key'),
    name: _string(body['name'], 'items[].name'),
    condition: _requiredNullableString(
      body,
      'condition',
      'items[].condition',
    ),
    rewards: rewards,
    holderCount: _integer(body['holderCount'], 'items[].holderCount'),
    earnedAt: _requiredNullableString(
      body,
      'earnedAt',
      'items[].earnedAt',
    ),
    relation: _decodeV4ProblemAchievementRelation(
      body['relation'],
      'items[].relation',
    ),
    byLevel: _boolean(body['byLevel'], 'items[].byLevel'),
  );
}

ProblemAchievementRelation _decodeV4ProblemAchievementRelation(
  dynamic value,
  String field,
) {
  final relation = _string(value, field);
  return switch (relation) {
    'unlocks' => ProblemAchievementRelation.unlocks,
    'counts' => ProblemAchievementRelation.counts,
    _ => throw FormatException('Invalid $field'),
  };
}

AchievementHoldersResult _decodeV4AchievementHolders(dynamic json) {
  final body = _object(json, 'achievement holders');
  return AchievementHoldersResult(
    unlockedByDefault: _boolean(
      body['unlockedByDefault'],
      'unlockedByDefault',
    ),
    total: _integer(body['total'], 'total'),
    items: List<AchievementHolderItem>.unmodifiable(
      _list(body['items'], 'items').map(
        (value) => _decodeV4AchievementHolderItem(
          _object(value, 'items[]'),
        ),
      ),
    ),
  );
}

AchievementHolderItem _decodeV4AchievementHolderItem(
  Map<String, dynamic> body,
) =>
    AchievementHolderItem(
      user: _decodeV4AchievementHolderUser(
        _object(body['user'], 'items[].user'),
      ),
      acquiredAt: _string(body['acquiredAt'], 'items[].acquiredAt'),
    );

AchievementHolderUser _decodeV4AchievementHolderUser(
  Map<String, dynamic> body,
) =>
    AchievementHolderUser(
      id: _number(body['id'], 'items[].user.id'),
      handle: _string(body['handle'], 'items[].user.handle'),
      tier: _requiredNullableTier(body, 'items[].user.tier'),
      profileImageUrl: _requiredNullableString(
        body,
        'profileImageUrl',
        'items[].user.profileImageUrl',
      ),
    );

ProfileAchievementSummaryResult _decodeV4ProfileAchievementSummary(
  dynamic json,
) {
  final body = _object(json, 'achievement summary');
  final recent = List<ProfileAchievementSummaryRecentItem>.unmodifiable(
    _list(body['recent'], 'recent').map(
      (item) => _decodeV4ProfileAchievementSummaryRecentItem(
        _object(item, 'recent[]'),
      ),
    ),
  );
  return ProfileAchievementSummaryResult(
    earned: _integer(body['earned'], 'earned'),
    total: _integer(body['total'], 'total'),
    past: _integer(body['past'], 'past'),
    badges: _integer(body['badges'], 'badges'),
    backgrounds: _integer(body['backgrounds'], 'backgrounds'),
    recent: recent,
  );
}

ProfileAchievementSummaryRecentItem
    _decodeV4ProfileAchievementSummaryRecentItem(
  Map<String, dynamic> body,
) =>
        ProfileAchievementSummaryRecentItem(
          kind: _decodeV4AchievementItemKind(body['kind'], 'recent[].kind'),
          id: _integer(body['id'], 'recent[].id'),
          key: _string(body['key'], 'recent[].key'),
          name: _string(body['name'], 'recent[].name'),
          imageUrl: _string(body['imageUrl'], 'recent[].imageUrl'),
          category: _string(body['category'], 'recent[].category'),
          addedAt: _string(body['addedAt'], 'recent[].addedAt'),
          acquiredAt: _string(body['acquiredAt'], 'recent[].acquiredAt'),
        );

ProfileBadgeStandResult _decodeV4ProfileBadgeStand(dynamic json) {
  final body = _object(json, 'badge stand');
  final badges = List<ProfileBadgeStandItem>.unmodifiable(
    _list(body['badges'], 'badges').map(
      (item) => _decodeV4ProfileBadgeStandItem(
        _object(item, 'badges[]'),
      ),
    ),
  );
  return ProfileBadgeStandResult(
    chosen: _boolean(body['chosen'], 'chosen'),
    badges: badges,
  );
}

ProfileBadgeStandItem _decodeV4ProfileBadgeStandItem(
  Map<String, dynamic> body,
) =>
    ProfileBadgeStandItem(
      kind: _decodeV4AchievementItemKind(body['kind'], 'badges[].kind'),
      id: _integer(body['id'], 'badges[].id'),
      key: _string(body['key'], 'badges[].key'),
      name: _string(body['name'], 'badges[].name'),
      imageUrl: _string(body['imageUrl'], 'badges[].imageUrl'),
      category: _string(body['category'], 'badges[].category'),
      addedAt: _string(body['addedAt'], 'badges[].addedAt'),
      holderCount: _integer(body['holderCount'], 'badges[].holderCount'),
    );

ProfileBackgroundAsset? _decodeV4BackgroundAsset(dynamic json) {
  final item = _decodeV4AchievementItem(
    json,
    OfficialAchievementItemKind.background,
  );
  final background = item.background;
  if (background == null) return null;
  return ProfileBackgroundAsset(
    key: item.key,
    imageUrl: background.imageUrl,
    fallbackImageUrl: background.fallbackImageUrl,
  );
}

ProfileBadgeAsset _decodeV4BadgeAsset(dynamic json) {
  final item = _decodeV4AchievementItem(
    json,
    OfficialAchievementItemKind.badge,
  );
  return ProfileBadgeAsset(
    key: item.key,
    name: item.name,
    imageUrl: item.imageUrl,
  );
}

OfficialAchievementItem _decodeV4AchievementItem(
  dynamic json,
  OfficialAchievementItemKind expectedKind,
) {
  final body = _object(json, 'achievement item');
  final kind = _decodeV4AchievementItemKind(body['kind']);
  if (kind != expectedKind) {
    throw FormatException('Expected a ${expectedKind.value} item');
  }
  if (!body.containsKey('background')) {
    throw const FormatException('Missing required field background');
  }
  final backgroundValue = body['background'];
  final credits = List<OfficialAchievementItemCredit>.unmodifiable(
    _list(body['credits'], 'credits').map(
      (value) => _decodeV4AchievementItemCredit(
        _object(value, 'credits[]'),
        'credits[]',
      ),
    ),
  );
  final achievements = List<OfficialAchievementItemAchievement>.unmodifiable(
    _list(body['achievements'], 'achievements').map(
      (value) => _decodeV4AchievementItemAchievement(
        _object(value, 'achievements[]'),
      ),
    ),
  );

  return OfficialAchievementItem(
    kind: kind,
    id: _integer(body['id'], 'id'),
    key: _string(body['key'], 'key'),
    name: _string(body['name'], 'name'),
    imageUrl: _string(body['imageUrl'], 'imageUrl'),
    category: _string(body['category'], 'category'),
    addedAt: _string(body['addedAt'], 'addedAt'),
    unlockedByDefault: _boolean(body['unlockedByDefault'], 'unlockedByDefault'),
    owned: _requiredNullableBoolean(body, 'owned'),
    equipped: _requiredNullableBoolean(body, 'equipped'),
    background: backgroundValue == null
        ? null
        : _decodeV4AchievementItemBackground(
            _object(backgroundValue, 'background'),
          ),
    credits: credits,
    userCount: _nonNegativeInteger(body['userCount'], 'userCount'),
    achievements: achievements,
  );
}

OfficialAchievementItemKind _decodeV4AchievementItemKind(
  Object? value, [
  String field = 'kind',
]) {
  switch (_string(value, field)) {
    case 'badge':
      return OfficialAchievementItemKind.badge;
    case 'background':
      return OfficialAchievementItemKind.background;
    default:
      throw const FormatException('Unknown achievement item kind');
  }
}

OfficialAchievementItemBackground _decodeV4AchievementItemBackground(
  Map<String, dynamic> body,
) {
  final authors = List<OfficialAchievementItemBackgroundAuthor>.unmodifiable(
    _list(body['authors'], 'background.authors').map(
      (value) => _decodeV4AchievementItemBackgroundAuthor(
        _object(value, 'background.authors[]'),
      ),
    ),
  );
  return OfficialAchievementItemBackground(
    key: _string(body['key'], 'background.key'),
    imageUrl: _string(
      body['backgroundImageUrl'],
      'background.backgroundImageUrl',
    ),
    fallbackImageUrl: _requiredNullableString(
      body,
      'fallbackBackgroundImageUrl',
      'background.fallbackBackgroundImageUrl',
    ),
    backgroundVideoUrl: _requiredNullableString(
      body,
      'backgroundVideoUrl',
      'background.backgroundVideoUrl',
    ),
    thumbnailPlaceholder: _requiredNullableString(
      body,
      'thumbnailPlaceholder',
      'background.thumbnailPlaceholder',
    ),
    isIllust: _boolean(body['isIllust'], 'background.isIllust'),
    displayName: _requiredNullableString(
      body,
      'displayName',
      'background.displayName',
    ),
    authors: authors,
  );
}

OfficialAchievementItemBackgroundAuthor
    _decodeV4AchievementItemBackgroundAuthor(
  Map<String, dynamic> body,
) =>
        OfficialAchievementItemBackgroundAuthor(
          key: _string(body['key'], 'background.authors[].key'),
          displayName: _requiredNullableString(
            body,
            'displayName',
            'background.authors[].displayName',
          ),
          role: _string(body['role'], 'background.authors[].role'),
          authorUrl: _requiredNullableString(
            body,
            'authorUrl',
            'background.authors[].authorUrl',
          ),
          handle: _requiredNullableString(
            body,
            'handle',
            'background.authors[].handle',
          ),
          twitter: _requiredNullableString(
            body,
            'twitter',
            'background.authors[].twitter',
          ),
          instagram: _requiredNullableString(
            body,
            'instagram',
            'background.authors[].instagram',
          ),
        );

OfficialAchievementItemCredit _decodeV4AchievementItemCredit(
  Map<String, dynamic> body,
  String field,
) =>
    OfficialAchievementItemCredit(
      key: _string(body['key'], '$field.key'),
      displayName: _requiredNullableString(
        body,
        'displayName',
        '$field.displayName',
      ),
      role: _string(body['role'], '$field.role'),
      authorUrl: _requiredNullableString(
        body,
        'authorUrl',
        '$field.authorUrl',
      ),
      handle: _requiredNullableString(body, 'handle', '$field.handle'),
      twitter: _requiredNullableString(body, 'twitter', '$field.twitter'),
      instagram: _requiredNullableString(
        body,
        'instagram',
        '$field.instagram',
      ),
    );

OfficialAchievementItemAchievement _decodeV4AchievementItemAchievement(
  Map<String, dynamic> body,
) {
  final problems = List<OfficialAchievementItemProblem>.unmodifiable(
    _list(body['problems'], 'achievements[].problems').map(
      (value) => _decodeV4AchievementItemProblem(
        _object(value, 'achievements[].problems[]'),
      ),
    ),
  );
  return OfficialAchievementItemAchievement(
    key: _string(body['key'], 'achievements[].key'),
    name: _string(body['name'], 'achievements[].name'),
    condition: _requiredNullableString(
      body,
      'condition',
      'achievements[].condition',
    ),
    historic: _boolean(body['historic'], 'achievements[].historic'),
    hidden: _boolean(body['hidden'], 'achievements[].hidden'),
    holderCount: _integer(body['holderCount'], 'achievements[].holderCount'),
    earnedAt: _requiredNullableString(
      body,
      'earnedAt',
      'achievements[].earnedAt',
    ),
    problems: problems,
  );
}

OfficialAchievementItemProblem _decodeV4AchievementItemProblem(
  Map<String, dynamic> body,
) {
  final titles = List<OfficialAchievementItemProblemTitle>.unmodifiable(
    _list(body['titles'], 'achievements[].problems[].titles').map(
      (value) => _decodeV4AchievementItemProblemTitle(
        _object(value, 'achievements[].problems[].titles[]'),
      ),
    ),
  );
  if (!body.containsKey('userStatus')) {
    throw const FormatException(
      'Missing required field achievements[].problems[].userStatus',
    );
  }
  final userStatusValue = body['userStatus'];
  return OfficialAchievementItemProblem(
    problemId: _number(
      body['problemId'],
      'achievements[].problems[].problemId',
    ),
    level: _number(body['level'], 'achievements[].problems[].level'),
    effectiveVoteCount: _number(
      body['effectiveVoteCount'],
      'achievements[].problems[].effectiveVoteCount',
    ),
    givesNoRating: _boolean(
      body['givesNoRating'],
      'achievements[].problems[].givesNoRating',
    ),
    isStandard: _boolean(
      body['isStandard'],
      'achievements[].problems[].isStandard',
    ),
    titles: titles,
    userStatus: userStatusValue == null
        ? null
        : _decodeV4ProblemUserStatus(
            userStatusValue,
            'achievements[].problems[].userStatus',
          ),
  );
}

OfficialAchievementItemProblemTitle _decodeV4AchievementItemProblemTitle(
  Map<String, dynamic> body,
) =>
    OfficialAchievementItemProblemTitle(
      language: _string(
        body['language'],
        'achievements[].problems[].titles[].language',
      ),
      title: _string(
        body['title'],
        'achievements[].problems[].titles[].title',
      ),
      isOriginal: _boolean(
        body['isOriginal'],
        'achievements[].problems[].titles[].isOriginal',
      ),
      latex: _boolean(
        body['latex'],
        'achievements[].problems[].titles[].latex',
      ),
      html: _boolean(
        body['html'],
        'achievements[].problems[].titles[].html',
      ),
    );

OfficialUserProfileBackground _decodeOfficialUserProfileBackground(
  Map<String, dynamic> background,
) {
  final authors = List<OfficialUserProfileBackgroundAuthor>.unmodifiable(
    _list(background['authors'], 'background.authors').map(
      (value) => _decodeOfficialUserProfileBackgroundAuthor(
        _object(value, 'background.authors[]'),
      ),
    ),
  );
  return OfficialUserProfileBackground(
    key: _string(background['key'], 'background.key'),
    imageUrl: _string(
      background['backgroundImageUrl'],
      'background.backgroundImageUrl',
    ),
    fallbackImageUrl: _requiredNullableString(
      background,
      'fallbackBackgroundImageUrl',
      'background.fallbackBackgroundImageUrl',
    ),
    backgroundVideoUrl: _requiredNullableString(
      background,
      'backgroundVideoUrl',
      'background.backgroundVideoUrl',
    ),
    thumbnailPlaceholder: _requiredNullableString(
      background,
      'thumbnailPlaceholder',
      'background.thumbnailPlaceholder',
    ),
    isIllust: _boolean(background['isIllust'], 'background.isIllust'),
    displayName: _requiredNullableString(
      background,
      'displayName',
      'background.displayName',
    ),
    authors: authors,
  );
}

OfficialUserProfileBackgroundAuthor _decodeOfficialUserProfileBackgroundAuthor(
        Map<String, dynamic> author) =>
    OfficialUserProfileBackgroundAuthor(
      key: _string(author['key'], 'background.authors[].key'),
      displayName: _requiredNullableString(
        author,
        'displayName',
        'background.authors[].displayName',
      ),
      role: _string(author['role'], 'background.authors[].role'),
      authorUrl: _requiredNullableString(
        author,
        'authorUrl',
        'background.authors[].authorUrl',
      ),
      handle: _requiredNullableString(
        author,
        'handle',
        'background.authors[].handle',
      ),
      twitter: _requiredNullableString(
        author,
        'twitter',
        'background.authors[].twitter',
      ),
      instagram: _requiredNullableString(
        author,
        'instagram',
        'background.authors[].instagram',
      ),
    );

OfficialUserProfileBadge _decodeOfficialUserProfileBadge(
  Map<String, dynamic> badge,
) {
  return OfficialUserProfileBadge(
    key: _string(badge['key'], 'badge.key'),
    name: _string(badge['name'], 'badge.name'),
    imageUrl: _string(badge['imageUrl'], 'badge.imageUrl'),
  );
}

ProfileTagRating _decodeV4TagRating(Map<String, dynamic> body) =>
    ProfileTagRating(
      key: _string(body['key'], 'tagRatings[].key'),
      rating: _integer(body['rating'], 'tagRatings[].rating'),
      solvedCount: _integer(body['solvedCount'], 'tagRatings[].solvedCount'),
      ratingByProblemsSum: _integer(
        body['ratingByProblemsSum'],
        'tagRatings[].ratingByProblemsSum',
      ),
      ratingBySolvedCount: _integer(
        body['ratingBySolvedCount'],
        'tagRatings[].ratingBySolvedCount',
      ),
      ratingProblemsCutoff: _integer(
        body['ratingProblemsCutoff'],
        'tagRatings[].ratingProblemsCutoff',
      ),
    );

String _pathSegment(
  String value,
  String name, {
  int maximumLength = 64,
}) {
  // Keep this aligned with the proxy's stricter path allowlist. OpenAPI only
  // specifies length, but decoded separators and controls are not safe route
  // parameters at the gateway boundary.
  if (value.isEmpty ||
      value.runes.length > maximumLength ||
      value == '.' ||
      value == '..' ||
      value.contains('/') ||
      value.contains(r'\') ||
      RegExp(r'[\u0000-\u001f\u007f-\u009f]').hasMatch(value)) {
    throw ArgumentError.value(value, name, 'Must be one safe path segment');
  }
  return Uri.encodeComponent(value);
}

void _positivePage(int page) {
  if (page < 1) {
    throw ArgumentError.value(page, 'page', 'Must be at least 1');
  }
}

DateTime _activityQueryDay(DateTime value, String name) {
  if (value.year < 0 || value.year > 9999) {
    throw ArgumentError.value(
      value,
      name,
      'Year must be from 0 through 9999',
    );
  }
  return DateTime.utc(value.year, value.month, value.day);
}

String _formatDay(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

void _activityFeedQueryDay(String value, String name) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      name,
      'Must match YYYY-MM-DD',
    );
  }
}

String _profileHistoryDay(Object? value, String field) {
  final day = _string(value, field);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
    throw FormatException('Invalid $field');
  }
  return day;
}

({int year, int month, int day}) _profileActivityDay(
  String value,
  String field,
) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw FormatException('Invalid $field');
  return (
    year: int.parse(match.group(1)!),
    month: int.parse(match.group(2)!),
    day: int.parse(match.group(3)!),
  );
}

Map<String, dynamic> _object(Object? value, String field) {
  if (value is! Map) throw FormatException('Expected object for $field');
  return Map<String, dynamic>.from(value);
}

Map<String, String> _stringMap(Object? value, String field) {
  if (value is! Map) throw FormatException('Expected object for $field');
  final decoded = <String, String>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('Expected string key for $field');
    }
    decoded[entry.key as String] = _string(entry.value, '$field[]');
  }
  return Map<String, String>.unmodifiable(decoded);
}

List<dynamic> _list(Object? value, String field) {
  if (value is! List) throw FormatException('Expected list for $field');
  return List<dynamic>.from(value);
}

Object? _immutableJsonValue(Object? value, String field) {
  if (value == null || value is String || value is bool) return value;
  if (value is num) return _number(value, field);
  if (value is List) {
    return List<Object?>.unmodifiable(
      value.map((item) => _immutableJsonValue(item, '$field[]')),
    );
  }
  if (value is Map) {
    final decoded = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FormatException('Expected string key for $field');
      }
      decoded[entry.key as String] =
          _immutableJsonValue(entry.value, '$field{}');
    }
    return Map<String, Object?>.unmodifiable(decoded);
  }
  throw FormatException('Expected JSON value for $field');
}

String _string(Object? value, String field) {
  if (value is! String) throw FormatException('Expected string for $field');
  return value;
}

String? _nullableString(Object? value, String field) =>
    value == null ? null : _string(value, field);

String? _requiredNullableString(
  Map<String, dynamic> body,
  String wireKey, [
  String? field,
]) {
  final decodedField = field ?? wireKey;
  if (!body.containsKey(wireKey)) {
    throw FormatException('Missing required field $decodedField');
  }
  return _nullableString(body[wireKey], decodedField);
}

num _number(Object? value, String field) {
  if (value is! num || !value.isFinite) {
    throw FormatException('Expected finite number for $field');
  }
  return value;
}

int _integer(Object? value, String field) {
  if (value is! int) throw FormatException('Expected integer for $field');
  return value;
}

int _officialUserProfileClass(Object? value, String field) {
  final decoded = _integer(value, field);
  if (decoded < 0 || decoded > 10) {
    throw FormatException('Expected $field from 0 through 10');
  }
  return decoded;
}

int _nonNegativeInteger(Object? value, String field) {
  final decoded = _integer(value, field);
  if (decoded < 0) {
    throw FormatException('Expected non-negative integer for $field');
  }
  return decoded;
}

int _profileActivityMaxSolvedLevel(Object? value, String field) {
  final decoded = _integer(value, field);
  if (decoded < 0 || decoded > 30) {
    throw FormatException('Expected integer from 0 through 30 for $field');
  }
  return decoded;
}

int _activityFeedProblemLevel(Object? value, String field) {
  final decoded = _integer(value, field);
  if (decoded < 0 || decoded > 30) {
    throw FormatException('Expected integer from 0 through 30 for $field');
  }
  return decoded;
}

int _wholeNumber(Object? value, String field) {
  if (value is int) return value;
  if (value is double &&
      value.isFinite &&
      value == value.truncateToDouble()) {
    return value.toInt();
  }
  throw FormatException('Expected whole number for $field');
}

int? _nullableInteger(Object? value, String field) =>
    value == null ? null : _integer(value, field);

int? _requiredNullableInteger(
  Map<String, dynamic> body,
  String wireKey,
  String field,
) {
  if (!body.containsKey(wireKey)) {
    throw FormatException('Missing required field $field');
  }
  return _nullableInteger(body[wireKey], field);
}

int? _requiredNullableTier(Map<String, dynamic> body, String field) {
  final tier = _requiredNullableInteger(body, 'tier', field);
  if (tier != null && (tier < 0 || tier > 31)) {
    throw FormatException('Expected tier from 0 through 31 for $field');
  }
  return tier;
}

bool _boolean(Object? value, String field) {
  if (value is! bool) throw FormatException('Expected boolean for $field');
  return value;
}

bool? _requiredNullableBoolean(
  Map<String, dynamic> body,
  String field,
) {
  if (!body.containsKey(field)) {
    throw FormatException('Missing required field $field');
  }
  final value = body[field];
  return value == null ? null : _boolean(value, field);
}
