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

  test('builds the bodyless viewer bans endpoint', () {
    final endpoint = contract.accountBans();
    expect(endpoint.proxy.path, 'account/bans');
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes bans with the shared profile-ban fields', () {
    final actual = contract.accountBans().decode(
          jsonDecode(fixture('v4/account_bans.json')),
        );

    expect(actual.items, hasLength(3));
    final first = actual.items.first;
    expect(first.ban.banType, OfficialUserProfileBanType.vote);
    expect(first.ban.banReason, OfficialUserProfileBanReason.voteProfanity);
    expect(first.ban.reason, 'raw / 한 글');
    expect(first.ban.until, 'not a date');
    expect(first.id, -1);
    expect(first.appealable, isFalse);
    expect(first.appeal!.status, BanAppealStatus.denied);
    expect(first.appeal!.text, '');
    expect(first.appeal!.appealedAt, 'x');
    expect(first.appeal!.response, 'no');
    final second = actual.items[1];
    expect(second.ban.banType, OfficialUserProfileBanType.rating);
    expect(second.ban.banReason, isNull);
    expect(second.appealable, isTrue);
    expect(second.appeal, isNull);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.accountBans();
    for (final invalid in <Object?>[null, 0, 'items', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    for (final field in [
      'banType',
      'banReason',
      'reason',
      'until',
      'id',
      'appealable',
      'appeal',
    ]) {
      final missing = _response();
      _first(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
    }
    for (final field in ['banType', 'reason', 'until', 'id', 'appealable']) {
      final nulled = _response();
      _first(nulled)[field] = null;
      expect(() => endpoint.decode(nulled), throwsFormatException);
    }
    final nullReason = _response();
    _first(nullReason)['banReason'] = null;
    expect(endpoint.decode(nullReason).items.first.ban.banReason, isNull);
    final nullAppeal = _response();
    _first(nullAppeal)['appeal'] = null;
    expect(endpoint.decode(nullAppeal).items.first.appeal, isNull);

    for (final field in ['status', 'text', 'appealedAt', 'response']) {
      final missing = _response();
      (_first(missing)['appeal'] as Map<String, dynamic>).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: 'appeal.$field missing',
      );
    }
    final nullResponse = _response();
    (_first(nullResponse)['appeal'] as Map<String, dynamic>)['response'] = null;
    expect(endpoint.decode(nullResponse).items.first.appeal!.response, isNull);
  });

  test('enforces exact enums and strict scalar types', () {
    final endpoint = contract.accountBans();
    for (final status in BanAppealStatus.values) {
      final body = _response();
      (_first(body)['appeal'] as Map<String, dynamic>)['status'] = status.value;
      expect(endpoint.decode(body).items.first.appeal!.status, status);
    }
    for (final entry in <String, Object?>{
      'banType': 'Vote',
      'banReason': 'vote_spam',
      'id': 1.0,
      'appealable': 'false',
      'reason': 0,
    }.entries) {
      final body = _response();
      _first(body)[entry.key] = entry.value;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: entry.key,
      );
    }
    final status = _response();
    (_first(status)['appeal'] as Map<String, dynamic>)['status'] = 'Pending';
    expect(() => endpoint.decode(status), throwsFormatException);
  });

  test('eagerly snapshots an ordered unmodifiable list', () {
    final endpoint = contract.accountBans();
    final body = _response();
    final items = body['items'] as List<dynamic>;
    final actual = endpoint.decode(body);
    _first(body)['reason'] = 'changed';
    items.clear();

    expect(actual.items, hasLength(3));
    expect(actual.items.first.ban.reason, 'raw / 한 글');
    expect(() => actual.items.clear(), throwsUnsupportedError);
  });
}

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_bans.json')) as Map<String, dynamic>;

Map<String, dynamic> _first(Map<String, dynamic> body) =>
    (body['items'] as List<dynamic>).first as Map<String, dynamic>;
