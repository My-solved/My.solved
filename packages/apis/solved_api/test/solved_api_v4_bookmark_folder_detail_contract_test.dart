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

  test('builds folder detail with omitted and explicit queries', () {
    final omitted = contract.bookmarkFolderDetail('alice', 'dp_set');
    final explicit = contract.bookmarkFolderDetail(
      'a b&한',
      List.filled(32, 'z').join(),
      page: 1,
      sort: SolvedApiV4BookmarkProblemSort.order,
      direction: SolvedApiV4SearchDirection.asc,
      query: '',
    );
    final bounded = contract.bookmarkFolderDetail(
      'alice',
      '0',
      page: 10000,
      sort: SolvedApiV4BookmarkProblemSort.averageTry,
      direction: SolvedApiV4SearchDirection.desc,
      query: List.filled(512, '🌏').join(),
    );

    expect(omitted.direct.path, 'users/alice/bookmarks/dp_set');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(
      explicit.direct.path,
      'users/a%20b%26%ED%95%9C/bookmarks/${List.filled(32, 'z').join()}',
    );
    expect(explicit.direct.queryParameters, {
      'page': '1',
      'sort': 'order',
      'direction': 'asc',
      'q': '',
    });
    expect(bounded.direct.queryParameters['page'], '10000');
    expect(bounded.direct.queryParameters['sort'], 'average_try');
    expect(bounded.direct.queryParameters['direction'], 'desc');
    expect(bounded.direct.queryParameters['q']!.runes, hasLength(512));
    expect(bounded.proxy.queryParameters, bounded.direct.queryParameters);
    expect(SolvedApiV4BookmarkProblemSort.values.map((sort) => sort.value), [
      'order',
      'level',
      'solved',
      'average_try',
      'id',
    ]);
  });

  test('rejects invalid handles, slugs, pages, and queries', () {
    expect(
      () => contract.bookmarkFolderDetail('a/b', 'dp'),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'handle'),
      ),
    );
    for (final slug in [
      '',
      'DP',
      'dp-set',
      'dp set',
      'dp/set',
      '..',
      List.filled(33, 'a').join(),
      'á',
      'dp\n',
    ]) {
      expect(
        () => contract.bookmarkFolderDetail('alice', slug),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'slug')
              .having((error) => error.invalidValue, 'invalidValue', slug),
        ),
        reason: slug,
      );
    }
    for (final page in [0, -1, 10001]) {
      expect(
        () => contract.bookmarkFolderDetail('alice', 'dp', page: page),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'page'),
        ),
      );
    }
    expect(
      () => contract.bookmarkFolderDetail(
        'alice',
        'dp',
        query: List.filled(513, 'a').join(),
      ),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'query'),
      ),
    );
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.bookmarkFolderDetail('alice', 'dp').decode(
          jsonDecode(fixture('v4/bookmark_folder_detail.json')),
        );

    expect(actual.folder.slug, 'dp_set');
    expect(actual.folder.owner.handle, 'folder-owner');
    expect(actual.isOwner, isFalse);
    expect(actual.isFavorite, isNull);
    expect(actual.total, -1);
    expect(actual.page, 7);
    expect(actual.pageSize, 30.5);
    expect(actual.levels.map((level) => level.level), [0, -1, 0]);
    expect(actual.levels.first.count, 2.5);
    expect(actual.levels.first.solved, isNull);
    expect(actual.levels[1].solved, 3);
    expect(actual.problems.map((item) => item.problem.problemId), [
      1001,
      1002,
      1001,
    ]);
    expect(actual.problems.map((item) => item.note), [
      null,
      '',
      'raw / 한 글',
    ]);
    expect(actual.problems.first.addedAt, 'not a date');
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.bookmarkFolderDetail('alice', 'dp');
    for (final invalid in <Object?>[null, 0, 'folder', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in _outerFields) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response()..[field] = null;
      if (field == 'isFavorite') {
        expect(endpoint.decode(nulled).isFavorite, isNull);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final value in [true, false]) {
      final actual = endpoint.decode(
        _response()
          ..['isOwner'] = value
          ..['isFavorite'] = value,
      );
      expect(actual.isOwner, value);
      expect(actual.isFavorite, value);
    }
    for (final invalid in <Object?>[0, 'true']) {
      for (final field in ['isOwner', 'isFavorite']) {
        expect(
          () => endpoint.decode(_response()..[field] = invalid),
          throwsFormatException,
        );
      }
    }

    for (final field in ['level', 'count', 'solved']) {
      final missing = _response();
      _first(missing, 'levels').remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
    for (final field in ['level', 'count']) {
      final nulled = _response();
      _first(nulled, 'levels')[field] = null;
      expect(() => endpoint.decode(nulled), throwsFormatException);
    }
    for (final field in ['problem', 'note', 'addedAt']) {
      final missing = _response();
      _first(missing, 'problems').remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
    for (final field in ['problem', 'addedAt']) {
      final nulled = _response();
      _first(nulled, 'problems')[field] = null;
      expect(() => endpoint.decode(nulled), throwsFormatException);
    }
    final folderMissing = _response();
    (folderMissing['folder'] as Map<String, dynamic>).remove('visibility');
    expect(() => endpoint.decode(folderMissing), throwsFormatException);
    final problemMissing = _response();
    (_first(problemMissing, 'problems')['problem'] as Map<String, dynamic>)
        .remove('viewerFolders');
    expect(() => endpoint.decode(problemMissing), throwsFormatException);
  });

  test('enforces finite numbers and strict strings', () {
    final endpoint = contract.bookmarkFolderDetail('alice', 'dp');
    for (final field in ['total', 'page', 'pageSize']) {
      for (final invalid in <Object?>[double.nan, '1', false]) {
        expect(
          () => endpoint.decode(_response()..[field] = invalid),
          throwsFormatException,
        );
      }
    }
    for (final field in ['level', 'count', 'solved']) {
      final body = _response();
      _first(body, 'levels')[field] = double.infinity;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final field in ['note', 'addedAt']) {
      final body = _response();
      _first(body, 'problems')[field] = 0;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
  });

  test('eagerly snapshots ordered unmodifiable lists', () {
    final endpoint = contract.bookmarkFolderDetail('alice', 'dp');
    final body = _response();
    final levels = body['levels'] as List<dynamic>;
    final problems = body['problems'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _first(body, 'problems')['note'] = 'changed';
    levels.clear();
    problems.clear();

    expect(actual.levels, hasLength(3));
    expect(actual.problems, hasLength(3));
    expect(actual.problems.first.note, isNull);
    expect(() => actual.levels.clear(), throwsUnsupportedError);
    expect(() => actual.problems.clear(), throwsUnsupportedError);
    final empty = endpoint.decode(
      _response()
        ..['levels'] = <Object?>[]
        ..['problems'] = <Object?>[]
        ..['future'] = true,
    );
    expect(empty.levels, isEmpty);
    expect(empty.problems, isEmpty);
  });
}

const _outerFields = [
  'folder',
  'isOwner',
  'isFavorite',
  'levels',
  'problems',
  'total',
  'page',
  'pageSize',
];

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/bookmark_folder_detail.json'))
        as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body, String field) =>
    (body[field] as List<dynamic>).first as Map<String, dynamic>;
