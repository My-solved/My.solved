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

  test('builds one bodyless DELETE on the favorite path', () {
    final mutation = contract.removeBookmarkFavorite('a b', 'z_9');

    expect(mutation.method, SolvedApiMutationMethod.delete);
    expect(mutation.method.value, 'DELETE');
    expect(
      mutation.proxy.path,
      contract.addBookmarkFavorite('a b', 'z_9').proxy.path,
    );
    expect(mutation.proxy.path, 'account/bookmark-favorites/a%20b/z_9');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.jsonBody, isNull);
  });

  test('applies the same path parameter limits', () {
    for (final (handle, slug, name) in [
      ('', 'a', 'handle'),
      (List.filled(65, 'a').join(), 'a', 'handle'),
      ('a/b', 'a', 'handle'),
      ('a', '', 'slug'),
      ('a', 'A', 'slug'),
      ('a', List.filled(33, 'a').join(), 'slug'),
    ]) {
      expect(
        () => contract.removeBookmarkFavorite(handle, slug),
        throwsA(
            isA<ArgumentError>().having((error) => error.name, 'name', name)),
        reason: '$handle/$slug',
      );
    }
  });

  test('decodes with the shared strict favorite-state decoder', () {
    final decode = contract.removeBookmarkFavorite('a', 'b').decode;
    final actual =
        decode(jsonDecode(fixture('v4/bookmark_favorite_state.json')));

    expect(actual.isFavorite, isFalse);
    expect(actual.favoriteCount, -1.5);
    expect(
      () => decode(<String, Object?>{'isFavorite': false}),
      throwsFormatException,
    );
  });
}
