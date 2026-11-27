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

  test('builds public bookmarks with omitted and explicit queries', () {
    final omitted = contract.publicBookmarks();
    final explicit = contract.publicBookmarks(
      page: 1,
      sort: SolvedApiV4BookmarkSort.updated,
      query: '',
    );
    final bounded = contract.publicBookmarks(
      page: 10000,
      sort: SolvedApiV4BookmarkSort.problems,
      query: List<String>.filled(100, '🌏').join(),
    );

    expect(omitted.direct.path, 'bookmarks');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, 'bookmarks');
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.queryParameters, {
      'page': '1',
      'sort': 'updated',
      'q': '',
    });
    expect(bounded.direct.queryParameters['page'], '10000');
    expect(bounded.direct.queryParameters['sort'], 'problems');
    expect(bounded.direct.queryParameters['q']!.runes, hasLength(100));
    expect(bounded.proxy.queryParameters, bounded.direct.queryParameters);
    expect(SolvedApiV4BookmarkSort.values.map((sort) => sort.value), [
      'updated',
      'problems',
    ]);
  });

  test('rejects pages outside 1..10000 and queries over 100 code points', () {
    for (final page in [0, -1, 10001]) {
      expect(
        () => contract.publicBookmarks(page: page),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'page')
              .having((error) => error.invalidValue, 'invalidValue', page),
        ),
      );
    }
    final query = List<String>.filled(101, 'a').join();
    expect(
      () => contract.publicBookmarks(query: query),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'query'),
      ),
    );
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.publicBookmarks().decode(
          jsonDecode(fixture('v4/bookmark_folders.json')),
        );

    expect(actual.total, -3);
    expect(actual.page, 2.0);
    expect(actual.page, isA<double>());
    expect(actual.pageSize, 0);
    expect(actual.folders, hasLength(2));

    final first = actual.folders.first;
    expect(first.slug, 'dp_set');
    expect(first.name, 'DP practice');
    expect(first.description, '');
    expect(first.color, ProblemSearchViewerFolderColor.teal);
    expect(first.visibility, BookmarkFolderVisibility.public);
    expect(first.problemCount, 12);
    expect(first.favoriteCount, -1);
    expect(first.solvedCount, 2.5);
    expect(first.owner.id, 1.5);
    expect(first.owner.handle, 'folder-owner');
    expect(first.owner.tier, 31);
    expect(first.owner.profileImageUrl, 'not necessarily a URI');
    expect(first.createdAt, 'not a date');
    expect(first.updatedAt, '2026-01-01T00:00:00Z');

    final last = actual.folders.last;
    expect(last.slug, 'Not A Request Slug');
    expect(last.description, 'raw / 한 글');
    expect(last.color, isNull);
    expect(last.visibility, BookmarkFolderVisibility.unlisted);
    expect(last.solvedCount, isNull);
    expect(last.owner.id, isA<int>());
    expect(last.owner.tier, isNull);
    expect(last.owner.profileImageUrl, isNull);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.publicBookmarks();
    for (final invalid in <Object?>[null, 0, 'folders', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['folders', 'total', 'page', 'pageSize']) {
      for (final invalid in <Object?>[_missing, null, '1', double.nan]) {
        final body = _response();
        _mutate(body, field, invalid);
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    for (final field in _folderFields) {
      final missing = _response();
      _firstFolder(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response();
      _firstFolder(nulled)[field] = null;
      if (field == 'color' || field == 'solvedCount') {
        final folder = endpoint.decode(nulled).folders.first;
        expect(
          field == 'color' ? folder.color : folder.solvedCount,
          isNull,
        );
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final field in ['id', 'handle', 'tier', 'profileImageUrl']) {
      final missing = _response();
      (_firstFolder(missing)['owner'] as Map<String, dynamic>).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: 'owner.$field missing',
      );
    }
    for (final field in ['id', 'handle']) {
      final nulled = _response();
      (_firstFolder(nulled)['owner'] as Map<String, dynamic>)[field] = null;
      expect(() => endpoint.decode(nulled), throwsFormatException);
    }
  });

  test('enforces strict types, exact enums, and only the tier bounds', () {
    final endpoint = contract.publicBookmarks();
    for (final field in ['problemCount', 'favoriteCount', 'solvedCount']) {
      for (final invalid in <Object?>[double.infinity, '1', false]) {
        final body = _response();
        _firstFolder(body)[field] = invalid;
        expect(() => endpoint.decode(body), throwsFormatException);
      }
    }
    for (final field in [
      'slug',
      'name',
      'description',
      'createdAt',
      'updatedAt',
    ]) {
      final body = _response();
      _firstFolder(body)[field] = 0;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final visibility in BookmarkFolderVisibility.values) {
      final body = _response();
      _firstFolder(body)['visibility'] = visibility.value;
      expect(endpoint.decode(body).folders.first.visibility, visibility);
    }
    for (final invalid in <Object?>['Public', 'hidden', '', null]) {
      final body = _response();
      _firstFolder(body)['visibility'] = invalid;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final color in ProblemSearchViewerFolderColor.values) {
      final body = _response();
      _firstFolder(body)['color'] = color.value;
      expect(endpoint.decode(body).folders.first.color, color);
    }
    for (final invalid in <Object?>['Red', 'green', '', 0]) {
      final body = _response();
      _firstFolder(body)['color'] = invalid;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final tier in <Object?>[-1, 32, 1.0]) {
      final body = _response();
      (_firstFolder(body)['owner'] as Map<String, dynamic>)['tier'] = tier;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final tier in [0, 31]) {
      final body = _response();
      (_firstFolder(body)['owner'] as Map<String, dynamic>)['tier'] = tier;
      expect(endpoint.decode(body).folders.first.owner.tier, tier);
    }
  });

  test('eagerly snapshots an ordered duplicate unmodifiable list', () {
    final endpoint = contract.publicBookmarks();
    final body = _response();
    final folders = body['folders'] as List<dynamic>;
    folders.add(folders.first);
    final actual = endpoint.decode(body);
    _firstFolder(body)['name'] = 'changed';
    folders.clear();

    expect(actual.folders.map((folder) => folder.name), [
      'DP practice',
      '',
      'DP practice',
    ]);
    expect(() => actual.folders.clear(), throwsUnsupportedError);
    expect(
      endpoint
          .decode(_response()
            ..['folders'] = <Object?>[]
            ..['future'] = true)
          .folders,
      isEmpty,
    );
  });
}

const _missing = Object();

const _folderFields = [
  'slug',
  'name',
  'description',
  'color',
  'visibility',
  'problemCount',
  'favoriteCount',
  'solvedCount',
  'owner',
  'createdAt',
  'updatedAt',
];

void _mutate(Map<String, dynamic> body, String field, Object? value) {
  if (identical(value, _missing)) {
    body.remove(field);
  } else {
    body[field] = value;
  }
}

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/bookmark_folders.json')) as Map<String, dynamic>;

Map<String, dynamic> _firstFolder(Map<String, dynamic> body) =>
    (body['folders'] as List<dynamic>).first as Map<String, dynamic>;
