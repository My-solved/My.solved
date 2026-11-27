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

  test('builds one POST with the ids in order and duplicates kept', () {
    final mutation = contract.addBookmarkProblems('z_9', [1000, 1, 1000]);

    expect(mutation.method, SolvedApiMutationMethod.post);
    expect(mutation.proxy.path, 'account/bookmarks/z_9/problems');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.successStatus, 200);
    expect(mutation.jsonBody, '{"problemIds":[1000,1,1000]}');
  });

  test('accepts 1 through 100 ids and snapshots the list', () {
    for (final count in [1, 100]) {
      final ids = [for (var i = 1; i <= count; i++) i];
      expect(
        jsonDecode(contract.addBookmarkProblems('a', ids).jsonBody!),
        {'problemIds': ids},
      );
    }
    final ids = [1, 2];
    final mutation = contract.addBookmarkProblems('a', ids);
    ids.add(3);
    expect(mutation.jsonBody, '{"problemIds":[1,2]}');
  });

  test('rejects arguments outside the official limits', () {
    for (final (slug, ids, field) in [
      ('A', [1], 'slug'),
      ('', [1], 'slug'),
      ('a', <int>[], 'problemIds'),
      ('a', [for (var i = 1; i <= 101; i++) i], 'problemIds'),
      ('a', [1, 0], 'problemIds'),
      ('a', [-1], 'problemIds'),
    ]) {
      expect(
        () => contract.addBookmarkProblems(slug, ids),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', field),
        ),
        reason: '$slug $ids',
      );
    }
  });

  test('decodes the folder and change count strictly', () {
    final decode = contract.addBookmarkProblems('a', [1]).decode;
    final body = _response();

    final actual = decode(body);

    expect(actual.changed, -0.5);
    expect(
      actual.folder.slug,
      (body['folder'] as Map<String, dynamic>)['slug'],
    );
    expect(
      decode(_response()..['changed'] = 0).changed,
      0,
    );
    for (final invalid in <Object?>[null, 0, 'change', const <Object?>[]]) {
      expect(() => decode(invalid), throwsFormatException);
    }
    for (final field in ['folder', 'changed']) {
      expect(
        () => decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      expect(
        () => decode(_response()..[field] = null),
        throwsFormatException,
        reason: '$field null',
      );
    }
    expect(
      () => decode(_response()..['changed'] = '1'),
      throwsFormatException,
    );
    final folder = _response();
    (folder['folder'] as Map<String, dynamic>).remove('owner');
    expect(() => decode(folder), throwsFormatException);
  });
}

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/bookmark_folder_change.json'))
        as Map<String, dynamic>;
