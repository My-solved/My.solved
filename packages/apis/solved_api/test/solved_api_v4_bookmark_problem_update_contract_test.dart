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
    final mutation = contract.updateBookmarkProblem(
      'z_9',
      1000,
      const BookmarkProblemPatch(),
    );

    expect(mutation.method, SolvedApiMutationMethod.patch);
    expect(mutation.proxy.path, 'account/bookmarks/z_9/problems/1000');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.successStatus, 200);
    expect(mutation.jsonBody, '{}');
  });

  test('wires every field to its own key with explicit nulls', () {
    for (final (patch, body) in <(BookmarkProblemPatch, Map<String, Object?>)>[
      (const BookmarkProblemPatch(after: 1), {'after': 1}),
      (
        const BookmarkProblemPatch(before: NullablePatch.value(2)),
        {'before': 2},
      ),
      (
        const BookmarkProblemPatch(before: NullablePatch.toNull()),
        {'before': null},
      ),
      (
        const BookmarkProblemPatch(note: NullablePatch.value('')),
        {'note': ''},
      ),
      (
        const BookmarkProblemPatch(note: NullablePatch.toNull()),
        {'note': null},
      ),
    ]) {
      expect(
        jsonDecode(contract.updateBookmarkProblem('a', 1, patch).jsonBody!),
        body,
      );
    }
    expect(
      contract
          .updateBookmarkProblem(
            'a',
            1,
            const BookmarkProblemPatch(
              after: 3,
              before: NullablePatch.value(4),
              note: NullablePatch.value('한 글'),
            ),
          )
          .jsonBody,
      '{"after":3,"before":4,"note":"한 글"}',
    );
    final note = List.filled(2048, '🌏').join();
    expect(
      jsonDecode(
        contract
            .updateBookmarkProblem(
              'a',
              1,
              BookmarkProblemPatch(note: NullablePatch.value(note)),
            )
            .jsonBody!,
      ),
      {'note': note},
    );
  });

  test('rejects arguments outside the official limits', () {
    for (final (slug, problemId, patch, field) in [
      ('A', 1, const BookmarkProblemPatch(), 'slug'),
      ('a', 0, const BookmarkProblemPatch(), 'problemId'),
      ('a', -1, const BookmarkProblemPatch(), 'problemId'),
      ('a', 1, const BookmarkProblemPatch(after: 0), 'patch.after'),
      (
        'a',
        1,
        const BookmarkProblemPatch(before: NullablePatch.value(0)),
        'patch.before',
      ),
      (
        'a',
        1,
        BookmarkProblemPatch(note: NullablePatch.value('a' * 2049)),
        'patch.note',
      ),
    ]) {
      expect(
        () => contract.updateBookmarkProblem(slug, problemId, patch),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', field),
        ),
        reason: field,
      );
    }
  });

  test('decodes with the shared strict folder-change decoder', () {
    final decode = contract
        .updateBookmarkProblem('a', 1, const BookmarkProblemPatch())
        .decode;
    final body = jsonDecode(fixture('v4/bookmark_folder_change.json'))
        as Map<String, dynamic>;

    expect(decode(body).changed, -0.5);
    expect(
      () => decode(Map<String, dynamic>.of(body)..remove('folder')),
      throwsFormatException,
    );
  });
}
