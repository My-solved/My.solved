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

  test('builds the viewer settings without query parameters', () {
    final endpoint = contract.accountSettings();

    expect(endpoint.proxy.path, 'account/settings');
    expect(endpoint.proxy.queryParameters, isEmpty);
  });

  test('decodes every setting from the fixture', () {
    final body = _response();
    final settings = contract.accountSettings().decode(body).settings;

    expect(_getters.keys, unorderedEquals(_settings(body).keys));
    for (final MapEntry(key: field, value: getter) in _getters.entries) {
      final wire = _settings(body)[field];
      final expected = _enums[field]?[wire] ?? wire;
      expect(getter(settings), expected, reason: field);
    }
  });

  test('requires every setting and rejects null', () {
    final endpoint = contract.accountSettings();
    for (final invalid in <Object?>[null, 0, 'settings', const <Object?>[]]) {
      expect(() => endpoint.decode(invalid), throwsFormatException);
    }
    expect(() => endpoint.decode(<String, Object?>{}), throwsFormatException);
    expect(
      () => endpoint.decode(<String, Object?>{'settings': null}),
      throwsFormatException,
    );
    for (final field in _getters.keys) {
      final missing = _response();
      _settings(missing).remove(field);
      expect(
        () => endpoint.decode(missing),
        throwsFormatException,
        reason: '$field missing',
      );
      final nulled = _response();
      _settings(nulled)[field] = null;
      expect(
        () => endpoint.decode(nulled),
        throwsFormatException,
        reason: '$field null',
      );
    }
  });

  test('maps every exact enum value and rejects others', () {
    final endpoint = contract.accountSettings();
    for (final MapEntry(key: field, value: values) in _enums.entries) {
      for (final MapEntry(key: wire, value: expected) in values.entries) {
        final body = _response();
        _settings(body)[field] = wire;
        expect(
          _getters[field]!(endpoint.decode(body).settings),
          expected,
          reason: '$field = $wire',
        );
      }
      for (final invalid in <Object?>[
        values.keys.first.toUpperCase(),
        '${values.keys.first} ',
        'unknown',
        0,
      ]) {
        final body = _response();
        _settings(body)[field] = invalid;
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$field = $invalid',
        );
      }
    }
  });

  test('enforces strict booleans and inclusive integer bounds', () {
    final endpoint = contract.accountSettings();
    for (final field in _booleans) {
      for (final value in [true, false]) {
        final body = _response();
        _settings(body)[field] = value;
        expect(_getters[field]!(endpoint.decode(body).settings), value);
      }
      final body = _response();
      _settings(body)[field] = 'true';
      expect(() => endpoint.decode(body), throwsFormatException, reason: field);
    }
    for (final MapEntry(key: field, value: (minimum, maximum))
        in _integers.entries) {
      for (final value in [minimum, maximum]) {
        final body = _response();
        _settings(body)[field] = value;
        expect(_getters[field]!(endpoint.decode(body).settings), value);
      }
      for (final value in <Object?>[minimum - 1, maximum + 1, 1.5, '0']) {
        final body = _response();
        _settings(body)[field] = value;
        expect(
          () => endpoint.decode(body),
          throwsFormatException,
          reason: '$field = $value',
        );
      }
    }
  });
}

final _getters = <String, Object? Function(AccountSettings settings)>{
  'theme': (settings) => settings.theme,
  'iconTheme': (settings) => settings.iconTheme,
  'iconSchemeSolved': (settings) => settings.iconSchemeSolved,
  'iconSchemeUnsolved': (settings) => settings.iconSchemeUnsolved,
  'iconSchemeHover': (settings) => settings.iconSchemeHover,
  'iconWarnMode': (settings) => settings.iconWarnMode,
  'iconWarnRelative': (settings) => settings.iconWarnRelative,
  'iconWarnAbsolute': (settings) => settings.iconWarnAbsolute,
  'alwaysShowUnrated': (settings) => settings.alwaysShowUnrated,
  'alwaysShowUnratable': (settings) => settings.alwaysShowUnratable,
  'showSolvedUserCount': (settings) => settings.showSolvedUserCount,
  'showVotedUserCount': (settings) => settings.showVotedUserCount,
  'showTagButton': (settings) => settings.showTagButton,
  'tagDisplayLanguage': (settings) => settings.tagDisplayLanguage,
  'problemSort': (settings) => settings.problemSort,
  'problemSortDirection': (settings) => settings.problemSortDirection,
  'showOriginalTitle': (settings) => settings.showOriginalTitle,
  'showOriginalContest': (settings) => settings.showOriginalContest,
  'sourceLevelAllSolved': (settings) => settings.sourceLevelAllSolved,
  'sourceLevelPartlySolved': (settings) => settings.sourceLevelPartlySolved,
  'sourceLevelUnsolved': (settings) => settings.sourceLevelUnsolved,
  'sourceLevelHover': (settings) => settings.sourceLevelHover,
  'sourceLevelDisplay': (settings) => settings.sourceLevelDisplay,
  'sourceSort': (settings) => settings.sourceSort,
  'sourceSortDirection': (settings) => settings.sourceSortDirection,
  'sourceOrderType': (settings) => settings.sourceOrderType,
  'sourceOrderHover': (settings) => settings.sourceOrderHover,
};

final _enums = <String, Map<String, Object>>{
  'theme': {for (final value in AccountSettingTheme.values) value.value: value},
  'iconTheme': {
    for (final value in AccountSettingIconTheme.values) value.value: value
  },
  'iconSchemeSolved': {
    for (final value in AccountSettingIconScheme.values) value.value: value
  },
  'iconSchemeUnsolved': {
    for (final value in AccountSettingIconScheme.values) value.value: value
  },
  'iconSchemeHover': {
    for (final value in AccountSettingIconScheme.values) value.value: value
  },
  'iconWarnMode': {
    for (final value in AccountSettingIconWarnMode.values) value.value: value
  },
  'showSolvedUserCount': {
    for (final value in AccountSettingSolvedOnlyVisibility.values)
      value.value: value
  },
  'showVotedUserCount': {
    for (final value in AccountSettingSolvedOnlyVisibility.values)
      value.value: value
  },
  'showTagButton': {
    for (final value in AccountSettingSolvedOnlyVisibility.values)
      value.value: value
  },
  'tagDisplayLanguage': {
    for (final value in AccountSettingTagDisplayLanguage.values)
      value.value: value
  },
  'problemSort': {
    for (final value in AccountSettingProblemSort.values) value.value: value
  },
  'problemSortDirection': {
    for (final value in AccountSettingSortDirection.values) value.value: value
  },
  'sourceLevelAllSolved': {
    for (final value in AccountSettingVisibility.values) value.value: value
  },
  'sourceLevelPartlySolved': {
    for (final value in AccountSettingSourceLevelPartlySolved.values)
      value.value: value
  },
  'sourceLevelUnsolved': {
    for (final value in AccountSettingVisibility.values) value.value: value
  },
  'sourceLevelHover': {
    for (final value in AccountSettingVisibility.values) value.value: value
  },
  'sourceLevelDisplay': {
    for (final value in AccountSettingSourceLevelDisplay.values)
      value.value: value
  },
  'sourceSort': {
    for (final value in AccountSettingSourceSort.values) value.value: value
  },
  'sourceSortDirection': {
    for (final value in AccountSettingSortDirection.values) value.value: value
  },
  'sourceOrderType': {
    for (final value in AccountSettingSourceOrderType.values) value.value: value
  },
  'sourceOrderHover': {
    for (final value in AccountSettingVisibility.values) value.value: value
  },
};

const _booleans = [
  'alwaysShowUnrated',
  'alwaysShowUnratable',
  'showOriginalTitle',
  'showOriginalContest'
];

const _integers = {
  'iconWarnRelative': (-30, 30),
  'iconWarnAbsolute': (0, 30),
};

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_settings.json')) as Map<String, dynamic>;

Map<String, dynamic> _settings(Map<String, dynamic> body) =>
    body['settings'] as Map<String, dynamic>;
