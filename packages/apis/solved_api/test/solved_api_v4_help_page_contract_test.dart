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

  test('builds a help page with a required path and optional language', () {
    final omitted = contract.helpPage('a');
    final nested = contract.helpPage('getting-started/tiers-2', language: '');
    final longest = contract.helpPage(List.filled(255, 'a').join());

    expect(omitted.direct.path, 'posts/help/page');
    expect(omitted.direct.queryParameters, {'path': 'a'});
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, {'path': 'a'});
    expect(nested.direct.queryParameters, {
      'lang': '',
      'path': 'getting-started/tiers-2',
    });
    expect(longest.direct.queryParameters['path'], hasLength(255));
  });

  test('rejects paths outside the official pattern and long languages', () {
    for (final path in [
      '',
      'A',
      '/a',
      'a/',
      'a//b',
      '-a',
      'a-/b',
      'a--b',
      'a_b',
      'a b',
      'á',
      'a\n',
      r'a\b',
      List.filled(256, 'a').join(),
    ]) {
      expect(
        () => contract.helpPage(path),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'path')
              .having((error) => error.invalidValue, 'invalidValue', path),
        ),
        reason: path,
      );
    }
    expect(
      () => contract.helpPage('a', language: List.filled(17, 'a').join()),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'language'),
      ),
    );
  });

  test('decodes with the shared strict post decoder', () {
    final endpoint = contract.helpPage('a');
    final body =
        jsonDecode(fixture('v4/post_detail.json')) as Map<String, dynamic>;
    body['board'] = 'help';
    final actual = endpoint.decode(body);

    expect(actual.board, PostBoard.help);
    expect(actual.content['type'], 'doc');
    expect(actual.breadcrumbs, hasLength(2));
    expect(() => actual.breadcrumbs.clear(), throwsUnsupportedError);
    expect(
      () => endpoint.decode(Map<String, dynamic>.of(body)..remove('next')),
      throwsFormatException,
    );
    expect(
      () => endpoint.decode(
        Map<String, dynamic>.of(body)..['content'] = <String, Object?>{},
      ),
      throwsFormatException,
    );
  });
}
