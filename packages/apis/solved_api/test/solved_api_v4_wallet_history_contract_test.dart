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

  test('builds wallet history with omitted and explicit queries', () {
    final omitted = contract.walletHistory();
    final explicit = contract.walletHistory(month: '2026-11', language: '');

    expect(omitted.proxy.path, 'account/wallet/history');
    expect(omitted.proxy.queryParameters, isEmpty);
    expect(explicit.proxy.queryParameters, {'month': '2026-11', 'lang': ''});
    for (final month in ['2026-13', '2026-1', '', '2026-11-01']) {
      expect(
        () => contract.walletHistory(month: month),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'month'),
        ),
        reason: month,
      );
    }
    expect(
      () => contract.walletHistory(language: List.filled(17, 'a').join()),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'language'),
      ),
    );
  });

  test('decodes moves with the shared problem and title shapes', () {
    final actual = contract.walletHistory().decode(
          jsonDecode(fixture('v4/wallet_history.json')),
        );

    expect(actual.month, 'not a month');
    expect(actual.moves, hasLength(3));
    final first = actual.moves.first;
    expect([first.id, first.delta, first.balanceAfter], [-1, -5, 0]);
    expect(first.reason, WalletMoveReason.firstSolve);
    expect(first.at, 'not a date');
    expect(first.day, 'x');
    expect(first.label, 'raw / 한 글');
    expect(first.problem!.problem.problemId, 1000.5);
    expect(first.problem!.problem.userStatus, isNull);
    expect(first.problem!.titles, hasLength(2));
    expect(first.problem!.titles.first.title, '문제');
    final second = actual.moves[1];
    expect(second.reason, WalletMoveReason.shopPurchase);
    expect(second.day, isNull);
    expect(second.problem, isNull);
    expect(second.label, isNull);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.walletHistory();
    for (final invalid in <Object?>[null, 0, 'month', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['month', 'moves']) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode(_response()..[field] = null),
        throwsFormatException,
      );
    }
    for (final field in _moveFields) {
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
        final move = endpoint.decode(nulled).moves.first;
        expect(
          switch (field) {
            'day' => move.day,
            'problem' => move.problem,
            _ => move.label,
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
    for (final field in ['titles', 'userStatus', 'problemId']) {
      final body = _response();
      (_first(body)['problem'] as Map<String, dynamic>).remove(field);
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: 'problem.$field missing',
      );
    }
    final title = _response();
    (((_first(title)['problem'] as Map)['titles'] as List).first as Map)
        .remove('html');
    expect(() => endpoint.decode(title), throwsFormatException);
  });

  test('enforces the exact reason set and strict integers', () {
    final endpoint = contract.walletHistory();
    for (final reason in WalletMoveReason.values) {
      final body = _response();
      _first(body)['reason'] = reason.value;
      expect(endpoint.decode(body).moves.first.reason, reason);
    }
    for (final entry in <String, Object?>{
      'reason': 'firstSolve',
      'id': 1.0,
      'delta': '1',
      'balanceAfter': 1.5,
      'at': 0,
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

  test('eagerly snapshots ordered unmodifiable lists', () {
    final endpoint = contract.walletHistory();
    final body = _response();
    final moves = body['moves'] as List<dynamic>;
    final titles = (_first(body)['problem'] as Map)['titles'] as List;
    final actual = endpoint.decode(body);
    titles.clear();
    moves.clear();

    expect(actual.moves, hasLength(3));
    expect(actual.moves.first.problem!.titles, hasLength(2));
    expect(() => actual.moves.clear(), throwsUnsupportedError);
    expect(
      () => actual.moves.first.problem!.titles.clear(),
      throwsUnsupportedError,
    );
  });
}

const _moveFields = [
  'id',
  'delta',
  'balanceAfter',
  'reason',
  'at',
  'day',
  'problem',
  'label',
];

const _nullable = {'day', 'problem', 'label'};

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/wallet_history.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['moves'] as List<dynamic>).first as Map<String, dynamic>;
