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
      decode: _decodeV4ProfileActivity,
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
      ),
    ),
  );
  final contests = List<ProblemSearchContest>.unmodifiable(
    _list(body['contests'], 'problems[].contests').map(
      (value) => _decodeV4ProblemSearchContest(
        _object(value, 'problems[].contests[]'),
      ),
    ),
  );
  final tags = List<ProblemSearchTag>.unmodifiable(
    _list(body['tags'], 'problems[].tags').map(
      (value) => _decodeV4ProblemSearchTag(_object(value, 'problems[].tags[]')),
    ),
  );
  final viewerFolders = List<ProblemSearchViewerFolder>.unmodifiable(
    _list(body['viewerFolders'], 'problems[].viewerFolders').map(
      (value) => _decodeV4ProblemSearchViewerFolder(
        _object(value, 'problems[].viewerFolders[]'),
      ),
    ),
  );
  final noRatingReasons = List<ProblemNoRatingReason>.unmodifiable(
    _list(
      body['noRatingReasons'],
      'problems[].noRatingReasons',
    ).map(_decodeV4ProblemNoRatingReason),
  );
  final noRatingWarnings = List<ProblemNoRatingWarning>.unmodifiable(
    _list(body['noRatingWarnings'], 'problems[].noRatingWarnings').map(
      (value) => _decodeV4ProblemNoRatingWarning(
        _object(value, 'problems[].noRatingWarnings[]'),
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

ProblemNoRatingWarning _decodeV4ProblemNoRatingWarning(
  Map<String, dynamic> body,
) {
  if (!body.containsKey('problem')) {
    throw const FormatException(
      'Missing required field problems[].noRatingWarnings[].problem',
    );
  }
  final problemValue = body['problem'];
  ProblemNoRatingWarningProblem? problem;
  if (problemValue != null) {
    problem = _decodeV4ProblemNoRatingWarningProblem(
      _object(problemValue, 'problems[].noRatingWarnings[].problem'),
    );
  }
  return ProblemNoRatingWarning(
    type: _decodeV4ProblemNoRatingWarningType(body['type']),
    problem: problem,
  );
}

ProblemNoRatingWarningType _decodeV4ProblemNoRatingWarningType(Object? value) {
  final code = _string(value, 'problems[].noRatingWarnings[].type');
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
) {
  if (!body.containsKey('userStatus')) {
    throw const FormatException(
      'Missing required field '
      'problems[].noRatingWarnings[].problem.userStatus',
    );
  }
  final userStatusValue = body['userStatus'];
  ProblemUserStatus? userStatus;
  if (userStatusValue != null) {
    userStatus = _decodeV4ProblemUserStatus(
      userStatusValue,
      'problems[].noRatingWarnings[].problem.userStatus',
    );
  }
  return ProblemNoRatingWarningProblem(
    problemId: _number(
      body['problemId'],
      'problems[].noRatingWarnings[].problem.problemId',
    ),
    subId: _string(
      body['subId'],
      'problems[].noRatingWarnings[].problem.subId',
    ),
    level: _number(
      body['level'],
      'problems[].noRatingWarnings[].problem.level',
    ),
    effectiveVoteCount: _number(
      body['effectiveVoteCount'],
      'problems[].noRatingWarnings[].problem.effectiveVoteCount',
    ),
    givesNoRating: _boolean(
      body['givesNoRating'],
      'problems[].noRatingWarnings[].problem.givesNoRating',
    ),
    isStandard: _boolean(
      body['isStandard'],
      'problems[].noRatingWarnings[].problem.isStandard',
    ),
    userStatus: userStatus,
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

ProblemNoRatingReason _decodeV4ProblemNoRatingReason(Object? value) {
  final code = _string(value, 'problems[].noRatingReasons[]');
  return switch (code) {
    'unofficial' => ProblemNoRatingReason.unofficial,
    'legacy' => ProblemNoRatingReason.legacy,
    'staff' => ProblemNoRatingReason.staff,
    'unsettled' => ProblemNoRatingReason.unsettled,
    _ => throw FormatException('Unknown problem no-rating reason: $code'),
  };
}

ProblemSearchTitle _decodeV4ProblemSearchTitle(Map<String, dynamic> body) =>
    ProblemSearchTitle(
      language: _string(body['language'], 'problems[].titles[].language'),
      title: _string(body['title'], 'problems[].titles[].title'),
      isOriginal: _boolean(
        body['isOriginal'],
        'problems[].titles[].isOriginal',
      ),
      latex: _boolean(body['latex'], 'problems[].titles[].latex'),
      html: _boolean(body['html'], 'problems[].titles[].html'),
    );

ProblemSearchTag _decodeV4ProblemSearchTag(Map<String, dynamic> body) =>
    ProblemSearchTag(
      id: _number(body['id'], 'problems[].tags[].id'),
      key: _string(body['key'], 'problems[].tags[].key'),
      isMeta: _boolean(body['isMeta'], 'problems[].tags[].isMeta'),
    );

ProblemSearchContest _decodeV4ProblemSearchContest(Map<String, dynamic> body) {
  if (!body.containsKey('abbreviation')) {
    throw const FormatException(
      'Missing required field problems[].contests[].abbreviation',
    );
  }
  return ProblemSearchContest(
    id: _number(body['id'], 'problems[].contests[].id'),
    displayId: _string(body['displayId'], 'problems[].contests[].displayId'),
    name: _string(body['name'], 'problems[].contests[].name'),
    abbreviation: _nullableString(
      body['abbreviation'],
      'problems[].contests[].abbreviation',
    ),
  );
}

ProblemSearchViewerFolder _decodeV4ProblemSearchViewerFolder(
  Map<String, dynamic> body,
) {
  if (!body.containsKey('color')) {
    throw const FormatException(
      'Missing required field problems[].viewerFolders[].color',
    );
  }
  final colorValue = body['color'];
  return ProblemSearchViewerFolder(
    slug: _string(body['slug'], 'problems[].viewerFolders[].slug'),
    name: _string(body['name'], 'problems[].viewerFolders[].name'),
    color:
        colorValue == null
            ? null
            : _decodeV4ProblemSearchViewerFolderColor(colorValue),
  );
}

ProblemSearchViewerFolderColor _decodeV4ProblemSearchViewerFolderColor(
  Object? value,
) {
  final color = _string(value, 'problems[].viewerFolders[].color');
  return switch (color) {
    'red' => ProblemSearchViewerFolderColor.red,
    'violet' => ProblemSearchViewerFolderColor.violet,
    'blue' => ProblemSearchViewerFolderColor.blue,
    'teal' => ProblemSearchViewerFolderColor.teal,
    'lime' => ProblemSearchViewerFolderColor.lime,
    'yellow' => ProblemSearchViewerFolderColor.yellow,
    'orange' => ProblemSearchViewerFolderColor.orange,
    _ =>
      throw const FormatException(
        'Unsupported problems[].viewerFolders[].color',
      ),
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
  final tagRatings = _list(body['tagRatings'], 'tagRatings')
      .map((item) => _decodeV4TagRating(_object(item, 'tagRatings[]')))
      .toList(growable: false);
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
    handle: _string(body['handle'], 'handle'),
    profileImageUrl: _requiredNullableString(body, 'profileImageUrl'),
    bio: _requiredNullableString(body, 'bio'),
    solvedCount: _integer(body['solvedCount'], 'solvedCount'),
    userClass: _integer(body['class'], 'class'),
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
