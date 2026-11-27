import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

void main() {
  late SolvedApiV4Contract contract;

  setUp(() {
    contract = SolvedApiV4Contract(
      proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
    );
  });

  test('builds one bodyless DELETE that succeeds only with no content', () {
    final mutation = contract.deleteBookmarkFolder('z_9');
    final longest = contract.deleteBookmarkFolder(List.filled(32, 'a').join());

    expect(mutation.method, SolvedApiMutationMethod.delete);
    expect(mutation.proxy.path, 'account/bookmarks/z_9');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.jsonBody, isNull);
    expect(mutation.successStatus, 204);
    expect(longest.proxy.path, 'account/bookmarks/${'a' * 32}');
    expect(() => mutation.decode(null), returnsNormally);
  });

  test('rejects slugs outside the official pattern', () {
    for (final slug in [
      '',
      'A',
      'a-b',
      'a b',
      'á',
      'a\n',
      '../a',
      List.filled(33, 'a').join(),
    ]) {
      expect(
        () => contract.deleteBookmarkFolder(slug),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'slug')
              .having((error) => error.invalidValue, 'invalidValue', slug),
        ),
        reason: slug,
      );
    }
  });

  test('keeps earlier mutations on a 200 success status', () {
    expect(
      contract
          .updateAccountSettings(const AccountSettingsPatch())
          .successStatus,
      200,
    );
    expect(contract.addBookmarkFavorite('a', 'b').successStatus, 200);
    expect(contract.removeBookmarkFavorite('a', 'b').successStatus, 200);
  });
}
