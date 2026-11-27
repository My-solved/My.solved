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

  test('builds one PATCH with an empty object for an empty patch', () {
    final mutation = contract.updateBookmarkFolder(
      'z_9',
      const BookmarkFolderPatch(),
    );

    expect(mutation.method, SolvedApiMutationMethod.patch);
    expect(mutation.proxy.path, 'account/bookmarks/z_9');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.successStatus, 200);
    expect(mutation.jsonBody, '{}');
  });

  test('wires every field to its own key', () {
    for (final (patch, body) in <(BookmarkFolderPatch, Map<String, Object?>)>[
      (const BookmarkFolderPatch(slug: 'new_1'), {'slug': 'new_1'}),
      (const BookmarkFolderPatch(name: '한'), {'name': '한'}),
      (const BookmarkFolderPatch(description: ''), {'description': ''}),
      (
        const BookmarkFolderPatch(
          color: NullablePatch.value(ProblemSearchViewerFolderColor.teal),
        ),
        {'color': 'teal'},
      ),
      (
        const BookmarkFolderPatch(color: NullablePatch.toNull()),
        {'color': null},
      ),
      (
        const BookmarkFolderPatch(
          visibility: BookmarkFolderVisibility.unlisted,
        ),
        {'visibility': 'unlisted'},
      ),
    ]) {
      expect(
        jsonDecode(contract.updateBookmarkFolder('a', patch).jsonBody!),
        body,
      );
    }
    expect(
      contract
          .updateBookmarkFolder(
            'a',
            const BookmarkFolderPatch(
              slug: 'b',
              name: 'n',
              description: 'd',
              color: NullablePatch.value(ProblemSearchViewerFolderColor.red),
              visibility: BookmarkFolderVisibility.public,
            ),
          )
          .jsonBody,
      '{"slug":"b","name":"n","description":"d","color":"red",'
      '"visibility":"public"}',
    );
  });

  test('accepts text at its code-point bounds', () {
    final name = List.filled(256, '🌏').join();
    final description = List.filled(2048, '한').join();

    expect(
      jsonDecode(
        contract
            .updateBookmarkFolder(
              'a',
              BookmarkFolderPatch(name: name, description: description),
            )
            .jsonBody!,
      ),
      {'name': name, 'description': description},
    );
  });

  test('rejects arguments outside the official limits', () {
    for (final (slug, patch, field) in [
      ('A', const BookmarkFolderPatch(), 'slug'),
      ('', const BookmarkFolderPatch(), 'slug'),
      ('a', const BookmarkFolderPatch(slug: 'A'), 'patch.slug'),
      ('a', const BookmarkFolderPatch(slug: ''), 'patch.slug'),
      ('a', const BookmarkFolderPatch(name: ''), 'patch.name'),
      ('a', BookmarkFolderPatch(name: 'a' * 257), 'patch.name'),
      (
        'a',
        BookmarkFolderPatch(description: 'a' * 2049),
        'patch.description',
      ),
    ]) {
      expect(
        () => contract.updateBookmarkFolder(slug, patch),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', field),
        ),
        reason: field,
      );
    }
  });

  test('decodes the response with the shared strict folder decoder', () {
    final decode =
        contract.updateBookmarkFolder('a', const BookmarkFolderPatch()).decode;
    final folder = ((jsonDecode(fixture('v4/bookmark_folders.json'))
            as Map<String, dynamic>)['folders'] as List<dynamic>)
        .first as Map<String, dynamic>;

    expect(decode(folder).slug, folder['slug']);
    expect(
      () => decode(Map<String, dynamic>.of(folder)..remove('updatedAt')),
      throwsFormatException,
    );
  });
}
