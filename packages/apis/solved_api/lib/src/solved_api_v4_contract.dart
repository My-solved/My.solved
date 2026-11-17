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

  SolvedApiEndpoint<UserProfile> userProfile(String handle) => _endpoint(
        path: 'users/${_pathSegment(handle, 'handle')}',
        queryParameters: const {'lang': 'ko'},
        decode: _decodeV4UserProfile,
      );

  SolvedApiEndpoint<ProfileStreak> userActivity(
    String handle, {
    required DateTime from,
    required DateTime to,
  }) {
    final fromDay = DateTime.utc(from.year, from.month, from.day);
    final toDay = DateTime.utc(to.year, to.month, to.day);
    if (fromDay.isAfter(toDay)) {
      throw ArgumentError.value(from, 'from', 'Must not be after to');
    }
    return _endpoint(
      path: 'users/${_pathSegment(handle, 'handle')}/activity/days',
      queryParameters: {
        'from': _formatDay(fromDay),
        'to': _formatDay(toDay),
      },
      decode: _decodeV4ProfileStreak,
    );
  }

  SolvedApiEndpoint<ProfileContributionStats> userReputation(
    String handle, {
    SolvedApiV4ReputationRange? range,
  }) =>
      _endpoint(
        path: 'users/${_pathSegment(handle, 'handle')}/reputation',
        queryParameters: {
          if (range != null) 'range': range.value,
        },
        decode: _decodeV4ContributionStats,
      );

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

  SolvedApiEndpoint<SearchObject<ProblemSearchItem>> searchProblems(
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

SearchObject<ProblemSearchItem> _decodeV4ProblemSearch(dynamic json) {
  final body = _object(json, 'problem search');
  final problems = _list(body['problems'], 'problems')
      .map((item) => _decodeV4ProblemSearchItem(_object(item, 'problems[]')))
      .toList(growable: false);
  return SearchObject(
    count: _wholeNumber(body['total'], 'total'),
    items: problems,
  );
}

ProblemSearchItem _decodeV4ProblemSearchItem(Map<String, dynamic> body) {
  final tagKeys = _list(body['tags'], 'problems[].tags')
      .map(
        (item) => _string(
          _object(item, 'problems[].tags[]')['key'],
          'problems[].tags[].key',
        ),
      )
      .toList(growable: false);
  return ProblemSearchItem(
    problemId: _wholeNumber(body['problemId'], 'problems[].problemId'),
    title: _decodeV4ProblemTitle(body['titles']),
    level: _wholeNumber(body['level'], 'problems[].level'),
    givesNoRating: _boolean(body['givesNoRating'], 'problems[].givesNoRating'),
    // The official v4 problem shape has tag keys but no localized names.
    tagNames: tagKeys,
  );
}

String? _decodeV4ProblemTitle(Object? value) {
  String? first;
  String? original;
  for (final item in _list(value, 'problems[].titles')) {
    final title = _object(item, 'problems[].titles[]');
    final language = _string(
      title['language'],
      'problems[].titles[].language',
    );
    final text = _string(title['title'], 'problems[].titles[].title');
    final isOriginal = _boolean(
      title['isOriginal'],
      'problems[].titles[].isOriginal',
    );
    first ??= text;
    if (language == 'ko') return text;
    if (isOriginal) original ??= text;
  }
  return original ?? first;
}

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
      handle: _string(body['handle'], 'user.handle'),
      profileImageUrl:
          _nullableString(body['profileImageUrl'], 'user.profileImageUrl'),
      tier: _nullableInteger(body['tier'], 'user.tier'),
      rank: _integer(body['rank'], 'user.rank'),
      rating: _integer(body['rating'], 'user.rating'),
      solvedCount: _integer(body['solvedCount'], 'user.solvedCount'),
      reputation: _integer(body['reputation'], 'user.reputation'),
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
  final pageItems = start >= matches.length
      ? const <TagSearchItem>[]
      : matches
          .skip(start)
          .take(SolvedApiV4Contract.tagSearchPageSize)
          .map(
            (tag) => TagSearchItem(
              key: tag.key,
              problemCount: null,
              displayName: tag.displayName,
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
  final aliases = _list(body['aliases'], 'tags[].aliases').map(
        (value) => _string(value, 'tags[].aliases[]'),
      );
  return _V4CatalogTag(
    key: _string(body['key'], 'tags[].key'),
    names: names.values.toList(growable: false),
    displayName: _preferredLocalizedName(names),
    aliases: aliases.toList(growable: false),
  );
}

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
    required this.key,
    required this.names,
    required this.displayName,
    required this.aliases,
  });

  final String key;
  final List<String> names;
  final String? displayName;
  final List<String> aliases;

  bool matches(String normalizedQuery) =>
      <String>[key, ...names, ...aliases].any(
        (candidate) => candidate.toLowerCase().contains(normalizedQuery),
      );
}

UserProfile _decodeV4UserProfile(dynamic json) {
  final body = _object(json, 'profile');
  final background = _decodeInlineBackground(body['background']);
  final badge = _decodeInlineBadge(body['badge']);
  final rating = _integer(body['rating'], 'rating');
  final tagRatings = _list(body['tagRatings'], 'tagRatings')
      .map((item) => _decodeV4TagRating(_object(item, 'tagRatings[]')))
      .toList(growable: false);

  return UserProfile(
    handle: _string(body['handle'], 'handle'),
    badgeId: badge?.key,
    backgroundId: background?.key,
    profileImageUrl:
        _nullableString(body['profileImageUrl'], 'profileImageUrl'),
    bio: _requiredNullableString(body, 'bio'),
    solvedCount: _integer(body['solvedCount'], 'solvedCount'),
    legacyContributionCount: null,
    userClass: _integer(body['class'], 'class'),
    classPlus: _boolean(body['classPlus'], 'classPlus'),
    reverseRivalCount: null,
    tier: _nullableInteger(body['tier'], 'tier'),
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
      ratingProblemsHistogram:
          _list(body['ratingProblemsHistogram'], 'ratingProblemsHistogram')
              .map((value) => _integer(value, 'ratingProblemsHistogram[]'))
              .toList(growable: false),
      noRatingSolvedCount:
          _integer(body['noRatingSolvedCount'], 'noRatingSolvedCount'),
    ),
    background: background,
    badge: badge,
    tagRatings: tagRatings,
  );
}

ProfileStreak _decodeV4ProfileStreak(dynamic json) {
  final body = _object(json, 'activity');
  final days = _list(body['days'], 'days').map((item) {
    final day = _object(item, 'days[]');
    final date = _day(_string(day['day'], 'days[].day'), 'days[].day');
    return ProfileSolvedDay(
      year: date.year,
      month: date.month,
      day: date.day,
      solvedCount: _integer(day['solvedCount'], 'days[].solvedCount'),
      maxSolvedLevel: _integer(day['maxSolvedLevel'], 'days[].maxSolvedLevel'),
      ratingDelta: _integer(day['ratingDelta'], 'days[].ratingDelta'),
      freezeUsed: _boolean(day['freezeUsed'], 'days[].freezeUsed'),
      streakRepaired: _boolean(day['streakRepaired'], 'days[].streakRepaired'),
    );
  }).toList(growable: false);
  return ProfileStreak(
    days: days,
    currentStreak: _integer(body['currentStreak'], 'currentStreak'),
    maxStreak: _integer(body['maxStreak'], 'maxStreak'),
    theme: _nullableString(body['theme'], 'theme'),
    firstActiveDay: _nullableString(body['firstActiveDay'], 'firstActiveDay'),
  );
}

ProfileContributionStats _decodeV4ContributionStats(dynamic json) {
  final body = _object(json, 'reputation');
  return ProfileContributionStats(
    reputation: _integer(body['reputation'], 'reputation'),
    scoringCount: _integer(body['scoringCount'], 'scoringCount'),
    helpfulCount: _integer(body['helpfulCount'], 'helpfulCount'),
    vouchedCount: _integer(body['vouchedCount'], 'vouchedCount'),
  );
}

ProfileBackgroundAsset? _decodeV4BackgroundAsset(dynamic json) {
  final body = _object(json, 'background item');
  if (body['kind'] != 'background') {
    throw const FormatException('Expected a background item');
  }
  if (body['background'] == null) return null;
  final background = _object(body['background'], 'background');
  return ProfileBackgroundAsset(
    key: _string(body['key'], 'key'),
    imageUrl: _string(background['backgroundImageUrl'], 'backgroundImageUrl'),
    fallbackImageUrl: _nullableString(
      background['fallbackBackgroundImageUrl'],
      'fallbackBackgroundImageUrl',
    ),
  );
}

ProfileBadgeAsset _decodeV4BadgeAsset(dynamic json) {
  final body = _object(json, 'badge item');
  if (body['kind'] != 'badge') {
    throw const FormatException('Expected a badge item');
  }
  return ProfileBadgeAsset(
    key: _string(body['key'], 'key'),
    name: _string(body['name'], 'name'),
    imageUrl: _string(body['imageUrl'], 'imageUrl'),
  );
}

ProfileBackgroundAsset? _decodeInlineBackground(Object? value) {
  if (value == null) return null;
  final background = _object(value, 'background');
  return ProfileBackgroundAsset(
    key: _string(background['key'], 'background.key'),
    imageUrl: _string(background['backgroundImageUrl'], 'backgroundImageUrl'),
    fallbackImageUrl: _nullableString(
      background['fallbackBackgroundImageUrl'],
      'fallbackBackgroundImageUrl',
    ),
  );
}

ProfileBadgeAsset? _decodeInlineBadge(Object? value) {
  if (value == null) return null;
  final badge = _object(value, 'badge');
  return ProfileBadgeAsset(
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

String _pathSegment(String value, String name) {
  // Keep this aligned with the proxy's stricter path allowlist. OpenAPI only
  // specifies length, but decoded separators and controls are not safe route
  // parameters at the gateway boundary.
  if (value.isEmpty ||
      value.runes.length > 64 ||
      value == '.' ||
      value == '..' ||
      value.contains('/') ||
      value.contains(r'\') ||
      RegExp(r'[\u0000-\u001f\u007f]').hasMatch(value)) {
    throw ArgumentError.value(value, name, 'Must be one safe path segment');
  }
  return Uri.encodeComponent(value);
}

void _positivePage(int page) {
  if (page < 1) {
    throw ArgumentError.value(page, 'page', 'Must be at least 1');
  }
}

String _formatDay(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

DateTime _day(String value, String field) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw FormatException('Invalid $field');
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final result = DateTime.utc(year, month, day);
  if (_formatDay(result) != value) throw FormatException('Invalid $field');
  return result;
}

Map<String, dynamic> _object(Object? value, String field) {
  if (value is! Map) throw FormatException('Expected object for $field');
  return Map<String, dynamic>.from(value);
}

List<dynamic> _list(Object? value, String field) {
  if (value is! List) throw FormatException('Expected list for $field');
  return List<dynamic>.from(value);
}

String _string(Object? value, String field) {
  if (value is! String) throw FormatException('Expected string for $field');
  return value;
}

String? _nullableString(Object? value, String field) =>
    value == null ? null : _string(value, field);

String? _requiredNullableString(
  Map<String, dynamic> body,
  String field,
) {
  if (!body.containsKey(field)) {
    throw FormatException('Missing required field $field');
  }
  return _nullableString(body[field], field);
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

bool _boolean(Object? value, String field) {
  if (value is! bool) throw FormatException('Expected boolean for $field');
  return value;
}
