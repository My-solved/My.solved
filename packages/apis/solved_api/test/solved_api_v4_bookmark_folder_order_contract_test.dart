import 'dart:convert';

import 'package:solved_api/solved_api.dart';
import 'package:test/test.dart';

void main() {
  late SolvedApiV4Contract contract;

  setUp(() {
    contract = SolvedApiV4Contract(
      proxyBaseUri: Uri.parse('https://proxy.example/solved/v4/'),
    );
  });

  test('builds one POST with the slugs in order and duplicates kept', () {
    final mutation = contract.reorderBookmarkFolders(['b', 'a_1', 'b']);

    expect(mutation.method, SolvedApiMutationMethod.post);
    expect(mutation.proxy.path, 'account/bookmarks/order');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.successStatus, 204);
    expect(mutation.jsonBody, '{"slugs":["b","a_1","b"]}');
    expect(() => mutation.decode(null), returnsNormally);
  });

  test('accepts 1 through 20 slugs', () {
    for (final count in [1, 20]) {
      final slugs = [for (var i = 0; i < count; i++) 's$i'];
      expect(
        jsonDecode(contract.reorderBookmarkFolders(slugs).jsonBody!),
        {'slugs': slugs},
      );
    }
  });

  test('snapshots the slugs when the mutation is built', () {
    final slugs = ['a', 'b'];
    final mutation = contract.reorderBookmarkFolders(slugs);
    slugs.add('c');

    expect(mutation.jsonBody, '{"slugs":["a","b"]}');
  });

  test('rejects counts and slugs outside the official limits', () {
    for (final slugs in [
      <String>[],
      [for (var i = 0; i < 21; i++) 's$i'],
      ['a', 'A'],
      ['a', ''],
      ['a b'],
      ['a\n'],
      [List.filled(33, 'a').join()],
    ]) {
      expect(
        () => contract.reorderBookmarkFolders(slugs),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'slugs'),
        ),
        reason: '$slugs',
      );
    }
  });
}
