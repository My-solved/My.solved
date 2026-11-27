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

  test('builds problem votes with omitted and explicit queries', () {
    final omitted = contract.problemVotes(1000);
    final explicit = contract.problemVotes(
      1,
      sub: '',
      page: 1,
      sort: ProblemVoteSort.recent,
    );

    expect(omitted.direct.path, 'problems/1000/votes');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.queryParameters, {
      'sub': '',
      'page': '1',
      'sort': 'recent',
    });
    expect(explicit.proxy.queryParameters, explicit.direct.queryParameters);
    expect(ProblemVoteSort.values.map((sort) => sort.value), [
      'recent',
      'level',
      'weight',
    ]);
  });

  test('rejects problem ids and pages below one', () {
    expect(
      () => contract.problemVotes(0),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'problemId'),
      ),
    );
    expect(
      () => contract.problemVotes(1, page: 0),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'page'),
      ),
    );
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.problemVotes(1).decode(
          jsonDecode(fixture('v4/problem_votes.json')),
        );

    expect(actual.total, -1);
    expect(actual.page, 3.0);
    expect(actual.pageSize, 30);
    expect(actual.sort, ProblemVoteSort.weight);
    expect(actual.markRefusal, ProblemVoteMarkRefusal.notSolved);
    expect(actual.unhelpfulLocked, isTrue);

    final first = actual.items.first;
    expect(first.id, 1.5);
    expect(first.user!.handle, 'voter');
    expect(first.user!.tier, 31);
    expect(first.user!.profileImageUrl, 'not a URI');
    expect(first.votedAt, 'not a date');
    expect(first.level, 12.5);
    expect(first.weight, -1);
    expect(
      [
        first.invalidated,
        first.notInCalculation,
        first.banned,
        first.superseded,
        first.cutoff,
      ],
      [true, false, true, false, true],
    );
    expect(first.comment, 'raw / 한 글');
    expect(first.commentLanguage, 'ko');
    expect(first.emoticonId, 'smile');
    expect(first.emoticon!.key, 'other');
    expect(first.emoticon!.url, 'not a URI');
    expect(first.source, '');
    expect(first.tags, hasLength(3));
    expect(first.tags.first.tag!.key, 'math');
    expect(first.tags.first.legacyKey, 'legacy');
    expect(first.tags[1].tag, isNull);
    expect(first.tags[1].legacyKey, isNull);
    expect(first.isStandard, isFalse);
    expect(first.marks!.score, -3);
    expect(first.marks!.counts!.helpful, 0);
    expect(first.marks!.counts!.unhelpful, 5);
    expect(first.marks!.mine, ProblemVoteMark.unhelpful);
    expect(first.marks!.own, isTrue);

    final last = actual.items.last;
    expect(last.user, isNull);
    expect(last.level, isNull);
    expect(last.comment, isNull);
    expect(last.commentLanguage, isNull);
    expect(last.emoticonId, isNull);
    expect(last.emoticon, isNull);
    expect(last.tags, isEmpty);
    expect(last.marks, isNull);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.problemVotes(1);
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in _outerFields) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response()..[field] = null;
      if (field == 'markRefusal') {
        expect(endpoint.decode(nulled).markRefusal, isNull);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final field in _voteFields) {
      final missing = _response();
      _vote(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: 'items[].$field missing',
      );
      final nulled = _response();
      _vote(nulled)[field] = null;
      if (_nullableVoteFields.contains(field)) {
        expect(
          _voteValue(endpoint.decode(nulled).items.first, field),
          isNull,
          reason: field,
        );
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: 'items[].$field null',
        );
      }
    }
    for (final field in ['score', 'counts', 'mine', 'own']) {
      final missing = _response();
      (_vote(missing)['marks'] as Map<String, dynamic>).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
    for (final field in ['counts', 'mine']) {
      final nulled = _response();
      (_vote(nulled)['marks'] as Map<String, dynamic>)[field] = null;
      final marks = endpoint.decode(nulled).items.first.marks!;
      expect(field == 'counts' ? marks.counts : marks.mine, isNull);
    }
    for (final field in ['tag', 'legacyKey']) {
      final missing = _response();
      ((_vote(missing)['tags'] as List).first as Map).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
    for (final field in ['key', 'url']) {
      final missing = _response();
      (_vote(missing)['emoticon'] as Map<String, dynamic>).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
    for (final field in ['id', 'handle', 'tier', 'profileImageUrl']) {
      final missing = _response();
      (_vote(missing)['user'] as Map<String, dynamic>).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
  });

  test('enforces exact enums and strict scalar types', () {
    final endpoint = contract.problemVotes(1);
    for (final sort in ProblemVoteSort.values) {
      expect(
        endpoint.decode(_response()..['sort'] = sort.value).sort,
        sort,
      );
    }
    for (final refusal in ProblemVoteMarkRefusal.values) {
      expect(
        endpoint
            .decode(_response()..['markRefusal'] = refusal.value)
            .markRefusal,
        refusal,
      );
    }
    for (final entry in <String, Object?>{
      'sort': 'Recent',
      'markRefusal': 'not_solved',
      'unhelpfulLocked': 'true',
      'total': double.nan,
    }.entries) {
      expect(
        () => endpoint.decode(_response()..[entry.key] = entry.value),
        throwsFormatException,
        reason: entry.key,
      );
    }
    for (final entry in <String, Object?>{
      'id': double.infinity,
      'weight': '1',
      'level': double.nan,
      'votedAt': 0,
      'source': null,
      'comment': 0,
      'cutoff': 1,
    }.entries) {
      final body = _response();
      _vote(body)[entry.key] = entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
    for (final entry in <String, Object?>{
      'score': 1.0,
      'mine': 'Helpful',
      'own': 'yes',
    }.entries) {
      final body = _response();
      (_vote(body)['marks'] as Map<String, dynamic>)[entry.key] = entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
    final counts = _response();
    ((_vote(counts)['marks'] as Map)['counts'] as Map)['helpful'] = 1.0;
    expect(() => endpoint.decode(counts), throwsFormatException);
    final tier = _response();
    (_vote(tier)['user'] as Map<String, dynamic>)['tier'] = 32;
    expect(() => endpoint.decode(tier), throwsFormatException);
    final tag = _response();
    (((_vote(tag)['tags'] as List).first as Map)['tag'] as Map)
        .remove('isMeta');
    expect(() => endpoint.decode(tag), throwsFormatException);
  });

  test('accepts null user tier and image and every mark value', () {
    final endpoint = contract.problemVotes(1);
    final body = _response();
    (_vote(body)['user'] as Map<String, dynamic>)
      ..['tier'] = null
      ..['profileImageUrl'] = null;
    final user = endpoint.decode(body).items.first.user!;
    expect(user.tier, isNull);
    expect(user.profileImageUrl, isNull);

    for (final mark in ProblemVoteMark.values) {
      final marked = _response();
      (_vote(marked)['marks'] as Map<String, dynamic>)['mine'] = mark.value;
      expect(endpoint.decode(marked).items.first.marks!.mine, mark);
    }
  });

  test('eagerly snapshots ordered unmodifiable lists', () {
    final endpoint = contract.problemVotes(1);
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final tags = _vote(body)['tags'] as List<dynamic>;
    final actual = endpoint.decode(body);
    tags.clear();
    items.clear();

    expect(actual.items, hasLength(2));
    expect(actual.items.first.tags, hasLength(3));
    expect(() => actual.items.clear(), throwsUnsupportedError);
    expect(() => actual.items.first.tags.clear(), throwsUnsupportedError);
    expect(
      endpoint
          .decode(_response()
            ..['items'] = <Object?>[]
            ..['future'] = true)
          .items,
      isEmpty,
    );
  });
}

const _outerFields = [
  'items',
  'total',
  'page',
  'pageSize',
  'sort',
  'markRefusal',
  'unhelpfulLocked',
];

const _voteFields = [
  'id',
  'user',
  'votedAt',
  'level',
  'weight',
  'invalidated',
  'notInCalculation',
  'banned',
  'superseded',
  'cutoff',
  'comment',
  'commentLanguage',
  'emoticonId',
  'emoticon',
  'source',
  'tags',
  'isStandard',
  'marks',
];

const _nullableVoteFields = {
  'user',
  'level',
  'comment',
  'commentLanguage',
  'emoticonId',
  'emoticon',
  'marks',
};

Object? _voteValue(ProblemVote vote, String field) => switch (field) {
      'user' => vote.user,
      'level' => vote.level,
      'comment' => vote.comment,
      'commentLanguage' => vote.commentLanguage,
      'emoticonId' => vote.emoticonId,
      'emoticon' => vote.emoticon,
      _ => vote.marks,
    };

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/problem_votes.json')) as Map<String, dynamic>;

Map<String, dynamic> _vote(Map<String, dynamic> body) =>
    (body['items'] as List<dynamic>).first as Map<String, dynamic>;
