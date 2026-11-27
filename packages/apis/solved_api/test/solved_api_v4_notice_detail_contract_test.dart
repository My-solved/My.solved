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

  test('builds a notice with an omitted or explicit language', () {
    final omitted = contract.notice('a');
    final explicit = contract.notice(
      'release-2026-11-27',
      language: '',
    );
    final longest = contract.notice(List.filled(64, 'a').join());

    expect(omitted.direct.path, 'posts/notice/a');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.path, 'posts/notice/release-2026-11-27');
    expect(explicit.direct.queryParameters, {'lang': ''});
    expect(longest.direct.path, 'posts/notice/${List.filled(64, 'a').join()}');
    expect(
      contract
          .notice('a', language: List.filled(16, '🌏').join())
          .direct
          .queryParameters['lang']!
          .runes,
      hasLength(16),
    );
  });

  test('rejects slugs outside the official pattern and long languages', () {
    for (final slug in [
      '',
      'A',
      '-a',
      'a-',
      'a--b',
      'a_b',
      'a/b',
      'a b',
      'á',
      'a\n',
      List.filled(65, 'a').join(),
    ]) {
      expect(
        () => contract.notice(slug),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'slug')
              .having((error) => error.invalidValue, 'invalidValue', slug),
        ),
        reason: slug,
      );
    }
    expect(
      () => contract.notice('a', language: List.filled(17, 'a').join()),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'language'),
      ),
    );
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.notice('a').decode(
          jsonDecode(fixture('v4/post_detail.json')),
        );

    expect(actual.board, PostBoard.notice);
    expect(actual.path, 'notice/first');
    expect(actual.language, 'en');
    expect(actual.languages, ['ko', 'en', 'ko']);
    expect(actual.title, '');
    expect(actual.summary, 'raw / 한 글');
    expect(actual.content['type'], 'doc');
    expect((actual.content['content']! as List).length, 4);
    expect(actual.content['attrs'], {
      'future': [1.5],
    });
    expect(actual.publishedAt, 'not a date');
    expect(actual.updatedAt, '');
    expect(actual.pinned, isTrue);
    expect(actual.coverImageUrl, 'not a URI');
    expect(actual.basisDate, '2026-13-45');
    expect(actual.breadcrumbs.map((link) => link.title), ['Notices', '']);
    expect(actual.previous!.path, 'notice/zero');
    expect(actual.next, isNull);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.notice('a');
    for (final invalid in <Object?>[null, 0, 'post', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in _fields) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response()..[field] = null;
      if (_nullableFields.contains(field)) {
        expect(_value(endpoint.decode(nulled), field), isNull, reason: field);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    final next = _response()
      ..['next'] = <String, Object?>{'path': 'p', 'title': 't'};
    expect(endpoint.decode(next).next!.title, 't');
    for (final field in ['path', 'title']) {
      final link = _response();
      (link['previous'] as Map<String, dynamic>).remove(field);
      expect(() => endpoint.decode(link), throwsFormatException);
      final crumb = _response();
      ((crumb['breadcrumbs'] as List).first as Map).remove(field);
      expect(() => endpoint.decode(crumb), throwsFormatException);
    }
  });

  test('enforces the documented document shape and exact enums', () {
    final endpoint = contract.notice('a');
    for (final board in PostBoard.values) {
      expect(
          endpoint.decode(_response()..['board'] = board.value).board, board);
    }
    for (final invalid in <Object?>['Notice', 'faq', 0]) {
      expect(
        () => endpoint.decode(_response()..['board'] = invalid),
        throwsFormatException,
      );
    }
    for (final content in <Object?>[
      <String, Object?>{},
      <String, Object?>{'type': 'Doc'},
      <String, Object?>{'type': null},
      <String, Object?>{'type': 'doc', 'content': null},
      <String, Object?>{'type': 'doc', 'content': 'text'},
      'doc',
      const <Object?>[],
    ]) {
      expect(
        () => endpoint.decode(_response()..['content'] = content),
        throwsFormatException,
        reason: '$content',
      );
    }
    expect(
      endpoint
          .decode(_response()..['content'] = <String, Object?>{'type': 'doc'})
          .content,
      {'type': 'doc'},
    );
    expect(
      () => endpoint.decode(
        _response()
          ..['content'] = <String, Object?>{
            'type': 'doc',
            'content': <Object?>[double.nan],
          },
      ),
      throwsFormatException,
    );
    for (final entry in <String, Object?>{
      'path': 0,
      'pinned': 'true',
      'languages': <Object?>['ko', 0],
      'summary': 0,
    }.entries) {
      expect(
        () => endpoint.decode(_response()..[entry.key] = entry.value),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });

  test('deeply isolates and freezes nested document nodes', () {
    final endpoint = contract.notice('a');
    final body = _response();
    final content = body['content'] as Map<String, dynamic>;
    final paragraph = (content['content'] as List).first as Map;
    final text = (paragraph['content'] as List).first as Map;
    final marks = text['marks'] as List;
    final future = (content['attrs'] as Map)['future'] as List;
    final actual = endpoint.decode(body);
    text['text'] = 'changed';
    marks.clear();
    future.add(2);

    final decodedParagraph = (actual.content['content']! as List).first as Map;
    final decodedText = (decodedParagraph['content'] as List).first as Map;
    final decodedMarks = decodedText['marks'] as List;
    final decodedFuture = (actual.content['attrs']! as Map)['future'] as List;
    expect(decodedText['text'], 'hello');
    expect(decodedMarks, [
      {'type': 'bold'},
    ]);
    expect(decodedFuture, [1.5]);
    expect(() => decodedText['text'] = 'x', throwsUnsupportedError);
    expect(() => decodedMarks.clear(), throwsUnsupportedError);
    expect(() => (decodedMarks.first as Map)['type'] = 'x',
        throwsUnsupportedError);
    expect(() => decodedFuture.add(2), throwsUnsupportedError);
  });

  test('isolates and freezes lists and the opaque document', () {
    final endpoint = contract.notice('a');
    final body = _response();
    final languages = body['languages'] as List<dynamic>;
    final crumbs = body['breadcrumbs'] as List<dynamic>;
    final nodes = (body['content'] as Map<String, dynamic>)['content'] as List;
    final actual = endpoint.decode(body);
    languages.clear();
    crumbs.clear();
    nodes.clear();

    expect(actual.languages, hasLength(3));
    expect(actual.breadcrumbs, hasLength(2));
    final decodedNodes = actual.content['content']! as List;
    expect(decodedNodes, hasLength(4));
    expect(() => actual.languages.clear(), throwsUnsupportedError);
    expect(() => actual.breadcrumbs.clear(), throwsUnsupportedError);
    expect(() => actual.content['x'] = 1, throwsUnsupportedError);
    expect(() => decodedNodes.clear(), throwsUnsupportedError);
    expect(
      () => (decodedNodes.first as Map)['type'] = 'changed',
      throwsUnsupportedError,
    );
  });
}

const _fields = [
  'board',
  'path',
  'language',
  'languages',
  'title',
  'summary',
  'content',
  'publishedAt',
  'updatedAt',
  'pinned',
  'coverImageUrl',
  'basisDate',
  'breadcrumbs',
  'previous',
  'next',
];

const _nullableFields = {
  'summary',
  'coverImageUrl',
  'basisDate',
  'previous',
  'next',
};

Object? _value(PostDetailResult post, String field) => switch (field) {
      'summary' => post.summary,
      'coverImageUrl' => post.coverImageUrl,
      'basisDate' => post.basisDate,
      'previous' => post.previous,
      _ => post.next,
    };

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/post_detail.json')) as Map<String, dynamic>;
