import 'dart:convert';

import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

import 'helpers/fixture.dart';

void main() {
  late SolvedApiV4Contract contract;

  setUp(() {
    contract = SolvedApiV4Contract(
      proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
    );
  });

  test('builds contributions with omitted and explicit queries', () {
    final omitted = contract.userContributions('a b');
    final explicit = contract.userContributions(
      'index',
      page: 10000,
      limit: 1,
      sort: UserContributionSort.helpful,
      only: UserContributionFilter.scoring,
      commented: true,
    );

    expect(omitted.direct.path, 'users/a%20b/contributions');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(explicit.direct.queryParameters, {
      'page': '10000',
      'limit': '1',
      'sort': 'helpful',
      'only': 'scoring',
      'commented': 'true',
    });
    expect(
      contract.userContributions('a', commented: false).direct.queryParameters,
      {'commented': 'false'},
    );
    expect(UserContributionSort.values.map((value) => value.value), [
      'recent',
      'helpful',
    ]);
    expect(UserContributionFilter.values.map((value) => value.value), [
      'scoring',
      'helpful',
      'vouched',
    ]);
  });

  test('rejects arguments outside the official limits', () {
    for (final (call, field) in [
      (() => contract.userContributions(''), 'handle'),
      (() => contract.userContributions('a/b'), 'handle'),
      (() => contract.userContributions('a', page: 0), 'page'),
      (() => contract.userContributions('a', page: 10001), 'page'),
      (() => contract.userContributions('a', limit: 0), 'limit'),
      (() => contract.userContributions('a', limit: 21), 'limit'),
    ]) {
      expect(
        call,
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', field),
        ),
        reason: field,
      );
    }
  });

  test('decodes contributions with the shared vote and title shapes', () {
    final actual = contract.userContributions('a').decode(_response());

    expect(actual.items, hasLength(3));
    expect([
      actual.total,
      actual.hiddenCount,
      actual.page,
      actual.pageSize
    ], [
      1,
      -2,
      9,
      0,
    ]);
    expect(actual.sort, UserContributionSort.helpful);
    final first = actual.items.first;
    expect(first.voteId, -1);
    expect(first.votedAt, 'not a date');
    expect(first.points, -5);
    expect(first.place, isNull);
    expect(first.problem.problemId, 1000);
    expect(first.problem.level, 30);
    expect(first.problem.effectiveVoteCount, 0);
    expect(first.problem.givesNoRating, isTrue);
    expect(first.problem.isStandard, isFalse);
    expect(first.problem.titles, hasLength(2));
    expect(first.problem.titles.first.title, '한 글');
    expect(first.problem.userStatus, isNull);
    final vote = contract.problemVotes(1).decode(
          jsonDecode(fixture('v4/problem_votes.json')),
        );
    expect(first.vote.id, vote.items.first.id);
    final second = actual.items[1];
    expect(second.place, 3);
    expect(second.problem.level, 0);
    expect(second.problem.userStatus, ProblemUserStatus.partial);
    expect(second.problem.titles, isEmpty);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.userContributions('a');
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in [
      'items',
      'total',
      'hiddenCount',
      'page',
      'pageSize',
      'sort',
    ]) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: field,
      );
      expect(
        () => endpoint.decode(_response()..[field] = null),
        throwsFormatException,
        reason: '$field null',
      );
    }
    for (final field in [
      'voteId',
      'problem',
      'votedAt',
      'points',
      'place',
      'vote',
    ]) {
      final missing = _response();
      _first(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
    }
    final placeNull = _response();
    _first(placeNull)['place'] = null;
    expect(endpoint.decode(placeNull).items.first.place, isNull);
    for (final field in [
      'problemId',
      'subId',
      'level',
      'effectiveVoteCount',
      'givesNoRating',
      'isStandard',
      'titles',
      'userStatus',
    ]) {
      final missing = _response();
      _problem(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: 'problem.$field missing',
      );
    }
    final vote = _response();
    (_first(vote)['vote'] as Map<String, dynamic>).remove('id');
    expect(() => endpoint.decode(vote), throwsFormatException);
  });

  test('enforces exact enums, strict integers, and documented bounds', () {
    final endpoint = contract.userContributions('a');
    for (final sort in UserContributionSort.values) {
      expect(
        endpoint.decode(_response()..['sort'] = sort.value).sort,
        sort,
      );
    }
    for (final (key, value) in <(String, Object?)>[
      ('sort', 'Recent'),
      ('total', 1.0),
      ('hiddenCount', '0'),
    ]) {
      expect(
        () => endpoint.decode(_response()..[key] = value),
        throwsFormatException,
        reason: key,
      );
    }
    for (final (key, value) in <(String, Object?)>[
      ('level', -1),
      ('level', 31),
      ('level', 1.0),
      ('effectiveVoteCount', -1),
      ('problemId', 1.5),
      ('userStatus', 'Solved'),
    ]) {
      final body = _response();
      _problem(body)[key] = value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: '$key = $value',
      );
    }
    for (final (key, value) in <(String, Object?)>[
      ('voteId', 1.5),
      ('points', '1'),
      ('place', 1.5),
      ('votedAt', 0),
    ]) {
      final body = _response();
      _first(body)[key] = value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: key,
      );
    }
  });

  test('eagerly snapshots ordered unmodifiable lists', () {
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final titles = _problem(body)['titles'] as List<dynamic>;
    final actual = contract.userContributions('a').decode(body);
    titles.clear();
    items.clear();

    expect(actual.items, hasLength(3));
    expect(actual.items.first.problem.titles, hasLength(2));
    expect(() => actual.items.clear(), throwsUnsupportedError);
    expect(
      () => actual.items.first.problem.titles.clear(),
      throwsUnsupportedError,
    );
  });
}

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/user_contributions.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['items'] as List<dynamic>).first as Map<String, dynamic>;

Map<String, dynamic> _problem(Map<String, dynamic> body) =>
    _first(body)['problem'] as Map<String, dynamic>;
