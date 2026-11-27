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

  test('builds notices with omitted and explicit queries', () {
    final omitted = contract.notices();
    final explicit = contract.notices(language: '', page: 1, query: '');
    final bounded = contract.notices(
      language: List.filled(16, '🌏').join(),
      page: 10000,
      query: List.filled(64, '한').join(),
    );

    expect(omitted.direct.path, 'posts/notice');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, 'posts/notice');
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.queryParameters, {
      'lang': '',
      'page': '1',
      'q': '',
    });
    expect(bounded.direct.queryParameters['page'], '10000');
    expect(bounded.proxy.queryParameters, bounded.direct.queryParameters);
  });

  test('rejects out-of-bound languages, pages, and queries', () {
    final cases = <String, void Function()>{
      'language': () => contract.notices(language: List.filled(17, 'a').join()),
      'page': () => contract.notices(page: 0),
      'query': () => contract.notices(query: List.filled(65, 'a').join()),
    };
    for (final MapEntry(key: name, value: call) in cases.entries) {
      expect(
        call,
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', name),
        ),
        reason: name,
      );
    }
    expect(
      () => contract.notices(page: 10001),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'page'),
      ),
    );
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.notices().decode(
          jsonDecode(fixture('v4/notice_list.json')),
        );

    expect(actual.total, -1);
    expect(actual.page, 7);
    expect(actual.perPage, 0);
    final first = actual.items.first;
    expect(first.path, 'notice/first');
    expect(first.language, 'ko');
    expect(first.title, '');
    expect(first.summary, 'raw / 한 글');
    expect(first.publishedAt, 'not a date');
    expect(first.pinned, isTrue);
    expect(first.isNew, isFalse);
    expect(first.coverImageUrl, 'not a URI');
    final last = actual.items.last;
    expect(last.summary, isNull);
    expect(last.coverImageUrl, isNull);
    expect(last.isNew, isTrue);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.notices();
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['items', 'total', 'page', 'perPage']) {
      for (final invalid in <Object?>[_missing, null, 1.0, '1']) {
        final body = _response();
        if (identical(invalid, _missing)) {
          body.remove(field);
        } else {
          body[field] = invalid;
        }
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
    for (final field in _itemFields) {
      final missing = _response();
      _first(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response();
      _first(nulled)[field] = null;
      if (field == 'summary' || field == 'coverImageUrl') {
        final item = endpoint.decode(nulled).items.first;
        expect(
          field == 'summary' ? item.summary : item.coverImageUrl,
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
    for (final entry in <String, Object?>{
      'path': 0,
      'title': false,
      'pinned': 'true',
      'isNew': 1,
      'summary': 0,
    }.entries) {
      final body = _response();
      _first(body)[entry.key] = entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });

  test('eagerly snapshots an ordered unmodifiable list', () {
    final endpoint = contract.notices();
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _first(body)['title'] = 'changed';
    items.clear();

    expect(actual.items, hasLength(2));
    expect(actual.items.first.title, '');
    expect(() => actual.items.clear(), throwsUnsupportedError);
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

const _missing = Object();

const _itemFields = [
  'path',
  'language',
  'title',
  'summary',
  'publishedAt',
  'pinned',
  'isNew',
  'coverImageUrl',
];

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/notice_list.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['items'] as List<dynamic>).first as Map<String, dynamic>;
