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

  test('builds one 201 POST with only the required fields by default', () {
    final mutation = contract.createBookmarkFolder(
      const NewBookmarkFolder(slug: 'z_9', name: '한'),
    );

    expect(mutation.method, SolvedApiMutationMethod.post);
    expect(mutation.proxy.path, 'account/bookmarks');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.successStatus, 201);
    expect(mutation.jsonBody, '{"slug":"z_9","name":"한"}');
  });

  test('sends every optional field with its wire value', () {
    for (final color in ProblemSearchViewerFolderColor.values) {
      for (final visibility in BookmarkFolderVisibility.values) {
        final mutation = contract.createBookmarkFolder(
          NewBookmarkFolder(
            slug: 'a',
            name: 'b',
            description: '',
            color: color,
            visibility: visibility,
          ),
        );
        expect(jsonDecode(mutation.jsonBody!), {
          'slug': 'a',
          'name': 'b',
          'description': '',
          'color': color.value,
          'visibility': visibility.value,
        });
      }
    }
  });

  test('accepts text at its code-point bounds', () {
    final name = List.filled(256, '🌏').join();
    final description = List.filled(2048, '한').join();

    final body = jsonDecode(
      contract
          .createBookmarkFolder(
            NewBookmarkFolder(
              slug: List.filled(32, 'a').join(),
              name: name,
              description: description,
            ),
          )
          .jsonBody!,
    ) as Map<String, dynamic>;

    expect(body['name'], name);
    expect(body['description'], description);
  });

  test('rejects fields outside the official limits before a request', () {
    for (final (folder, field) in [
      (const NewBookmarkFolder(slug: '', name: 'a'), 'slug'),
      (const NewBookmarkFolder(slug: 'A', name: 'a'), 'slug'),
      (NewBookmarkFolder(slug: 'a' * 33, name: 'a'), 'slug'),
      (const NewBookmarkFolder(slug: 'a', name: ''), 'name'),
      (NewBookmarkFolder(slug: 'a', name: 'a' * 257), 'name'),
      (
        NewBookmarkFolder(slug: 'a', name: 'a', description: 'a' * 2049),
        'description',
      ),
    ]) {
      expect(
        () => contract.createBookmarkFolder(folder),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', field),
        ),
        reason: field,
      );
    }
  });

  test('decodes the response with the shared strict folder decoder', () {
    final decode = contract
        .createBookmarkFolder(const NewBookmarkFolder(slug: 'a', name: 'b'))
        .decode;
    final folder = _folder();

    final actual = decode(folder);

    expect(actual.slug, folder['slug']);
    expect(actual.name, folder['name']);
    expect(actual.visibility.value, folder['visibility']);
    for (final invalid in <Object?>[null, 0, 'folder', const <Object?>[]]) {
      expect(() => decode(invalid), throwsFormatException);
    }
    for (final field in ['slug', 'color', 'owner', 'solvedCount']) {
      expect(
        () => decode(_folder()..remove(field)),
        throwsFormatException,
        reason: field,
      );
    }
  });
}

Map<String, dynamic> _folder() => Map<String, dynamic>.of(
      ((jsonDecode(fixture('v4/bookmark_folders.json'))
              as Map<String, dynamic>)['folders'] as List<dynamic>)
          .first as Map<String, dynamic>,
    );
