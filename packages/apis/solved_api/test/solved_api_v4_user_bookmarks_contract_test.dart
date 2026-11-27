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

  test('builds user bookmarks with omitted and explicit pages', () {
    final omitted = contract.userBookmarks('alice');
    final first = contract.userBookmarks('alice', page: 1);
    final last = contract.userBookmarks('a b&한', page: 10000);

    expect(omitted.direct.path, 'users/alice/bookmarks');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(first.direct.queryParameters, {'page': '1'});
    expect(last.direct.path, 'users/a%20b%26%ED%95%9C/bookmarks');
    expect(last.direct.queryParameters, {'page': '10000'});
    expect(last.proxy.queryParameters, last.direct.queryParameters);
  });

  test('rejects unsafe handles and pages outside 1..10000', () {
    for (final handle in ['', '.', '..', 'a/b', List.filled(65, 'a').join()]) {
      expect(
        () => contract.userBookmarks(handle),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'handle'),
        ),
        reason: handle,
      );
    }
    for (final page in [0, -1, 10001]) {
      expect(
        () => contract.userBookmarks('alice', page: page),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'page')
              .having((error) => error.invalidValue, 'invalidValue', page),
        ),
      );
    }
  });

  test('decodes with the shared strict bookmark-folder decoder', () {
    final endpoint = contract.userBookmarks('alice');
    final actual = endpoint.decode(
      jsonDecode(fixture('v4/bookmark_folders.json')),
    );

    expect(actual.total, -3);
    expect(actual.page, 2.0);
    expect(actual.folders.map((folder) => folder.slug), [
      'dp_set',
      'Not A Request Slug',
    ]);
    expect(actual.folders.last.visibility, BookmarkFolderVisibility.unlisted);
    expect(actual.folders.last.color, isNull);
    expect(() => actual.folders.clear(), throwsUnsupportedError);

    final body =
        jsonDecode(fixture('v4/bookmark_folders.json')) as Map<String, dynamic>;
    final folder = (body['folders'] as List<dynamic>).first;
    (folder as Map<String, dynamic>).remove('color');
    expect(() => endpoint.decode(body), throwsFormatException);
  });
}
