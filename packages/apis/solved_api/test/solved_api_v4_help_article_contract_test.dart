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

  test('builds a help article with an omitted or unbounded language', () {
    final omitted = contract.helpArticle('a');
    final explicit = contract.helpArticle('getting-started', language: '');
    final unbounded = contract.helpArticle(
      List.filled(128, 'a').join(),
      language: List.filled(100, '🌏').join(),
    );

    expect(omitted.direct.path, 'help/a');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.path, 'help/getting-started');
    expect(explicit.direct.queryParameters, {'lang': ''});
    expect(unbounded.direct.queryParameters['lang']!.runes, hasLength(100));
    expect(unbounded.direct.path, 'help/${List.filled(128, 'a').join()}');
  });

  test('rejects slugs outside the official pattern', () {
    for (final slug in [
      '',
      'A',
      '-a',
      'a-',
      'a--b',
      'a/b',
      'a_b',
      'á',
      'a\n',
      List.filled(129, 'a').join(),
    ]) {
      expect(
        () => contract.helpArticle(slug),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'slug')
              .having((error) => error.invalidValue, 'invalidValue', slug),
        ),
        reason: slug,
      );
    }
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.helpArticle('a').decode(
          jsonDecode(fixture('v4/help_article.json')),
        );

    expect(actual.slug, 'other-slug');
    expect(actual.language, 'en');
    expect(actual.title, '');
    expect(actual.updatedAt, 'not a date');
    expect(actual.content['type'], 'doc');
    expect(actual.content['future'], isTrue);
    expect(actual.content['content'], [
      {
        'type': 'heading',
        'attrs': {'level': 1},
      },
      null,
    ]);
  });

  test('requires every field and the documented document shape', () {
    final endpoint = contract.helpArticle('a');
    for (final invalid in <Object?>[null, 0, 'article', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['slug', 'language', 'title', 'content', 'updatedAt']) {
      for (final invalid in <Object?>[_missing, null, 0]) {
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
    for (final content in <Object?>[
      <String, Object?>{},
      <String, Object?>{'type': 'paragraph'},
      <String, Object?>{'type': 'doc', 'content': 'text'},
      <String, Object?>{'type': 'doc', 'content': null},
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
  });

  test('deeply isolates and freezes the opaque document', () {
    final endpoint = contract.helpArticle('a');
    final body = _response();
    final nodes = (body['content'] as Map<String, dynamic>)['content'] as List;
    final attrs = (nodes.first as Map<String, dynamic>)['attrs'] as Map;
    final actual = endpoint.decode(body);
    attrs['level'] = 9;
    nodes.clear();

    final decodedNodes = actual.content['content']! as List;
    final decodedAttrs = (decodedNodes.first as Map)['attrs'] as Map;
    expect(decodedNodes, hasLength(2));
    expect(decodedAttrs['level'], 1);
    expect(() => actual.content['x'] = 1, throwsUnsupportedError);
    expect(() => decodedNodes.clear(), throwsUnsupportedError);
    expect(() => decodedAttrs['level'] = 2, throwsUnsupportedError);
  });
}

const _missing = Object();

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/help_article.json')) as Map<String, dynamic>;
