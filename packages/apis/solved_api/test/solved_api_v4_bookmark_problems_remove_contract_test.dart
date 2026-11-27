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

  test('builds one POST on the remove path with the shared id body', () {
    final mutation = contract.removeBookmarkProblems('z_9', [1000, 1, 1000]);

    expect(mutation.method, SolvedApiMutationMethod.post);
    expect(mutation.proxy.path, 'account/bookmarks/z_9/problems/remove');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.successStatus, 200);
    expect(mutation.jsonBody, '{"problemIds":[1000,1,1000]}');
    expect(
      mutation.jsonBody,
      contract.addBookmarkProblems('z_9', [1000, 1, 1000]).jsonBody,
    );
  });

  test('applies the same argument limits', () {
    for (final count in [1, 100]) {
      expect(
        () => contract.removeBookmarkProblems(
          'a',
          [for (var i = 1; i <= count; i++) i],
        ),
        returnsNormally,
      );
    }
    for (final (slug, ids, field) in [
      ('A', [1], 'slug'),
      ('a', <int>[], 'problemIds'),
      ('a', [for (var i = 1; i <= 101; i++) i], 'problemIds'),
      ('a', [0], 'problemIds'),
    ]) {
      expect(
        () => contract.removeBookmarkProblems(slug, ids),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', field),
        ),
        reason: '$slug $ids',
      );
    }
  });

  test('decodes with the shared strict folder-change decoder', () {
    final decode = contract.removeBookmarkProblems('a', [1]).decode;
    final body = jsonDecode(fixture('v4/bookmark_folder_change.json'))
        as Map<String, dynamic>;

    expect(decode(body).changed, -0.5);
    expect(
      () => decode(Map<String, dynamic>.of(body)..remove('changed')),
      throwsFormatException,
    );
  });
}
