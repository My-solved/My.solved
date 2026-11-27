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

  test('builds one PATCH with an empty object for an empty patch', () {
    final mutation = contract.updateAccountSettings(
      const AccountSettingsPatch(),
    );

    expect(mutation.method, SolvedApiMutationMethod.patch);
    expect(mutation.method.value, 'PATCH');
    expect(mutation.proxy.path, 'account/settings');
    expect(mutation.proxy.queryParameters, isEmpty);
    expect(mutation.jsonBody, '{}');
  });

  test('sends exactly the set fields with their wire values', () {
    final body = _response();
    final settings = contract.accountSettings().decode(body).settings;

    final mutation = contract.updateAccountSettings(_fullPatch(settings));

    expect(jsonDecode(mutation.jsonBody!), body['settings']);
    expect(
      (jsonDecode(mutation.jsonBody!) as Map<String, dynamic>).keys,
      orderedEquals((body['settings'] as Map<String, dynamic>).keys),
    );
    expect(
      contract
          .updateAccountSettings(
            const AccountSettingsPatch(
              theme: NullablePatch.value(AccountSettingTheme.light),
              iconTheme: NullablePatch.toNull(),
              alwaysShowUnrated: NullablePatch.value(false),
              iconWarnRelative: NullablePatch.value(-30),
            ),
          )
          .jsonBody,
      '{"theme":"light","iconTheme":null,"iconWarnRelative":-30,'
      '"alwaysShowUnrated":false}',
    );
  });

  test('wires every field to its own key', () {
    const cases = <(String, AccountSettingsPatch, Object)>[
      (
        'theme',
        AccountSettingsPatch(
            theme: NullablePatch.value(AccountSettingTheme.system)),
        'system',
      ),
      (
        'iconTheme',
        AccountSettingsPatch(
            iconTheme:
                NullablePatch.value(AccountSettingIconTheme.defaultValue)),
        'default',
      ),
      (
        'iconSchemeSolved',
        AccountSettingsPatch(
            iconSchemeSolved:
                NullablePatch.value(AccountSettingIconScheme.show)),
        'show',
      ),
      (
        'iconSchemeUnsolved',
        AccountSettingsPatch(
            iconSchemeUnsolved:
                NullablePatch.value(AccountSettingIconScheme.show)),
        'show',
      ),
      (
        'iconSchemeHover',
        AccountSettingsPatch(
            iconSchemeHover:
                NullablePatch.value(AccountSettingIconScheme.show)),
        'show',
      ),
      (
        'iconWarnMode',
        AccountSettingsPatch(
            iconWarnMode:
                NullablePatch.value(AccountSettingIconWarnMode.relative)),
        'relative',
      ),
      (
        'iconWarnRelative',
        AccountSettingsPatch(iconWarnRelative: NullablePatch.value(-30)),
        -30,
      ),
      (
        'iconWarnAbsolute',
        AccountSettingsPatch(iconWarnAbsolute: NullablePatch.value(0)),
        0,
      ),
      (
        'alwaysShowUnrated',
        AccountSettingsPatch(alwaysShowUnrated: NullablePatch.value(false)),
        false,
      ),
      (
        'alwaysShowUnratable',
        AccountSettingsPatch(alwaysShowUnratable: NullablePatch.value(false)),
        false,
      ),
      (
        'showSolvedUserCount',
        AccountSettingsPatch(
            showSolvedUserCount:
                NullablePatch.value(AccountSettingSolvedOnlyVisibility.show)),
        'show',
      ),
      (
        'showVotedUserCount',
        AccountSettingsPatch(
            showVotedUserCount:
                NullablePatch.value(AccountSettingSolvedOnlyVisibility.show)),
        'show',
      ),
      (
        'showTagButton',
        AccountSettingsPatch(
            showTagButton:
                NullablePatch.value(AccountSettingSolvedOnlyVisibility.show)),
        'show',
      ),
      (
        'tagDisplayLanguage',
        AccountSettingsPatch(
            tagDisplayLanguage: NullablePatch.value(
                AccountSettingTagDisplayLanguage.identifier)),
        'identifier',
      ),
      (
        'problemSort',
        AccountSettingsPatch(
            problemSort: NullablePatch.value(AccountSettingProblemSort.id)),
        'id',
      ),
      (
        'problemSortDirection',
        AccountSettingsPatch(
            problemSortDirection:
                NullablePatch.value(AccountSettingSortDirection.asc)),
        'asc',
      ),
      (
        'showOriginalTitle',
        AccountSettingsPatch(showOriginalTitle: NullablePatch.value(false)),
        false,
      ),
      (
        'showOriginalContest',
        AccountSettingsPatch(showOriginalContest: NullablePatch.value(false)),
        false,
      ),
      (
        'sourceLevelAllSolved',
        AccountSettingsPatch(
            sourceLevelAllSolved:
                NullablePatch.value(AccountSettingVisibility.show)),
        'show',
      ),
      (
        'sourceLevelPartlySolved',
        AccountSettingsPatch(
            sourceLevelPartlySolved: NullablePatch.value(
                AccountSettingSourceLevelPartlySolved.show)),
        'show',
      ),
      (
        'sourceLevelUnsolved',
        AccountSettingsPatch(
            sourceLevelUnsolved:
                NullablePatch.value(AccountSettingVisibility.show)),
        'show',
      ),
      (
        'sourceLevelHover',
        AccountSettingsPatch(
            sourceLevelHover:
                NullablePatch.value(AccountSettingVisibility.show)),
        'show',
      ),
      (
        'sourceLevelDisplay',
        AccountSettingsPatch(
            sourceLevelDisplay:
                NullablePatch.value(AccountSettingSourceLevelDisplay.dots)),
        'dots',
      ),
      (
        'sourceSort',
        AccountSettingsPatch(
            sourceSort:
                NullablePatch.value(AccountSettingSourceSort.defaultValue)),
        'default',
      ),
      (
        'sourceSortDirection',
        AccountSettingsPatch(
            sourceSortDirection:
                NullablePatch.value(AccountSettingSortDirection.asc)),
        'asc',
      ),
      (
        'sourceOrderType',
        AccountSettingsPatch(
            sourceOrderType:
                NullablePatch.value(AccountSettingSourceOrderType.show)),
        'show',
      ),
      (
        'sourceOrderHover',
        AccountSettingsPatch(
            sourceOrderHover:
                NullablePatch.value(AccountSettingVisibility.show)),
        'show',
      ),
    ];

    expect(cases.map((entry) => entry.$1).toSet(), hasLength(27));
    for (final (field, patch, wire) in cases) {
      expect(
        jsonDecode(contract.updateAccountSettings(patch).jsonBody!),
        {field: wire},
        reason: field,
      );
    }
  });

  test('sends an explicit null for every field', () {
    final mutation = contract.updateAccountSettings(_nullPatch);
    final body = jsonDecode(mutation.jsonBody!) as Map<String, dynamic>;

    expect(body.keys, hasLength(27));
    expect(body.values, everyElement(isNull));
  });

  test('rejects out-of-range integers before building a request', () {
    for (final value in [-30, 30]) {
      expect(
        contract
            .updateAccountSettings(
              AccountSettingsPatch(
                  iconWarnRelative: NullablePatch.value(value)),
            )
            .jsonBody,
        '{"iconWarnRelative":$value}',
      );
    }
    for (final value in [0, 30]) {
      expect(
        contract
            .updateAccountSettings(
              AccountSettingsPatch(
                  iconWarnAbsolute: NullablePatch.value(value)),
            )
            .jsonBody,
        '{"iconWarnAbsolute":$value}',
      );
    }
    for (final (field, patch) in [
      (
        'iconWarnRelative',
        const AccountSettingsPatch(iconWarnRelative: NullablePatch.value(-31)),
      ),
      (
        'iconWarnRelative',
        const AccountSettingsPatch(iconWarnRelative: NullablePatch.value(31)),
      ),
      (
        'iconWarnAbsolute',
        const AccountSettingsPatch(iconWarnAbsolute: NullablePatch.value(-1)),
      ),
      (
        'iconWarnAbsolute',
        const AccountSettingsPatch(iconWarnAbsolute: NullablePatch.value(31)),
      ),
    ]) {
      expect(
        () => contract.updateAccountSettings(patch),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', field),
        ),
      );
    }
  });

  test('decodes the response with the strict settings decoder', () {
    final mutation = contract.updateAccountSettings(
      const AccountSettingsPatch(),
    );
    final body = _response();

    expect(
      mutation.decode(body).settings.theme,
      contract.accountSettings().decode(body).settings.theme,
    );
    expect(
      () => mutation.decode(<String, Object?>{'settings': <String, Object?>{}}),
      throwsFormatException,
    );
  });
}

AccountSettingsPatch _fullPatch(AccountSettings settings) =>
    AccountSettingsPatch(
      theme: NullablePatch.value(settings.theme),
      iconTheme: NullablePatch.value(settings.iconTheme),
      iconSchemeSolved: NullablePatch.value(settings.iconSchemeSolved),
      iconSchemeUnsolved: NullablePatch.value(settings.iconSchemeUnsolved),
      iconSchemeHover: NullablePatch.value(settings.iconSchemeHover),
      iconWarnMode: NullablePatch.value(settings.iconWarnMode),
      iconWarnRelative: NullablePatch.value(settings.iconWarnRelative),
      iconWarnAbsolute: NullablePatch.value(settings.iconWarnAbsolute),
      alwaysShowUnrated: NullablePatch.value(settings.alwaysShowUnrated),
      alwaysShowUnratable: NullablePatch.value(settings.alwaysShowUnratable),
      showSolvedUserCount: NullablePatch.value(settings.showSolvedUserCount),
      showVotedUserCount: NullablePatch.value(settings.showVotedUserCount),
      showTagButton: NullablePatch.value(settings.showTagButton),
      tagDisplayLanguage: NullablePatch.value(settings.tagDisplayLanguage),
      problemSort: NullablePatch.value(settings.problemSort),
      problemSortDirection: NullablePatch.value(settings.problemSortDirection),
      showOriginalTitle: NullablePatch.value(settings.showOriginalTitle),
      showOriginalContest: NullablePatch.value(settings.showOriginalContest),
      sourceLevelAllSolved: NullablePatch.value(settings.sourceLevelAllSolved),
      sourceLevelPartlySolved:
          NullablePatch.value(settings.sourceLevelPartlySolved),
      sourceLevelUnsolved: NullablePatch.value(settings.sourceLevelUnsolved),
      sourceLevelHover: NullablePatch.value(settings.sourceLevelHover),
      sourceLevelDisplay: NullablePatch.value(settings.sourceLevelDisplay),
      sourceSort: NullablePatch.value(settings.sourceSort),
      sourceSortDirection: NullablePatch.value(settings.sourceSortDirection),
      sourceOrderType: NullablePatch.value(settings.sourceOrderType),
      sourceOrderHover: NullablePatch.value(settings.sourceOrderHover),
    );

const _nullPatch = AccountSettingsPatch(
  theme: NullablePatch.toNull(),
  iconTheme: NullablePatch.toNull(),
  iconSchemeSolved: NullablePatch.toNull(),
  iconSchemeUnsolved: NullablePatch.toNull(),
  iconSchemeHover: NullablePatch.toNull(),
  iconWarnMode: NullablePatch.toNull(),
  iconWarnRelative: NullablePatch.toNull(),
  iconWarnAbsolute: NullablePatch.toNull(),
  alwaysShowUnrated: NullablePatch.toNull(),
  alwaysShowUnratable: NullablePatch.toNull(),
  showSolvedUserCount: NullablePatch.toNull(),
  showVotedUserCount: NullablePatch.toNull(),
  showTagButton: NullablePatch.toNull(),
  tagDisplayLanguage: NullablePatch.toNull(),
  problemSort: NullablePatch.toNull(),
  problemSortDirection: NullablePatch.toNull(),
  showOriginalTitle: NullablePatch.toNull(),
  showOriginalContest: NullablePatch.toNull(),
  sourceLevelAllSolved: NullablePatch.toNull(),
  sourceLevelPartlySolved: NullablePatch.toNull(),
  sourceLevelUnsolved: NullablePatch.toNull(),
  sourceLevelHover: NullablePatch.toNull(),
  sourceLevelDisplay: NullablePatch.toNull(),
  sourceSort: NullablePatch.toNull(),
  sourceSortDirection: NullablePatch.toNull(),
  sourceOrderType: NullablePatch.toNull(),
  sourceOrderHover: NullablePatch.toNull(),
);

Map<String, dynamic> _response() =>
    jsonDecode(fixture('v4/account_settings.json')) as Map<String, dynamic>;
