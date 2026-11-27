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

  test('builds the viewer profile without query parameters', () {
    final endpoint = contract.accountProfile();

    expect(endpoint.proxy.path, 'account/profile');
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes every editable field without inference', () {
    final profile = contract
        .accountProfile()
        .decode(jsonDecode(fixture('v4/account_profile.json')))
        .profile;

    expect(profile.bio, 'raw / 한 글');
    expect(profile.profileImageUrl, 'not a URI');
    expect(profile.countryCode, 'ZZ');
    expect(profile.showCountry, isTrue);
    expect(profile.gender, 9);
    expect(profile.customGender, '');
    expect(profile.pronouns, 'they/them');
    expect(profile.showPronouns, isFalse);
    expect([
      profile.birthYear,
      profile.birthMonth,
      profile.birthDay
    ], [
      1900,
      12,
      31,
    ]);
    expect(profile.showBirthday, isTrue);
    expect(profile.showBirthYear, isFalse);
    expect(profile.name, 'Example Person');
    expect(profile.nameNative, '예시');
    expect(profile.showName, isTrue);
    expect(profile.showDiscord, isFalse);
    expect(profile.showIcpc, isTrue);
    expect(profile.backgroundId, -1);
  });

  test('requires every field and preserves nullable states', () {
    final endpoint = contract.accountProfile();
    for (final invalid in <Object?>[null, 0, 'profile', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    expect(() => endpoint.decode(<String, Object?>{}), throwsFormatException);
    expect(
      () => endpoint.decode(<String, Object?>{'profile': null}),
      throwsFormatException,
    );
    for (final field in _fields) {
      final missing = _response();
      _profile(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response();
      _profile(nulled)[field] = null;
      if (_nullable.contains(field)) {
        final profile = endpoint.decode(nulled).profile;
        expect(
          switch (field) {
            'bio' => profile.bio,
            'profileImageUrl' => profile.profileImageUrl,
            'countryCode' => profile.countryCode,
            'customGender' => profile.customGender,
            'pronouns' => profile.pronouns,
            'birthYear' => profile.birthYear,
            'birthMonth' => profile.birthMonth,
            'birthDay' => profile.birthDay,
            'name' => profile.name,
            'nameNative' => profile.nameNative,
            _ => profile.backgroundId,
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
  });

  test('enforces the documented gender set and country pattern', () {
    final endpoint = contract.accountProfile();
    for (final gender in <num>[0, 1, 2, 9, 2.0]) {
      final body = _response();
      _profile(body)['gender'] = gender;
      expect(endpoint.decode(body).profile.gender, gender);
    }
    for (final gender in <Object?>[3, -1, 0.5, '0', true]) {
      final body = _response();
      _profile(body)['gender'] = gender;
      expect(
        () => endpoint.decode(body),
        throwsFormatException,
        reason: '$gender',
      );
    }
    for (final code in ['K', 'kr', 'KOR', 'Kr', 'ＫＲ', 'KR\n', '']) {
      final body = _response();
      _profile(body)['countryCode'] = code;
      expect(() => endpoint.decode(body), throwsFormatException, reason: code);
    }
  });

  test('enforces documented length and range bounds at their edges', () {
    final endpoint = contract.accountProfile();
    for (final MapEntry(key: field, value: maximum) in _lengths.entries) {
      final atLimit = _response();
      _profile(atLimit)[field] = List.filled(maximum, '🌏').join();
      expect(() => endpoint.decode(atLimit), returnsNormally, reason: field);
      final over = _response();
      _profile(over)[field] = List.filled(maximum + 1, 'a').join();
      expect(() => endpoint.decode(over), throwsFormatException, reason: field);
    }
    for (final MapEntry(key: field, value: (minimum, maximum))
        in _ranges.entries) {
      for (final value in [minimum, maximum]) {
        final body = _response();
        _profile(body)[field] = value;
        expect(() => endpoint.decode(body), returnsNormally, reason: field);
      }
      for (final value in <Object?>[minimum - 1, maximum + 1, 1.0 * minimum]) {
        final body = _response();
        _profile(body)[field] = value;
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$field = $value',
        );
      }
    }
    for (final field in _flags) {
      final body = _response();
      _profile(body)[field] = 'true';
      expect(() => endpoint.decode(body), throwsFormatException, reason: field);
    }
    final background = _response();
    _profile(background)['backgroundId'] = 1.5;
    expect(() => endpoint.decode(background), throwsFormatException);
  });
}

const _flags = [
  'showCountry',
  'showPronouns',
  'showBirthday',
  'showBirthYear',
  'showName',
  'showDiscord',
  'showIcpc',
];

const _nullable = {
  'bio',
  'profileImageUrl',
  'countryCode',
  'customGender',
  'pronouns',
  'birthYear',
  'birthMonth',
  'birthDay',
  'name',
  'nameNative',
  'backgroundId',
};

const _fields = [..._nullable, ..._flags, 'gender'];

const _lengths = {
  'bio': 2000,
  'profileImageUrl': 1024,
  'customGender': 64,
  'pronouns': 64,
  'name': 128,
  'nameNative': 128,
};

const _ranges = {
  'birthYear': (1900, 2100),
  'birthMonth': (1, 12),
  'birthDay': (1, 31),
};

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_profile.json')) as Map<String, dynamic>;

Map<String, dynamic> _profile(Map<String, dynamic> body) =>
    body['profile'] as Map<String, dynamic>;
