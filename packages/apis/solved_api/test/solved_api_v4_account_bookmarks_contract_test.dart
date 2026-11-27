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

  test('builds viewer folders with an omitted or explicit problem id', () {
    final omitted = contract.accountBookmarks();
    final explicit = contract.accountBookmarks(problemId: 1);

    expect(omitted.proxy.path, 'account/bookmarks');
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.proxy.queryParameters, {'problemId': '1'});
    for (final id in [0, -1]) {
      expect(
        () => contract.accountBookmarks(problemId: id),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'problemId'),
        ),
      );
    }
  });

  test('decodes folders with the shared folder fields', () {
    final actual = contract.accountBookmarks().decode(
          jsonDecode(fixture('v4/account_bookmark_folders.json')),
        );

    expect(actual.folders, hasLength(3));
    expect(actual.folders.first.folder.slug, 'dp_set');
    expect(actual.folders.first.folder.owner.tier, 31);
    expect(actual.folders.first.containsProblem, isTrue);
    expect(actual.folders[1].folder.color, isNull);
    expect(actual.folders[1].containsProblem, isFalse);
  });

  test('requires containsProblem and every shared folder field', () {
    final endpoint = contract.accountBookmarks();
    for (final invalid in <Object?>[null, 0, 'folders', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    expect(
      () => endpoint.decode(<String, Object?>{}),
      throwsFormatException,
    );
    for (final invalid in <Object?>[_missing, null, 'true', 1]) {
      final body = _response();
      if (identical(invalid, _missing)) {
        _first(body).remove('containsProblem');
      } else {
        _first(body)['containsProblem'] = invalid;
      }
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: '$invalid',
      );
    }
    for (final field in ['slug', 'color', 'visibility', 'owner', 'createdAt']) {
      final missing = _response();
      _first(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: field,
      );
    }
  });

  test('eagerly snapshots an ordered unmodifiable list', () {
    final endpoint = contract.accountBookmarks();
    final body = _response();
    final folders = body['folders'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _first(body)['containsProblem'] = false;
    folders.clear();

    expect(actual.folders, hasLength(3));
    expect(actual.folders.first.containsProblem, isTrue);
    expect(() => actual.folders.clear(), throwsUnsupportedError);
  });
}

const _missing = Object();

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_bookmark_folders.json'))
        as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['folders'] as List<dynamic>).first as Map<String, dynamic>;
