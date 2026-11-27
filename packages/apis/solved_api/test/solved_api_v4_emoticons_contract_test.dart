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

  test('builds the bodyless emoticon catalog endpoint', () {
    final endpoint = contract.emoticons();
    expect(endpoint.proxy.path, 'me/emoticons');
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes the catalog in wire order', () {
    final actual = contract.emoticons().decode(
          jsonDecode(fixture('v4/emoticon_catalog.json')),
        );

    expect(actual.items.map((item) => item.key), ['smile', '', 'smile']);
    expect(actual.items.first.url, 'not a URI');
    expect(actual.items.first.category, '');
    expect(actual.items.first.displayName, 'Smile 😀');
    expect(actual.items.first.owned, isTrue);
    expect(actual.items[1].displayName, isNull);
    expect(actual.items[1].owned, isFalse);
  });

  test('requires every field and preserves the nullable display name', () {
    final endpoint = contract.emoticons();
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final invalid in <Object?>[
      _missing,
      null,
      <Object?>[1]
    ]) {
      final body = _response();
      if (identical(invalid, _missing)) {
        body.remove('items');
      } else {
        body['items'] = invalid;
      }
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final field in ['key', 'url', 'category', 'displayName', 'owned']) {
      final missing = _response();
      _first(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response();
      _first(nulled)[field] = null;
      if (field == 'displayName') {
        expect(endpoint.decode(nulled).items.first.displayName, isNull);
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
      final wrong = _response();
      _first(wrong)[field] = field == 'owned' ? 'true' : 0;
      expect(
        () => endpoint.decode(wrong),
        throwsFormatException,
        reason: '$field wrong type',
      );
    }
  });

  test('eagerly snapshots an ordered unmodifiable list', () {
    final endpoint = contract.emoticons();
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _first(body)['key'] = 'changed';
    items.clear();

    expect(actual.items, hasLength(3));
    expect(actual.items.first.key, 'smile');
    expect(() => actual.items.clear(), throwsUnsupportedError);
  });
}

const _missing = Object();

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/emoticon_catalog.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['items'] as List<dynamic>).first as Map<String, dynamic>;
