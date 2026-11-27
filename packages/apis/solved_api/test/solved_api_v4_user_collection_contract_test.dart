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

  test('builds the collection with omitted and explicit queries', () {
    final omitted = contract.userCollection('alice');
    final explicit = contract.userCollection(
      'a b&한',
      language: '',
      kind: OfficialAchievementItemKind.badge,
      sort: SolvedApiV4CollectionSort.recent,
      category: '',
      query: '',
      offset: 0,
    );
    final bounded = contract.userCollection(
      'alice',
      language: List.filled(16, '🌏').join(),
      kind: OfficialAchievementItemKind.background,
      sort: SolvedApiV4CollectionSort.rarity,
      category: List.filled(64, '한').join(),
      query: List.filled(64, 'q').join(),
      offset: 9007199254740991,
    );

    expect(omitted.direct.path, 'users/alice/collection');
    expect(omitted.direct.queryParameters, isEmpty);
    expect(omitted.proxy.path, omitted.direct.path);
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.direct.path, 'users/a%20b%26%ED%95%9C/collection');
    expect(explicit.direct.queryParameters, {
      'lang': '',
      'kind': 'badge',
      'sort': 'recent',
      'category': '',
      'q': '',
      'offset': '0',
    });
    expect(bounded.direct.queryParameters['kind'], 'background');
    expect(bounded.direct.queryParameters['sort'], 'rarity');
    expect(bounded.direct.queryParameters['offset'], '9007199254740991');
    expect(bounded.proxy.queryParameters, bounded.direct.queryParameters);
    expect(SolvedApiV4CollectionSort.values.map((sort) => sort.value), [
      'recent',
      'rarity',
      'name',
    ]);
  });

  test('rejects unsafe handles and out-of-bound query values', () {
    expect(
      () => contract.userCollection('a/b'),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'handle'),
      ),
    );
    final cases = <String, void Function()>{
      'language': () => contract.userCollection(
            'alice',
            language: List.filled(17, 'a').join(),
          ),
      'category': () => contract.userCollection(
            'alice',
            category: List.filled(65, 'a').join(),
          ),
      'query': () => contract.userCollection(
            'alice',
            query: List.filled(65, 'a').join(),
          ),
      'offset': () => contract.userCollection('alice', offset: -1),
    };
    for (final MapEntry(key: name, value: call) in cases.entries) {
      expect(
        call,
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', name),
        ),
        reason: name,
      );
    }
  });

  test('builds the viewer collection with the same query rules', () {
    final omitted = contract.accountCollection();
    final explicit = contract.accountCollection(
      language: '',
      kind: OfficialAchievementItemKind.background,
      sort: SolvedApiV4CollectionSort.name,
      category: '',
      query: '',
      offset: 0,
    );

    expect(omitted.proxy.path, 'account/collection');
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.proxy.queryParameters, {
      'lang': '',
      'kind': 'background',
      'sort': 'name',
      'category': '',
      'q': '',
      'offset': '0',
    });
    final cases = <String, void Function()>{
      'language': () =>
          contract.accountCollection(language: List.filled(17, 'a').join()),
      'category': () =>
          contract.accountCollection(category: List.filled(65, 'a').join()),
      'query': () =>
          contract.accountCollection(query: List.filled(65, 'a').join()),
      'offset': () => contract.accountCollection(offset: -1),
    };
    for (final MapEntry(key: name, value: call) in cases.entries) {
      expect(
        call,
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', name),
        ),
        reason: name,
      );
    }
    expect(
      omitted
          .decode(jsonDecode(fixture('v4/user_collection.json')))
          .counts
          .background,
      -2,
    );
  });

  test('decodes the complete fixture without inferred relationships', () {
    final actual = contract.userCollection('alice').decode(
          jsonDecode(fixture('v4/user_collection.json')),
        );

    expect(actual.total, -5);
    expect(actual.nextOffset, isNull);
    expect(actual.counts.badge, 0);
    expect(actual.counts.background, -2);
    expect(actual.categories, ['event', '', 'event']);
    expect(actual.items, hasLength(2));
    final first = actual.items.first;
    expect(first.kind, OfficialAchievementItemKind.badge);
    expect(first.id, -1);
    expect(first.key, 'first');
    expect(first.imageUrl, 'not necessarily a URI');
    expect(first.addedAt, 'not a date');
    expect(first.equipped, isTrue);
    expect(first.acquiredAt, 'set');
    expect(first.holderCount, 5);
    final last = actual.items.last;
    expect(last.kind, OfficialAchievementItemKind.background);
    expect(last.name, '');
    expect(last.category, '');
    expect(last.acquiredAt, '2026-01-01');
    expect(last.holderCount, -3);
    expect(actual.equipped!.equipped, isFalse);
    expect(actual.equipped!.category, 'raw / 한 글');
    expect(actual.equippedBadge, isNull);
    expect(actual.equippedBackground!.key, 'bg');
    expect(actual.equippedBackground!.holderCount, 0);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.userCollection('alice');
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in _outerFields) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response()..[field] = null;
      if (field == 'nextOffset' || field == 'equipped') {
        final actual = endpoint.decode(nulled);
        expect(
          field == 'nextOffset' ? actual.nextOffset : actual.equipped,
          isNull,
        );
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: '$field null',
        );
      }
    }
    for (final field in ['badge', 'background']) {
      final missing = _response();
      (missing['equippedByKind'] as Map<String, dynamic>).remove(field);
      expect(() => endpoint.decode(missing), throwsFormatException);
      final countMissing = _response();
      (countMissing['counts'] as Map<String, dynamic>).remove(field);
      expect(() => endpoint.decode(countMissing), throwsFormatException);
    }
    final bothNull = _response()
      ..['equippedByKind'] = <String, Object?>{
        'badge': null,
        'background': null,
      };
    expect(endpoint.decode(bothNull).equippedBackground, isNull);

    for (final field in _itemFields) {
      final missing = _response();
      _firstItem(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: 'items[].$field missing',
      );
      final nulled = _response();
      _firstItem(nulled)[field] = null;
      if (field == 'acquiredAt' || field == 'holderCount') {
        final item = endpoint.decode(nulled).items.first;
        expect(
          field == 'acquiredAt' ? item.acquiredAt : item.holderCount,
          isNull,
        );
      } else {
        expect(
          () => endpoint.decode(nulled),
          throwsFormatException,
          reason: 'items[].$field null',
        );
      }
    }
    final equippedMissing = _response();
    (equippedMissing['equipped'] as Map<String, dynamic>).remove('kind');
    expect(() => endpoint.decode(equippedMissing), throwsFormatException);
  });

  test('enforces strict integers, strings, booleans, and exact kinds', () {
    final endpoint = contract.userCollection('alice');
    for (final field in ['total', 'nextOffset']) {
      expect(
        () => endpoint.decode(_response()..[field] = 1.0),
        throwsFormatException,
      );
    }
    for (final field in ['id', 'holderCount']) {
      final body = _response();
      _firstItem(body)[field] = 1.0;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    for (final field in ['key', 'name', 'imageUrl', 'category', 'addedAt']) {
      final body = _response();
      _firstItem(body)[field] = 0;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    final equipped = _response();
    _firstItem(equipped)['equipped'] = 'true';
    expect(() => endpoint.decode(equipped), throwsFormatException);
    for (final invalid in <Object?>['Badge', 'item', '', 0]) {
      final body = _response();
      _firstItem(body)['kind'] = invalid;
      expect(() => endpoint.decode(body), throwsFormatException);
    }
    expect(
      () => endpoint.decode(_response()..['categories'] = ['ok', 0]),
      throwsFormatException,
    );
  });

  test('decodes non-null optional values and strict counts', () {
    final endpoint = contract.userCollection('alice');
    final body = _response()..['nextOffset'] = -7;
    final badge =
        Map<String, dynamic>.of(body['equipped'] as Map<String, dynamic>)
          ..['key'] = 'equipped-badge';
    (body['equippedByKind'] as Map<String, dynamic>)['badge'] = badge;
    final actual = endpoint.decode(body);
    expect(actual.nextOffset, -7);
    expect(actual.equippedBadge!.key, 'equipped-badge');
    expect(actual.equippedBadge!.kind, OfficialAchievementItemKind.badge);

    for (final field in ['badge', 'background']) {
      for (final invalid in <Object?>[null, 1.0, '1']) {
        final counts = _response();
        (counts['counts'] as Map<String, dynamic>)[field] = invalid;
        expect(
          () => endpoint.decode(counts),
          throwsFormatException,
          reason: 'counts.$field = $invalid',
        );
      }
    }
    for (final field in ['badge', 'background']) {
      final nested = _response();
      (nested['equippedByKind'] as Map<String, dynamic>)[field] =
          <String, Object?>{'kind': 'badge'};
      expect(() => endpoint.decode(nested), throwsFormatException);
    }
  });

  test('eagerly snapshots ordered unmodifiable lists', () {
    final endpoint = contract.userCollection('alice');
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final categories = body['categories'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _firstItem(body)['key'] = 'changed';
    items.clear();
    categories.clear();

    expect(actual.items, hasLength(2));
    expect(actual.items.first.key, 'first');
    expect(actual.categories, ['event', '', 'event']);
    expect(() => actual.items.clear(), throwsUnsupportedError);
    expect(() => actual.categories.clear(), throwsUnsupportedError);
    final empty = endpoint.decode(
      _response()
        ..['items'] = <Object?>[]
        ..['categories'] = <Object?>[]
        ..['future'] = true,
    );
    expect(empty.items, isEmpty);
    expect(empty.categories, isEmpty);
  });
}

const _outerFields = [
  'items',
  'total',
  'nextOffset',
  'counts',
  'categories',
  'equipped',
  'equippedByKind',
];

const _itemFields = [
  'kind',
  'id',
  'key',
  'name',
  'imageUrl',
  'category',
  'addedAt',
  'equipped',
  'acquiredAt',
  'holderCount',
];

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/user_collection.json')) as Map<String, dynamic>;

Map<String, dynamic> _firstItem(Map<String, dynamic> body) =>
    (body['items'] as List<dynamic>).first as Map<String, dynamic>;
