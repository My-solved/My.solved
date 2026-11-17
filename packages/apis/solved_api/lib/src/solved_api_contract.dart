import 'models/models.dart';

typedef SolvedApiDecoder<T> = T Function(dynamic json);

/// One concrete request target for a solved.ac endpoint.
final class SolvedApiTarget {
  SolvedApiTarget({
    required Uri baseUri,
    required this.path,
    Map<String, String> queryParameters = const {},
  })  : baseUri = _normalizeBaseUri(baseUri),
        queryParameters = Map<String, String>.unmodifiable(queryParameters) {
    if (!baseUri.isAbsolute ||
        baseUri.host.isEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        baseUri.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        baseUri,
        'baseUri',
        'Must be an absolute URI without credentials, query, or fragment',
      );
    }
    if (!_isRelativeEndpointPath(path)) {
      throw ArgumentError.value(path, 'path', 'Must be a relative URI path');
    }
  }

  final Uri baseUri;
  final String path;
  final Map<String, String> queryParameters;
}

/// Direct and proxy request targets plus the decoder for one endpoint.
final class SolvedApiEndpoint<T> {
  const SolvedApiEndpoint({
    required this.direct,
    required this.proxy,
    required this.decode,
  });

  final SolvedApiTarget direct;
  final SolvedApiTarget proxy;
  final SolvedApiDecoder<T> decode;
}

/// The complete wire contract consumed by [SolvedApiClient].
abstract interface class SolvedApiContract {
  SolvedApiEndpoint<User> userShow(String handle);

  SolvedApiEndpoint<List<Organization>> userOrganizations(String handle);

  SolvedApiEndpoint<List<Badge>> userAvailableBadges(String handle);

  SolvedApiEndpoint<Streak> userGrass(String handle, String? topic);

  SolvedApiEndpoint<List<Problem>> userTop100(String handle);

  SolvedApiEndpoint<List<ProblemStat>> userProblemStats(String handle);

  SolvedApiEndpoint<List<TagRating>> userTagRatings(String handle);

  SolvedApiEndpoint<Background> backgroundShow(String backgroundId);

  SolvedApiEndpoint<Badge> badgeShow(String badgeId);

  SolvedApiEndpoint<SearchSuggestion> searchSuggestion(String query);

  SolvedApiEndpoint<SearchObject<ProblemSearchItem>> searchProblem(
    String query,
    int? page,
    String? sort,
    String? direction,
  );

  SolvedApiEndpoint<SearchObject<UserSearchItem>> searchUser(
    String query,
    int? page,
  );

  SolvedApiEndpoint<SearchObject<TagSearchItem>> searchTag(
    String query,
    int? page,
  );

  SolvedApiEndpoint<List<ArenaContest>> arenaContests();

  SolvedApiEndpoint<SiteStats> siteStats();
}

/// The verified v3 request paths, query parameters, and response decoders.
class SolvedApiV3Contract implements SolvedApiContract {
  const SolvedApiV3Contract();

  static final Uri _directBaseUri = Uri.https('solved.ac', '/api/v3/');
  static final Uri _proxyBaseUri = Uri.https('codepoker.w8385.dev', '/solved/');

  @override
  SolvedApiEndpoint<User> userShow(String handle) => _endpoint(
        path: 'user/show',
        queryParameters: {'handle': handle},
        decode: (json) => User.fromJson(json),
      );

  @override
  SolvedApiEndpoint<List<Organization>> userOrganizations(String handle) =>
      _endpoint(
        path: 'user/organizations',
        queryParameters: {'handle': handle},
        decode: (json) => json
            .map((item) => Organization.fromJson(item))
            .toList()
            .cast<Organization>(),
      );

  @override
  SolvedApiEndpoint<List<Badge>> userAvailableBadges(String handle) =>
      _endpoint(
        path: 'user/available_badges',
        queryParameters: {'handle': handle},
        decode: (json) => json['items']
            .map((item) => Badge.fromJson(item))
            .toList()
            .cast<Badge>(),
      );

  @override
  SolvedApiEndpoint<Streak> userGrass(String handle, String? topic) =>
      _endpoint(
        path: 'user/grass',
        queryParameters: {'handle': handle, 'topic': topic ?? 'default'},
        decode: (json) => Streak.fromJson(json),
      );

  @override
  SolvedApiEndpoint<List<Problem>> userTop100(String handle) => _endpoint(
        path: 'user/top_100',
        queryParameters: {'handle': handle},
        decode: (json) => json['items']
            .map((item) => Problem.fromJson(item))
            .toList()
            .cast<Problem>(),
      );

  @override
  SolvedApiEndpoint<List<ProblemStat>> userProblemStats(String handle) =>
      _endpoint(
        path: 'user/problem_stats',
        queryParameters: {'handle': handle},
        decode: (json) => List<ProblemStat>.from(
          json.map((item) => ProblemStat.fromJson(item)),
        ),
      );

  @override
  SolvedApiEndpoint<List<TagRating>> userTagRatings(String handle) => _endpoint(
        path: 'user/tag_ratings',
        queryParameters: {'handle': handle},
        decode: (json) =>
            List<TagRating>.from(json.map((item) => TagRating.fromJson(item))),
      );

  @override
  SolvedApiEndpoint<Background> backgroundShow(String backgroundId) =>
      _endpoint(
        path: 'background/show',
        queryParameters: {'backgroundId': backgroundId},
        decode: (json) => Background.fromJson(json),
      );

  @override
  SolvedApiEndpoint<Badge> badgeShow(String badgeId) => _endpoint(
        path: 'badge/show',
        queryParameters: {'badgeId': badgeId},
        decode: (json) => Badge.fromJson(json),
      );

  @override
  SolvedApiEndpoint<SearchSuggestion> searchSuggestion(String query) =>
      _endpoint(
        path: 'search/suggestion',
        queryParameters: {'query': query},
        decode: (json) => SearchSuggestion.fromJson(json),
      );

  @override
  SolvedApiEndpoint<SearchObject<ProblemSearchItem>> searchProblem(
    String query,
    int? page,
    String? sort,
    String? direction,
  ) =>
      _endpoint(
        path: 'search/problem',
        queryParameters: {
          'query': query,
          'page': page?.toString() ?? '1',
          'sort': sort ?? 'solved',
          'direction': direction ?? 'descending',
        },
        decode: (json) =>
            _decodeV3SearchObject(json, _decodeV3ProblemSearchItem),
      );

  @override
  SolvedApiEndpoint<SearchObject<UserSearchItem>> searchUser(
    String query,
    int? page,
  ) =>
      _endpoint(
        path: 'search/user',
        queryParameters: {'query': query, 'page': page?.toString() ?? '1'},
        decode: (json) => _decodeV3SearchObject(json, _decodeV3UserSearchItem),
      );

  @override
  SolvedApiEndpoint<SearchObject<TagSearchItem>> searchTag(
    String query,
    int? page,
  ) =>
      _endpoint(
        path: 'search/tag',
        queryParameters: {'query': query, 'page': page?.toString() ?? '1'},
        decode: (json) => _decodeV3SearchObject(json, _decodeV3TagSearchItem),
      );

  @override
  SolvedApiEndpoint<List<ArenaContest>> arenaContests() => _endpoint(
        path: 'arena/contests',
        decode: (json) {
          final contests = <ArenaContest>[];
          for (final status in json.keys) {
            json[status].forEach(
              (contest) => contests.add(ArenaContest.fromJson(contest)),
            );
          }
          return contests;
        },
      );

  @override
  SolvedApiEndpoint<SiteStats> siteStats() =>
      _endpoint(path: 'site/stats', decode: (json) => SiteStats.fromJson(json));

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

SearchObject<T> _decodeV3SearchObject<T>(
  dynamic json,
  T Function(Map<String, dynamic> item) decodeItem,
) {
  final body = Map<String, dynamic>.from(json as Map);
  final items = body['items'] as List<dynamic>;
  return SearchObject<T>(
    count: body['count'] as int,
    items: items
        .map((item) => decodeItem(Map<String, dynamic>.from(item as Map)))
        .toList(),
  );
}

ProblemSearchItem _decodeV3ProblemSearchItem(Map<String, dynamic> json) {
  final tags = json['tags'] as List<dynamic>;
  return ProblemSearchItem(
    problemId: json['problemId'] as int,
    title: json['titleKo'] as String,
    level: json['level'] as int,
    tagNames: tags
        .map(
          (tag) => _decodeV3TagName(Map<String, dynamic>.from(tag as Map)),
        )
        .toList(),
  );
}

UserSearchItem _decodeV3UserSearchItem(Map<String, dynamic> json) {
  return UserSearchItem(
    handle: json['handle'] as String,
    profileImageUrl: json['profileImageUrl'] as String?,
    tier: json['tier'] as int,
  );
}

TagSearchItem _decodeV3TagSearchItem(Map<String, dynamic> json) {
  return TagSearchItem(
    key: json['key'] as String,
    problemCount: json['problemCount'] as int,
  );
}

String _decodeV3TagName(Map<String, dynamic> tag) {
  final key = tag['key'] as String;
  final displayNames = tag['displayNames'];
  if (displayNames is! List) return key;

  String? firstName;
  for (final displayName in displayNames) {
    if (displayName is! Map) continue;
    final fields = Map<String, dynamic>.from(displayName);
    final name = fields['name'];
    if (name is! String || name.isEmpty) continue;
    firstName ??= name;
    if (fields['language'] == 'ko') return name;
  }
  return firstName ?? key;
}

Uri _normalizeBaseUri(Uri uri) {
  if (uri.path.endsWith('/')) return uri;
  return uri.replace(path: '${uri.path}/');
}

bool _isRelativeEndpointPath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains('\\') ||
      path.contains('?') ||
      path.contains('#') ||
      path.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    return false;
  }
  final uri = Uri.tryParse(path);
  return uri != null &&
      !uri.isAbsolute &&
      uri.scheme.isEmpty &&
      uri.host.isEmpty &&
      uri.userInfo.isEmpty &&
      uri.pathSegments.every((segment) => segment != '.' && segment != '..');
}
