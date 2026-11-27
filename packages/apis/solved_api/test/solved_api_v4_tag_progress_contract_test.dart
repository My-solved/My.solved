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

  test('builds the bodyless viewer tag-progress endpoint', () {
    final endpoint = contract.tagProgress();
    expect(endpoint.proxy.path, 'me/tag-progress');
    expect(endpoint.proxy.queryParameters, isEmpty);
    expect(endpoint.direct.path, 'me/tag-progress');
  });

  test('decodes all three lists without joining them', () {
    final actual = contract.tagProgress().decode(
          jsonDecode(fixture('v4/tag_progress.json')),
        );

    expect(actual.counts.map((count) => count.key), ['math', '', 'math']);
    expect(actual.counts.first.problemCount, -1);
    expect(actual.items.first.key, 'dp');
    expect(actual.items.first.solved, 3);
    expect(actual.items.first.tried, -2);
    expect(actual.items.last.key, '한글');
    expect(actual.ratings.single.key, 'graphs');
    expect(actual.ratings.single.rating, -50);
  });

  test('requires every field with strict types', () {
    final endpoint = contract.tagProgress();
    for (final invalid in <Object?>[null, 0, 'counts', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['counts', 'items', 'ratings']) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode(_response()..[field] = null),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode(_response()..[field] = <Object?>[1]),
        throwsFormatException,
      );
    }
    for (final (list, field) in [
      ('counts', 'key'),
      ('counts', 'problemCount'),
      ('items', 'key'),
      ('items', 'solved'),
      ('items', 'tried'),
      ('ratings', 'key'),
      ('ratings', 'rating'),
    ]) {
      for (final invalid in <Object?>[_missing, null, 1.0, false]) {
        final body = _response();
        final entry = (body[list] as List).first as Map<String, dynamic>;
        if (identical(invalid, _missing)) {
          entry.remove(field);
        } else {
          entry[field] = field == 'key' && invalid == 1.0 ? 1 : invalid;
        }
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$list[].$field = $invalid',
        );
      }
    }
  });

  test('eagerly snapshots ordered unmodifiable lists', () {
    final endpoint = contract.tagProgress();
    final body = _response();
    final counts = body['counts'] as List<dynamic>;
    final items = body['items'] as List<dynamic>;
    final ratings = body['ratings'] as List<dynamic>;
    final actual = endpoint.decode(body);
    (counts.first as Map)['key'] = 'changed';
    counts.clear();
    items.clear();
    ratings.clear();

    expect(actual.counts, hasLength(3));
    expect(actual.counts.first.key, 'math');
    expect(actual.items, hasLength(2));
    expect(actual.ratings, hasLength(1));
    expect(() => actual.counts.clear(), throwsUnsupportedError);
    expect(() => actual.items.clear(), throwsUnsupportedError);
    expect(() => actual.ratings.clear(), throwsUnsupportedError);
    final empty = endpoint.decode(<String, Object?>{
      'counts': <Object?>[],
      'items': <Object?>[],
      'ratings': <Object?>[],
      'future': true,
    });
    expect(empty.counts, isEmpty);
  });
}

const _missing = Object();

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/tag_progress.json')) as Map<String, dynamic>;
