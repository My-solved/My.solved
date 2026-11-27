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

  test('builds viewer items with an omitted or explicit language', () {
    expect(contract.accountItems().proxy.path, 'account/items');
    expect(contract.accountItems().proxy.queryParameters, isEmpty);
    expect(
      contract.accountItems(language: '').proxy.queryParameters,
      {'lang': ''},
    );
    expect(
      () => contract.accountItems(language: List.filled(17, 'a').join()),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'language'),
      ),
    );
  });

  test('decodes items, themes, and the shared vacation shape', () {
    final actual = contract.accountItems().decode(
          jsonDecode(fixture('v4/account_items.json')),
        );

    expect(actual.items, hasLength(3));
    final first = actual.items.first;
    expect(first.key, 'freeze');
    expect(first.kind, AccountItemKind.consumable);
    expect(first.effect, 'streak_freeze');
    expect(first.description, 'raw / 한 글');
    expect(first.imageUrl, 'not a URI');
    expect([first.units, first.maxUnits], [3, 2]);
    expect(first.usable, isTrue);
    expect(first.equipped, isTrue);
    expect(first.progress!.held, 5);
    expect(first.progress!.total, -1);
    expect(first.stacks, hasLength(3));
    expect(first.stacks.first.units, -1);
    expect(first.stacks.first.expiresAt, 'later');
    expect(first.stacks[1].expiresAt, isNull);
    expect(first.stacks[1].day, isNull);
    final second = actual.items[1];
    expect(second.kind, AccountItemKind.keepsake);
    expect(second.effect, isNull);
    expect(second.equipped, isNull);
    expect(second.progress, isNull);
    expect(second.stacks, isEmpty);
    expect(actual.streakThemes.equipped, 'not owned');
    expect(actual.streakThemes.owned.map((theme) => theme.theme), [
      'fire',
      '',
    ]);
    expect(actual.streakThemes.owned.last.acquiredAt, isNull);
    expect(actual.vacation!.fromDay, 'not a day');
    expect(actual.vacation!.source, ProfileActivityVacationSource.launch);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.accountItems();
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['items', 'streakThemes', 'vacation']) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
    }
    expect(endpoint.decode(_response()..['vacation'] = null).vacation, isNull);
    for (final field in _itemFields) {
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
        final item = endpoint.decode(nulled).items.first;
        expect(
          switch (field) {
            'effect' => item.effect,
            'equipped' => item.equipped,
            _ => item.progress,
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
    for (final field in ['units', 'expiresAt', 'day', 'usable', 'counted']) {
      final missing = _response();
      ((_first(missing)['stacks'] as List).first as Map).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: 'stacks[].$field missing',
      );
    }
    for (final field in ['held', 'total']) {
      final missing = _response();
      (_first(missing)['progress'] as Map).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
    }
    for (final (object, field) in [
      ('streakThemes', 'equipped'),
      ('streakThemes', 'owned'),
      ('vacation', 'fromDay'),
      ('vacation', 'source'),
    ]) {
      final missing = _response();
      (missing[object] as Map<String, dynamic>).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$object.$field missing',
      );
    }
    final owned = _response();
    (((owned['streakThemes'] as Map)['owned'] as List).first as Map)
        .remove('acquiredAt');
    expect(() => endpoint.decode(owned), throwsFormatException);
  });

  test('enforces exact enums and strict scalar types', () {
    final endpoint = contract.accountItems();
    for (final kind in AccountItemKind.values) {
      final body = _response();
      _first(body)['kind'] = kind.value;
      expect(endpoint.decode(body).items.first.kind, kind);
    }
    for (final entry in <String, Object?>{
      'kind': 'Consumable',
      'units': 1.0,
      'usable': 'true',
      'equipped': 1,
      'key': 0,
    }.entries) {
      final body = _response();
      _first(body)[entry.key] = entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
    final source = _response();
    (source['vacation'] as Map<String, dynamic>)['source'] = 'shop';
    expect(() => endpoint.decode(source), throwsFormatException);
  });

  test('eagerly snapshots ordered unmodifiable lists', () {
    final endpoint = contract.accountItems();
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final stacks = _first(body)['stacks'] as List<dynamic>;
    final owned = (body['streakThemes'] as Map)['owned'] as List<dynamic>;
    final actual = endpoint.decode(body);
    stacks.clear();
    owned.clear();
    items.clear();

    expect(actual.items, hasLength(3));
    expect(actual.items.first.stacks, hasLength(3));
    expect(actual.streakThemes.owned, hasLength(2));
    expect(() => actual.items.clear(), throwsUnsupportedError);
    expect(() => actual.items.first.stacks.clear(), throwsUnsupportedError);
    expect(() => actual.streakThemes.owned.clear(), throwsUnsupportedError);
  });
}

const _itemFields = [
  'key',
  'kind',
  'effect',
  'name',
  'description',
  'imageUrl',
  'units',
  'maxUnits',
  'usable',
  'equipped',
  'progress',
  'stacks',
];

const _nullable = {'effect', 'equipped', 'progress'};

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_items.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['items'] as List<dynamic>).first as Map<String, dynamic>;
