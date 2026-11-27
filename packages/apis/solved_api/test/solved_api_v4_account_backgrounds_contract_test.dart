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

  test('builds the bodyless viewer backgrounds endpoint', () {
    final endpoint = contract.accountBackgrounds();
    expect(endpoint.proxy.path, 'account/backgrounds');
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes backgrounds in picker order without inference', () {
    final actual = contract.accountBackgrounds().decode(
          jsonDecode(fixture('v4/account_backgrounds.json')),
        );

    expect(actual.backgrounds, hasLength(3));
    final first = actual.backgrounds.first;
    expect(first.id, -1);
    expect(first.key, 'default');
    expect(first.backgroundImageUrl, 'not a URI');
    expect(first.fallbackBackgroundImageUrl, 'fallback');
    expect(first.thumbnailImageUrl, 'thumb');
    expect(first.thumbnailPlaceholder, 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH');
    expect(first.isIllust, isTrue);
    expect(first.category, '');
    expect(first.createdAt, 'not a date');
    expect(first.acquiredAt, '2026-01-01');
    expect(first.ownedUserCount, 0);
    final second = actual.backgrounds[1];
    expect(second.fallbackBackgroundImageUrl, isNull);
    expect(second.thumbnailImageUrl, isNull);
    expect(second.thumbnailPlaceholder, isNull);
    expect(second.acquiredAt, isNull);
    expect(second.ownedUserCount, -3);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.accountBackgrounds();
    for (final invalid in <Object?>[
      null,
      0,
      'backgrounds',
      const <Object?>[]
    ]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final invalid in <Object?>[
      _missing,
      null,
      <Object?>[1]
    ]) {
      final body = _response();
      if (identical(invalid, _missing)) {
        body.remove('backgrounds');
      } else {
        body['backgrounds'] = invalid;
      }
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final field in _fields) {
      final missing = _response();
      _first(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response();
      _first(nulled)[field] = null;
      if (_nullable.contains(field)) {
        final item = endpoint.decode(nulled).backgrounds.first;
        expect(
          switch (field) {
            'fallbackBackgroundImageUrl' => item.fallbackBackgroundImageUrl,
            'thumbnailImageUrl' => item.thumbnailImageUrl,
            'thumbnailPlaceholder' => item.thumbnailPlaceholder,
            _ => item.acquiredAt,
          },
          isNull,
          reason: field,
        );
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final entry in <String, Object?>{
      'id': 1.0,
      'ownedUserCount': '1',
      'isIllust': 'true',
      'key': 0,
      'acquiredAt': 0,
    }.entries) {
      final body = _response();
      _first(body)[entry.key] = entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });

  test('eagerly snapshots an ordered unmodifiable list', () {
    final endpoint = contract.accountBackgrounds();
    final body = _response();
    final backgrounds = body['backgrounds'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _first(body)['key'] = 'changed';
    backgrounds.clear();

    expect(actual.backgrounds, hasLength(3));
    expect(actual.backgrounds.first.key, 'default');
    expect(() => actual.backgrounds.clear(), throwsUnsupportedError);
  });
}

const _missing = Object();

const _fields = [
  'id',
  'key',
  'backgroundImageUrl',
  'fallbackBackgroundImageUrl',
  'thumbnailImageUrl',
  'thumbnailPlaceholder',
  'isIllust',
  'category',
  'createdAt',
  'acquiredAt',
  'ownedUserCount',
];

const _nullable = {
  'fallbackBackgroundImageUrl',
  'thumbnailImageUrl',
  'thumbnailPlaceholder',
  'acquiredAt',
};

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_backgrounds.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['backgrounds'] as List<dynamic>).first as Map<String, dynamic>;
