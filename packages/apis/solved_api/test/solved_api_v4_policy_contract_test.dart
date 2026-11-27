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

  test('builds every policy slug with an omitted or explicit language', () {
    expect(PolicySlug.values.map((slug) => slug.value), [
      'tos',
      'tos_recurring',
      'privacy',
      'chrome_privacy',
      'guideline',
      'rules',
      'developer_terms',
      'partner_terms',
    ]);
    for (final slug in PolicySlug.values) {
      final endpoint = contract.policy(slug);
      expect(endpoint.direct.path, 'policies/${slug.value}');
      expect(endpoint.direct.queryParameters, isEmpty);
      expect(endpoint.proxy.path, endpoint.direct.path);
    }
    expect(
      contract.policy(PolicySlug.tos, language: '').direct.queryParameters,
      {'lang': ''},
    );
    expect(
      () => contract.policy(
        PolicySlug.tos,
        language: List.filled(17, 'a').join(),
      ),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'language'),
      ),
    );
  });

  test('decodes the complete markdown fixture without inference', () {
    final actual = contract.policy(PolicySlug.tos).decode(
          jsonDecode(fixture('v4/policy.json')),
        );

    expect(actual.slug, PolicySlug.privacy);
    expect(actual.version, '20240714');
    expect(actual.label, 'v3');
    expect(actual.announcedAt, isNull);
    expect(actual.effectiveAt, 'not a date');
    expect(actual.language, 'en');
    expect(actual.title, '');
    expect(
      (actual.content as PolicyMarkdownContent).body,
      '# raw / 한 글\n<script>not sanitized</script>',
    );
    expect(actual.revisedAt, '2026-13-45');
    expect(actual.isCurrent, isFalse);
    expect(actual.currentLabel, 'v4');
    expect(actual.versions.map((version) => version.version), [
      'beta',
      '20240714',
      'beta',
    ]);
    expect(actual.versions.first.announcedAt, 'x');
    expect(actual.versions[1].announcedAt, isNull);
  });

  test('discriminates markdown and tiptap content exactly', () {
    final endpoint = contract.policy(PolicySlug.tos);
    final tiptap = endpoint
        .decode(
          _response()
            ..['content'] = <String, Object?>{
              'format': 'tiptap',
              'doc': <String, Object?>{
                'type': 'doc',
                'content': <Object?>[
                  <String, Object?>{'type': 'text'},
                ],
              },
              'body': 'ignored',
            },
        )
        .content as PolicyTiptapContent;
    expect(tiptap.doc['type'], 'doc');
    expect(() => tiptap.doc['x'] = 1, throwsUnsupportedError);
    expect(
      () => ((tiptap.doc['content']! as List).first as Map)['type'] = 'x',
      throwsUnsupportedError,
    );

    for (final content in <Object?>[
      null,
      'markdown',
      <String, Object?>{'body': 'x'},
      <String, Object?>{'format': 'Markdown', 'body': 'x'},
      <String, Object?>{'format': 'html', 'body': 'x'},
      <String, Object?>{'format': 'markdown'},
      <String, Object?>{'format': 'markdown', 'body': null},
      <String, Object?>{'format': 'tiptap'},
      <String, Object?>{'format': 'tiptap', 'body': 'x'},
      <String, Object?>{
        'format': 'tiptap',
        'doc': <String, Object?>{'type': 'paragraph'},
      },
      <String, Object?>{
        'format': 'tiptap',
        'doc': <String, Object?>{'type': 'doc', 'content': 'x'},
      },
    ]) {
      expect(
        () => endpoint.decode(_response()..['content'] = content),
        throwsFormatException,
        reason: '$content',
      );
    }
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.policy(PolicySlug.tos);
    for (final invalid in <Object?>[null, 0, 'policy', const <Object?>[]]) {
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
        final actual = endpoint.decode(nulled);
        expect(
          switch (field) {
            'announcedAt' => actual.announcedAt,
            'revisedAt' => actual.revisedAt,
            _ => actual.currentLabel,
          },
          isNull,
          reason: field,
        );
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    expect(
      endpoint.decode(_response()..['announcedAt'] = 'set').announcedAt,
      'set',
    );
    for (final field in ['version', 'label', 'announcedAt', 'effectiveAt']) {
      final missing = _response();
      ((missing['versions'] as List).first as Map).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
    for (final slug in PolicySlug.values) {
      expect(endpoint.decode(_response()..['slug'] = slug.value).slug, slug);
    }
    for (final entry in <String, Object?>{
      'slug': 'TOS',
      'isCurrent': 'false',
      'version': 1,
      'currentLabel': 0,
    }.entries) {
      expect(
        () => endpoint.decode(_response()..[entry.key] = entry.value),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });

  test('eagerly snapshots ordered unmodifiable versions', () {
    final endpoint = contract.policy(PolicySlug.tos);
    final body = _response();
    final versions = body['versions'] as List<dynamic>;
    final actual = endpoint.decode(body);
    versions.clear();

    expect(actual.versions, hasLength(3));
    expect(() => actual.versions.clear(), throwsUnsupportedError);
    expect(
      endpoint
          .decode(_response()
            ..['versions'] = <Object?>[]
            ..['future'] = true)
          .versions,
      isEmpty,
    );
  });
}

const _fields = [
  'slug',
  'version',
  'label',
  'announcedAt',
  'effectiveAt',
  'language',
  'title',
  'content',
  'revisedAt',
  'isCurrent',
  'currentLabel',
  'versions',
];

const _nullableFields = {'announcedAt', 'revisedAt', 'currentLabel'};

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/policy.json')) as Map<String, dynamic>;
