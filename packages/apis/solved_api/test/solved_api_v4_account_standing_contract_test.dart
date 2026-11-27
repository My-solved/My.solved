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

  test('builds the bodyless viewer standing endpoint', () {
    final endpoint = contract.accountStanding();
    expect(endpoint.proxy.path, 'account/standing');
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes strikes and bans without inferred relationships', () {
    final actual = contract.accountStanding().decode(
          jsonDecode(fixture('v4/account_standing.json')),
        );

    expect(actual.priorStrikeBans, -1);
    expect(actual.nextBanDays, 0);
    expect(actual.bans.single.banType, OfficialUserProfileBanType.vote);
    expect(actual.bans.single.banReason, isNull);
    expect(actual.strikes, hasLength(3));
    final first = actual.strikes.first;
    expect(first.id, -1);
    expect(first.problem!.title, 'raw / 한 글');
    expect(first.problem!.problem.problemId, 1000.5);
    expect(first.problem!.problem.userStatus, ProblemUserStatus.tried);
    expect(first.category, AccountStrikeCategory.personalInfo);
    expect(first.text, '');
    expect(first.action, AccountStrikeAction.hidden);
    expect(first.createdAt, 'not a date');
    expect([first.seen, first.restored, first.appealable, first.strikeCleared],
        [true, false, false, true]);
    expect(first.appeal!.status, BanAppealStatus.pending);
    expect(first.appeal!.text, 'please');
    expect(first.appeal!.response, isNull);
    expect(first.strikeExpiresAt, 'later');
    final second = actual.strikes[1];
    expect(second.problem, isNull);
    expect(second.appeal, isNull);
    expect(second.strikeExpiresAt, isNull);
    expect(second.action, AccountStrikeAction.removed);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.accountStanding();
    for (final invalid in <Object?>[null, 0, 'strikes', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in ['strikes', 'bans', 'priorStrikeBans', 'nextBanDays']) {
      expect(
        () => endpoint.decode(_response()..remove(field)),
        throwsFormatException,
      );
      expect(
        () => endpoint.decode(_response()..[field] = null),
        throwsFormatException,
      );
    }
    for (final field in _strikeFields) {
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
        final strike = endpoint.decode(nulled).strikes.first;
        expect(
          switch (field) {
            'problem' => strike.problem,
            'appeal' => strike.appeal,
            _ => strike.strikeExpiresAt,
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
    final titleMissing = _response();
    (_first(titleMissing)['problem'] as Map<String, dynamic>).remove('title');
    expect(() => endpoint.decode(titleMissing), throwsFormatException);
    final titleNull = _response();
    (_first(titleNull)['problem'] as Map<String, dynamic>)['title'] = null;
    expect(endpoint.decode(titleNull).strikes.first.problem!.title, isNull);
    final problemField = _response();
    (_first(problemField)['problem'] as Map<String, dynamic>)
        .remove('userStatus');
    expect(() => endpoint.decode(problemField), throwsFormatException);
    final appealField = _response();
    (_first(appealField)['appeal'] as Map<String, dynamic>).remove('text');
    expect(() => endpoint.decode(appealField), throwsFormatException);
    final banField = _response();
    ((banField['bans'] as List).first as Map).remove('banReason');
    expect(() => endpoint.decode(banField), throwsFormatException);
  });

  test('enforces exact enums and strict scalar types', () {
    final endpoint = contract.accountStanding();
    for (final category in AccountStrikeCategory.values) {
      final body = _response();
      _first(body)['category'] = category.value;
      expect(endpoint.decode(body).strikes.first.category, category);
    }
    for (final action in AccountStrikeAction.values) {
      final body = _response();
      _first(body)['action'] = action.value;
      expect(endpoint.decode(body).strikes.first.action, action);
    }
    for (final entry in <String, Object?>{
      'category': 'personal_info',
      'action': 'Hidden',
      'id': 1.0,
      'seen': 1,
      'text': 0,
    }.entries) {
      final body = _response();
      _first(body)[entry.key] = entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
    for (final field in ['priorStrikeBans', 'nextBanDays']) {
      expect(
        () => endpoint.decode(_response()..[field] = 1.0),
        throwsFormatException,
      );
    }
  });

  test('eagerly snapshots ordered unmodifiable lists', () {
    final endpoint = contract.accountStanding();
    final body = _response();
    final strikes = body['strikes'] as List<dynamic>;
    final bans = body['bans'] as List<dynamic>;
    final actual = endpoint.decode(body);
    strikes.clear();
    bans.clear();

    expect(actual.strikes, hasLength(3));
    expect(actual.bans, hasLength(1));
    expect(() => actual.strikes.clear(), throwsUnsupportedError);
    expect(() => actual.bans.clear(), throwsUnsupportedError);
  });
}

const _strikeFields = [
  'id',
  'problem',
  'category',
  'text',
  'action',
  'createdAt',
  'seen',
  'restored',
  'appeal',
  'appealable',
  'strikeCleared',
  'strikeExpiresAt',
];

const _nullable = {'problem', 'appeal', 'strikeExpiresAt'};

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_standing.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['strikes'] as List<dynamic>).first as Map<String, dynamic>;
