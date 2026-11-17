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

/// Official v4 profile endpoints and response normalization.
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
    solvedCount: _integer(body['solvedCount'], 'solvedCount'),
    legacyContributionCount: null,
    userClass: _integer(body['class'], 'class'),
    reverseRivalCount: null,
    tier: _nullableInteger(body['tier'], 'tier'),
    rating: rating,
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

int _integer(Object? value, String field) {
  if (value is! int) throw FormatException('Expected integer for $field');
  return value;
}

int? _nullableInteger(Object? value, String field) =>
    value == null ? null : _integer(value, field);

bool _boolean(Object? value, String field) {
  if (value is! bool) throw FormatException('Expected boolean for $field');
  return value;
}
