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

  test('builds one bodyless POST with encoded path segments', () {
    final mutation = contract.addBookmarkFavorite('a b', 'z_9');
    final longest = contract.addBookmarkFavorite(
      List.filled(64, '한').join(),
      List.filled(32, 'a').join(),
    );

    expect(mutation.method, SolvedApiMutationMethod.post);
    expect(mutation.proxy.path, 'account/bookmark-favorites/a%20b/z_9');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.jsonBody, isNull);
    expect(longest.proxy.path, startsWith('account/bookmark-favorites/'));
  });

  test('rejects path parameters outside the official limits', () {
    for (final handle in ['', '.', '..', 'a/b', List.filled(65, 'a').join()]) {
      expect(
        () => contract.addBookmarkFavorite(handle, 'a'),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'handle'),
        ),
        reason: handle,
      );
    }
    for (final slug in [
      '',
      'A',
      'a-b',
      'a b',
      'á',
      'a\n',
      List.filled(33, 'a').join(),
    ]) {
      expect(
        () => contract.addBookmarkFavorite('a', slug),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'slug'),
        ),
        reason: slug,
      );
    }
  });

  test('decodes the favorite state strictly', () {
    final decode = contract.addBookmarkFavorite('a', 'b').decode;
    final actual =
        decode(jsonDecode(fixture('v4/bookmark_favorite_state.json')));

    expect(actual.isFavorite, isFalse);
    expect(actual.favoriteCount, -1.5);
    expect(
      decode(<String, Object?>{'isFavorite': true, 'favoriteCount': 3})
          .favoriteCount,
      3,
    );
    for (final invalid in <Object?>[null, 0, 'state', const <Object?>[]]) {
      expect(() => decode(invalid), throwsFormatException);
    }
    for (final body in <Map<String, Object?>>[
      {'favoriteCount': 1},
      {'isFavorite': true},
      {'isFavorite': null, 'favoriteCount': 1},
      {'isFavorite': true, 'favoriteCount': null},
      {'isFavorite': 'true', 'favoriteCount': 1},
      {'isFavorite': true, 'favoriteCount': '1'},
    ]) {
      expect(() => decode(body), throwsFormatException, reason: '$body');
    }
  });
}
